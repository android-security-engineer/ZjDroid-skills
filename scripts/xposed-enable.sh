#!/usr/bin/env bash
# scripts/xposed-enable.sh — 把指定包名注册为 Xposed 模块
set -euo pipefail
PKG="$1"

# 路径1: LSPosed（管理端 scope）
LSPOSED_DB=/data/adb/lspd/config/modules_config.db
if adb shell su -c "test -f $LSPOSED_DB" 2>/dev/null; then
  echo "  检测到 LSPosed，写入 scope..."
  adb shell su -c "sqlite3 $LSPOSED_DB \"INSERT OR REPLACE INTO modules(module_pkg_name,enabled) VALUES('$PKG',1);\"" 2>/dev/null || \
    echo "  WARN: LSPosed 自动注册失败，请用 LSPosed Manager 手动勾选 $PKG"
  exit 0
fi

# 路径2: 经典 Xposed（写 modules.list）
ML=/data/data/de.robv.android.xposed.installer/conf/modules.list
if adb shell su -c "test -d $(dirname $ML)" 2>/dev/null; then
  echo "  检测到经典 Xposed，追加 modules.list..."
  APK_PATH=$(adb shell pm path "$PKG" | head -1 | sed 's/package://')
  adb shell su -c "grep -q '$PKG' $ML 2>/dev/null || echo '$APK_PATH' >> $ML"
  exit 0
fi

echo "  WARN: 未检测到已知 Xposed 框架。请手动在 Xposed Manager 中启用 $PKG。"
