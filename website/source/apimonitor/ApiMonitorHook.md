---
title: ApiMonitorHook
order: 2
---

# 🪝 ApiMonitorHook

> 所有敏感 API Hook 类的**抽象基类**——提供共享的 `HookHelperInterface` 实例，并声明 `startHook()` 抽象方法作为注册契约。

| 属性 | 值 |
|------|-----|
| 源码路径 | [ApiMonitorHook.java](https://github.com/android-security-engineer/ZjDroid-skills/blob/master/src/com/android/reverse/apimonitor/ApiMonitorHook.java) |
| 类型 | 抽象类 |
| 所在包 | `com.android.reverse.apimonitor` |
| 关键依赖 | `HookHelperFacktory`、`HookHelperInterface` |

## 🎯 职责

`ApiMonitorHook` 是监控框架中**最顶层的抽象**，定义了两件事：

1. **共享工具**：通过 `HookHelperFacktory.getHookHelper()` 获取平台无关的 Hook 执行器，所有子类通过 `protected hookhelper` 字段直接使用，无需重复初始化。
2. **注册契约**：声明 `startHook()` 抽象方法，强制每个子类实现自己的 Hook 注册逻辑。

## 🔍 监控的 API

本类为抽象类，不直接 Hook 任何方法。

## 🧠 关键实现

### 共享 Hook 执行器

```java
public abstract class ApiMonitorHook {

    protected HookHelperInterface hookhelper = HookHelperFacktory.getHookHelper();
```

`HookHelperFacktory` 是一个工厂类，根据运行环境（Xposed / 其他）返回对应的 `HookHelperInterface` 实现。子类直接调用 `hookhelper.hookMethod(method, callback)` 即可完成拦截注册，**彻底屏蔽了 Xposed API 的直接依赖**。

::: tip 工厂模式的好处
如果未来需要支持非 Xposed 环境（如 inline hook），只需更换 `HookHelperFacktory` 的返回值，所有 17 个 Hook 子类零改动。
:::

### InvokeInfo 内部类

```java
public static class InvokeInfo {
    private long invokeAtTime;
    private String className;
    private String methodName;
    private Object[] argv;
    private Object result;
    private Object invokeState;
}
```

`InvokeInfo` 是一个为**未来扩展**准备的调用信息载体——记录调用时间、类名、方法名、参数列表、返回值和调用状态。当前代码中各子类并未实际使用此类（日志直接通过 `Logger.log_behavior()` 输出），但它为后续结构化分析（如将行为数据序列化上报）预留了接口。

::: info 当前状态
`InvokeInfo` 字段均为 `private` 且没有 getter/setter，目前属于"骨架预留"状态。
:::

### startHook 抽象方法

```java
public abstract void startHook();
```

这是整个子系统的**核心契约**。`ApiMonitorHookManager.startMonitor()` 对每个 Hook 实例调用 `startHook()`，触发对应敏感 API 的 Xposed Hook 注册。

## 🔗 调用关系

```mermaid
classDiagram
    class ApiMonitorHook {
        #HookHelperInterface hookhelper
        +startHook()* void
    }
    class InvokeInfo {
        -long invokeAtTime
        -String className
        -String methodName
        -Object[] argv
        -Object result
        -Object invokeState
    }
    ApiMonitorHook +-- InvokeInfo
    ApiMonitorHook <|-- SmsManagerHook
    ApiMonitorHook <|-- TelephonyManagerHook
    ApiMonitorHook <|-- NetWorkHook
    ApiMonitorHook <|-- ContentResolverHook
    ApiMonitorHook <|-- AccountManagerHook
    ApiMonitorHook <|-- CameraHook
    ApiMonitorHook <|-- AudioRecordHook
    ApiMonitorHook <|-- "... 10 个其他子类"
```

## 📌 小结

`ApiMonitorHook` 体现了**模板方法模式**的精髓：将"如何 Hook"的公共基础设施（`hookhelper`）集中在基类，将"Hook 哪些方法"的具体逻辑下放给子类。加上 `InvokeInfo` 的前瞻性设计，整体架构具备良好的扩展性。

**相关文档：**
- [ApiMonitorHookManager](/source/apimonitor/ApiMonitorHookManager) — 统一调度入口
- [AbstractBahaviorHookCallBack](/source/apimonitor/AbstractBahaviorHookCallBack) — 行为日志回调基类
