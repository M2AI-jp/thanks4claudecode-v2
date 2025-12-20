#!/bin/bash
# ==============================================================================
# critic-guard.sh - phase/state 完了時に critic 呼び出しを強制
# ==============================================================================
# トリガー: PreToolUse(Edit)
# 目的: critic PASS なしで phase/state を完了にすることを防止
#
# M106: phase.status 変更検出を追加
#   - state.md の "state: done" だけでなく
#   - playbook の "status: done" も検出
#
# 動作:
#   1. 編集対象が state.md または playbook かチェック
#   2. new_string に完了パターンが含まれるかチェック
#   3. self_complete: true がファイルに存在しなければブロック
#
# 根拠: CONTEXT.md「自己報酬詐欺」対策
# ==============================================================================

set -uo pipefail

STATE_FILE="${STATE_FILE:-state.md}"
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)

INPUT=$(cat)

if ! command -v jq &> /dev/null; then
    exit 0
fi

FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""')
NEW_STRING=$(echo "$INPUT" | jq -r '.tool_input.new_string // .tool_input.content // ""')

# ==============================================================================
# M106: 対象ファイル判定（state.md + playbook-*.md）
# ==============================================================================
IS_STATE_MD=false
IS_PLAYBOOK=false

if [[ "$FILE_PATH" == *"state.md" ]]; then
    IS_STATE_MD=true
elif [[ "$FILE_PATH" == *"playbook-"*".md" ]]; then
    IS_PLAYBOOK=true
fi

if [[ "$IS_STATE_MD" == false && "$IS_PLAYBOOK" == false ]]; then
    exit 0
fi

# ==============================================================================
# M106: 完了パターン検出（state: done + status: done）
# ==============================================================================
COMPLETION_DETECTED=false

if echo "$NEW_STRING" | grep -qE "state:[[:space:]]*done"; then
    COMPLETION_DETECTED=true
fi

if [[ "$IS_PLAYBOOK" == true ]]; then
    if echo "$NEW_STRING" | grep -qE "status:[[:space:]]*(done|completed)"; then
        COMPLETION_DETECTED=true
    fi
fi

if [[ "$COMPLETION_DETECTED" == false ]]; then
    exit 0
fi

# ------------------------------------------------------------------
# layer セクション内の state: done かを判定
# ------------------------------------------------------------------
if ! echo "$NEW_STRING" | grep -qE "^state:[[:space:]]*done"; then
    :
fi

# self_complete: true が現在のファイルに存在するかチェック
if [ -f "$STATE_FILE" ]; then
    SELF_COMPLETE=$(grep -E "self_complete:[[:space:]]*true" "$STATE_FILE" 2>/dev/null | wc -l | tr -d ' ')

    if [ "$SELF_COMPLETE" -gt 0 ]; then
        exit 0
    fi
fi

# ------------------------------------------------------------------
# ブロック: critic PASS なしで完了に変更しようとしている
# ------------------------------------------------------------------

cat >&2 << 'EOF'

========================================
  ⛔ critic 未実行 - 編集をブロック
========================================

  phase/state の完了変更には critic PASS が必要です。

  対処法（順番に実行）:

    1. done_criteria の全項目に証拠を示す

    2. critic エージェントを呼び出す:
       Task(subagent_type='critic')
       または /crit

    3. critic が PASS を返したら:
       state.md の self_complete: true を確認

    4. 再度完了に変更

  ┌─────────────────────────────────────────┐
  │ 証拠なしの done は自己報酬詐欺です。    │
  │ 「完了した気がする」は証拠ではありません。│
  └─────────────────────────────────────────┘

========================================

EOF

exit 2
