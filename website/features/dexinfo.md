# DEX 加载信息收集（dump_dexinfo）

这是脱壳工作流的**第一步**：搞清楚目标进程到底加载了哪些 DEX、它们的内存指针是什么。后续的 `backsmali`、`dump_dexfile`、`dump_class` 都依赖这一步拿到的 `mCookie`。

## 指令

```bash
adb shell am broadcast -a com.zjdroid.invoke \
  --ei target <PID> \
  --es cmd '{"action":"dump_dexinfo"}'
```

## 它解决什么问题

加固 App 的真实 DEX 不在文件里，只在内存里。要 dump 它，首先得回答两个问题：

1. **进程加载了哪些 DEX？**（不止 APK 自带的，还有运行时动态加载的）
2. **每个 DEX 在内存里的"入口指针"是什么？**（Dalvik 里就是 `mCookie`）

`dump_dexinfo` 就是来回答这两个问题的。

## 实现原理

核心类是 [`DexFileInfoCollecter`](https://github.com/android-security-engineer/ZjDroid-skills/blob/master/src/com/android/reverse/collecter/DexFileInfoCollecter.java)。它在模块启动时就 hook 了 Dalvik 加载 DEX 的 native 入口，被动记录每一次加载。

### 1. Hook `openDexFileNative`

Dalvik 加载一个 DEX 文件时，最终会调用：

```java
dalvik.system.DexFile.openDexFileNative(String sourcePath, String outputPath, int flags)
```

它的**返回值是一个 `int mCookie`**——这就是指向内存中 DEX 的句柄。ZjDroid hook 这个方法的 `after`：

```java
Method openDexFileNativeMethod = RefInvoke.findMethodExact(
    "dalvik.system.DexFile", ClassLoader.getSystemClassLoader(),
    "openDexFileNative", String.class, String.class, int.class);

hookhelper.hookMethod(openDexFileNativeMethod, new MethodHookCallBack() {
    @Override
    public void afterHookedMethod(HookParam param) {
        String dexPath = (String) param.args[0];     // 加载的 DEX 路径
        int mCookie = (Integer) param.getResult();   // 返回的内存句柄
        if (mCookie != 0) {
            dynLoadedDexInfo.put(dexPath, new DexFileInfo(dexPath, mCookie));
        }
    }
});
```

> **关键点**：`mCookie != 0` 才记录。0 表示加载失败。

这样，App 每加载一个 DEX（包括壳代码动态解密后加载的真实 DEX），ZjDroid 都会悄悄记下它的路径和 `mCookie`，存进 `dynLoadedDexInfo` 这个 Map。

### 2. Hook `defineClassNative`（记录 ClassLoader）

```java
dalvik.system.DexFile.defineClassNative(String name, ClassLoader loader, int mCookie)
```

这个方法把类从 DEX 里定义出来。ZjDroid hook 它，是为了把 `mCookie` 和对应的 `ClassLoader` 关联起来——后续如果想用目标 App 的 ClassLoader 反射调用类，会用到。

### 3. dumpDexFileInfo：合并"动态加载"与"静态加载"

当收到 `dump_dexinfo` 指令时，`DumpDexInfoCommandHandler` 调用 `dumpDexFileInfo()`。这个方法合并两个来源：

```java
public HashMap<String, DexFileInfo> dumpDexFileInfo() {
    // 来源 A：运行时通过 openDexFileNative 动态加载的 DEX（壳解密出来的）
    HashMap<String, DexFileInfo> dexs = new HashMap<>(dynLoadedDexInfo);

    // 来源 B：APK 启动时就已加载的 DEX（从 PathClassLoader 的 pathList 里枚举）
    Object dexPathList = RefInvoke.getFieldOjbect(
        "dalvik.system.BaseDexClassLoader", pathClassLoader, "pathList");
    Object[] dexElements = (Object[]) RefInvoke.getFieldOjbect(
        "dalvik.system.DexPathList", dexPathList, "dexElements");

    for (int i = 0; i < dexElements.length; i++) {
        DexFile dexFile = (DexFile) RefInvoke.getFieldOjbect(
            "dalvik.system.DexPathList$Element", dexElements[i], "dexFile");
        String mFileName = (String) RefInvoke.getFieldOjbect(
            "dalvik.system.DexFile", dexFile, "mFileName");
        int mCookie = RefInvoke.getFieldInt("dalvik.system.DexFile", dexFile, "mCookie");
        dexs.put(mFileName, new DexFileInfo(mFileName, mCookie, pathClassLoader));
    }
    return dexs;
}
```

- **来源 A**：动态加载的 DEX（`dynLoadedDexInfo`）——这是壳解密出来的真实 DEX，**脱壳最关心的就是这部分**；
- **来源 B**：从 `PathClassLoader.pathList.dexElements` 反射枚举出来的、App 启动时已加载的 DEX。

::: tip 为什么用反射读 pathList
Dalvik 的 `BaseDexClassLoader` 把加载的 DEX 列表藏在 `pathList.dexElements` 这个私有字段里，每个 `Element` 又持有 `dexFile`（含 `mCookie`）。这些字段都是私有的，只能靠反射逐层取出。这正是 DexPathList 的内部结构：

```
PathClassLoader
   └─ pathList : DexPathList
         └─ dexElements : Element[]
               └─ Element
                     └─ dexFile : DexFile
                           ├─ mFileName : String
                           └─ mCookie   : int   ← 内存句柄
```
:::

## 输出

执行后，logcat 会打印出所有 DEX 的路径与对应的 `mCookie`。例如：

```
the dexinfo = /data/app/com.example.target/base.apk  mCookie=12345678
the dexinfo = /data/data/.../encrypted.dex  mCookie=87654321   ← 可疑！壳解密出来的
```

第二个就是壳运行时才解密加载出来的真实 DEX。**把它的路径记下来**，下一步就能用 `backsmali` 或 `dump_dexfile` 把它导出。

## getCookie：按路径反查 mCookie

后续指令（如 `backsmali`）只传 `dexpath`，ZjDroid 需要根据路径找回 `mCookie`。`getCookie(dexPath)` 方法做这件事：

```java
private int getCookie(String dexPath) {
    // 先在动态加载记录里找
    if (dynLoadedDexInfo.containsKey(dexPath)) {
        return dynLoadedDexInfo.get(dexPath).getmCookie();
    }
    // 找不到再去 PathClassLoader 的 dexElements 里逐个比对 mFileName
    ...
    return 0;
}
```

先查动态加载表，再回退到静态枚举，保证两种来源的 DEX 都能被定位。

## 小结

| 要点 | 说明 |
|------|------|
| 核心 hook | `openDexFileNative`（捕获 mCookie） |
| 数据来源 | 动态加载表 + PathClassLoader 反射枚举 |
| 输出 | 每个 DEX 的路径 + mCookie |
| 在脱壳链路中的位置 | 第一步：找到要 dump 的目标 |

---

下一步，看最核心的 [内存 BackSmali 脱壳](./backsmali)。
