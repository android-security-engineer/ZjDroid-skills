# 内存 BackSmali 脱壳（backsmali）

这是 ZjDroid **最核心的能力**：基于 Dalvik 内存指针，直接从进程内存中把 DEX 反编译成 smali，再重新组装成一个干净的可读 dex 文件。它能破解当时主流的加固方案。

## 指令

```bash
adb shell am broadcast -a com.zjdroid.invoke \
  --ei target <PID> \
  --es cmd '{"action":"backsmali","dexpath":"<DEX路径>"}'
```

`dexpath` 来自上一步 `dump_dexinfo` 的输出。

## 它解决什么问题

加固 App 的真实 DEX 只在内存中以明文存在。但"内存里有明文 DEX"和"拿到一个能用的 dex 文件"之间，还隔着几个难题：

1. 内存里的 DEX 可能**不完整**（壳可能抹掉了部分头或索引）；
2. 即便完整，直接 dump 出来的内存块可能带垃圾数据，**baksmali 反编译会报错**；
3. 我们最终要的是**能在 PC 上用 jadx 阅读的 dex 文件**。

`backsmali` 的解法是：**绕过文件、绕过内存块的物理边界，直接依据 Dalvik 内部指针表重建 DEX 结构，反汇编成 smali，再用 smali 重新组装成一个全新的、干净的 dex。**

## 实现原理

