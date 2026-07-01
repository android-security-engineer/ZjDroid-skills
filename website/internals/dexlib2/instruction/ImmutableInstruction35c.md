---
title: ImmutableInstruction35c — 方法调用指令（≤5参数）
order: 4
---

# 📞 ImmutableInstruction35c

`ImmutableInstruction35c` 实现格式 `35c`（3 code units，最多 5 个寄存器 + 16-bit 引用），是 Dalvik 中**方法调用**最常用的格式，对应 `invoke-virtual`、`invoke-direct`、`invoke-static`、`invoke-interface`、`filled-new-array` 等指令。

| 属性 | 值 |
|---|---|
| 源码 | [immutable/instruction/ImmutableInstruction35c.java](https://github.com/android-security-engineer/ZjDroid-skills/blob/master/src/org/jf/dexlib2/immutable/instruction/ImmutableInstruction35c.java) |
| 包名 | `org.jf.dexlib2.immutable.instruction` |
| 格式 | `Format.Format35c`（6 字节）|
| 实现接口 | `Instruction35c` |

## 🎯 职责

持有最多 5 个参数寄存器（`registerC`~`registerG`）+ 方法/类型引用 + 实际参数数量（`registerCount`），支持 0~5 个参数的方法调用。

## 🧠 关键实现

```java
public class ImmutableInstruction35c extends ImmutableInstruction implements Instruction35c {
    protected final int registerCount;
    protected final int registerC, registerD, registerE, registerF, registerG;
    @Nonnull protected final ImmutableReference reference;

    public ImmutableInstruction35c(@Nonnull Opcode opcode,
                                    int registerCount,
                                    int registerC, int registerD, int registerE,
                                    int registerF, int registerG,
                                    @Nonnull Reference reference) {
        super(opcode);
        this.registerCount = Preconditions.check35cRegisterCount(registerCount); // 0~5
        // 未使用的寄存器槽位强制为 0
        this.registerC = (registerCount > 0) ? Preconditions.checkNibbleRegister(registerC) : 0;
        this.registerD = (registerCount > 1) ? Preconditions.checkNibbleRegister(registerD) : 0;
        this.registerE = (registerCount > 2) ? Preconditions.checkNibbleRegister(registerE) : 0;
        this.registerF = (registerCount > 3) ? Preconditions.checkNibbleRegister(registerF) : 0;
        this.registerG = (registerCount > 4) ? Preconditions.checkNibbleRegister(registerG) : 0;
        this.reference = ImmutableReferenceFactory.of(opcode.referenceType, reference);
    }
}
```

### 遍历 invoke 指令示例

```java
for (Instruction instruction : methodImpl.getInstructions()) {
    if (instruction instanceof Instruction35c) {
        Instruction35c inv = (Instruction35c) instruction;
        if (inv.getReference() instanceof MethodReference) {
            MethodReference mRef = (MethodReference) inv.getReference();
            // ZjDroid：识别被混淆的方法调用，重建真实引用
            System.out.println(mRef.getDefiningClass() + "->" + mRef.getName());
        }
    }
}
```

## 📐 格式布局（6 字节）

```
+--------+--------+--------+--------+--------+--------+
| opcode |B|regG  |   方法引用索引(16位)  |D |  E |F|G|
+--------+--------+--------+--------+--------+--------+
                             寄存器 C~G 编码在高低 nibble 中
```

其中 B = `registerCount`（4 bits），G = `registerG`（4 bits），在同一字节中。

::: info 超过 5 个参数时
当方法参数 > 5 时，使用 `Format3rc`（即 `invoke-virtual/range`），以寄存器范围方式表达。`ImmutableInstruction3rc` 持有 `startRegister` 和 `registerCount`。
:::

## 🔗 关系

```mermaid
graph LR
    ImmutableInstruction35c -->|"extends"| ImmutableInstruction
    ImmutableInstruction35c -->|"implements"| Instruction35c
    ImmutableInstruction35c -->|"持有"| ImmutableMethodReference
    ImmutableInstruction35c -->|"持有"| ImmutableTypeReference
    "invoke-virtual" -->|"使用"| ImmutableInstruction35c
    "invoke-static" -->|"使用"| ImmutableInstruction35c
```

## 📌 小结

`ImmutableInstruction35c` 是 ZjDroid 在分析方法调用链时最常遇到的指令类型。通过 `getReference()` 获取 `MethodReference` 后，可以还原完整的方法签名（`定义类->方法名(参数类型列表)返回类型`），这是 ZjDroid smali 重建输出的关键数据来源。
