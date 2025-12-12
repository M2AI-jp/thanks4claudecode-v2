#!/bin/bash
# test-no-read.sh - LLM が Read せずに応答できることをシミュレート
#
# 目的:
#   systemMessage から必要な情報を抽出し、
#   LLM が Read ツールを使わずに応答できることを確認する。
#
# 検証項目:
#   - focus.current
#   - goal.milestone
#   - goal.phase
#   - remaining
#   - project_summary
#   - last_critic

set -e

echo "=== test-no-read.sh: systemMessage 情報抽出テスト ==="
echo ""

# prompt-guard.sh の出力を取得
OUTPUT=$(echo '{"prompt": "test"}' | bash .claude/hooks/prompt-guard.sh 2>/dev/null)

# jq で systemMessage を抽出
if ! command -v jq &> /dev/null; then
    echo "[ERROR] jq is required"
    exit 1
fi

SYSTEM_MSG=$(echo "$OUTPUT" | jq -r '.systemMessage')

echo "=== systemMessage 全文 ==="
echo "$SYSTEM_MSG"
echo ""

echo "=== 情報抽出 ==="

# 各フィールドを抽出
FOCUS=$(echo "$SYSTEM_MSG" | grep "^focus:" | sed 's/focus: //')
MILESTONE=$(echo "$SYSTEM_MSG" | grep "^milestone:" | sed 's/milestone: //')
PHASE=$(echo "$SYSTEM_MSG" | grep "^phase:" | sed 's/phase: //')
REMAINING=$(echo "$SYSTEM_MSG" | grep "^remaining:" | sed 's/remaining: //')
PROJECT_SUMMARY=$(echo "$SYSTEM_MSG" | grep "^project_summary:" | sed 's/project_summary: //')
LAST_CRITIC=$(echo "$SYSTEM_MSG" | grep "^last_critic:" | sed 's/last_critic: //')
PLAYBOOK=$(echo "$SYSTEM_MSG" | grep "^playbook:" | sed 's/playbook: //')
BRANCH=$(echo "$SYSTEM_MSG" | grep "^branch:" | sed 's/branch: //')
GIT=$(echo "$SYSTEM_MSG" | grep "^git:" | sed 's/git: //')

echo "focus.current:    $FOCUS"
echo "goal.milestone:   $MILESTONE"
echo "goal.phase:       $PHASE"
echo "remaining:        $REMAINING"
echo "project_summary:  $PROJECT_SUMMARY"
echo "last_critic:      $LAST_CRITIC"
echo "playbook:         $PLAYBOOK"
echo "branch:           $BRANCH"
echo "git_status:       $GIT"
echo ""

# 必須フィールドの検証
echo "=== 必須フィールド検証 ==="
ERRORS=0

check_field() {
    local name=$1
    local value=$2
    if [ -z "$value" ]; then
        echo "[FAIL] $name: 空または未設定"
        ERRORS=$((ERRORS + 1))
    else
        echo "[PASS] $name: $value"
    fi
}

check_field "focus" "$FOCUS"
check_field "milestone" "$MILESTONE"
check_field "phase" "$PHASE"
check_field "remaining" "$REMAINING"
check_field "project_summary" "$PROJECT_SUMMARY"
check_field "last_critic" "$LAST_CRITIC"
check_field "playbook" "$PLAYBOOK"
check_field "branch" "$BRANCH"
check_field "git_status" "$GIT"

echo ""

# done_criteria の抽出確認
echo "=== done_criteria 抽出 ==="
CRITERIA_COUNT=$(echo "$SYSTEM_MSG" | grep -c "^• " || echo "0")
echo "done_criteria 件数: $CRITERIA_COUNT"

if [ "$CRITERIA_COUNT" -gt 0 ]; then
    echo "[PASS] done_criteria が含まれている"
else
    echo "[WARN] done_criteria が空（playbook=null の可能性）"
fi

echo ""

# 総合判定
echo "=== 総合判定 ==="
if [ "$ERRORS" -eq 0 ]; then
    echo "[ALL PASS] LLM は Read せずに必要な情報を取得できます"
    exit 0
else
    echo "[FAIL] $ERRORS 件のエラーがあります"
    exit 1
fi
