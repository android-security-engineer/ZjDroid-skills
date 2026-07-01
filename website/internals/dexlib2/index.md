---
title: dexlib2 内嵌工具链概览
order: 0
---

# 📦 dexlib2 内嵌工具链

ZjDroid 内嵌了 smali 项目的 **dexlib2** 库（`org.jf.dexlib2`），并在此基础上进行了关键的"内存化改造"，使其能直接读取进程内存中的 DEX 数据，从而实现**整体性脱壳**。

::: info 为什么要内嵌 dexlib2？
脱壳的核心目标是将运行时内存中解密后的 DEX 数据重新序列化为合法的 `.dex` 文件。dexlib2 提供了完整的 DEX 抽象模型和读取/写入能力，是完成这项工作的最合适工具。
:::

## 🗺️ 子包结构

| 子包 | 路径 | 职责 |
|------|------|------|
| [iface/](./iface/) | `org.jf.dexlib2.iface` | DEX 对象的纯抽象接口层（DexFile、ClassDef、Method 等） |
| [dexbacked/](./dexbacked/) | `org.jf.dexlib2.dexbacked` | 基于字节数据的高性能读取实现层，含内存化改造类 |
| [base/](./base/) | `org.jf.dexlib2.base` | 为接口提供 equals/hashCode/compareTo 等抽象基类实现 |

## 🔄 DEX 读取流水线

```mermaid
flowchart LR
    A["📱 Android 进程内存<br/>(加壳 App)"] -->|NativeFunction<br/>读取原始字节| B["MemoryReader<br/>接口"]
    B --> C["BaseDexBuffer<br/>内存感知读取层"]
    C --> D["DexBackedDexFile<br/>MEMORYTYPE 模式"]
    D --> E["DexBackedClassDef<br/>逐类解析"]
    E --> F["DexBackedMethod<br/>逐方法解析"]
    F --> G["MemoryBackSmali<br/>反汇编输出"]
    G --> H["💾 落地 .smali 文件"]

    style A fill:#ff6b6b,color:#fff
    style B fill:#ffd93d
    style D fill:#6bcb77
    style H fill:#4d96ff,color:#fff
```

## 🔑 ZjDroid 改造重点

ZjDroid 对 dexlib2 的改造主要集中在 **dexbacked/** 子包中的两个新增类：

- **`MemoryReader`**（接口）：定义从任意内存地址读取字节的契约
- **`MemoryDexFileItemPointer`**（数据类）：存储进程内存中 DEX 各 section 的绝对地址

这两个类打通了 dexlib2 与进程内存之间的最后一环。详见 [dexbacked 精讲](./dexbacked/)。

::: warning 数组越界与容错
在内存模式下，ZjDroid 绕过了所有边界检查（`DexFileDataType.MEMORYTYPE` 分支不做 index 合法性校验），并在 `DexBackedClassDef` 构造函数中用 `try/catch` 捕获异常、通过 `isValid` 标志跳过损坏的类定义，以应对加壳应用中常见的非标准 DEX 结构。
:::

## 🔗 相关文档

- [NativeFunction —— 内存读取底层实现](/source/util/NativeFunction)
- [MemoryBackSmali —— 脱壳后 Smali 还原](/source/smali/MemoryBackSmali)
- [整体脱壳流水线](/architecture/unpacking-pipeline)
