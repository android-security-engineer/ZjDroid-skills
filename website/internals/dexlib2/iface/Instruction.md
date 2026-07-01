---
title: Instruction
order: 5
---

# 🔩 Instruction

Dalvik 单条指令的**根接口**，所有指令格式接口的基类。

| 属性 | 值 |
|------|----|
| 包名 | `org.jf.dexlib2.iface.instruction` |
| 类型 | `interface` |
| 源码 | [Instruction.java](https://github.com/android-security-engineer/ZjDroid-skills/blob/master/src/org/jf/dexlib2/iface/instruction/Instruction.java) |

## 🎯 职责

`Instruction` 只提供两个最基本属性：

- `getOpcode()`：指令操作码（对应 `Opcode` 枚举，如 `INVOKE_VIRTUAL`、`IGET`）
- `getCodeUnits()`：指令占用的 16-bit code unit 数量（用于计算下一条指令偏移）

## 🧠 关键实现

```java
public interface Instruction {
    Opcode getOpcode();
    int getCodeUnits();
}
```

### 指令接口层次

dexlib2 将指令按**操作数类型**组织为两层接口层次：

**通用类型接口**（`iface.instruction.*`）：
- `ReferenceInstruction`：携带类/方法/字段/字符串引用
- `OneRegisterInstruction` / `TwoRegisterInstruction` / ...：寄存器数量
- `NarrowLiteralInstruction` / `WideLiteralInstruction`：字面量类型
- `OffsetInstruction`：跳转偏移量

**格式接口**（`iface.instruction.formats.*`）：
- `Instruction35c`：5 寄存器 + 引用（`invoke-virtual {v0,v1}, Ljava/io/PrintStream;->println(Ljava/lang/String;)V`）
- `Instruction21c`：1 寄存器 + 引用
- `PackedSwitchPayload` / `SparseSwitchPayload`：switch 分支表

::: tip 组合式设计
每种具体格式接口通常是多个通用接口的**组合**（多重继承），如 `Instruction21c extends OneRegisterInstruction, ReferenceInstruction`。脱壳时反汇编器按 `instanceof` 检查组合类型来格式化输出。
:::

## 🔗 关系

```mermaid
classDiagram
    class Instruction {
        <<interface>>
        +getOpcode() Opcode
        +getCodeUnits() int
    }
    class ReferenceInstruction {
        <<interface>>
        +getReference() Reference
        +getReferenceType() int
    }
    class OneRegisterInstruction {
        <<interface>>
        +getRegisterA() int
    }
    class "Instruction21c" {
        <<interface>>
    }
    Instruction <|-- ReferenceInstruction
    Instruction <|-- OneRegisterInstruction
    ReferenceInstruction <|-- "Instruction21c"
    OneRegisterInstruction <|-- "Instruction21c"
```

## 📌 小结

`Instruction` 的极简设计使 smali 反汇编器可以统一处理所有指令：先取 opcode 确定格式，再强转为具体格式接口读取操作数，最后格式化输出文本。ZjDroid 的 `MemoryBackSmali` 正是这个模式的应用。