核心类是 [`MemoryBackSmali`](https://github.com/android-security-engineer/ZjDroid-skills/blob/master/src/com/android/reverse/smali/MemoryBackSmali.java)。整个流程分四步。

### 第 1 步：从 mCookie 解析出 DEX 各索引表的内存指针

`mCookie` 只是一个整型句柄，要拿到 DEX 在内存里的真实结构，需要 native 库 `libdvmnative.so` 帮忙。入口在 `NativeFunction.queryDexFileItemPointer`：

```java
public static MemoryDexFileItemPointer queryDexFileItemPointer(int cookie) {
    int version = ModuleContext.getInstance().getApiLevel();
    // 调 native：从 mCookie 解析出 DexFile 结构体的各字段地址
    DexFileHeadersPointer iteminfo = getHeaderItemPtr(cookie, version);

    MemoryDexFileItemPointer pointer = new MemoryDexFileItemPointer();
    pointer.setBaseAddr(iteminfo.getBaseAddr());      // DEX 在内存的基地址
    pointer.setpClassDefs(iteminfo.getpClassDefs());   // class_defs 表指针
    pointer.setpFieldIds(iteminfo.getpFieldIds());     // field_ids 表指针
    pointer.setpMethodIds(iteminfo.getpMethodIds());   // method_ids 表指针
    pointer.setpProtoIds(iteminfo.getpProtoIds());     // proto_ids 表指针
    pointer.setpStringIds(iteminfo.getpStringIds());   // string_ids 表指针
    pointer.setpTypeIds(iteminfo.getpTypeIds());       // type_ids 表指针
    pointer.setClassCount(iteminfo.getClassCount());   // 类的数量
    return pointer;
}
```

::: tip DEX 文件结构回顾
一个标准 DEX 文件由若干"索引表 + 数据区"组成：`string_ids`、`type_ids`、`proto_ids`、`field_ids`、`method_ids`、`class_defs`，最后是数据区。Dalvik 加载 DEX 后，会在内存里维护一个 `DexFile` 结构体，记录这些表的指针。`libdvmnative.so` 的工作就是：给定 `mCookie`，读出这个 `DexFile` 结构体，把各表指针告诉我们。

**这就是 ZjDroid 为什么强绑定 Dalvik**——它读的是 Dalvik 内部的 `DexFile` 结构体布局，不同 Android 版本布局还不同（所以要传 `version`/apiLevel）。ART 里这套结构完全不存在了。
:::

### 第 2 步：构造一个"内存版" DexBackedDexFile

拿到各表指针后，ZjDroid 没有把内存拷贝成文件再交给 baksmali，而是构造了一个**直接从内存读**的 `DexBackedDexFile`：

```java
Opcodes opcodes = new Opcodes(ModuleContext.getInstance().getApiLevel());

MemoryReader reader = new NativeFunction();          // 读内存的实现
MemoryDexFileItemPointer pointer = NativeFunction.queryDexFileItemPointer(mCookie);

DexBackedDexFile mmDexFile = new DexBackedDexFile(opcodes, pointer, reader);
```

`NativeFunction` 实现了 `MemoryReader` 接口，其 `readBytes` 通过 native 方法 `dumpMemory` 直接读进程内存：

```java
public byte[] readBytes(int addr, int length) {
    ByteBuffer data = dumpMemory(addr, length);      // native: 读内存
    data.order(ByteOrder.LITTLE_ENDIAN);              // DEX 是小端
    byte[] buffer = new byte[data.capacity()];
    data.get(buffer, 0, data.capacity());
    return buffer;
}
```

这样 baksmali 反汇编时，每需要读一段 DEX 数据，就由 `MemoryReader` 直接去内存里抓——**完全绕过了文件**。

### 第 3 步：配置 baksmali 选项并多线程反汇编

[`configOptions()`](https://github.com/android-security-engineer/ZjDroid-skills/blob/master/src/com/android/reverse/smali/MemoryBackSmali.java#L37) 配置 baksmali，几个关键项：

```java
options.outputDirectory = ".../files/smali";   // smali 输出目录
options.allowOdex = true;
options.deodex = true;                         // 反 odex
options.jobs = 8;                              // 8 线程并发反汇编
options.apiLevel = ...;                        // 决定 opcode 版本
options.bootClassPathDirs.add("/system/framework/");  // 系统框架类路径
```

然后配置类路径（用于解析父类、inline 方法等）：

```java
options.bootClassPathEntries = getDefaultBootClassPathForApi(options.apiLevel);
options.classPath = ClassPath.fromClassPath(..., mmDexFile, options.apiLevel);

// inline 方法解析器（Dalvik 的 quick 指令需要）
String inlineString = NativeFunction.getInlineOperation();   // native: 取设备的 inline 表
options.inlineResolver = new CustomInlineMethodResolver(options.classPath, inlineString);
```

::: tip inline 方法
Dalvik 会把一些短小的方法（如 `Math.abs`）编译成 inline 指令直接嵌入调用处。反汇编时若不还原这些 inline，smali 会看不懂。ZjDroid 通过 native 读取设备实际的 inline 操作表，构造 `CustomInlineMethodResolver` 来正确还原。
:::

反汇编是**多线程**的，每个类一个任务：

```java
ExecutorService executor = Executors.newFixedThreadPool(options.jobs);  // 8 线程
for (final ClassDef classDef : classDefs) {
    tasks.add(executor.submit(() -> disassembleClass(classDef, fileNameHandler, options)));
}
```

每个类被反汇编成一个 `.smali` 文件，存到 `files/smali/` 目录下。

### 第 4 步：用 smali 重新组装成 dex

反汇编得到一堆 smali 文件后，调用 `DexFileBuilder` 把它们重新组装：

```java
boolean result = DexFileBuilder.buildDexFile(options.outputDirectory, outDexName);
// 最终产物：/data/data/<包名>/files/dexfile.dex
```

成功后清理临时 smali 目录：

```java
if (result) {
    Runtime.getRuntime().exec("rm -rf " + options.outputDirectory);
}
```

## 完整链路

```
mCookie
  │  NativeFunction.queryDexFileItemPointer (libdvmnative.so)
  ▼
各索引表内存指针 (baseAddr, pClassDefs, pMethodIds, ...)
  │  DexBackedDexFile + MemoryReader (直接读内存)
  ▼
baksmali 多线程反汇编
  │  (8 线程，每类一个 .smali)
  ▼
files/smali/*.smali
  │  DexFileBuilder.buildDexFile
  ▼
files/dexfile.dex  ← 干净的、可被 jadx 反编译的真实 DEX（脱壳成功）
```

## 为什么这样能脱壳

关键在于 ZjDroid **不依赖文件层面**：

- 加固保护的是**文件**（APK 里的 dex 是加密的），但 Dalvik 加载后内存里有明文；
- ZjDroid 通过 `mCookie` 拿到 Dalvik 内部的 `DexFile` 结构指针，**直接按指针从内存读 DEX 内容**，绕过了文件加密；
- 经过 baksmali 反汇编 → smali → 重组，得到的 `dexfile.dex` 是一个**全新的、结构完整的、不带壳的 dex**，可以直接用 jadx 阅读。

这就完成了脱壳。

## 性能提示

README 原话："由于手机性能问题，运行较忙。" BackSmali 要在目标进程内跑完整的反汇编 + 重组，对大 App 较慢。日志会输出各阶段耗时：

```
start disassemble the mCookie 12345678
end disassemble the mCookie: cost time = 12s
start build the smali files to dex
end build the smali files to dex: cost time = 5s
the dexfile data save to = /data/data/<包名>/files/dexfile.dex
```

耐心等待即可。

## 小结

| 要点 | 说明 |
|------|------|
| 输入 | `dexpath` → 经 `getCookie` 得到 `mCookie` |
| 核心 native | `libdvmnative.so`：`getHeaderItemPtr`、`dumpMemory`、`getInlineOperation` |
| 反汇编 | baksmali + `MemoryReader` 直接读内存，8 线程 |
| 重组 | `DexFileBuilder` 把 smali 组装回 dex |
| 产物 | `/data/data/<包名>/files/dexfile.dex` |
| 局限 | 强绑定 Dalvik；ART 上不可用 |

---

接下来看更简单的 [DEX 内存 Dump](./dex-dump)（不做反编译，直接导出内存 DEX）。
