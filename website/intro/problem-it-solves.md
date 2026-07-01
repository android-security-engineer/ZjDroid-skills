# 它解决什么问题

要理解 ZjDroid 的价值，得先看看在它出现的年代，Android 逆向面临什么困境。

## 加固让静态逆向失效

早期 Android 逆向的主流手段是**静态反编译**：把 APK 里的 `classes.dex` 拿出来，用 baksmali / dex2jar 反编译成 smali 或 Java，再阅读分析。

但随着**应用加固（壳）**技术的普及，这条路走不通了。加固的核心思路是：

1. 把真正的业务 DEX **加密**或**隐藏**，APK 里的 `classes.dex` 只是壳代码；
2. App 启动时，壳代码先运行，在内存里把真正的 DEX **解密**出来；
3. 真正的 DEX 只在**内存中**短暂存在，文件层面始终是加密的。

于是你反编译 APK 拿到的，永远只是壳。静态分析在这里彻底失效——你看到的是锁，不是锁背后的房间。

## 关键洞察：内存里有明文 DEX

加固再强，真正的代码终究要被加载进内存才能运行。也就是说：

> **只要 App 跑起来，真正的 DEX 就一定在内存里以明文形式存在过。**

问题只剩一个：**怎么把它从内存里拿出来？**

这正是 ZjDroid 的切入点。

## ZjDroid 的解法：运行时 + Hook

ZjDroid 不和文件层面的加密硬碰硬，而是换了一个维度——**运行时动态分析**：

1. **借助 Xposed 注入**：以 Xposed 模块身份进入目标进程，与目标代码同进程同权限，能访问 Dalvik 的所有内部结构。

2. **Hook DEX 加载入口**：Dalvik 加载 DEX 时会调用 `dalvik.system.DexFile.openDexFileNative`，返回一个 `mCookie`（一个整型句柄，指向内存中的 DEX）。ZjDroid hook 这个方法，就能**捕获每一次 DEX 加载的内存指针**。

3. **从内存指针重建 DEX**：拿到 `mCookie` 后，结合 native 库 `libdvmnative.so` 解析 Dalvik 内部的 `DexFile` 结构体，定位 DEX 在内存中的基地址和各索引表，直接把明文 DEX 导出来。

4. **进一步反编译**：甚至能直接基于内存指针跑 baksmali，把内存里的 DEX 反编译成 smali，再重组回可读的 dex 文件——这就是**脱壳**。

```
传统静态逆向：  APK 文件 ──decrypt?──> ❌ 拿到的是壳
ZjDroid 动态：   内存中明文 DEX ──hook指针──> ✅ 直接导出
```

## 解决得如何

ZjDroid 在 Dalvik 时代是**非常有效**的：

- ✅ 对当时主流的免费/商业加固方案，内存 BackSmali 脱壳基本通杀；
- ✅ 不修改 APK、不重打包，对目标 App 几乎零侵入；
- ✅ 单条广播指令即可操作，使用门槛低；
- ✅ 顺带提供了 API 监控、Lua 注入等动态分析能力，不止脱壳。

但也有明确的边界：

- ⚠️ **强绑定 Dalvik**：`mCookie`、`DexFile` 内部结构、`libdvmnative.so` 都是 Dalvik 特有的。ART（Android 5.0+）运行时结构完全不同，核心脱壳能力失效；
- ⚠️ **依赖 Xposed**：需要 root + Xposed 框架，环境门槛较高；
- ⚠️ **特定加固需特殊处理**：如 ApkProtect 有防修改检测，需额外步骤（见 [ApkProtect 特殊处理](../guide/apkprotect)）。

## 与同类工具的关系

ZjDroid 属于 **"内存取 DEX"** 这一脱壳流派早期的代表。后来 ART 时代出现了 [FRIDA](https://frida.re/)、[FART](https://github.com/hanbinglengyue/Fart)、[BlackDex](https://github.com/CodingGay/BlackDex) 等后继者，思路一脉相承但适配了新的运行时。理解 ZjDroid 的原理，是理解这一整条技术脉络的基础。

---

下一步，看 [能力总览](./capabilities) 了解 ZjDroid 提供了哪些具体能力。
