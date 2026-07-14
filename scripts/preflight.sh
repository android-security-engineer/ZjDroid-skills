#!/usr/bin/env bash
# scripts/preflight.sh — Agent 安装前环境自检
# 退出码: 0=全绿可装, 1=有致命缺失(宿主工具/设备), 2=仅有warn(可尝试装)
set -uo pipefail

PASS=0; WARN=0; FAIL=0
ok()   { echo "  ✓ $1"; PASS=$((PASS+1)); }
warn() { echo "  ⚠ $1"; WARN=$((WARN+1)); }
fail() { echo "  ✗ $1"; FAIL=$((FAIL+1)); }

echo "=== ZjDroid 安装前置自检 ==="

echo "[1/5] 宿主工具..."
command -v gh      >/dev/null && ok "gh CLI: $(gh --version | head -1)" || fail "gh CLI 缺失 → 安装: https://cli.github.com/"
command -v adb     >/dev/null && ok "adb: $(adb --version | head -1)" || fail "adb 缺失 → apt install android-tools-adb / 装 platform-tools"
command -v python3 >/dev/null && ok "python3: $(python3 --version)"   || fail "python3 缺失 → apt install python3"
python3 -c "import sys; sys.exit(0 if sys.version_info>=(3,10) else 1)" 2>/dev/null \
  && ok "python3 ≥3.10" || fail "python3 版本 <3.10 → 升级"

echo "[2/5] gh 认证..."
gh auth status >/dev/null 2>&1 && ok "gh 已认证" || fail "gh 未认证 → gh auth login"

echo "[3/5] adb 设备..."
DEV=$(adb devices 2>/dev/null | awk 'NR>1 && $2=="device"{print $1; exit}')
if [[ -n "$DEV" ]]; then ok "在线设备: $DEV"; else fail "无在线设备 → adb connect / 插 USB / 开 USB 调试"; fi

echo "[4/5] root 权限..."
if adb shell su -c id 2>/dev/null | grep -q uid=0; then ok "设备已 root"; else warn "su 不可用或无 root → Xposed 模块无法注册"; fi

echo "[5/5] Xposed 框架..."
XPOSED=0
adb shell su -c "test -f /data/adb/lspd/config/modules_config.db" 2>/dev/null && { ok "检测到 LSPosed"; XPOSED=1; }
adb shell su -c "test -d /data/data/de.robv.android.xposed.installer/conf" 2>/dev/null && { ok "检测到经典 Xposed"; XPOSED=1; }
[[ $XPOSED -eq 0 ]] && warn "未检测到已知 Xposed 框架 → 装 LSPosed/EdXposed，或装完用 Manager 手动启用"

echo ""
echo "汇总: $PASS 通过 / $WARN 警告 / $FAIL 致命缺失"
if [[ $FAIL -gt 0 ]]; then echo "→ 修复致命项后重跑: bash scripts/preflight.sh"; exit 1; fi
[[ $WARN -gt 0 ]] && exit 2
exit 0
