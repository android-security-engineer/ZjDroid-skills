# AGENTS.md — AI Agent 安装 ZjDroid 操作手册

本文件让 AI Agent 无需人类介入即可安装并调用 ZjDroid。APK 由 GitHub Actions 预编译发到 Release，Agent 只下载不构建。

## 单命令入口（推荐）
```bash
./install.sh
```
该命令自动完成：环境自检 → 下载 Release APK（无产物则触发 CI 并等待）→ 装 APK → 注册 Xposed 模块 → 重启生效 → 验证。退出码 0=成功。

## 分步执行（调试或单命令失败时）

### Step 0: 环境自检
```bash
bash scripts/preflight.sh
```
退出码：`0`=全绿可装；`2`=有警告（Xposed 可能需手动启用）可继续；`1`=致命缺失（gh/adb/python/设备缺失）须先修。

### Step 1: 获取 APK
```bash
gh release download --repo android-security-engineer/ZjDroid-skills --pattern zjdroid.apk --dir /tmp/zjdroid
```
若 404（Release 无产物）：
```bash
bash scripts/wait-release.sh   # 触发 CI + 轮询，最多 10 分钟，退出码 0=就绪 3=超时
```

### Step 2: 安装+注册+验证
```bash
./install.sh --skip-preflight   # 已自检过则跳过
```

### 路径 B：源码编译安装（当 Release 不可用或需自定义时）

默认走 Release 下载（路径 A，见 Step 1）。若需从源码编译（如修改了源码、Release 无产物且不想等 CI）：

前置环境（在路径 A 基础上额外需要）：
- JDK 17（`java -version` 确认）
- Android SDK platform 18（CI 自动装，本地需手动 `sdkmanager "platforms;android-18"`）

```bash
./install.sh --build          # 调 ./gradlew 本地编译 → 自检产物 → 装 → 注册 → 验证
```

或单独只构建不安装：
```bash
./gradlew :app:assembleRelease -x lint
# 产物: app/build/outputs/apk/release/zjdroid-release.apk
bash scripts/check-apk.sh app/build/outputs/apk/release/zjdroid-release.apk   # 校验
```

`--build` 与 Release 下载一样会跑 `check-apk.sh` 校验产物完整性后再安装。

### Step 3: 调用（Python SDK）
```python
from zjdroid_agent import ZjDroidClient, DumpDexInfo, BackSmali
c = ZjDroidClient(package='com.example.target')
print(c.invoke(DumpDexInfo()))
print(c.invoke(BackSmali(dexpath='/data/app/.../base.apk')))
c.close()
```
完整脱壳示例见 `sdk/examples/demo_unpack.py`。

## 前置环境
- 宿主（路径 A 必需）: Python ≥3.10, gh CLI（`gh auth login` 已认证）, adb（platform-tools）
- 宿主（路径 B 额外）: JDK 17, Android SDK platform 18
- 设备: 已 root 的 Android，已装 Xposed 框架（LSPosed/EdXposed/经典 Xposed 之一）
- `adb devices` 能看到目标设备

## 安装形式
ZjDroid 是标准 Xposed 模块（`AndroidManifest.xml` 含 `xposedmodule` 元数据），安装形式即 **APK**：
`adb install` → Xposed 框架加载模块 → 目标进程被注入。两条路径最终都产出同一 `zjdroid.apk`。

## 退出码语义
| 脚本 | 0 | 1 | 2 | 3 |
|------|---|---|---|---|
| install.sh | 成功 | 致命缺失/无设备 | - | wait-release 超时 |
| preflight.sh | 全绿 | 致命缺失 | 仅有警告 | - |
| wait-release.sh | APK 就绪 | - | - | 超时 |
| verify-install.sh | 验证通过 | 有项未通过 | - | - |

## 排障决策树
| 现象 | 判断 | 处理 |
|------|------|------|
| preflight 报 gh 缺失 | 宿主无 gh | 装 gh CLI 并 `gh auth login` |
| preflight 报无设备 | adb 未连 | `adb connect <ip>:5555` 或插 USB 开 USB 调试 |
| preflight 报无 root | 设备未 root | 换 root 设备；无 root 无法用 Xposed |
| preflight warn 无 Xposed | 框架未装 | 装 LSPosed/EdXposed，或装完用 Manager 手动启用模块 |
| gh release download 404 | Release 无产物 | `bash scripts/wait-release.sh` |
| wait-release 超时(exit 3) | CI 未在 10 分钟完成 | `gh run list --repo ...` 查 CI 日志，或 `./install.sh --build` 本地构建 |
| verify [4/4] 无 zjdroid 日志 | 目标进程未被注入 | 拉起目标 App 后 `adb logcat -s zjdroid-shell-<目标包名>` 确认；模块未启用则查 Xposed Manager |
| invoke 返回 (timeout) | 进程未注入/SDK 轮询未命中 | 确认目标 App 在前台运行、模块已启用 |
| CI 报 platform-18 not found | SDK 18 下架 | app/build.gradle 的 compileSdk 改 34（minSdk 不变） |
