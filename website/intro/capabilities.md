# 能力总览

ZjDroid 提供 8 项核心能力，全部通过同一种方式驱动：`adb` 发送 `com.zjdroid.invoke` 广播，附带一条 JSON 指令。

## 能力一览表

| 能力 | 指令 action | 一句话说明 | 详细原理 |
|------|------------|-----------|---------|
| DEX 加载信息收集 | `dump_dexinfo` | 列出当前进程已加载的所有 DEX 及其内存指针 | [查看](../features/dexinfo) |
| 类信息枚举 | `dump_class` | 列出指定 DEX 中所有可加载的类名 | [查看](../features/dump-class) |
| 内存 BackSmali 脱壳 | `backsmali` | 从内存反编译指定 DEX 并重组，破解加固 | [查看](../features/backsmali) |
| DEX 内存 Dump | `dump_dexfile` | 直接导出内存中的 DEX（odex 格式） | [查看](../features/dex-dump) |
| 内存区域 Dump | `dump_mem` | 导出任意内存地址范围的原始数据 | [查看](../features/mem-dump) |
| Dalvik 堆 Dump | `dump_heap` | 导出 Java 堆快照（.hprof） | [查看](../features/heap-dump) |
| Lua 脚本注入 | `invoke` | 在目标进程内运行 Lua，可调 Java | [查看](../features/lua-invoke) |
| 敏感 API 监控 | （自动） | hook 短信/网络/定位等 17 类敏感 API | [查看](../features/api-monitor) |

## 典型使用链路

这些能力不是孤立的，它们组合起来构成一条完整的逆向工作流：

```
1. dump_dexinfo        ← 先搞清楚目标加载了哪些 DEX（找到可疑的加密 DEX）
        │
        ▼
2. dump_class          ← 看看那个 DEX 里有哪些类（定位业务逻辑类）
        │
        ▼
3. backsmali / dump_dexfile  ← 把内存里的 DEX 导出来（脱壳）
        │
        ▼
4. (PC 上) 反编译分析导出的 dex  ← 用 jadx / baksmali 阅读真实代码
        │
        ▼
5. invoke (Lua)        ← 发现某个解密函数，用 Lua 在进程内调用它解密数据
        │
        ▼
6. api-monitor         ← 同时观察 App 的敏感行为（网络请求、短信等）
```

## 输出方式

ZjDroid 的所有输出都走 **logcat**，用两个不同的 tag 区分：

| Tag | 内容 |
|-----|------|
| `zjdroid-shell-{包名}` | 指令执行结果（dump 的文件路径、状态日志等） |
| `zjdroid-apimonitor-{包名}` | 敏感 API 监控输出（调用方法、参数、返回值） |

::: tip 查看结果
```bash
# 查看指令执行结果
adb shell logcat -s zjdroid-shell-com.example.target

# 查看 API 监控结果
adb shell logcat -s zjdroid-apimonitor-com.example.target
```
:::

## dump 出来的文件在哪

所有 dump 出来的文件（dex、内存数据、hprof）都保存在**目标 App 的私有目录**下：

```
/data/data/{目标包名}/files/
```

由于是目标 App 自己的私有目录，需要 root 或 `run-as` 才能取出。详见 [查看执行结果](../guide/view-results)。

---

接下来了解 [适用场景与局限](./limitations)，或直接进入 [快速开始](../guide/getting-started)。
