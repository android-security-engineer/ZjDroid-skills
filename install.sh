#!/usr/bin/env bash
# install.sh — ZjDroid 一键安装（Agent 无人值守版）
# 流程: preflight 自检 → 下载Release(无产物则wait-release) → 装APK → 注册Xposed → verify验证
# 用法: ./install.sh [--build] [--skip-preflight]
set -euo pipefail

PKG="com.android.reverse"
REPO="android-security-engineer/ZjDroid-skills"
LOCAL_APK="${LOCAL_APK:-app/build/outputs/apk/release/zjdroid-release.apk}"
DLDIR="${DLDIR:-/tmp/zjdroid-apk}"
SKIP_PREFLIGHT=0
BUILD_MODE=0
for a in "$@"; do
  case "$a" in
    --build) BUILD_MODE=1;;
    --skip-preflight) SKIP_PREFLIGHT=1;;
  esac
done

echo "[0/6] 前置自检..."
if [[ $SKIP_PREFLIGHT -eq 1 ]]; then
  echo "  (跳过 preflight)"
elif bash scripts/preflight.sh; then
  echo "  preflight 全绿"
else
  rc=$?
  if [[ $rc -eq 2 ]]; then echo "  preflight 有警告，继续（Xposed 可能需手动启用）"; else echo "  preflight 致命缺失，终止。修复后重跑。"; exit 1; fi
fi

APK=""
if [[ $BUILD_MODE -eq 1 ]]; then
  echo "[1/6] 本地构建 APK..."
  ./gradlew :app:assembleRelease -x lint
  APK="$LOCAL_APK"
else
  echo "[1/6] 从 GitHub Release 下载预编译 APK..."
  mkdir -p "$DLDIR"
  if gh release download --repo "$REPO" --pattern "zjdroid.apk" --dir "$DLDIR" 2>/dev/null; then
    APK="$DLDIR/zjdroid.apk"
  else
    echo "  Release 无产物，等待 CI 构建..."
    bash scripts/wait-release.sh && APK="$DLDIR/zjdroid.apk" || { echo "  等待产物失败，可用 --build 本地构建。"; exit 3; }
  fi
fi
[[ -f "$APK" ]] || { echo "ERROR: APK 不存在: $APK"; exit 1; }

echo "[2/6] 检测 adb 设备..."
DEVICE=$(adb devices | awk 'NR>1 && $2=="device"{print $1; exit}')
[[ -z "$DEVICE" ]] && { echo "ERROR: 未检测到在线设备。先 adb connect 或开 USB 调试。"; exit 1; }
echo "  device=$DEVICE  apk=$APK"

echo "[3/6] 安装 APK..."
adb install -r -t "$APK"

echo "[4/6] 注册为 Xposed 模块..."
bash scripts/xposed-enable.sh "$PKG"

echo "[5/6] 重启 Zygote 使模块生效..."
adb root 2>/dev/null || true
adb shell su -c 'stop; start' 2>/dev/null || adb shell setprop ctl.restart zygote

echo "[6/6] 验证安装结果..."
bash scripts/verify-install.sh "$PKG" || echo "  (验证有项未通过，见上方提示)"
echo "完成。"
