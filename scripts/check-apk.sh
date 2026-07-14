#!/usr/bin/env bash
# scripts/check-apk.sh — 校验 ZjDroid APK 产物完整性
# 用法: bash scripts/check-apk.sh <apk-path>
# 退出码: 0=校验通过, 1=校验失败, 2=用法错误
set -uo pipefail
APK="${1:-}"
if [[ -z "$APK" ]]; then echo "用法: bash scripts/check-apk.sh <apk-path>"; exit 2; fi
if [[ ! -f "$APK" ]]; then echo "✗ APK 不存在: $APK"; exit 1; fi

PASS=0; FAIL=0
ok()   { echo "  ✓ $1"; PASS=$((PASS+1)); }
fail() { echo "  ✗ $1"; FAIL=$((FAIL+1)); }

echo "=== APK 产物校验: $APK ==="

# [1/4] 文件大小（>100KB，空/坏包通常极小）
SIZE=$(stat -c%s "$APK" 2>/dev/null || stat -f%z "$APK" 2>/dev/null)
if [[ -n "$SIZE" && "$SIZE" -gt 102400 ]]; then ok "大小: ${SIZE} bytes"; else fail "大小异常: ${SIZE:-0} bytes（应 >100KB）"; fi

# [2/4] 是有效 zip/APK
if unzip -l "$APK" >/dev/null 2>&1; then ok "是有效 zip"; else fail "不是有效 zip/APK"; fi

# [3/4] 含 AndroidManifest.xml + classes.dex（APK 必备）
# 注意: unzip -l | grep -q 在大 APK + pipefail 下有 SIGPIPE 竞态，先存变量再 grep 更稳
ZIP_LST=$(unzip -l "$APK" 2>/dev/null)
if echo "$ZIP_LST" | grep -q "AndroidManifest.xml"; then ok "含 AndroidManifest.xml"; else fail "缺 AndroidManifest.xml"; fi
if echo "$ZIP_LST" | grep -q "classes.dex"; then ok "含 classes.dex"; else fail "缺 classes.dex"; fi

# [4/4] xposedmodule 元数据（用 aapt 若有，否则降级跳过）
if command -v aapt >/dev/null 2>&1; then
  if aapt dump xmltree "$APK" AndroidManifest.xml 2>/dev/null | grep -q "xposedmodule"; then
    ok "含 xposedmodule 元数据（Xposed 模块注册）"
  else
    fail "缺 xposedmodule 元数据（非 Xposed 模块？）"
  fi
  # 签名校验（release 应已签名，debug 用默认 debug key）
  if command -v apksigner >/dev/null 2>&1; then
    if apksigner verify --print-certs "$APK" >/dev/null 2>&1; then ok "签名有效"; else fail "签名无效或未签名"; fi
  fi
else
  echo "  ⚠ 无 aapt，跳过元数据/签名深度校验（已做基础 zip+大小校验）"
fi

echo ""
echo "汇总: $PASS 通过 / $FAIL 失败"
[[ $FAIL -gt 0 ]] && exit 1
exit 0
