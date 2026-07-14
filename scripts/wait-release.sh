#!/usr/bin/env bash
# scripts/wait-release.sh — Release 无产物时触发 CI 并轮询直到 zjdroid.apk 可下载
# 退出码: 0=产物就绪, 3=超时(10分钟)
set -uo pipefail
REPO="android-security-engineer/ZjDroid-skills"
MAX=20  # 20 次 × 30s = 10 分钟

echo "[wait-release] 触发 build-apk workflow..."
gh workflow run build-apk.yml --repo "$REPO" 2>/dev/null || true

echo "[wait-release] 轮询 CI（最多 ${MAX}×30s）..."
for i in $(seq 1 $MAX); do
  # 优先看最新 run 是否成功
  RUN_STATE=$(gh run list --workflow=build-apk.yml --repo "$REPO" --limit 1 --json status,conclusion --jq '.[0]|.status+":"+(.conclusion//"-")' 2>/dev/null)
  if gh release download --repo "$REPO" --pattern "zjdroid.apk" --dir /tmp/zjdroid-apk --clobber 2>/dev/null; then
    echo "[wait-release] ✓ APK 就绪 (/tmp/zjdroid-apk/zjdroid.apk)"
    exit 0
  fi
  echo "  [$i/$MAX] run=$RUN_STATE，30s 后重试..."
  sleep 30
done
echo "[wait-release] ✗ 超时，CI 未在 10 分钟内产出。手动查看: gh run list --repo $REPO"
exit 3
