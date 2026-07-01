---
title: DexPool — 基于接口对象的 DEX 写出器
order: 2
---

# 🏊 DexPool

`DexPool` 是 `DexWriter` 面向 **dexlib2 iface 接口对象**（`ClassDef`、`Field`、`Method` 等）的具体实现。调用方只需将符合接口的对象注册（`intern`）进来，再调用 `writeTo()` 即可生成完整的 `.dex` 文件。

| 属性 | 值 |
|---|---|
| 源码 | [writer/pool/DexPool.java](https://github.com/android-security-engineer/ZjDroid-skills/blob/master/src/org/jf/dexlib2/writer/pool/DexPool.java) |
| 包名 | `org.jf.dexlib2.writer.pool` |
| 继承 | `extends DexWriter<CharSequence, StringReference, CharSequence, TypeReference, ...>` |

## 🎯 职责

- 提供 `makeDexPool()` 静态工厂，一次性初始化全部子 Pool
- 提供 `writeTo(String path, DexFile input)` 便捷方法，一行代码完成 DEX 文件写出
- 实现 `writeEncodedValue()` 分发 15 种 `EncodedValue` 类型的序列化

## 🧠 关键实现

### 工厂方法 — 构建 Pool 依赖树

```java
public static DexPool makeDexPool(int api) {
    StringPool stringPool = new StringPool();
    TypePool typePool = new TypePool(stringPool);
    FieldPool fieldPool = new FieldPool(stringPool, typePool);
    TypeListPool typeListPool = new TypeListPool(typePool);
    ProtoPool protoPool = new ProtoPool(stringPool, typePool, typeListPool);
    MethodPool methodPool = new MethodPool(stringPool, typePool, protoPool);
    AnnotationPool annotationPool = new AnnotationPool(stringPool, typePool, fieldPool, methodPool);
    AnnotationSetPool annotationSetPool = new AnnotationSetPool(annotationPool);
    ClassPool classPool = new ClassPool(stringPool, typePool, fieldPool, methodPool,
                                        annotationSetPool, typeListPool);
    return new DexPool(api, stringPool, typePool, protoPool, fieldPool, methodPool,
                       classPool, typeListPool, annotationPool, annotationSetPool);
}
```

各 Pool 之间形成依赖链：`ClassPool` 依赖所有其他 Pool，`MethodPool` 依赖 `ProtoPool`，以此类推。

### 一行写出 DEX 文件

```java
public static void writeTo(@Nonnull String path,
                           @Nonnull org.jf.dexlib2.iface.DexFile input) throws IOException {
    DexPool dexPool = makeDexPool();
    for (ClassDef classDef : input.getClasses()) {
        ((ClassPool) dexPool.classSection).intern(classDef);
    }
    dexPool.writeTo(new FileDataStore(new File(path)));
}
```

### EncodedValue 分发

```java
protected void writeEncodedValue(@Nonnull InternalEncodedValueWriter writer,
                                  @Nonnull EncodedValue encodedValue) throws IOException {
    switch (encodedValue.getValueType()) {
        case ValueType.ANNOTATION: ...
        case ValueType.ARRAY: ...
        case ValueType.STRING:
            writer.writeString(((StringEncodedValue)encodedValue).getValue()); break;
        case ValueType.TYPE:
            writer.writeType(((TypeEncodedValue)encodedValue).getValue()); break;
        // ... 共 15 种
    }
}
```

## 🔗 关系

```mermaid
graph TD
    DexPool -->|"extends"| DexWriter
    DexPool -->|"contains"| StringPool
    DexPool -->|"contains"| TypePool
    DexPool -->|"contains"| ProtoPool
    DexPool -->|"contains"| FieldPool
    DexPool -->|"contains"| MethodPool
    DexPool -->|"contains"| ClassPool
    ClassPool -->|"intern(ClassDef)"| "dexlib2.iface.ClassDef"
```

## 📌 小结

`DexPool` 是 ZjDroid 脱壳管道中最常用的写出入口：将内存中重建的 `ClassDef` 对象批量 `intern`，再调用 `writeTo()` 生成合法 `.dex`。相比 `DexBuilder`，它对调用方要求更低——只要实现 `iface` 接口即可。

::: tip 与 DexBuilder 的区别
`DexPool` 接受 iface 接口对象（更通用），`DexBuilder` 接受 Builder 引用类型（更精细，配合 `MutableMethodImplementation` 使用）。脱壳场景通常优先用 `DexPool`。
:::
