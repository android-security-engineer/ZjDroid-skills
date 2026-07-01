# 目录结构

ZjDroid 仓库的源码结构与各部分职责，方便你定位代码。

## 顶层结构

```
ZjDroid-skills/
├── src/                        # 源码
├── libs/                       # 第三方 jar 与 native 库
├── lib/                        # 编译用 framework jar
├── res/                        # Android 资源
├── assets/                     # 资产（xposed_init 等）
├── AndroidManifest.xml         # 清单（声明 Xposed 模块）
├── XposedBridgeApi-54.jar      # Xposed API
├── project.properties          # Eclipse 工程配置
├── .project / .classpath       # Eclipse 工程文件
├── proguard-project.txt        # 混淆规则
├── lint.xml
├── README.md
├── LICENSE
└── website/                    # 本文档站
```

## 源码 src 结构

只列 ZjDroid 自身代码（不含 `org/jf`（baksmali）、`org/keplerproject`（luajava）、`javax`（注解）、`ds/tree`（RadixTree）等第三方/工具代码）：

```
src/com/android/reverse/
├── mod/                        # 模块入口
│   ├── ReverseXposedModule.java       # Xposed 入口（IXposedHookLoadPackage）
│   ├── CommandBroadcastReceiver.java  # 广播接收器
│   └── PackageMetaInfo.java           # 目标包元信息
│
├── collecter/                  # 采集器（核心能力）
│   ├── ModuleContext.java             # 模块上下文（单例，管理初始化）
│   ├── DexFileInfoCollecter.java      # DEX 信息收集（hook openDexFileNative）
│   ├── DexFileInfo.java               # 单个 DEX 信息封装
│   ├── MemoryBackSmali.java           # 内存 BackSmali 脱壳（baksmali 集成）
│   ├── MemDump.java                   # 内存区域 dump
│   ├── HeapDump.java                  # Java 堆 dump
│   └── LuaScriptInvoker.java          # Lua 脚本执行
│
├── smali/                      # DEX 反汇编/重组
│   ├── DexFileHeadersPointer.java     # DexFile 结构指针封装
│   └── DexFileBuilder.java            # smali → dex 重组
│
├── apimonitor/                 # 敏感 API 监控（17 类）
│   ├── ApiMonitorHookManager.java     # 监控管理器
│   ├── ApiMonitorHook.java            # Hook 抽象基类
│   ├── AbstractBahaviorHookCallBack.java # 通用回调
│   ├── SmsManagerHook.java            # 短信
│   ├── TelephonyManagerHook.java      # 电话
│   ├── NetWorkHook.java               # 网络
│   ├── ContentResolverHook.java       # 通讯录
│   ├── AccountManagerHook.java        # 账号
│   ├── CameraHook.java                # 摄像头
│   ├── AudioRecordHook.java           # 录音
│   ├── MediaRecorderHook.java         # 录像
│   ├── RuntimeHook.java               # 进程创建
│   ├── ProcessBuilderHook.java        # 进程创建
│   ├── ContextImplHook.java           # 广播注册
│   ├── NotificationManagerHook.java   # 通知
│   ├── AlarmManagerHook.java          # 闹钟
│   ├── ConnectivityManagerHook.java  # 网络连接
│   ├── PackageManagerHook.java        # 包管理
│   ├── ActivityManagerHook.java       # Activity 管理
│   └── ActivityThreadHook.java        # ActivityThread 调度
│
├── request/                    # 指令处理（命令模式）
│   ├── CommandHandler.java            # Handler 接口
│   ├── CommandHandlerParser.java      # JSON 解析 + 分发
│   ├── DumpDexInfoCommandHandler.java
│   ├── DumpClassCommandHandler.java
│   ├── BackSmaliCommandHandler.java
│   ├── DumpDexFileCommandHandler.java
│   ├── DumpMemCommandHandler.java
│   ├── DumpHeapCommandHandler.java
│   ├── InvokeScriptCommandHandler.java
│   └── NativeHookInfoHandler.java
│
├── hook/                       # Hook 框架抽象
│   ├── HookHelperInterface.java       # Hook 助手接口
│   ├── HookHelperFacktory.java        # 工厂
│   ├── XposeHookHelperImpl.java       # Xposed 实现
│   ├── HookParam.java                 # Hook 参数封装
│   └── MethodHookCallBack.java        # 回调基类
│
├── util/                       # 工具
│   ├── NativeFunction.java            # JNI 桥梁（libdvmnative.so）
│   ├── RefInvoke.java                 # 反射工具
│   ├── Logger.java                    # 日志（logcat）
│   ├── JsonWriter.java                # JSON 序列化
│   ├── Utility.java                   # 杂项工具
│   └── Constant.java                  # 常量
│
└── client/
    └── MainActivity.java              # 模块自身的 Activity（占位）
```

## native 库

```
libs/armeabi/
├── libdvmnative.so    # Dalvik DEX 内存操作（脱壳核心）
└── libluajava.so      # Lua ↔ Java 绑定
```

::: tip 两个 so 的来源不同
- `libdvmnative.so` 是 ZjDroid **自己**的 native 代码，实现 `dumpDexFileByCookie`、`dumpMemory`、`getHeaderItemPtr` 等——这是脱壳的底层核心，本仓库**未包含其源码**（只有编译好的 so）。
- `libluajava.so` 来自第三方 [luajava](http://www.keplerproject.org/luajava/) 项目。

两者都通过 hook `findLibrary` 的方式让目标进程加载（见 [Lua 脚本注入](../features/lua-invoke)）。
:::

## 第三方代码

仓库内嵌了若干第三方库的源码（不是 jar）：

| 包 | 作用 |
|----|------|
| `org.jf.smali` / `org.jf.baksmali` / `org.jf.dexlib2` | smali 反汇编/汇编工具链（[smali](https://github.com/JesusFreke/smali)） |
| `org.keplerproject.luajava` | Lua ↔ Java 绑定 |
| `javax.annotation` | JSR 305 注解（NonNull 等） |
| `ds.tree` | Radix 树实现 |

## 文档站

```
website/
├── .vitepress/
│   └── config.mts          # VitePress 配置
├── index.md                # 首页
├── intro/                  # 项目介绍
├── guide/                  # 快速开始
├── features/               # 功能原理
├── reference/              # 命令参考
├── package.json
└── .gitignore
```

详见 [GitHub Actions CI/CD](https://github.com/android-security-engineer/ZjDroid-skills/blob/master/.github/workflows/deploy.yml)。
