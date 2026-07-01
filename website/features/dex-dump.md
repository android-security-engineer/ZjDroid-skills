# DEX 内存 Dump（dump_dexfile）

和 [BackSmali 脱壳](./backsmali) 不同，`dump_dexfile` **不做反编译**，它直接把内存中的 DEX 原样导出成一个文件。更轻量、更快，但产物是 odex 格式，需要 PC 上再处理。

## 指令

```bash
adb shell am broadcast -a com.zjdroid.invoke \
  --ei target <PID> \
  --es cmd '{"action":"dump_dexfile","dexpath":"<DEX路径>"}'
```

## 与 backsmali 的区别

| | `backsmali` | `dump_dexfile` |
|---|------------|----------------|
| 做反汇编重组？ | ✅ 是 | ❌ 否 |
| 产物 | 干净的 `.dex` | odex 格式的内存数据 |
| 能直接 jadx 阅读？ | ✅ 能 | ❌ 需 PC 上再反编译 |
| 速度 | 慢（跑 baksmali） | 快（直接拷内存） |

简单说：`backsmali` 是"帮你反编译好"，`dump_dexfile` 是"把内存原样给你，你自己回去反编译"。

## 实现原理

入口是 [`DexFileInfoCollecter.dumpDexFile`](https://github.com/android-security-engineer/ZjDroid-skills/blob/master/src/com/android/reverse/collecter/DexFileInfoCollecter.java#L154)：

```java
public void dumpDexFile(String filename, String dexPath) {
    File file = new File(filename);
    if (!file.exists()) file.createNewFile();

    int mCookie = this.getCookie(dexPath);        // 按路径拿到 mCookie
    if (mCookie != 0) {
        FileOutputStream out = new FileOutputStream(file);
        // 关键：native 方法直接把整个 DEX 内存导出成 ByteBuffer
        ByteBuffer data = NativeFunction.dumpDexFileByCookie(
            mCookie, ModuleContext.getInstance().getApiLevel());
        data.order(ByteOrder.LITTLE_ENDIAN);       // DEX 小端

        // 分块写入文件
        byte[] buffer = new byte[8192];
        data.clear();
        while (data.hasRemaining()) {
            int count = Math.min(buffer.length, data.remaining());
            data.get(buffer, 0, count);
            out.write(buffer, 0, count);
        }
    }
}
```

核心就一行 native 调用：

```java
public static native ByteBuffer dumpDexFileByCookie(int cookie, int version);
```

`libdvmnative.so` 里这个函数的作用：给定 `mCookie` 和 Android 版本，解析 Dalvik 的 `DexFile` 结构体，**把整个 DEX 的内存数据打包成一个 `ByteBuffer` 返回**。Java 层再以 8KB 为块写入文件。

::: tip 为什么传 version
和 BackSmali 一样，不同 Android 版本的 Dalvik `DexFile` 结构体布局有差异，native 层需要按 `version`（apiLevel）选择正确的偏移来解析。这就是 `NativeFunction` 多处都带 `version` 参数的原因。
:::

## 产物

导出的文件路径（由 `DumpDexFileCommandHandler` 决定）会通过 logcat 输出：

```
the dexfile data save to = /data/data/<包名>/files/<filename>
```

::: warning 是 odex 格式
README 明确说："数据为 odex 格式，可在 pc 上反编译。" 也就是说产物不是标准 dex，可能带有 odex 头或结构差异，需要用 baksmali（带 `deodex` 选项）等工具在 PC 上处理，而不能直接拖进 jadx。
:::

## 什么时候用 dump_dexfile 而不是 backsmali

- **想要最快的速度**拿到内存 DEX，不在设备上花时间反汇编；
- **App 较大**，设备端 BackSmali 太慢甚至 OOM，宁可拷回 PC 处理；
- **想保留内存中 DEX 的原始状态**用于分析（BackSmali 经过反汇编-重组会有微小变化）。

## 小结

| 要点 | 说明 |
|------|------|
| 核心 native | `dumpDexFileByCookie(cookie, version)` |
| 流程 | mCookie → native 导出 ByteBuffer → 分块写文件 |
| 产物 | odex 格式内存数据，需 PC 再反编译 |
| 优势 | 快，省设备算力 |

---

下一步：[类信息枚举](./dump-class)。
