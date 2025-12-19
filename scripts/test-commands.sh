#!/bin/bash
# ==============================================================================
# test-commands.sh - Command 動作保証テスト
# ==============================================================================
#
# 目的:
#   - 8 個の Command の存在と基本構造を検証
#   - YAML フロントマターの必須フィールド確認
#   - description フィールドの存在確認
#
# 使用方法:
#   bash scripts/test-commands.sh [--verbose]
#
# Command 一覧:
#   1. crit
#   2. focus
#   3. lint
#   4. playbook-init
#   5. rollback
#   6. state-rollback
#   7. task-start
#   8. test
#
# ==============================================================================

set -e

VERBOSE=false
[ "$1" = "--verbose" ] && VERBOSE=true

PASS_COUNT=0
FAIL_COUNT=0
SKIP_COUNT=0
RESULTS=""

log() {
    if [ "$VERBOSE" = true ]; then
        echo "$1"
    fi
}

COMMANDS_DIR=".claude/commands"

# ==============================================================================
# 1. テスト関数定義
# ==============================================================================

test_command() {
    local command_name="$1"
    local command_file="$COMMANDS_DIR/$command_name.md"
    local description="$2"

    log "Testing: $command_name..."

    # ファイル存在チェック
    if [ ! -f "$command_file" ]; then
        RESULTS="$RESULTS\n  [FAIL] $command_name - ファイルが存在しません: $command_file"
        FAIL_COUNT=$((FAIL_COUNT + 1))
        return
    fi

    # YAML フロントマター存在チェック（---で始まる）
    if ! head -1 "$command_file" | grep -q '^---$'; then
        RESULTS="$RESULTS\n  [FAIL] $command_name - YAML フロントマターがありません"
        FAIL_COUNT=$((FAIL_COUNT + 1))
        return
    fi

    # description フィールド存在チェック
    if ! grep -q "^description:" "$command_file"; then
        RESULTS="$RESULTS\n  [FAIL] $command_name - description フィールドがありません"
        FAIL_COUNT=$((FAIL_COUNT + 1))
        return
    fi

    # allowed-tools フィールド存在チェック
    if ! grep -q "^allowed-tools:" "$command_file"; then
        RESULTS="$RESULTS\n  [FAIL] $command_name - allowed-tools フィールドがありません"
        FAIL_COUNT=$((FAIL_COUNT + 1))
        return
    fi

    # 最低限のコンテンツがあるか（10行以上）
    line_count=$(wc -l < "$command_file" | tr -d ' ')
    if [ "$line_count" -lt 10 ]; then
        RESULTS="$RESULTS\n  [FAIL] $command_name - コンテンツが少なすぎます (${line_count}行)"
        FAIL_COUNT=$((FAIL_COUNT + 1))
        return
    fi

    RESULTS="$RESULTS\n  [PASS] $command_name - $description"
    PASS_COUNT=$((PASS_COUNT + 1))
}

# ==============================================================================
# 2. 各 Command のテスト実行
# ==============================================================================

echo ""
echo "========================================"
echo "  Command 動作保証テスト"
echo "========================================"
echo ""

test_command "crit" "CRITIQUE 実行コマンド"
test_command "focus" "フォーカス切り替えコマンド"
test_command "lint" "lint 実行コマンド"
test_command "playbook-init" "playbook 初期化コマンド"
test_command "rollback" "ロールバックコマンド"
test_command "state-rollback" "state.md ロールバックコマンド"
test_command "task-start" "タスク開始コマンド"
test_command "test" "テスト実行コマンド"

# ==============================================================================
# 3. 結果サマリー
# ==============================================================================

echo ""
echo "========================================"
echo "  テスト結果"
echo "========================================"
echo -e "$RESULTS"
echo ""
echo "========================================"
echo "  合計: $((PASS_COUNT + FAIL_COUNT + SKIP_COUNT)) テスト"
echo "  PASS: $PASS_COUNT"
echo "  FAIL: $FAIL_COUNT"
echo "  SKIP: $SKIP_COUNT"
echo "========================================"

# 全て PASS の場合
if [ "$FAIL_COUNT" -eq 0 ] && [ "$PASS_COUNT" -eq 8 ]; then
    echo ""
    echo "ALL TESTS PASSED"
fi

# 失敗があれば exit 1
if [ "$FAIL_COUNT" -gt 0 ]; then
    echo ""
    echo "WARNING: $FAIL_COUNT 件のテストが失敗しました。"
    exit 1
fi

exit 0
