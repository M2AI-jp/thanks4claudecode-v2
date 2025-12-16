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
#   - 現在進行中の playbook（state.md active_playbooks）はアーカイブ対象外
#
# 実行経路:
#   1. playbook を Edit → このスクリプト発火
#   2. 全 Phase done を検出 → 「アーカイブ推奨」を出力
#   3. Claude が POST_LOOP に入る
#   4. POST_LOOP 行動 0.5 で mv 実行
#
# 参照: docs/archive-operation-rules.md

set -e

# state.md が存在しない場合はスキップ
if [ ! -f "state.md" ]; then
    exit 0
fi

# stdin から JSON を読み込む
INPUT=$(cat)

# jq がない場合はスキップ
if ! command -v jq &> /dev/null; then
    exit 0
fi

# 編集対象ファイルを取得
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""')
if [[ -z "$FILE_PATH" ]]; then
    exit 0
fi

# playbook ファイル以外は無視
if [[ "$FILE_PATH" != *playbook*.md ]]; then
    exit 0
fi

# playbook ファイルが存在しない場合はスキップ
if [ ! -f "$FILE_PATH" ]; then
    exit 0
fi

# playbook 内の Phase status を確認
# 全ての status: が done であるかチェック
TOTAL_PHASES=$(grep -c "^  status:" "$FILE_PATH" 2>/dev/null || echo "0")
DONE_PHASES=$(grep "^  status: done" "$FILE_PATH" 2>/dev/null | wc -l | tr -d ' ')

# Phase がない場合はスキップ
if [ "$TOTAL_PHASES" -eq 0 ]; then
    exit 0
fi

# 全 Phase が done でない場合はスキップ
if [ "$DONE_PHASES" -ne "$TOTAL_PHASES" ]; then
    exit 0
fi

# ==============================================================================
# V12: チェックボックス形式の完了判定
# ==============================================================================
# `- [x]` の数と `- [ ]` の数をカウントして完了率を確認
# ==============================================================================
CHECKED_COUNT=$(grep -c '\- \[x\]' "$FILE_PATH" 2>/dev/null || echo "0")
UNCHECKED_COUNT=$(grep -c '\- \[ \]' "$FILE_PATH" 2>/dev/null || echo "0")
TOTAL_CHECKBOX=$((CHECKED_COUNT + UNCHECKED_COUNT))

if [ "$TOTAL_CHECKBOX" -gt 0 ]; then
    if [ "$UNCHECKED_COUNT" -gt 0 ]; then
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "  ⚠️ 未完了の subtask があります（V12 形式）"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "  完了: $CHECKED_COUNT / 未完了: $UNCHECKED_COUNT"
        echo ""
        echo "  全ての subtask を完了させてください:"
        echo "  - [ ] → - [x] に変更"
        echo "  - validations を追加"
        echo "  - validated タイムスタンプを追加"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
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
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "  ⚠️ final_tasks が未完了です"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "  完了: $DONE_FINAL_TASKS / $TOTAL_FINAL_TASKS"
        echo "  → final_tasks を全て完了してからアーカイブしてください"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        exit 0
    fi
fi

# 現在進行中の playbook（state.md active_playbooks）かチェック
# 進行中ならアーカイブ提案しない（安全策）
if grep -q "$(basename "$FILE_PATH")" state.md 2>/dev/null; then
    # active_playbooks に含まれているか確認
    ACTIVE_SECTION=$(awk '/^## active_playbooks/,/^## [^a]/' state.md 2>/dev/null || true)
    if echo "$ACTIVE_SECTION" | grep -q "$(basename "$FILE_PATH")"; then
        # 現在進行中なのでスキップ（完了後に再度発火する）
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
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "  ⚠️ p_final（完了検証フェーズ）が存在しません"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "  done_when: $DONE_WHEN_COUNT 項目"
        echo ""
        echo "  playbook に p_final フェーズを追加してください。"
        echo "  参照: plan/template/playbook-format.md"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        # 警告のみ（ブロックしない）- 既存 playbook との互換性のため
    fi

    # p_final Phase の status チェック
    P_FINAL_STATUS=$(grep -A 30 "p_final" "$FILE_PATH" 2>/dev/null | grep "^status:" | head -1 | sed 's/status: *//')
    if [ -n "$P_FINAL_STATUS" ] && [ "$P_FINAL_STATUS" != "done" ]; then
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "  ❌ p_final（完了検証）が未完了です"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "  done_when の検証: status = $P_FINAL_STATUS"
        echo ""
        echo "  p_final を完了させてからアーカイブしてください。"
        echo "  → done_when の各項目が実際に満たされているか検証"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
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
            echo ""
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo "  ❌ done_when の検証に失敗しました"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo "  PASS: $PASS_COUNT / FAIL: $FAIL_COUNT"
            echo ""
            echo "  アーカイブをブロックします。"
            echo "  → 失敗した done_when 項目を修正してください。"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
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

# 全 Phase が done の場合、アーカイブを提案
cat << EOF

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  📦 Playbook 完了検出
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Playbook: $RELATIVE_PATH
  Status: 全 $TOTAL_PHASES Phase が done

  アーカイブを推奨します:
    mkdir -p $ARCHIVE_DIR
    mv $RELATIVE_PATH $ARCHIVE_PATH

  アーカイブ後:
    1. state.md の active_playbooks を null に更新
    2. 新しい playbook を作成（必要に応じて）

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF

exit 0
