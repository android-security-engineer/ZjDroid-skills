#!/usr/bin/env bash
# scripts/e2e-test.sh — ZjDroid 端到端安装测试
# 链路: 下载Release APK → check-apk校验 → adb install → pm path确认 → uninstall清理
# 用法: bash scripts/e2e-test.sh
# 退出码: 0=安装成功, 1=任一环节失败
set -uo pipefail
REPO="android-security-engineer/ZjDroid-skills"
PKG="com.android.reverse"
DLDIR="${DLDIR:-/tmp/zjdroid-e2e}"
APK="$DLDIR/zjdroid.apk"

mkdir -p "$DLDIR"
echo "=== ZjDroid 端到端安装测试 ==="

echo "[1/5] 下载 Release APK..."
if ! gh release download --repo "$REPO" --pattern "zjdroid.apk" --dir "$DLDIR" --clobber; then
  echo "  ✗ 下载失败（Release 无产物？）"; exit 1
fi
echo "  ✓ 已下载: $APK ($(stat -c%s "$APK" 2>/dev/null || stat -f%z "$APK") bytes)"

echo "[2/5] 校验 APK 产物..."
if ! bash scripts/check-apk.sh "$APK"; then
  echo "  ✗ 产物校验失败"; exit 1
fi
echo "  ✓ 产物校验通过"

echo "[3/5] 检测 adb 设备..."
DEVICE=$(adb devices | awk 'NR>1 && $2=="device"{print $1; exit}')
if [[ -z "$DEVICE" ]]; then echo "  ✗ 无在线设备"; exit 1; fi
echo "  ✓ 设备: $DEVICE"

echo "[4/5] 安装 APK 到设备..."
adb uninstall "$PKG" >/dev/null 2>&1 || true   # 先清理旧装
if adb install -r -t "$APK" 2>&1 | tee /tmp/zjdroid-install.log | tail -3; then
  echo "  ✓ install 命令退出 0"
else
  echo "  ✗ install 失败，日志见 /tmp/zjdroid-install.log"; exit 1
fi

echo "[5/5] 确认安装成功（pm path）..."
INSTALLED=$(adb shell pm path "$PKG" 2>/dev/null | head -1)
if [[ -n "$INSTALLED" ]]; then
  echo "  ✓ 安装成功: $INSTALLED"
  echo ""
  echo "=== E2E 结果: SUCCESS ==="
  # 清理（默认卸载以保持设备干净）
  adb uninstall "$PKG" >/dev/null 2>&1 && echo "(已卸载清理 $PKG)"
  exit 0
else
  echo "  ✗ pm path 未找到 $PKG，安装未生效"
  echo "=== E2E 结果: FAILED ==="
  exit 1
fi
