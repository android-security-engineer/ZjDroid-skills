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
---
