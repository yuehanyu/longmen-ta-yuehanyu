#!/bin/bash
# 龙门计划 - 助教每日自动上传脚本（Mac）
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$SCRIPT_DIR"
LOG_DIR="$REPO_DIR/.longmen"
LOG_FILE="$LOG_DIR/auto_push.log"
CONFIG_FILE="$REPO_DIR/config.json"
TODAY=$(date '+%y%m%d')

mkdir -p "$LOG_DIR"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "=== 开始每日上传 (${TODAY}) ==="

# 读取助教名称
if command -v python3 &>/dev/null && [ -f "$CONFIG_FILE" ]; then
    TA_NAME=$(python3 -c "import json; print(json.load(open('$CONFIG_FILE'))['ta_name'])" 2>/dev/null || echo "助教")
else
    TA_NAME="助教"
fi

cd "$REPO_DIR"

# 检查是否为 Git 仓库
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    log "错误：当前目录不是 Git 仓库，请联系管理员"
    exit 1
fi

# 只暂存4个每日工作文件夹（不提交其他文件）
git add "每日输出/" "每日解答/" "每日补充/" "每日反馈/" 2>/dev/null || true

# 检查是否有新内容
if git diff --staged --quiet; then
    log "今天没有新内容，跳过上传"
    exit 0
fi

# 提交
git commit -m "每日上传 ${TODAY} - ${TA_NAME}"

# 推送
if git push origin main 2>&1 | tee -a "$LOG_FILE"; then
    log "上传成功 ✓"
else
    log "上传失败，请检查网络连接或联系管理员"
    exit 1
fi
