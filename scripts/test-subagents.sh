#!/bin/bash
# ==============================================================================
# test-subagents.sh - SubAgent 動作保証テスト
# ==============================================================================
#
# 目的:
#   - 6 個の SubAgent の存在と基本構造を検証
#   - YAML フロントマターの必須フィールド確認
#   - description フィールドの存在確認
#
# 使用方法:
#   bash scripts/test-subagents.sh [--verbose]
#
# SubAgent 一覧:
#   1. codex-delegate
#   2. critic
#   3. health-checker
#   4. pm
#   5. reviewer
#   6. setup-guide
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

AGENTS_DIR=".claude/agents"

# ==============================================================================
# 1. テスト関数定義
# ==============================================================================

test_subagent() {
    local agent_name="$1"
    local agent_file="$AGENTS_DIR/$agent_name.md"
    local description="$2"

    log "Testing: $agent_name..."

    # ファイル存在チェック
    if [ ! -f "$agent_file" ]; then
        RESULTS="$RESULTS\n  [FAIL] $agent_name - ファイルが存在しません: $agent_file"
        FAIL_COUNT=$((FAIL_COUNT + 1))
        return
    fi

    # YAML フロントマター存在チェック（---で始まる）
    if ! head -1 "$agent_file" | grep -q '^---$'; then
        RESULTS="$RESULTS\n  [FAIL] $agent_name - YAML フロントマターがありません"
        FAIL_COUNT=$((FAIL_COUNT + 1))
        return
    fi

    # name フィールド存在チェック
    if ! grep -q "^name:" "$agent_file"; then
        RESULTS="$RESULTS\n  [FAIL] $agent_name - name フィールドがありません"
        FAIL_COUNT=$((FAIL_COUNT + 1))
        return
    fi

    # description フィールド存在チェック
    if ! grep -q "^description:" "$agent_file"; then
        RESULTS="$RESULTS\n  [FAIL] $agent_name - description フィールドがありません"
        FAIL_COUNT=$((FAIL_COUNT + 1))
        return
    fi

    # tools フィールド存在チェック
    if ! grep -q "^tools:" "$agent_file"; then
        RESULTS="$RESULTS\n  [FAIL] $agent_name - tools フィールドがありません"
        FAIL_COUNT=$((FAIL_COUNT + 1))
        return
    fi

    RESULTS="$RESULTS\n  [PASS] $agent_name - $description"
    PASS_COUNT=$((PASS_COUNT + 1))
}

# ==============================================================================
# 2. 各 SubAgent のテスト実行
# ==============================================================================

echo ""
echo "========================================"
echo "  SubAgent 動作保証テスト"
echo "========================================"
echo ""

test_subagent "codex-delegate" "Codex MCP ラッパー SubAgent"
test_subagent "critic" "done_criteria 評価 SubAgent"
test_subagent "health-checker" "システム状態監視 SubAgent"
test_subagent "pm" "プロジェクトマネージャー SubAgent"
test_subagent "reviewer" "コード/設計レビュー SubAgent"
test_subagent "setup-guide" "セットアップガイド SubAgent"

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
if [ "$FAIL_COUNT" -eq 0 ] && [ "$PASS_COUNT" -eq 6 ]; then
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
