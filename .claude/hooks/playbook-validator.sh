#!/bin/bash
# ============================================================
# playbook-validator.sh - Playbook Schema v2 形式検証 Hook
# ============================================================
# 発火条件: 手動実行（playbook ファイルパスを引数として渡す）
# 目的: playbook が Schema v2 に準拠しているか検証
#
# 使用方法:
#   bash .claude/hooks/playbook-validator.sh path/to/playbook.md
#
# 終了コード:
#   0: 正常（PASS または SKIP）
#   1: 不正形式検出（BLOCK）
#
# M082: Hook 契約準拠
# 参照: docs/hook-exit-code-contract.md, docs/playbook-schema-v2.md
# ============================================================

set -uo pipefail

HOOK_NAME="playbook-validator"
ERRORS=()

# ============================================================
# 引数チェック
# ============================================================
if [ $# -lt 1 ]; then
    echo "[SKIP] $HOOK_NAME: no file path provided" >&2
    exit 0
fi

FILE_PATH="$1"

# ============================================================
# ファイル存在チェック
# ============================================================
if [ ! -f "$FILE_PATH" ]; then
    echo "[SKIP] $HOOK_NAME: file not found: $FILE_PATH" >&2
    exit 0
fi

# ============================================================
# playbook ファイル名パターンチェック
# ============================================================
BASENAME=$(basename "$FILE_PATH")
if [[ ! "$BASENAME" =~ ^playbook-[a-zA-Z0-9_-]+\.md$ ]]; then
    echo "[SKIP] $HOOK_NAME: not a playbook file: $BASENAME" >&2
    exit 0
fi

echo "[INFO] $HOOK_NAME: validating $FILE_PATH" >&2

# ============================================================
# 1. 必須セクションの存在チェック
# ============================================================
check_section() {
    local section="$1"
    if ! grep -q "^## $section" "$FILE_PATH" 2>/dev/null; then
        ERRORS+=("Missing required section: ## $section")
    fi
}

check_section "meta"
check_section "goal"
check_section "phases"
check_section "final_tasks"

# ============================================================
# 2. meta セクションの必須フィールドチェック
# ============================================================
# meta セクションを抽出（## meta から次の ## まで、macOS 互換）
META_SECTION=$(sed -n '/^## meta/,/^## /p' "$FILE_PATH" | sed '$d')

# project フィールド（YAML 内なのでインデント考慮）
if ! echo "$META_SECTION" | grep -q 'project:' 2>/dev/null; then
    ERRORS+=("Missing required field in meta: project")
fi

# branch フィールド
if ! echo "$META_SECTION" | grep -q 'branch:' 2>/dev/null; then
    ERRORS+=("Missing required field in meta: branch")
fi

# created フィールド
if ! echo "$META_SECTION" | grep -q 'created:' 2>/dev/null; then
    ERRORS+=("Missing required field in meta: created")
fi

# reviewed フィールド
if ! echo "$META_SECTION" | grep -q 'reviewed:' 2>/dev/null; then
    ERRORS+=("Missing required field in meta: reviewed")
fi

# ============================================================
# 3. goal セクションの必須フィールドチェック
# ============================================================
# goal セクションを抽出（macOS 互換）
GOAL_SECTION=$(sed -n '/^## goal/,/^## /p' "$FILE_PATH" | sed '$d')

# summary フィールド（YAML 内なのでインデント考慮）
if ! echo "$GOAL_SECTION" | grep -q 'summary:' 2>/dev/null; then
    ERRORS+=("Missing required field in goal: summary")
fi

# done_when フィールド
if ! echo "$GOAL_SECTION" | grep -q 'done_when:' 2>/dev/null; then
    ERRORS+=("Missing required field in goal: done_when")
fi

# ============================================================
# 4. 不正なチェックボックス形式の検出
# ============================================================
# 大文字 X の検出
if grep -qE '^\- \[X\]' "$FILE_PATH" 2>/dev/null; then
    ERRORS+=("Invalid checkbox format: [X] (uppercase) should be [x] (lowercase)")
fi

# 空白なしの検出
if grep -qE '^\-\[' "$FILE_PATH" 2>/dev/null; then
    ERRORS+=("Invalid checkbox format: missing space after '-'")
fi

# 空のブラケットの検出
if grep -qE '^\- \[\]' "$FILE_PATH" 2>/dev/null; then
    ERRORS+=("Invalid checkbox format: [] (empty) should be [ ] (with space)")
fi

# ============================================================
# 5. status 値の検証
# ============================================================
# 不正な status 値の検出（大文字または不正な値）
if grep -qE '^\*\*status\*\*: (PENDING|IN_PROGRESS|DONE|Pending|Done)' "$FILE_PATH" 2>/dev/null; then
    ERRORS+=("Invalid status value: must be lowercase (pending|in_progress|done)")
fi

# ============================================================
# 結果出力
# ============================================================
if [ ${#ERRORS[@]} -eq 0 ]; then
    echo "[PASS] $HOOK_NAME: $FILE_PATH is valid Schema v2 format" >&2
    exit 0
else
    echo "[BLOCK] $HOOK_NAME: validation failed with ${#ERRORS[@]} error(s)" >&2
    for error in "${ERRORS[@]}"; do
        echo "  - $error" >&2
    done
    exit 1
fi
