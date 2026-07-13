# AGENTS.md — 给 AI Agent 的 ZjDroid 自动化操作手册

本文件让任何 AI Agent 无需人类介入即可完成 ZjDroid 的安装、调用。

## 前置环境（Agent 自行检测，缺什么装什么）
- **宿主**: Python ≥3.10, gh CLI（已认证）, adb(platform-tools)
- **设备**: 已 root 的 Android（真机或模拟器），已装 Xposed 框架（LSPosed/EdXposed/经典 Xposed 之一）
- `adb devices` 必须能看到目标设备

## Step 1: 获取 APK（无需本地构建）
APK 已由 GitHub Actions 预编译并发布到 Release。Agent 直接下载：
```bash
gh release download --repo android-security-engineer/ZjDroid-skills --pattern zjdroid.apk --dir /tmp/zjdroid
```
或直接用 `./install.sh`（脚本内部自动下载）。仅当 Release 无产物时才需本地 `./install.sh --build`。

## Step 2: 安装并启用模块
```bash
./install.sh
```
脚本会：下载预编译 APK → 装 APK → 注册 Xposed 模块 → 重启 Zygote。

## Step 3: 调用（Python SDK）
```python
from zjdroid_agent import ZjDroidClient, DumpDexInfo, BackSmali
c = ZjDroidClient(package='com.example.target')
print(c.invoke(DumpDexInfo()))
print(c.invoke(BackSmali(dexpath='/data/app/.../base.apk')))
c.close()
```
完整脱壳示例见 `sdk/examples/demo_unpack.py`。

## 排障
| 现象 | 原因 | 处理 |
|------|------|------|
| gh release download 404 | Release 尚无产物 | `gh workflow run build-apk.yml` 触发 CI，等 3-5 分钟 |
| invoke 返回 (timeout) | 进程未注入 | 目标 App 拉起后再调用；模块未启用 |
| logcat 无 zjdroid-* tag | Xposed 未加载模块 | 重启设备 / 检查 modules.list |
| CI build 报 platform-18 not found | SDK 18 下架 | app/build.gradle 的 compileSdk 改 34（minSdk 不变） |
