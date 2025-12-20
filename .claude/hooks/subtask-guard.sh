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

# ==============================================================================
# M085: 厳格モード（M106: デフォルトを STRICT=1 に変更）
# ==============================================================================
# STRICT=1: validations 不足時に BLOCK（exit 2）- デフォルト
# STRICT=0: validations 不足時に WARN のみ（exit 0）
# ==============================================================================
# M106: 報酬詐欺防止のため、デフォルトを BLOCK に変更
# 旧: STRICT_MODE="${STRICT:-0}" (デフォルト WARN)
# 新: STRICT_MODE="${STRICT:-1}" (デフォルト BLOCK)
STRICT_MODE="${STRICT:-1}"

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

# playbook ファイルが存在しない場合
if [[ ! -f "$FILE_PATH" ]]; then
    if [[ "$STRICT_MODE" == "1" ]]; then
        # STRICT=1: 存在しないファイルへの編集は警告
        echo "[WARN] $HOOK_NAME: playbook file not found in STRICT mode (file=$FILE_PATH)" >&2
        exit 0
    else
        echo "[SKIP] $HOOK_NAME: playbook file not found (file=$FILE_PATH)" >&2
        exit 0
    fi
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
#
# M085: モード切替
#   - 通常モード（STRICT=0）: validations 不足は WARN のみ（exit 0）
#   - 厳格モード（STRICT=1）: validations 不足は BLOCK（exit 2）
# ==============================================================================
if [[ "$NEW_STRING" != *"validations:"* ]]; then
    # validations がない場合
    if [[ "$STRICT_MODE" == "1" ]]; then
        # 厳格モード: BLOCK
        echo "[BLOCK] $HOOK_NAME: subtask 完了には validations が必須です (STRICT=1)" >&2
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
    else
        # 通常モード: WARN のみで通す
        echo "[WARN] $HOOK_NAME: validations が不足しています。3 検証 (technical/consistency/completeness) の追加を推奨します" >&2
        echo "{\"decision\": \"allow\", \"systemMessage\": \"[subtask-guard] validations 不足: 3 検証の追加を推奨します。\"}"
        exit 0
    fi
fi

# validations がある場合は PASS で許可
echo "[PASS] $HOOK_NAME: validations 確認済み" >&2
echo "{\"decision\": \"allow\", \"systemMessage\": \"[subtask-guard] subtask 完了: validations 確認済み\"}"
exit 0
