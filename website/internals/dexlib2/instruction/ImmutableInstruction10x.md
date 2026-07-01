---
title: ImmutableInstruction10x — 无操作数指令
order: 2
---

# 🔸 ImmutableInstruction10x

`ImmutableInstruction10x` 是 Dalvik 格式 `10x`（1 code unit = 2 字节，0 寄存器）的不可变实现，对应最简单的指令：`nop` 和 `return-void`。

| 属性 | 值 |
|---|---|
| 源码 | [immutable/instruction/ImmutableInstruction10x.java](https://github.com/android-security-engineer/ZjDroid-skills/blob/master/src/org/jf/dexlib2/immutable/instruction/ImmutableInstruction10x.java) |
| 包名 | `org.jf.dexlib2.immutable.instruction` |
| 格式 | `Format.Format10x`（2 字节）|
| 对应指令 | `nop`（0x00）、`return-void`（0x0e）|

## 🎯 职责

最轻量的指令表示：只有一个 `opcode` 字段，无任何操作数，`getCodeUnits()` 恒返回 1。

## 🧠 关键实现

```java
public class ImmutableInstruction10x extends ImmutableInstruction implements Instruction10x {
    public static final Format FORMAT = Format.Format10x;

    public ImmutableInstruction10x(@Nonnull Opcode opcode) {
        super(opcode);
    }

    public static ImmutableInstruction10x of(Instruction10x instruction) {
        if (instruction instanceof ImmutableInstruction10x) {
            return (ImmutableInstruction10x) instruction;
        }
        return new ImmutableInstruction10x(instruction.getOpcode());
    }

    @Override public Format getFormat() { return FORMAT; }
}
```

## 📐 格式布局（2 字节）

```
+--------+--------+
| opcode |  0x00  |  （第二字节固定为 0，填充对齐）
+--------+--------+
```

::: info nop 与加壳填充
加壳工具常用大量 `nop`（0x0000）填充无效代码区域，ZjDroid 在重建方法体时需要识别并过滤纯 nop-slide 区段，避免将填充字节误当作有效指令序列。
:::

## 📌 小结

`ImmutableInstruction10x` 虽然结构最简单，但在 DEX 分析中有重要意义：大量连续 `nop` 是加壳工具常用的填充手段，`return-void` 是无返回值方法的唯一合法结束指令。理解此格式有助于识别混淆 padding。
