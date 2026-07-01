# 类信息枚举（dump_class）

`dump_class` 列出**指定 DEX 中所有可加载的类名**。它不 dump 代码，只列名单——用于快速了解某个 DEX 里有哪些类，定位感兴趣的业务类。

## 指令

```bash
adb shell am broadcast -a com.zjdroid.invoke \
  --ei target <PID> \
  --es cmd '{"action":"dump_class","dexpath":"<DEX路径>"}'
```

## 它解决什么问题

脱壳前，你拿到一堆 DEX 路径，但不知道哪个 DEX 里有你关心的业务逻辑。直接 `backsmali` 全部反编译太慢。`dump_class` 让你**先看类名清单**，快速定位：

- 哪个 DEX 里有 `com.example.target.LoginActivity` 这样的业务类？
- 哪个 DEX 是壳代码（大量混淆类名）？
- 这个 DEX 大概有多少类？

## 实现原理

入口是 [`DexFileInfoCollecter.dumpLoadableClass`](https://github.com/android-security-engineer/ZjDroid-skills/blob/master/src/com/android/reverse/collecter/DexFileInfoCollecter.java#L122)：

```java
public String[] dumpLoadableClass(String dexPath) {
    int mCookie = this.getCookie(dexPath);        // 按路径拿 mCookie
    if (mCookie != 0) {
        // 直接调用 Dalvik 自己的 API
        return (String[]) RefInvoke.invokeStaticMethod(
            "dalvik.system.DexFile", "getClassNameList",
            new Class[] { int.class },
            new Object[] { mCookie });
    }
    return null;
}
```

这里 ZjDroid **没有自己解析 DEX 的 class_defs 表**，而是直接调用了 Dalvik **自带的方法**：

```java
dalvik.system.DexFile.getClassNameList(int mCookie)
```

这是 Dalvik 内部用来枚举 DEX 类列表的方法（虽然不是公开 API）。给定 `mCookie`，它返回该 DEX 所有类的全限定名数组。

::: tip 为什么能直接调用
`getClassNameList` 是 `DexFile` 类里的一个方法，只是对普通应用不可见（无公开文档）。但 ZjDroid 通过反射 `RefInvoke.invokeStaticMethod` 可以无视可见性直接调用它——反正目标进程里这个方法就在那里。这比自己解析 DEX 二进制结构简单得多，而且一定和 Dalvik 实际认知一致。
:::

## 一个值得注意的代码细节

阅读 [`CommandHandlerParser`](https://github.com/android-security-engineer/ZjDroid-skills/blob/master/src/com/android/reverse/request/CommandHandlerParser.java) 时，`dump_class` 分支有个细节：

```java
} else if (ACTION_DUMP_DEXCLASS.equals(action)) {   // "dump_class"
    if (jsoncmd.has(PARAM_DEXPATH_DUMPDEXCLASS)) {   // "dexpath"
        // 注意：这里取的 key 是 PARAM_DEXPATH_DUMP_DEXFILE，但它也等于 "dexpath"
        String dexpath = jsoncmd.getString(PARAM_DEXPATH_DUMP_DEXFILE);
        handler = new DumpClassCommandHandler(dexpath);
    }
}
```

虽然代码里取的常量名是 `PARAM_DEXPATH_DUMP_DEXFILE`（看起来像笔误，应该是 `PARAM_DEXPATH_DUMPDEXCLASS`），但**两个常量的值都是字符串 `"dexpath"`**，所以行为完全正确——你传 `"dexpath":"..."` 就行。

::: warning 但 README 与代码不一致
README 里 `dump_mem` 的参数写的是 `start`/`length`，但代码里实际解析的 key 是 **`startaddr`**/`length`。以代码为准。详见 [命令参考](../reference/commands)。
:::

## 输出

logcat 会打印出该 DEX 包含的所有类名，例如：

```
Lcom/example/target/LoginActivity;
Lcom/example/target/MainActivity;
Lcom/example/target/net/ApiClient;
...
```

类名是 Dalvik 的内部描述符形式（`L` 开头、`;` 结尾、`/` 分隔包名）。

## 小结

| 要点 | 说明 |
|------|------|
| 核心 | 反射调用 Dalvik 自带 `DexFile.getClassNameList(mCookie)` |
| 输入 | dexpath → mCookie |
| 输出 | 该 DEX 所有类名（内部描述符形式） |
| 用途 | 快速定位业务类，决定接下来 backsmali 哪个 DEX |

---

下一步：[内存区域 Dump](./mem-dump)。
