# 适用场景与局限

诚实地讲清楚 ZjDroid 能用在什么地方、在什么地方会失效，是这份教学文档的重要部分。

## 适用场景

ZjDroid 适合以下场景：

- **Dalvik 设备上的脱壳分析**：目标 App 运行在 Android 4.4 及以下（Dalvik 运行时）的设备上，需要从内存取出被加固保护的真实 DEX。
- **运行时行为监控**：观察 App 在运行时调用了哪些敏感 API（发短信、联网、读通讯录、录音、拍照等），用于恶意行为分析或隐私合规审计。
- **动态触发逻辑**：发现某个解密函数后，想直接在进程内调用它解密数据，而不必重写 Java 代码——用 Lua 注入即可。
- **内存取证**：dump 指定内存区域或 Java 堆，分析运行时数据结构。
- **学习 Android 逆向原理**：ZjDroid 代码量适中、结构清晰，是学习"内存取 DEX""Dalvik 内部结构""Xposed Hook"等概念的优质教材。

## 主要局限

### 1. 强绑定 Dalvik 运行时（最关键的局限）

ZjDroid 的核心脱壳能力建立在 Dalvik 的内部结构之上：

- 依赖 `dalvik.system.DexFile` 的 `mCookie` 字段（一个指向内存中 DEX 的整型句柄）；
- 依赖 native 库 `libdvmnative.so` 去解析 Dalvik 内部的 `DexFile` 结构体；
- 依赖 `openDexFileNative` / `defineClassNative` 等 Dalvik 特有方法。

**Android 5.0（API 21）起默认运行时改为 ART**，上述 Dalvik 特有结构不再存在或含义改变。因此：

::: warning ART 上不可用
在 ART 运行时的设备上，ZjDroid 的 DEX dump / BackSmali 脱壳等核心能力**基本失效**。它是一款 Dalvik 时代工具。
:::

如果你需要在 ART 设备上脱壳，请使用 FRIDA、FART、BlackDex 等后继工具。

### 2. 依赖 Root + Xposed 框架

- 设备必须 root；
- 必须安装 Xposed Framework（[Xposed Installer](https://github.com/rovo89/XposedInstaller)）；
- 必须在 Xposed Installer 中启用 ZjDroid 模块并重启。

这套环境本身有门槛，且现代 Android（尤其高版本）安装 Xposed 越来越困难。

### 3. 性能开销

BackSmali 脱壳要在目标进程内跑完整的 baksmali 反汇编 + 重组流程，README 原话是"由于手机性能问题，运行较忙"。对大型 App 可能较慢。

### 4. 特定加固需额外处理

ApkProtect 有防修改检测，需要额外步骤绕过（修改模块加载路径为 `zjdroid.jar`）。详见 [ApkProtect 特殊处理](../guide/apkprotect)。

### 5. 法律与道德边界

ZjDroid 是安全研究工具，**仅可用于**：

- 你自己拥有的 App 的安全测试；
- 授权的渗透测试；
- CTF、安全研究与教学。

不可用于破解他人的受版权保护软件、侵犯他人隐私等非法用途。

## 小结

| 维度 | 评价 |
|------|------|
| 脱壳能力（Dalvik） | ⭐⭐⭐⭐⭐ 通杀当时主流加固 |
| 脱壳能力（ART） | ❌ 不适用 |
| API 监控 | ⭐⭐⭐⭐ 覆盖 17 类敏感 API |
| 易用性 | ⭐⭐⭐⭐ 单条广播驱动，但环境门槛高 |
| 教学价值 | ⭐⭐⭐⭐⭐ 原理清晰，适合学习 |

ZjDroid 不是"最新最强"的工具，但它是理解 Android 动态逆向与脱壳原理的一把好钥匙。这正是这份文档要做的事。
