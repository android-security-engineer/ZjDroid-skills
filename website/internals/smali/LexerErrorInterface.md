---
title: LexerErrorInterface — 词法错误接口
order: 3
---

# 🚦 LexerErrorInterface

> 统一词法分析器错误计数的接口，解决 ANTLR 框架无法直接给 lexer 添加接口的问题。

| 属性 | 值 |
|---|---|
| 完整类名 | `org.jf.smali.LexerErrorInterface` |
| 源码链接 | [LexerErrorInterface.java](https://github.com/android-security-engineer/ZjDroid-skills/blob/master/src/org/jf/smali/LexerErrorInterface.java) |
| 类型 | `interface`（含内部抽象类） |

---

## 🎯 职责

ANTLR 生成的 Lexer 类不支持通过 grammar 文件直接声明 `implements` 语句，导致无法统一词法器和语法器的错误查询接口。`LexerErrorInterface` 提供了一个变通方案：

1. **顶层接口**：声明 `getNumberOfSyntaxErrors()` 方法
2. **桥接抽象类**：`ANTLRLexerWithErrorInterface` 继承 ANTLR 的 `Lexer` 并实现该接口，供 ANTLR 生成的 lexer 扩展

---

## 🧠 关键实现

**完整类体**

```java
public interface LexerErrorInterface {
    public int getNumberOfSyntaxErrors();

    // ANTLR doesn't provide any way to add interfaces to the lexer class directly,
    // so this is an intermediate class that implements LexerErrorInterface that we
    // can have the ANTLR parser extend
    public abstract static class ANTLRLexerWithErrorInterface extends Lexer implements LexerErrorInterface {
        public ANTLRLexerWithErrorInterface() {
        }

        public ANTLRLexerWithErrorInterface(CharStream input, RecognizerSharedState state) {
            super(input, state);
        }
    }
}
```

**使用场景**

在 `main.assembleSmaliFile()` 中，通过该接口统一检查两个分析器的错误：

```java
LexerErrorInterface lexer;
lexer = new smaliFlexLexer(reader);
// ...
smaliParser parser = new smaliParser(tokens);
// ...
if (parser.getNumberOfSyntaxErrors() > 0 || lexer.getNumberOfSyntaxErrors() > 0) {
    return false;
}
```

`smaliFlexLexer` 直接实现 `LexerErrorInterface`（JFlex 生成的类可以自由指定 `implements`）。而基于 ANTLR 生成的 lexer 则需要继承 `ANTLRLexerWithErrorInterface` 中间类。

---

## 🔗 关系

```mermaid
classDiagram
    class LexerErrorInterface {
        <<interface>>
        +getNumberOfSyntaxErrors() int
    }
    class "LexerErrorInterface.ANTLRLexerWithErrorInterface" {
        <<abstract>>
    }
    LexerErrorInterface <|.. "LexerErrorInterface.ANTLRLexerWithErrorInterface"
    LexerErrorInterface <|.. smaliFlexLexer
    "LexerErrorInterface.ANTLRLexerWithErrorInterface" --|> Lexer : extends ANTLR
    main ..> LexerErrorInterface : "类型声明变量"
```

---

## 📌 小结

`LexerErrorInterface` 是一个典型的"适配器接口"——它的存在完全是为了填补 ANTLR 框架的一个设计局限。通过这个接口，`main` 可以用统一的方式查询词法和语法两个阶段的错误计数，而不必对 `smaliFlexLexer`（JFlex 生成）和 ANTLR Lexer（ANTLR 生成）分别处理。
