---
title: WithRegister — 寄存器标记接口
order: 9
---

# 🔖 WithRegister

> 标记"携带寄存器编号"的简单接口，为 smali 汇编过程中需要关联寄存器号的对象提供统一类型。

| 属性 | 值 |
|---|---|
| 完整类名 | `org.jf.smali.WithRegister` |
| 源码链接 | [WithRegister.java](https://github.com/android-security-engineer/ZjDroid-skills/blob/master/src/org/jf/smali/WithRegister.java) |
| 类型 | `interface`（单方法） |

---

## 🎯 职责

`WithRegister` 是一个只有一个方法的标记接口：

```java
public interface WithRegister {
    int getRegister();
}
```

它的存在使得不同类型的"带寄存器对象"（如 `SmaliMethodParameter`）可以通过统一类型被 `SmaliMethodParameter.COMPARATOR` 排序，而不需要转型。

---

## 🔗 关系

```mermaid
classDiagram
    class WithRegister {
        <<interface>>
        +getRegister() int
    }
    WithRegister <|.. SmaliMethodParameter
    SmaliMethodParameter --> "Comparator~WithRegister~" : COMPARATOR（按寄存器排序）
```

---

## 📌 小结

`WithRegister` 是典型的"标记接口 + 泛型约束"用法，用最少的代码（4 行）建立类型关联，使 `SmaliMethodParameter.COMPARATOR` 可以对实现该接口的任何对象排序，具备良好的可扩展性。
