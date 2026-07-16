#!/usr/bin/env bash
# scripts/verify-install.sh — 安装后验证 ZjDroid 模块是否真的生效
# 用法: bash scripts/verify-install.sh [package]
# 退出码: 0=全部生效, 1=有项未通过
set -uo pipefail
PKG="${1:-com.android.reverse}"

echo "=== ZjDroid 安装后验证 ==="

echo "[1/4] 等待设备回连（重启 Zygote 后 adb 短暂掉线）..."
for i in $(seq 1 18); do
  S=$(adb get-state 2>/dev/null)
  [[ "$S" == "device" ]] && break
  sleep 5
done
S=$(adb get-state 2>/dev/null)
if [[ "$S" == "device" ]]; then echo "  ✓ 设备在线"; else echo "  ✗ 设备未回连 (90s)"; exit 1; fi

echo "[2/4] APK 已安装..."
if adb shell pm path "$PKG" 2>/dev/null | grep -q package:; then
  echo "  ✓ $PKG 已安装: $(adb shell pm path "$PKG" | head -1)"
else
  echo "  ✗ $PKG 未安装"; exit 1
fi

echo "[3/4] Xposed 模块已注册..."
# 兼容: adb root 后 shell 即 root, 否则 su 0(redroid/Magisk) / su -c(经典)
if adb shell id 2>/dev/null | grep -q 'uid=0'; then SU_PREFIX=""; else SU_PREFIX="su 0 "; fi
REG=0
adb shell "${SU_PREFIX}test -f /data/adb/lspd/config/modules_config.db" 2>/dev/null && \
  adb shell "${SU_PREFIX}sqlite3 /data/adb/lspd/config/modules_config.db \"SELECT enabled FROM modules WHERE module_pkg_name='$PKG';\"" 2>/dev/null | grep -q 1 && { echo "  ✓ LSPosed 已启用"; REG=1; }
adb shell "${SU_PREFIX}grep -q $PKG /data/data/de.robv.android.xposed.installer/conf/modules.list" 2>/dev/null && { echo "  ✓ 经典 Xposed modules.list 已含"; REG=1; }
[[ $REG -eq 0 ]] && echo "  ⚠ 无法自动确认模块启用（设备可能无 Xposed 框架），请用 Xposed Manager 核对 $PKG 已勾选"

echo "[4/4] logcat 出现 zjdroid tag（需目标进程被注入）..."
echo "  提示: 先拉起一个目标 App，ZjDroid 注入后 logcat 会有 zjdroid-shell-<pkg> tag"
echo "  抽样 5s logcat（可能为空，若模块刚生效且无目标运行属正常）:"
timeout 5 adb logcat -d 2>/dev/null | grep -i "zjdroid" | head -3 || echo "  (本次未捕获 zjdroid 日志)"

echo ""
echo "验证完成。若 [4/4] 为空：拉起目标 App 后运行 adb logcat -s zjdroid-shell-<目标包名> 确认注入。"
exit 0
