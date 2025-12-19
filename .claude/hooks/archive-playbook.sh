#!/bin/bash
# archive-playbook.sh - playbook 完了時の自動アーカイブ提案
#
# 発火条件: PostToolUse:Edit
# 目的: playbook の全 Phase が done になったら plan/archive/ に移動を提案
#
# 設計思想（2025-12-09 改善）:
#   - playbook 完了を自動検出
#   - 移動は提案のみ（自動実行しない）★安全側設計
#   - Claude が POST_LOOP で実行（CLAUDE.md 行動 0.5）
#   - 現在進行中の playbook（state.md playbook.active）はアーカイブ対象外
#
# 実行経路:
#   1. playbook を Edit → このスクリプト発火
#   2. 全 Phase done を検出 → 「アーカイブ推奨」を出力
#   3. Claude が POST_LOOP に入る
#   4. POST_LOOP 行動 0.5 で mv 実行
#
# M082: Hook 契約準拠（必ず理由を出力、パース失敗時は INTERNAL ERROR）
# 参照: docs/archive-operation-rules.md

# -e を使わない（エラーでも処理を続けて理由を出力するため）
set -uo pipefail

HOOK_NAME="archive-playbook"

# state.md が存在しない場合はスキップ
if [ ! -f "state.md" ]; then
    echo "[SKIP] $HOOK_NAME: state.md not found" >&2
    exit 0
fi

# stdin から JSON を読み込む
INPUT=$(cat) || {
    echo "[INTERNAL ERROR] $HOOK_NAME: failed to read input" >&2
    exit 0
}

# jq がない場合はスキップ
if ! command -v jq &> /dev/null; then
    echo "[SKIP] $HOOK_NAME: jq command not found" >&2
    exit 0
fi

# 編集対象ファイルを取得
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""' 2>/dev/null) || {
    echo "[INTERNAL ERROR] $HOOK_NAME: JSON parse failed" >&2
    exit 0
}

if [[ -z "$FILE_PATH" ]]; then
    echo "[SKIP] $HOOK_NAME: no file_path in input" >&2
    exit 0
fi

# playbook ファイル以外は無視
if [[ "$FILE_PATH" != *playbook*.md ]]; then
    echo "[SKIP] $HOOK_NAME: not a playbook file ($FILE_PATH)" >&2
    exit 0
fi

# playbook ファイルが存在しない場合はスキップ
if [ ! -f "$FILE_PATH" ]; then
    echo "[SKIP] $HOOK_NAME: playbook file not found ($FILE_PATH)" >&2
    exit 0
fi

# playbook 内の Phase status を確認
# 全ての status: が done であるかチェック
TOTAL_PHASES=$(grep -c "^  status:" "$FILE_PATH" 2>/dev/null | head -1 | tr -d ' \n' || echo "0")
DONE_PHASES=$(grep "^  status: done" "$FILE_PATH" 2>/dev/null | wc -l | tr -d ' \n')
# 空の場合は 0 に設定
TOTAL_PHASES=${TOTAL_PHASES:-0}
DONE_PHASES=${DONE_PHASES:-0}

# Phase がない場合はスキップ
if [ "$TOTAL_PHASES" -eq 0 ]; then
    echo "[SKIP] $HOOK_NAME: no phases found in playbook" >&2
    exit 0
fi

# 全 Phase が done でない場合はスキップ
if [ "$DONE_PHASES" -ne "$TOTAL_PHASES" ]; then
    echo "[SKIP] $HOOK_NAME: phases not all done ($DONE_PHASES/$TOTAL_PHASES)" >&2
    exit 0
fi

# ==============================================================================
# V12: チェックボックス形式の完了判定
# ==============================================================================
# `- [x]` の数と `- [ ]` の数をカウントして完了率を確認
# ==============================================================================
CHECKED_COUNT=$(grep -c '\- \[x\]' "$FILE_PATH" 2>/dev/null | head -1 | tr -d ' \n' || echo "0")
UNCHECKED_COUNT=$(grep -c '\- \[ \]' "$FILE_PATH" 2>/dev/null | head -1 | tr -d ' \n' || echo "0")
# 空の場合は 0 に設定
CHECKED_COUNT=${CHECKED_COUNT:-0}
UNCHECKED_COUNT=${UNCHECKED_COUNT:-0}
TOTAL_CHECKBOX=$((CHECKED_COUNT + UNCHECKED_COUNT))

