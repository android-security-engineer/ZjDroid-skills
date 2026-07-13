#!/usr/bin/env bash
# install.sh — ZjDroid 一键安装到已连接的 root + Xposed 设备
# Agent 默认路径: 从 GitHub Release 下载预编译 APK（CI 已构建好）
# 开发 fallback: 若想本地构建，传 --build，则调用 ./gradlew
# 用法: ./install.sh [--build]
set -euo pipefail

PKG="com.android.reverse"
REPO="android-security-engineer/ZjDroid-skills"
LOCAL_APK="${LOCAL_APK:-app/build/outputs/apk/release/zjdroid-release.apk}"
DLDIR="${DLDIR:-/tmp/zjdroid-apk}"

APK=""
if [[ "${1:-}" == "--build" ]]; then
  echo "[1/5] 本地构建 APK..."
  ./gradlew :app:assembleRelease -x lint
  APK="$LOCAL_APK"
else
  echo "[1/5] 从 GitHub Release 下载预编译 APK..."
  mkdir -p "$DLDIR"
  if gh release download --repo "$REPO" --pattern "zjdroid.apk" --dir "$DLDIR" 2>/dev/null; then
    APK="$DLDIR/zjdroid.apk"
  else
    echo "  Release 无产物，触发 CI 构建并等待..."
    gh workflow run build-apk.yml --repo "$REPO" || true
    echo "  请等待 CI 完成（约 3-5 分钟）后重跑本脚本，或用 --build 本地构建。"
    exit 2
  fi
fi
[[ -f "$APK" ]] || { echo "ERROR: APK 不存在: $APK"; exit 1; }

echo "[2/5] 检测 adb 设备..."
DEVICE=$(adb devices | awk 'NR>1 && $2=="device"{print $1; exit}')
[[ -z "$DEVICE" ]] && { echo "ERROR: 未检测到在线设备。"; exit 1; }
echo "  device=$DEVICE  apk=$APK"

echo "[3/5] 安装 APK..."
adb install -r -t "$APK"

echo "[4/5] 注册为 Xposed 模块..."
bash scripts/xposed-enable.sh "$PKG"

echo "[5/5] 重启 Zygote 使模块生效..."
adb root 2>/dev/null || true
adb shell su -c 'stop; start' 2>/dev/null || adb shell setprop ctl.restart zygote
echo "完成。设备重启后目标 App 重新拉起即被注入。"
