#!/usr/bin/env bash
# scripts/xposed-enable.sh — 把指定包名注册为 Xposed 模块
set -euo pipefail
PKG="$1"

# 兼容多设备 root 调用: 优先 adb root 后直跑(root shell), 回退 su 0(redroid/Magisk), 再回退 su -c(经典)
# redroid 的 su 不支持 -c(报 invalid uid/gid), 用 "su 0 <cmd>" 语法
_run() {
  if adb shell id 2>/dev/null | grep -q 'uid=0'; then
    adb shell "$1" 2>/dev/null
  elif adb shell "su 0 $1" 2>/dev/null | grep -q .; then
    :
  else
    adb shell "su -c '$1'" 2>/dev/null
  fi
}

# 路径1: LSPosed（管理端 scope）
LSPOSED_DB=/data/adb/lspd/config/modules_config.db
if _run "test -f $LSPOSED_DB"; then
  echo "  检测到 LSPosed，写入 scope..."
  _run "sqlite3 $LSPOSED_DB \"INSERT OR REPLACE INTO modules(module_pkg_name,enabled) VALUES('$PKG',1);\"" \
    || echo "  WARN: LSPosed 自动注册失败，请用 LSPosed Manager 手动勾选 $PKG"
  exit 0
fi

# 路径2: 经典 Xposed（写 modules.list）
ML=/data/data/de.robv.android.xposed.installer/conf/modules.list
if _run "test -d $(dirname $ML)"; then
  echo "  检测到经典 Xposed，追加 modules.list..."
  APK_PATH=$(adb shell pm path "$PKG" | head -1 | sed 's/package://')
  _run "grep -q '$PKG' $ML 2>/dev/null || echo '$APK_PATH' >> $ML"
  exit 0
fi

echo "  WARN: 未检测到已知 Xposed 框架。请手动在 Xposed Manager 中启用 $PKG。"