if [ "$TOTAL_CHECKBOX" -gt 0 ]; then
    if [ "$UNCHECKED_COUNT" -gt 0 ]; then
        echo "[SKIP] $HOOK_NAME: unchecked subtasks remain ($UNCHECKED_COUNT unchecked, $CHECKED_COUNT checked)" >&2
        exit 0  # 未完了があれば提案しない
    fi
fi

# M019: final_tasks チェック（存在する場合のみ）
# playbook に final_tasks セクションがある場合、全て完了しているか確認
# V12 形式: `- [x] **ft1**` でチェック
if grep -q "^## final_tasks" "$FILE_PATH" 2>/dev/null; then
    # V12 形式: チェックボックスでカウント
    TOTAL_FINAL_TASKS=$(grep -A 100 "^## final_tasks" "$FILE_PATH" | grep -c '\- \[.\] \*\*ft' 2>/dev/null || echo "0")
    DONE_FINAL_TASKS=$(grep -A 100 "^## final_tasks" "$FILE_PATH" | grep -c '\- \[x\] \*\*ft' 2>/dev/null || echo "0")

    # V11 形式（フォールバック）: status: done でカウント
    if [ "$TOTAL_FINAL_TASKS" -eq 0 ]; then
        TOTAL_FINAL_TASKS=$(awk '/^final_tasks:/,/^[a-z_]+:/' "$FILE_PATH" | grep -c "^ *- " 2>/dev/null || echo "0")
        DONE_FINAL_TASKS=$(awk '/^final_tasks:/,/^[a-z_]+:/' "$FILE_PATH" | grep -c "status: done" 2>/dev/null || echo "0")
    fi

    if [ "$TOTAL_FINAL_TASKS" -gt 0 ] && [ "$DONE_FINAL_TASKS" -lt "$TOTAL_FINAL_TASKS" ]; then
        echo "[SKIP] $HOOK_NAME: final_tasks incomplete ($DONE_FINAL_TASKS/$TOTAL_FINAL_TASKS done)" >&2
        exit 0
    fi
fi

# 現在進行中の playbook（state.md playbook.active）かチェック
# 進行中ならアーカイブ提案しない（安全策）
ACTIVE_PLAYBOOK=$(grep -A 5 "^## playbook" state.md 2>/dev/null | grep "^active:" | head -1 | sed 's/active: *//' | tr -d ' ')
if [ -n "$ACTIVE_PLAYBOOK" ] && [ "$ACTIVE_PLAYBOOK" != "null" ]; then
    if echo "$ACTIVE_PLAYBOOK" | grep -q "$(basename "$FILE_PATH")"; then
        # 現在進行中なのでスキップ（完了後に再度発火する）
        echo "[SKIP] $HOOK_NAME: playbook is currently active (state.md playbook.active)" >&2
        exit 0
    fi
fi

# ==============================================================================
# M056: done_when 再検証（報酬詐欺防止）
# ==============================================================================
# playbook の goal.done_when を抽出し、関連する test_command を実行して検証
# 全 PASS でなければアーカイブをブロック

DONE_WHEN_SECTION=$(sed -n '/^done_when:/,/^[a-z_]*:/p' "$FILE_PATH" 2>/dev/null | grep "^  - " | head -10)
DONE_WHEN_COUNT=$(echo "$DONE_WHEN_SECTION" | grep -c "^  - " 2>/dev/null || echo "0")

