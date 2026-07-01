---
layout: home

hero:
  name: ZjDroid
  text: Android 动态逆向工具
  tagline: 基于 Xposed 框架的运行时分析模块 —— 脱壳、内存 Dump、API 监控、Lua 脚本注入，一站式动态逆向
  actions:
    - theme: brand
      text: 了解 ZjDroid
      link: /intro/what-is-zjdroid
    - theme: alt
      text: 快速开始
      link: /guide/getting-started
    - theme: alt
      text: GitHub
      link: https://github.com/android-security-engineer/ZjDroid-skills

features:
  - icon: 📦
    title: DEX 内存 Dump
    details: 直接依据 Dalvik 的 mCookie 指针，从进程内存中导出已被加载的 DEX，绕过文件层面的加固保护。
    link: /features/dex-dump
    linkText: 查看原理 →
  - icon: 🔓
    title: 内存 BackSmali 脱壳
    details: 基于内存指针动态反编译 DEX 为 smali 并重组，有效破解主流加固方案，是 ZjDroid 的核心能力。
    link: /features/backsmali
    linkText: 查看原理 →
  - icon: 👁️
    title: 敏感 API 监控
    details: 运行时 hook 短信、网络、定位、摄像头、录音等 17 类敏感 API，记录调用参数与返回值。
    link: /features/api-monitor
    linkText: 查看原理 →
  - icon: 🧠
    title: Lua 脚本注入
    details: 在目标进程内动态执行 Lua 脚本，可调用 Java 代码触发解密、改写逻辑，灵活应对各种场景。
    link: /features/lua-invoke
    linkText: 查看原理 →
  - icon: 💾
    title: 内存与堆 Dump
    details: 支持导出任意内存区域数据，以及 Dalvik Java 堆快照（.hprof），便于离线分析。
    link: /features/mem-dump
    linkText: 查看原理 →
  - icon: 🧩
    title: 广播指令驱动
    details: 通过 adb 发送一条广播即可驱动目标进程完成所有操作，无需修改 APK，零侵入。
    link: /reference/protocol
    linkText: 查看协议 →
  - icon: 🏛️
    title: 架构与原理
    details: 从 Xposed 注入生命周期到脱壳全链路，10 篇专题配时序图/流程图讲透运行机制。
    link: /architecture/overview
    linkText: 深入架构 →
  - icon: 🧬
    title: 源码逐类精讲
    details: ZjDroid 自身 56 个类逐一精读，附真实代码引用与调用关系图，读文档即读源码。
    link: /source/
    linkText: 阅读源码 →
  - icon: 🔧
    title: 内嵌工具链原理
    details: dexlib2 / baksmali / smali / luajava 的内存化改造与关键类，揭示脱壳最后一公里。
    link: /internals/
    linkText: 探索工具链 →
---

## 📚 这是一个「教学型」文档站

本站不满足于"怎么用"，更讲透"为什么这样设计、底层如何实现"。全站 **200+ 篇文档**，覆盖从入门到源码级细节：

<div class="tip custom-block" style="padding-top: 8px">

- 🚀 **[快速开始](/guide/getting-started)** —— 环境准备、安装、第一条指令、看结果，5 步跑通。
- 🧠 **[功能原理](/features/dex-dump)** —— 8 大功能点的实现原理逐一拆解。
- 🏛️ **[架构与原理](/architecture/overview)** —— 注入 / 指令流 / 脱壳链路 / Native 桥等横切专题。
- 🧬 **[源码精讲](/source/)** —— ZjDroid 自身 56 类，按包组织，逐类精读。
- 🔧 **[内嵌工具链](/internals/)** —— dexlib2 / baksmali / smali / luajava / native 层原理。
- 📖 **[命令参考](/reference/commands)** —— 全部指令、协议、API 监控清单速查。

</div>

::: warning 合规声明
ZjDroid 及本文档仅用于**安全研究、恶意软件分析与教学**。请在获得授权的前提下、于你自己的测试设备上使用，遵守所在地法律法规。
:::
