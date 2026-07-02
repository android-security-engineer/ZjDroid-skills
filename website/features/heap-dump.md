# Dalvik 堆 Dump（dump_heap）

`dump_heap` 导出目标进程的 **Java 堆快照**（`.hprof` 文件），可在 PC 上用 MAT、Android Studio Profiler 分析，查看对象分配、引用关系、内存泄漏。

## 指令

```bash
adb shell am broadcast -a com.zjdroid.invoke \
  --ei target <PID> \
  --es cmd '{"action":"dump_heap"}'
```

无需任何参数，直接导出整个 Java 堆。

## 它解决什么问题

动态分析中，光看代码和 API 调用不够，有时需要看**运行时的对象状态**：

- App 解密出的密钥/明文存在哪个对象里？被谁引用？
- 某个单例持有的大量数据长什么样？
- 有没有内存里残留的敏感信息？

Java 堆快照（hprof）记录了某一时刻堆上所有对象及其引用图，是回答这些问题的标准工具。

## 实现原理

### 1. 指令处理

[`DumpHeapCommandHandler`](https://github.com/android-security-engineer/ZjDroid-skills/blob/master/src/com/android/reverse/request/DumpHeapCommandHandler.java)：

```java
public class DumpHeapCommandHandler implements CommandHandler {
    private static String dumpFileName;

    public DumpHeapCommandHandler() {
        // 文件名用目标进程的 PID
        dumpFileName = android.os.Process.myPid() + ".hprof";
    }

    public void doAction() {
        String heapfilePath = ModuleContext.getInstance().getAppContext().getFilesDir()
                              + "/" + dumpFileName;
        HeapDump.dumpHeap(heapfilePath);
        Logger.log("the heap data save to = " + heapfilePath);
    }
}
```

文件名是 `<PID>.hprof`，例如 `12345.hprof`。

### 2. HeapDump 实现

[`HeapDump`](https://github.com/android-security-engineer/ZjDroid-skills/blob/master/src/com/android/reverse/collecter/HeapDump.java) 内部调用 Android 系统自带的 `Debug.dumpHprofData`：

```java
// HeapDump.java 核心逻辑（精简）
import android.os.Debug;

public class HeapDump {
    public static void dumpHeap(String path) {
        // Android 系统方法：把当前进程的 Java 堆 dump 到指定文件
        Debug.dumpHprofData(path);
    }
}
```

::: tip 复用系统能力
和 `dump_class` 复用 `DexFile.getClassNameList` 一样，这里复用了 Android 自带的 `android.os.Debug.dumpHprofData(String fileName)`。这是系统提供的标准 hprof 导出方法，ZjDroid 只是在目标进程里替它调一下——产物和 `am dumpheap` 命令导出的是同一种格式。
:::

整个堆 dump 流程（注意：全程复用系统 API，非自研）：

```mermaid
flowchart LR
    A["dump_heap 指令"] --> B["DumpHeapCommandHandler"]
    B --> C["HeapDump.dumpHeap(path)"]
    C --> D["android.os.Debug.dumpHprofData(filename)<br/>系统 API 封装，非自研"]
    D --> E[".hprof 文件<br/>/data/data/包名/files/PID.hprof"]
```


### 3. 为什么要在目标进程内调

`Debug.dumpHprofData` dump 的是**当前进程**的堆。ZjDroid 已注入目标进程，在目标进程内调用它，dump 出来的自然就是目标 App 的 Java 堆——这正是我们想要的，无需额外指定 PID。

## 产物与使用

文件路径通过 logcat 输出：

```
the heap data save to = /data/data/<包名>/files/12345.hprof
```

取出后用以下工具分析：

- **[MAT (Memory Analyzer Tool)](https://eclipse.org/mat/)**：Eclipse 基金会的堆分析利器，能查对象支配树、泄漏 suspects；
- **Android Studio Profiler**：直接拖入 hprof 即可；
- **[VisualVM](https://visualvm.github.io/)**：也能打开。

::: tip Android hprof 格式转换
Android 导出的 hprof 与标准 Java hprof 格式略有不同。MAT 通常会提示用 `android-sdk/tools/hprof-conv` 转换：

```bash
hprof-conv original.hprof converted.hprof
```
:::

## 小结

| 要点 | 说明 |
|------|------|
| 参数 | 无 |
| 核心 | 复用 `android.os.Debug.dumpHprofData(path)` |
| 产物 | `/data/data/<包名>/files/<PID>.hprof` |
| 分析工具 | MAT / Android Studio Profiler / VisualVM |
| 用途 | 查看运行时对象状态、引用关系、敏感数据残留 |

---

下一步：[Lua 脚本注入](./lua-invoke)。