if [ "$DONE_WHEN_COUNT" -gt 0 ]; then
    # p_final Phase の存在チェック
    if ! grep -q "p_final" "$FILE_PATH" 2>/dev/null; then
        echo "[WARN] $HOOK_NAME: p_final phase not found (done_when: $DONE_WHEN_COUNT items)" >&2
        # 警告のみ（ブロックしない）- 既存 playbook との互換性のため
    fi

    # p_final Phase の status チェック
    P_FINAL_STATUS=$(grep -A 30 "p_final" "$FILE_PATH" 2>/dev/null | grep "^status:" | head -1 | sed 's/status: *//')
    if [ -n "$P_FINAL_STATUS" ] && [ "$P_FINAL_STATUS" != "done" ]; then
        echo "[BLOCK] $HOOK_NAME: p_final not done (status=$P_FINAL_STATUS)" >&2
        exit 2  # done_when 未検証でブロック
    fi

    # done_when の test_command を実行（p_final.* の test_command を収集）
    P_FINAL_TEST_COMMANDS=$(grep -A 50 "p_final" "$FILE_PATH" 2>/dev/null | grep "test_command:" | head -10)
    if [ -n "$P_FINAL_TEST_COMMANDS" ]; then
        FAIL_COUNT=0
        PASS_COUNT=0

        # 各 test_command を実行（簡易版: grep で PASS/FAIL を確認）
        while IFS= read -r line; do
            CMD=$(echo "$line" | sed 's/.*test_command: *"//' | sed 's/"$//')
            if [ -n "$CMD" ] && [ "$CMD" != "test_command:" ]; then
                # test_command を実行して結果を確認
                RESULT=$(eval "$CMD" 2>/dev/null || echo "FAIL")
                if echo "$RESULT" | grep -q "PASS"; then
                    PASS_COUNT=$((PASS_COUNT + 1))
                else
                    FAIL_COUNT=$((FAIL_COUNT + 1))
                fi
            fi
        done <<< "$P_FINAL_TEST_COMMANDS"

        if [ "$FAIL_COUNT" -gt 0 ]; then
            echo "[BLOCK] $HOOK_NAME: done_when verification failed (PASS=$PASS_COUNT, FAIL=$FAIL_COUNT)" >&2
            exit 2  # done_when FAIL でブロック
        fi
    fi
fi

# 相対パスに変換
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
RELATIVE_PATH="${FILE_PATH#$PROJECT_DIR/}"

# playbook 名を取得
PLAYBOOK_NAME=$(basename "$FILE_PATH")

# アーカイブ先を決定
ARCHIVE_DIR="plan/archive"
ARCHIVE_PATH="$ARCHIVE_DIR/$PLAYBOOK_NAME"

# ==============================================================================
# M083: derives_from を読み取り、project.md の milestone を自動更新
# ==============================================================================
# playbook の meta.derives_from を読み取り、対応する milestone を特定
# status: achieved に更新し、achieved_at を設定

DERIVES_FROM=""
MILESTONE_UPDATE_CMD=""

# derives_from を抽出（meta セクション内）
if grep -q "^derives_from:" "$FILE_PATH" 2>/dev/null; then
    DERIVES_FROM=$(grep "^derives_from:" "$FILE_PATH" | head -1 | sed 's/derives_from: *//' | tr -d ' "')
fi

# derives_from が見つかった場合、project.md 更新コマンドを生成
if [ -n "$DERIVES_FROM" ] && [ "$DERIVES_FROM" != "null" ]; then
    if [ -f "plan/project.md" ]; then
        # milestone ID を確認
        if grep -q "id: $DERIVES_FROM" plan/project.md 2>/dev/null; then
            CURRENT_DATE=$(date +%Y-%m-%d)
            # sed コマンドを生成（milestone ブロック内の status と achieved_at を更新）
            MILESTONE_UPDATE_CMD="sed -i '' '/id: $DERIVES_FROM/,/^- id:/ { s/status: .*/status: achieved/; s/achieved_at: .*/achieved_at: $CURRENT_DATE/; }' plan/project.md"
            echo "[INFO] $HOOK_NAME: milestone $DERIVES_FROM will be marked as achieved" >&2
        else
            echo "[WARN] $HOOK_NAME: milestone $DERIVES_FROM not found in project.md" >&2
        fi
    else
        echo "[WARN] $HOOK_NAME: plan/project.md not found" >&2
    fi
fi

# 全 Phase が done の場合、アーカイブを提案
echo "[PASS] $HOOK_NAME: playbook ready for archive ($RELATIVE_PATH)" >&2
cat << EOF

  Playbook: $RELATIVE_PATH
  Status: all $TOTAL_PHASES phases done
  Milestone: ${DERIVES_FROM:-"(none)"}

  Archive commands:
    mkdir -p $ARCHIVE_DIR && mv $RELATIVE_PATH $ARCHIVE_PATH
EOF

# milestone 更新コマンドがある場合は追加
if [ -n "$MILESTONE_UPDATE_CMD" ]; then
    cat << EOF
    $MILESTONE_UPDATE_CMD
EOF
fi

cat << EOF

  Post-archive tasks:
    1. Update state.md playbook.active to null
    2. Update state.md playbook.last_archived to $ARCHIVE_PATH
    3. Create new playbook if needed

EOF

exit 0
