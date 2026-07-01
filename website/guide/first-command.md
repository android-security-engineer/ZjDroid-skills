# 发送第一条指令

ZjDroid 所有操作都通过一条广播指令驱动。我们来发第一条：获取目标 App 当前加载的 DEX 信息。

## 指令格式

```bash
adb shell am broadcast \
  -a com.zjdroid.invoke \
  --ei target <目标进程PID> \
  --es cmd '{"action":"<动作>"}'
```

- `-a com.zjdroid.invoke`：广播的 action，ZjDroid 监听的就是它；
- `--ei target <PID>`：目标进程的 PID（整数 extra）；
- `--es cmd '{...}'`：一条 JSON 字符串 extra，描述具体要做什么。

## 获取目标 PID

```bash
adb shell pidof com.example.target
# 或
adb shell ps | grep com.example.target
```

输出一个数字，例如 `12345`，就是 `target` 的值。

## 发送：dump_dexinfo

```bash
adb shell am broadcast \
  -a com.zjdroid.invoke \
  --ei target 12345 \
  --es cmd '{"action":"dump_dexinfo"}'
```

## 接收端的处理

ZjDroid 在目标进程里的 [`CommandBroadcastReceiver`](https://github.com/android-security-engineer/ZjDroid-skills/blob/master/src/com/android/reverse/mod/CommandBroadcastReceiver.java) 收到广播后：

```java
public void onReceive(final Context arg0, Intent arg1) {
    if (INTENT_ACTION.equals(arg1.getAction())) {
        int pid = arg1.getIntExtra(TARGET_KEY, 0);
        if (pid == android.os.Process.myPid()) {     // 只处理发给本进程的指令
            String cmd = arg1.getStringExtra(COMMAND_NAME_KEY);
            final CommandHandler handler = CommandHandlerParser.parserCommand(cmd);
            if (handler != null) {
                new Thread(new Runnable() {           // 新线程执行，避免阻塞主线程
                    public void run() { handler.doAction(); }
                }).start();
            }
        }
    }
}
```

注意两个设计：

1. **按 PID 路由**：广播是全局的，但接收器会比较 `target` 和自己的 PID，只有匹配才执行——避免每个被注入的进程都响应同一条指令。
2. **新线程执行**：脱壳、dump 是耗时操作，放主线程会 ANR，因此 `handler.doAction()` 在新线程跑。

## 指令解析

JSON 里的 `action` 字段决定执行哪个 handler。[`CommandHandlerParser`](https://github.com/android-security-engineer/ZjDroid-skills/blob/master/src/com/android/reverse/request/CommandHandlerParser.java) 是一个简单的 if-else 分发器：

```java
String action = jsoncmd.getString("action");
if ("dump_dexinfo".equals(action))      handler = new DumpDexInfoCommandHandler();
else if ("dump_dexfile".equals(action)) handler = new DumpDexFileCommandHandler(dexpath);
else if ("backsmali".equals(action))    handler = new BackSmaliCommandHandler(dexpath);
else if ("dump_class".equals(action))   handler = new DumpClassCommandHandler(dexpath);
else if ("dump_heap".equals(action))    handler = new DumpHeapCommandHandler();
else if ("invoke".equals(action))       handler = new InvokeScriptCommandHandler(filepath, ScriptType.FILETYPE);
else if ("dump_mem".equals(action))     handler = new DumpMemCommandHandler(start, length);
```

所有指令详见 [命令参考](../reference/commands)。

---

下一条：[查看执行结果](./view-results)。
