---
title: ReferenceUtil — 引用描述符工具
order: 1
---

# 🔗 ReferenceUtil

`ReferenceUtil` 是一个纯静态工具类，提供将 `FieldReference`、`MethodReference` 等引用对象格式化为 DEX/smali 标准描述符字符串的方法。

| 属性 | 值 |
|---|---|
| 源码 | [util/ReferenceUtil.java](https://github.com/android-security-engineer/ZjDroid-skills/blob/master/src/org/jf/dexlib2/util/ReferenceUtil.java) |
| 包名 | `org.jf.dexlib2.util` |
| 类型 | `public final class ReferenceUtil` |

## 🎯 职责

格式化各种引用为人类可读（也是 smali 语法兼容的）字符串。

## 🧠 关键实现

### 方法描述符

```java
public static String getMethodDescriptor(MethodReference methodReference) {
    StringBuilder sb = new StringBuilder();
    sb.append(methodReference.getDefiningClass());  // Lcom/example/A;
    sb.append("->");
    sb.append(methodReference.getName());           // myMethod
    sb.append('(');
    for (CharSequence paramType : methodReference.getParameterTypes()) {
        sb.append(paramType);                       // ILjava/lang/String;
    }
    sb.append(')');
    sb.append(methodReference.getReturnType());     // V
    return sb.toString();
    // 结果：Lcom/example/A;->myMethod(ILjava/lang/String;)V
}

// 简短版（不含 defining class）
public static String getShortMethodDescriptor(MethodReference methodReference) {
    // 结果：myMethod(ILjava/lang/String;)V
}
```

### 字段描述符

```java
public static String getFieldDescriptor(FieldReference fieldReference) {
    StringBuilder sb = new StringBuilder();
    sb.append(fieldReference.getDefiningClass());  // Lcom/example/A;
    sb.append("->");
    sb.append(fieldReference.getName());           // myField
    sb.append(':');
    sb.append(fieldReference.getType());           // I
    return sb.toString();
    // 结果：Lcom/example/A;->myField:I
}
```

### 统一分发

```java
@Nullable public static String getReferenceString(Reference reference) {
    if (reference instanceof StringReference) return String.format("\"%s\"", ...);
    if (reference instanceof TypeReference)  return ((TypeReference)reference).getType();
    if (reference instanceof FieldReference)  return getFieldDescriptor((FieldReference)reference);
    if (reference instanceof MethodReference) return getMethodDescriptor((MethodReference)reference);
    return null;
}
```

## 📌 小结

`ReferenceUtil` 是 ZjDroid 的 smali 输出模块生成方法/字段签名的直接调用点。在 `MemoryBackSmali` 输出 `.smali` 文件时，每个 `invoke-*` 指令的方法引用都通过 `getMethodDescriptor()` 格式化为标准 smali 语法字符串。

### getReferenceString 分发流程

```mermaid
flowchart TD
    IN["getReferenceString(Reference)"]
    IN --> C1{"instanceof"}
    C1 -->|"StringReference"| R1["\"...\"（带引号字符串）"]
    C1 -->|"TypeReference"| R2["type（类型描述符）"]
    C1 -->|"FieldReference"| R3["getFieldDescriptor<br/>Lcom/A;->field:I"]
    C1 -->|"MethodReference"| R4["getMethodDescriptor<br/>Lcom/A;->m(II)V"]
    C1 -->|"其他"| R5["null"]

    R4 --> SHORT["getShortMethodDescriptor<br/>m(II)V（省略 defining class）"]
```
