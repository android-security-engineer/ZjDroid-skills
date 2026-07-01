---
title: 指令格式体系详解
order: 5
---

# 📐 Dalvik 指令格式体系

dexlib2 将 Dalvik 指令格式系统化地编码为 `Format` 枚举，并为每种格式提供 `iface/instruction/formats/` 下的接口约束和 `immutable/instruction/` 下的实现。

## 格式命名解码

格式名 `FormatABC` 中：

| 位置 | 含义 | 示例 |
|---|---|---|
| A | 指令字节数 / 2（即 code unit 数） | `1` = 2字节，`2` = 4字节，`3` = 6字节 |
| B | 寄存器规格 | `0`=无，`1`=1个，`2`=2个，`x`=无寄存器，`r`=寄存器范围 |
| C | 操作数类型 | `x`=无，`c`=常量池引用，`s`=有符号立即数，`t`=跳转偏移，`i`=立即数 |

## 完整格式速查表

| 格式 | 字节 | 寄存器 | 额外操作数 | 典型指令 |
|---|---|---|---|---|
| `10x` | 2 | 0 | — | `nop`, `return-void` |
| `10t` | 2 | 0 | 8-bit 偏移 | `goto` |
| `11n` | 2 | 1 | 4-bit 立即数 | `const/4` |
| `11x` | 2 | 1 | — | `return`, `throw`, `monitor-enter` |
| `12x` | 2 | 2 | — | `move`, `neg-int`, `array-length` |
| `20t` | 4 | 0 | 16-bit 偏移 | `goto/16` |
| `21c` | 4 | 1 | 16-bit 引用 | `const-string`, `new-instance`, `sget` |
| `21s` | 4 | 1 | 16-bit 有符号整数 | `const/16`, `const-wide/16` |
| `21t` | 4 | 1 | 16-bit 跳转偏移 | `if-eqz`, `if-nez` |
| `22c` | 4 | 2 | 16-bit 引用 | `instance-of`, `iget`, `iput` |
| `22s` | 4 | 2 | 16-bit 有符号整数 | `add-int/lit16` |
| `22t` | 4 | 2 | 16-bit 跳转偏移 | `if-eq`, `if-ne`, `if-lt` |
| `22x` | 4 | 2 | — | `move/from16` |
| `23x` | 4 | 3 | — | `add-int`, `aget`, `aput` |
| `30t` | 6 | 0 | 32-bit 偏移 | `goto/32` |
| `31c` | 6 | 1 | 32-bit 引用 | `const-string/jumbo` |
| `31i` | 6 | 1 | 32-bit 整数 | `const`, `const-wide/32` |
| `31t` | 6 | 1 | 32-bit 偏移 | `packed-switch`, `sparse-switch`, `fill-array-data` |
| `35c` | 6 | 最多5 | 16-bit 引用 | `invoke-virtual`, `invoke-static`, `invoke-direct` |
| `3rc` | 6 | 范围 | 16-bit 引用 | `invoke-virtual/range`, `filled-new-array/range` |
| `51l` | 10 | 1 | 64-bit 字面量 | `const-wide` |

## iface/instruction/formats 接口层

每种格式在 `iface/instruction/formats/` 下都有对应接口，声明该格式特有的操作数 getter：

```java
// Instruction21c.java
public interface Instruction21c extends OneRegisterInstruction, ReferenceInstruction {
    // 继承自 OneRegisterInstruction: int getRegisterA()
    // 继承自 ReferenceInstruction: Reference getReference(), int getReferenceType()
}

// Instruction35c.java
public interface Instruction35c extends FiveRegisterInstruction, ReferenceInstruction {
    // 继承自 FiveRegisterInstruction:
    // int getRegisterCount(), getRegisterC/D/E/F/G()
}
```

## 指令格式与寄存器编号范围

| 格式 | 寄存器编号范围 | 说明 |
|---|---|---|
| `1x`（nibble） | 0~15 | 4-bit 编码 |
| `1x`（byte） | 0~255 | 8-bit 编码 |
| `2x`（short） | 0~65535 | 16-bit 编码，`move/from16` |
| `35c` | 0~15 | 每个寄存器 4-bit |
| `3rc` | 0~65535 | 16-bit `startRegister` |

::: tip ZjDroid 中的格式判断
在遍历方法体时，通过 `instruction.getOpcode().format` 或 `instanceof` 检查快速判断格式，然后强转为对应接口取操作数：
```java
if (instruction instanceof Instruction21c) {
    Reference ref = ((Instruction21c) instruction).getReference();
}
```
:::

## 📌 小结

理解 Dalvik 指令格式体系是理解 dexlib2 指令模型、`InstructionWriter` 写出逻辑和 `MethodAnalyzer` 分析逻辑的基础。ZjDroid 在 smali 重建和脱壳输出阶段，需要正确处理每种格式的操作数才能生成语义正确的 `.smali` 文件。
