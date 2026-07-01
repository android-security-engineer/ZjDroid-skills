# Lua 脚本注入（invoke）

`invoke` 让你在**目标进程内动态运行 Lua 脚本**，而 Lua 脚本又能调用 Java 代码。这是 ZjDroid 最灵活的能力——相当于在运行中的 App 里开了一个"脚本后门"，可以调用任意已加载的 Java 方法。

## 指令

```bash
adb shell am broadcast -a com.zjdroid.invoke \
  --ei target <PID> \
  --es cmd '{"action":"invoke","filepath":"<Lua脚本路径>"}'
```

`filepath` 是**设备上** Lua 脚本的路径（需先把脚本 push 到设备）。

## 它解决什么问题

逆向中常遇到这种困境：你通过反编译看懂了某个**解密函数** `Decryptor.decrypt(byte[])`，想把某段密文喂给它、拿到明文。但这个函数依赖 App 运行时环境（上下文、已初始化的字段、native so 等），**脱离 App 进程根本跑不起来**。

传统做法是：自己用 Java 重写一遍解密逻辑，或用 Xposed 写个 hook 在调用点拦截——都很麻烦，且容易错。

`invoke` 给了一个优雅解法：**直接在目标进程内、在 App 的运行时环境里，调用这个现成的 Java 方法**。Lua 只是触发器，真正干活的是 App 自己的代码。

## 实现原理

核心类是 [`LuaScriptInvoker`](https://github.com/android-security-engineer/ZjDroid-skills/blob/master/src/com/android/reverse/collecter/LuaScriptInvoker.java)，基于 [luajava](http://www.keplerproject.org/luajava/)（Lua 与 Java 的绑定库）。

### 1. 让目标进程能加载 luajava 的 native 库

luajava 需要一个 native 库 `libluajava.so`。但这个 so 装在 ZjDroid 自己的私有目录，目标进程默认找不到。ZjDroid 的解决办法是 hook `BaseDexClassLoader.findLibrary`：

```java
public void start() {
    Method findLibraryMethod = RefInvoke.findMethodExact(
        "dalvik.system.BaseDexClassLoader", ClassLoader.getSystemClassLoader(),
        "findLibrary", String.class);

    hookhelper.hookMethod(findLibraryMethod, new MethodHookCallBack() {
        @Override
        public void afterHookedMethod(HookParam param) {
            if ("luajava".equals(param.args[0]) && param.getResult() == null) {
                // 目标找不到 luajava 时，把 ZjDroid 自己的 so 塞回去
                param.setResult("/data/data/com.android.reverse/lib/libluajava.so");
            }
        }
    });
}
```

::: tip 这个 findLibrary 劫持技巧
这是 ZjDroid 一个精巧的设计。当目标进程尝试 `System.loadLibrary("luajava")` 时，`findLibrary("luajava")` 原本返回 null（目标 App 没这个库）。ZjDroid 在 `after` 阶段把结果改成 ZjDroid 自身目录下的 so 路径，于是目标进程就能加载它。

同样的手法也用在 `libdvmnative.so` 上（见 [DexFileInfoCollecter](https://github.com/android-security-engineer/ZjDroid-skills/blob/master/src/com/android/reverse/collecter/DexFileInfoCollecter.java#L89)）。
:::

### 2. 创建 Lua 状态机并注册回调

收到 `invoke` 指令后，创建一个新的 Lua 解释器实例，并注册两个 Java 函数供 Lua 调用：

```java
public void invokeFileScript(String scriptFilePath) {
    LuaState luaState = LuaStateFactory.newLuaState();   // 新建 Lua 解释器
    luaState.openLibs();                                  // 打开标准库
    this.initLuaContext(luaState);                        // 注册自定义函数
    int error = luaState.LdoFile(scriptFilePath);         // 执行脚本文件
    if (error != 0) {
        Logger.log("Read/Parse lua error. Exit");
        return;
    }
    luaState.close();
}

private void initLuaContext(LuaState luaState) {
    new LogFunctionCallBack(luaState).register("log");            // 注册 log()
    new ToStringFunctionCallBack(luaState).register("tostring");  // 注册 tostring()
}
```

ZjDroid 给 Lua 环境注入了两个函数：

- **`log(msg)`**：把字符串打到 logcat（走 `zjdroid-shell` tag）；
- **`tostring(obj)`**：把 Java 对象序列化成 JSON 打印出来（用 `JsonWriter`）。

::: tip luajava 的魔法
luajava 让 Lua 脚本能直接 `import` Java 类、调用 Java 方法、访问字段。比如在 Lua 里：

```lua
-- 调用 App 的解密方法（伪代码，类名/方法名按实际情况）
require("luajava")
local Decryptor = luajava.newInstance("com.example.target.Decryptor")
local result = Decryptor:decrypt(luajava.newInstance("java.lang.String", "密文"))
log("解密结果: " .. result:toString())
```

这就是"用 Lua 触发 Java"的本质——脚本里写的还是 Java 类名和方法调用，只是由 Lua 解释器在目标进程内执行。
:::

### 3. 脚本类型

[`InvokeScriptCommandHandler`](https://github.com/android-security-engineer/ZjDroid-skills/blob/master/src/com/android/reverse/request/InvokeScriptCommandHandler.java) 支持两种脚本类型：

```java
public static enum ScriptType {
    TEXTTYPE,   // 直接传脚本字符串
    FILETYPE    // 传脚本文件路径
}
```

不过 `CommandHandlerParser` 里 `invoke` 分支目前只构造 `FILETYPE`（文件路径），所以实际只能用 `filepath` 传文件。

## 使用流程

```bash
# 1. 编写 Lua 脚本 decrypt.lua（在 PC 上写好）

# 2. push 到设备
adb push decrypt.lua /data/local/tmp/

# 3. 发送 invoke 指令
adb shell am broadcast -a com.zjdroid.invoke \
  --ei target <PID> \
  --es cmd '{"action":"invoke","filepath":"/data/local/tmp/decrypt.lua"}'

# 4. 查看 logcat 输出（脚本里 log() 的内容）
adb shell logcat -s zjdroid-shell-<包名>
```

## 典型场景

| 场景 | 脚本里做什么 |
|------|-------------|
| 调用解密函数 | `newInstance` 解密类，调用其方法，`log` 结果 |
| 触发特定逻辑 | 调用某个 Activity 的方法，模拟用户操作 |
| 读取运行时状态 | 访问单例对象字段，`tostring` 打印成 JSON |
| 主动构造数据 | new 一个对象，设置字段，传给目标方法 |

## 小结

| 要点 | 说明 |
|------|------|
| 基础 | luajava（Lua ↔ Java 绑定） |
| so 加载技巧 | hook `findLibrary`，把自身 so 塞给目标 |
| 注入的函数 | `log()`、`tostring()` |
| 脚本类型 | 文件路径（`filepath`） |
| 核心价值 | 在 App 运行时环境内调用任意 Java 方法 |

---

最后一个核心功能：[敏感 API 监控](./api-monitor)。
