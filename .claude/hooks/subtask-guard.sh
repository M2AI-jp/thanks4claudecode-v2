#!/bin/bash
# ==============================================================================
# subtask-guard.sh - subtask の 3 検証を強制（V12: チェックボックス形式対応）
# ==============================================================================
# 目的: subtask の完了変更時に 3 つの検証を実行
# トリガー: PreToolUse(Edit)
#
# 【単一責任原則 (SRP)】
# このスクリプトは「subtask 検証」のみを担当
#
# 3 つの検証:
#   1. technical: 技術的に正しく動作するか
#   2. consistency: 他のコンポーネントと整合性があるか
#   3. completeness: 必要な変更が全て完了しているか
#
# V12 対応:
#   - `- [ ]` → `- [x]` の変更を検出
#   - final_tasks のチェックボックス変更はスキップ
#
# M056: final_tasks の変更は許可（スキップ）
# M082: Hook 契約準拠（パース失敗時は INTERNAL ERROR で通す）
# ==============================================================================

# -e を外す（エラーでも処理を続けて理由を出力するため）
set -uo pipefail

HOOK_NAME="subtask-guard"

# 入力 JSON を読み取り（失敗時は INTERNAL ERROR）
INPUT=$(cat) || {
    echo "[INTERNAL ERROR] $HOOK_NAME: failed to read input" >&2
    exit 0
}

# JSON パース（失敗時は INTERNAL ERROR で通す）
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null) || {
    echo "[INTERNAL ERROR] $HOOK_NAME: JSON parse failed, allowing operation" >&2
    exit 0
}

TOOL_INPUT=$(echo "$INPUT" | jq -r '.tool_input // {}' 2>/dev/null) || {
    echo "[INTERNAL ERROR] $HOOK_NAME: tool_input parse failed, allowing operation" >&2
    exit 0
}

# Edit ツール以外はパス
if [[ "$TOOL_NAME" != "Edit" ]]; then
    echo "[SKIP] $HOOK_NAME: not Edit tool (tool=$TOOL_NAME)" >&2
    exit 0
fi

# playbook ファイルへの編集のみチェック
FILE_PATH=$(echo "$TOOL_INPUT" | jq -r '.file_path // empty' 2>/dev/null) || {
    echo "[INTERNAL ERROR] $HOOK_NAME: file_path parse failed, allowing operation" >&2
    exit 0
}

if [[ "$FILE_PATH" != *"playbook-"* ]]; then
    echo "[SKIP] $HOOK_NAME: not playbook file (file=$FILE_PATH)" >&2
    exit 0
fi

# playbook ファイルが存在しない場合は SKIP
if [[ ! -f "$FILE_PATH" ]]; then
    echo "[SKIP] $HOOK_NAME: playbook file not found (file=$FILE_PATH)" >&2
    exit 0
fi

# old_string / new_string を取得
OLD_STRING=$(echo "$TOOL_INPUT" | jq -r '.old_string // empty' 2>/dev/null) || ""
NEW_STRING=$(echo "$TOOL_INPUT" | jq -r '.new_string // empty' 2>/dev/null) || ""

# ==============================================================================
# M056: final_tasks セクションの変更は許可（スキップ）
# ==============================================================================
# final_tasks は subtasks とは異なり、単純なチェックリストなので
# validations は不要。変更を許可する。
# 判定: old_string に "final_tasks" または "**ft" が含まれていれば final_tasks
# ==============================================================================
if [[ "$OLD_STRING" == *"final_tasks"* ]] || [[ "$OLD_STRING" == *"**ft"* ]] || [[ "$OLD_STRING" == *"- id: ft"* ]]; then
    # final_tasks の変更 → 許可（bypass）
    echo "[SKIP] $HOOK_NAME: final_tasks change, validation not required" >&2
    exit 0
fi

# ==============================================================================
# V12: チェックボックス形式 `- [ ]` → `- [x]` の変更を検出
# ==============================================================================
CHECKBOX_CHANGE=false

# パターン 1: `- [ ]` → `- [x]` の変更
if [[ "$OLD_STRING" == *"- [ ]"* ]] && [[ "$NEW_STRING" == *"- [x]"* ]]; then
    CHECKBOX_CHANGE=true
fi

# パターン 2: V11 形式（旧）status: pending/in_progress → status: done
if [[ "$OLD_STRING" == *"status: pending"* || "$OLD_STRING" == *"status: in_progress"* ]]; then
    if [[ "$NEW_STRING" == *"status: done"* ]]; then
        CHECKBOX_CHANGE=true
    fi
fi

# パターン 3: status: PASS への変更（旧形式の互換性）
if [[ "$NEW_STRING" == *"status: PASS"* ]]; then
    CHECKBOX_CHANGE=true
fi

# チェックボックス/status 変更がない場合はパス
if [[ "$CHECKBOX_CHANGE" == "false" ]]; then
    echo "[SKIP] $HOOK_NAME: not a subtask completion change" >&2
    exit 0
fi

# ==============================================================================
# validations チェック
# ==============================================================================
# V12 形式: - [x] の後に validations ブロックがあるか
# V11 形式: status: done の後に validations があるか
# ==============================================================================
if [[ "$NEW_STRING" != *"validations:"* ]]; then
    # validations がない場合はブロック
    echo "[BLOCK] $HOOK_NAME: subtask 完了には validations が必須です" >&2
    echo "" >&2
    echo "V12 形式（チェックボックス）で以下の 3 検証を追加してください:" >&2
    echo "" >&2
    echo "- [x] **p1.1**: criterion が満たされている" >&2
    echo "  - executor: claudecode" >&2
    echo "  - test_command: \`...\`" >&2
    echo "  - validations:" >&2
    echo "    - technical: \"PASS - 技術的に正しい\"" >&2
    echo "    - consistency: \"PASS - 整合性がある\"" >&2
    echo "    - completeness: \"PASS - 完全に実装\"" >&2
    echo "  - validated: $(date -u +%Y-%m-%dT%H:%M:%S)" >&2
    echo "" >&2
    echo "参照: plan/template/playbook-format.md" >&2
    exit 2
fi

# validations がある場合は警告のみで許可
echo "[WARN] $HOOK_NAME: subtask を完了にする前に 3 検証を確認してください (technical/consistency/completeness)" >&2
echo "{\"decision\": \"allow\", \"systemMessage\": \"[subtask-guard] subtask 完了確認: 3 検証 (technical/consistency/completeness) の確認を推奨します。\"}"
exit 0
