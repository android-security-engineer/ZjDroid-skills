# 内存区域 Dump（dump_mem）

`dump_mem` 把目标进程**任意一段内存**原样导出到文件。不限于 DEX，任何地址范围都行——用于内存取证、查看数据段、抓取解密后的明文等。

## 指令

::: warning 参数名以代码为准
README 写的参数是 `start`/`length`，但代码实际解析的 key 是 **`startaddr`**。请使用 `startaddr`。
:::

```bash
adb shell am broadcast -a com.zjdroid.invoke \
  --ei target <PID> \
  --es cmd '{"action":"dump_mem","startaddr":<起始地址>,"length":<字节数>}'
```

::: danger 地址必须是整数
`startaddr` 和 `length` 在代码里都用 `getInt` 解析，是 **32 位整数**。这意味着只能 dump 32 位地址空间内的内存（Dalvik 设备本来就是 32 位，问题不大），且单次 length 不能超过 `Integer.MAX_VALUE`。
:::

## 它解决什么问题

动态分析中常需要"看看某段内存里到底是什么"：

- 怀疑某个 buffer 里有解密后的明文，想直接 dump 出来看；
- 分析某个 native 结构体的内容；
- DEX dump 之外的零散内存取证需求。

`dump_mem` 提供这种"给我一个地址、一个长度，我把这段内存给你"的能力。

## 实现原理

### 1. 指令解析

[`CommandHandlerParser`](https://github.com/android-security-engineer/ZjDroid-skills/blob/master/src/com/android/reverse/request/CommandHandlerParser.java#L69) 解析这两个参数：

```java
} else if (ACTION_DUMP_MEMERY.equals(action)) {   // "dump_mem"
    int start = jsoncmd.getInt(PARAM_START_DUMP_MEMERY);   // "startaddr"
    int length = jsoncmd.getInt(PARAM_LENGTH_DUMP_MEMERY); // "length"
    handler = new DumpMemCommandHandler(start, length);
}
```

### 2. 执行 dump

[`DumpMemCommandHandler.doAction`](https://github.com/android-security-engineer/ZjDroid-skills/blob/master/src/com/android/reverse/request/DumpMemCommandHandler.java)：

```java
public void doAction() {
    String memfilePath = ModuleContext.getInstance().getAppContext().getFilesDir()
                         + "/" + dumpFileName;     // dumpFileName = String.valueOf(start)
    MemDump.dumpMem(memfilePath, start, length);
    Logger.log("the mem data save to =" + memfilePath);
}
```

注意输出文件名直接用起始地址命名，例如 `/data/data/<包名>/files/12345678`（无扩展名）。

### 3. MemDump 与 native 读取

最终通过 [`NativeFunction.dumpMemory`](https://github.com/android-security-engineer/ZjDroid-skills/blob/master/src/com/android/reverse/util/NativeFunction.java#L24) 读取内存：

```java
public static native ByteBuffer dumpMemory(int start, int length);

// NativeFunction.readBytes（MemoryReader 接口实现也复用了它）
public byte[] readBytes(int addr, int length) {
    ByteBuffer data = dumpMemory(addr, length);     // native: 读进程内存
    data.order(ByteOrder.LITTLE_ENDIAN);
    byte[] buffer = new byte[data.capacity()];
    data.get(buffer, 0, data.capacity());
    return buffer;
}
```

`libdvmnative.so` 的 `dumpMemory` 直接以目标进程身份读取 `[start, start+length)` 这段内存，返回 `ByteBuffer`。由于 ZjDroid 已注入目标进程，它和目标同进程，能合法访问目标内存空间。

::: tip 同进程的优势
因为是 Xposed 注入、和目标同进程同权限，`dumpMemory` 不需要 `ptrace`，没有跨进程读内存的开销和权限问题。这也是 ZjDroid 内存 dump 比 PC 端工具（如通过 gdbserver）更顺手的原因。
:::

## 怎么拿到地址

`dump_mem` 需要你自己提供起始地址。地址从哪来？

- **从 `dump_dexinfo` / `backsmali` 日志**：能看到 DEX 的 `baseAddr`，可据此 dump DEX 头部周围的内存；
- **从 `dump_heap`**：hprof 里有对象地址；
- **从 native 调试**：IDA/GDB 分析 so 时得到的地址；
- **从其他 hook**：自己扩展 ZjDroid hook 出来的指针值。

## 产物

文件路径（无扩展名）通过 logcat 输出：

```
the mem data save to = /data/data/<包名>/files/12345678
```

用 hex 编辑器或 010 Editor 打开即可查看原始字节。

## 小结

| 要点 | 说明 |
|------|------|
| 参数 | `startaddr`（注意不是 `start`）、`length`，均为 32 位整数 |
| 核心 native | `dumpMemory(start, length)` |
| 产物 | `/data/data/<包名>/files/<起始地址>`（无扩展名） |
| 优势 | 同进程读取，无需 ptrace |
| 局限 | 32 位整数寻址，单次长度受 `Integer.MAX_VALUE` 限制 |

---

下一步：[Dalvik 堆 Dump](./heap-dump)。
