---
title: EncodedValueAdaptor — 编码值渲染路由
order: 7
---

# 📊 EncodedValueAdaptor

> 将 DEX 中所有类型的编码常量值（注解值、字段初始值、数组元素）路由到对应渲染器的分发中心。

| 属性 | 值 |
|---|---|
| 完整类名 | `org.jf.baksmali.Adaptors.EncodedValue.EncodedValueAdaptor` |
| 源码链接 | [Adaptors/EncodedValue/EncodedValueAdaptor.java](https://github.com/android-security-engineer/ZjDroid-skills/blob/master/src/org/jf/baksmali/Adaptors/EncodedValue/EncodedValueAdaptor.java) |
| 类型 | 抽象类（仅含静态方法，不可实例化） |

---

## 🎯 职责

DEX 格式的 `encoded_value` 可以是 14 种类型（boolean、byte、char、short、int、long、float、double、string、type、field、method、enum、array、annotation、null）。`EncodedValueAdaptor.writeTo()` 是这 14 种类型的统一分发入口。

---

## 🧠 关键实现

**writeTo 完整实现**

```java
public static void writeTo(IndentingWriter writer, EncodedValue encodedValue) throws IOException {
    switch (encodedValue.getValueType()) {
        case ValueType.ANNOTATION:
            AnnotationEncodedValueAdaptor.writeTo(writer, (AnnotationEncodedValue)encodedValue);
            return;
        case ValueType.ARRAY:
            ArrayEncodedValueAdaptor.writeTo(writer, (ArrayEncodedValue)encodedValue);
            return;
        case ValueType.BOOLEAN:
            BooleanRenderer.writeTo(writer, ((BooleanEncodedValue)encodedValue).getValue());
            return;
        case ValueType.BYTE:
            ByteRenderer.writeTo(writer, ((ByteEncodedValue)encodedValue).getValue());
            return;
        case ValueType.CHAR:
            CharRenderer.writeTo(writer, ((CharEncodedValue)encodedValue).getValue());
            return;
        case ValueType.DOUBLE:
            DoubleRenderer.writeTo(writer, ((DoubleEncodedValue)encodedValue).getValue());
            return;
        case ValueType.ENUM:
            writer.write(".enum ");
            ReferenceUtil.writeFieldDescriptor(writer, ((EnumEncodedValue)encodedValue).getValue());
            return;
        case ValueType.FIELD:
            ReferenceUtil.writeFieldDescriptor(writer, ((FieldEncodedValue)encodedValue).getValue());
            return;
        case ValueType.FLOAT:
            FloatRenderer.writeTo(writer, ((FloatEncodedValue)encodedValue).getValue());
            return;
        case ValueType.INT:
            IntegerRenderer.writeTo(writer, ((IntEncodedValue)encodedValue).getValue());
            return;
        case ValueType.LONG:
            LongRenderer.writeTo(writer, ((LongEncodedValue)encodedValue).getValue());
            return;
        case ValueType.METHOD:
            ReferenceUtil.writeMethodDescriptor(writer, ((MethodEncodedValue)encodedValue).getValue());
            return;
        case ValueType.NULL:
            writer.write("null");
            return;
        case ValueType.SHORT:
            ShortRenderer.writeTo(writer, ((ShortEncodedValue)encodedValue).getValue());
            return;
        case ValueType.STRING:
            ReferenceFormatter.writeStringReference(writer, ((StringEncodedValue)encodedValue).getValue());
            return;
        case ValueType.TYPE:
            writer.write(((TypeEncodedValue)encodedValue).getValue());
    }
}
```

---

## 🔗 关系

```mermaid
flowchart LR
    A["EncodedValueAdaptor.writeTo()"] -->|"ANNOTATION"| B["AnnotationEncodedValueAdaptor"]
    A -->|"ARRAY"| C["ArrayEncodedValueAdaptor"]
    A -->|"BOOLEAN"| D["BooleanRenderer"]
    A -->|"LONG"| E["LongRenderer"]
    A -->|"INT"| F["IntegerRenderer"]
    A -->|"FLOAT"| G["FloatRenderer"]
    A -->|"STRING"| H["ReferenceFormatter"]
    A -->|"ENUM/FIELD"| I["ReferenceUtil"]
    A -->|"NULL"| J["直接写 null"]
    AnnotationFormatter --> A : "注解元素值"
    FieldDefinition --> A : "字段初始值"
```

---

## 📌 小结

`EncodedValueAdaptor` 是 DEX 常量系统与 smali 文本之间的桥梁。它的价值在于统一接口——无论调用方是处理注解元素（`AnnotationFormatter`）还是字段初始值（`FieldDefinition`），都通过同一个 `writeTo()` 入口，由内部 switch 路由到对应的 Renderer。

`Renderers/` 包中的 8 个渲染器（`LongRenderer`、`IntegerRenderer`、`FloatRenderer`、`DoubleRenderer`、`BooleanRenderer`、`ByteRenderer`、`CharRenderer`、`ShortRenderer`）负责将 Java 基本类型格式化为 smali 字面量语法（如 `-0x1L`、`0x1.8p0f`）。
