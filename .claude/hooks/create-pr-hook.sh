#!/bin/bash
# ============================================================
# create-pr-hook.sh - playbook 完了時の PR 自動作成フック
# ============================================================
# 発火条件: playbook の全 Phase が done になった後
# 目的: POST_LOOP で自動的に PR を作成
#
# このスクリプトは create-pr.sh のラッパーとして機能し、
# 以下の追加チェックを行います：
#   - playbook が完了しているか確認
#   - 未コミット変更がないか確認
#   - main ブランチでないか確認
#   - create-pr.sh を呼び出し
#
# M082: Hook 契約準拠（必ず理由を出力、パース失敗時は INTERNAL ERROR）
# ============================================================

# -e を外す（エラーでも処理を続けて理由を出力するため）
set -uo pipefail

HOOK_NAME="create-pr-hook"

# ============================================================
# 設定
# ============================================================
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
STATE_FILE="$REPO_ROOT/state.md"
CREATE_PR_SCRIPT="$REPO_ROOT/.claude/hooks/create-pr.sh"
SEP="━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# 色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# ============================================================
# 前提条件チェック
# ============================================================

# M086: gh CLI の存在確認（不存在時は WARN で通す）
if ! command -v gh &> /dev/null; then
    echo "[WARN] $HOOK_NAME: gh CLI not installed, PR creation will be skipped" >&2
    echo "  Install: brew install gh" >&2
    exit 0
fi

# create-pr.sh の存在確認
if [ ! -x "$CREATE_PR_SCRIPT" ]; then
    echo "[SKIP] $HOOK_NAME: create-pr.sh not found or not executable ($CREATE_PR_SCRIPT)" >&2
    exit 0
fi

# state.md の存在確認
if [ ! -f "$STATE_FILE" ]; then
    echo "[SKIP] $HOOK_NAME: state.md not found" >&2
    exit 0
fi

# main/master ブランチチェック
CURRENT_BRANCH=$(git branch --show-current 2>/dev/null || echo "")
if [ "$CURRENT_BRANCH" = "main" ] || [ "$CURRENT_BRANCH" = "master" ]; then
    echo "[SKIP] $HOOK_NAME: on main/master branch, PR not needed" >&2
    exit 0
fi

# ============================================================
# playbook 完了チェック
# ============================================================

# active playbook を取得
PLAYBOOK_PATH=$(grep -A5 "## playbook" "$STATE_FILE" 2>/dev/null | grep "active:" | sed 's/.*: *//' | sed 's/ *#.*//' || echo "null")

if [ "$PLAYBOOK_PATH" = "null" ] || [ -z "$PLAYBOOK_PATH" ]; then
    echo "[SKIP] $HOOK_NAME: no active playbook" >&2
    exit 0
fi

if [ ! -f "$REPO_ROOT/$PLAYBOOK_PATH" ]; then
    echo "[SKIP] $HOOK_NAME: playbook not found ($PLAYBOOK_PATH)" >&2
    exit 0
fi

PLAYBOOK_FILE="$REPO_ROOT/$PLAYBOOK_PATH"

# 全 Phase が done かチェック
# status: pending または in_progress があれば未完了
INCOMPLETE_PHASES=$(grep -cE "status: (pending|in_progress)" "$PLAYBOOK_FILE" 2>/dev/null || echo "0")

if [ "$INCOMPLETE_PHASES" -gt 0 ]; then
    echo "[SKIP] $HOOK_NAME: playbook has incomplete phases ($INCOMPLETE_PHASES remaining)" >&2
    exit 0
fi

# ============================================================
# 未コミット変更チェック
# ============================================================

UNCOMMITTED=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')

if [ "$UNCOMMITTED" -gt 0 ]; then
    echo "[SKIP] $HOOK_NAME: uncommitted changes exist ($UNCOMMITTED files)" >&2
    echo "  Run: git add -A && git commit -m \"feat: playbook completion\"" >&2
    exit 0
fi

# ============================================================
# PR 作成
# ============================================================

echo "[PASS] $HOOK_NAME: all checks passed, creating PR" >&2
echo "  Playbook: $PLAYBOOK_PATH" >&2

# create-pr.sh を実行
exec "$CREATE_PR_SCRIPT"
