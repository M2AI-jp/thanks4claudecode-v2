#!/bin/bash
# ==============================================================================
# test-skills.sh - Skill 動作保証テスト
# ==============================================================================
#
# 目的:
#   - 9 個の Skill の存在と基本構造を検証
#   - SKILL.md の必須セクション確認
#   - name, description フィールドの存在確認
#
# 使用方法:
#   bash scripts/test-skills.sh [--verbose]
#
# Skill 一覧:
#   1. consent-process
#   2. context-management
#   3. deploy-checker
#   4. frontend-design
#   5. lint-checker
#   6. plan-management
#   7. post-loop
#   8. state
#   9. test-runner
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

SKILLS_DIR=".claude/skills"

# ==============================================================================
# 1. テスト関数定義
# ==============================================================================

test_skill() {
    local skill_name="$1"
    local skill_file="$SKILLS_DIR/$skill_name/SKILL.md"
    local description="$2"

    log "Testing: $skill_name..."

    # ディレクトリ存在チェック
    if [ ! -d "$SKILLS_DIR/$skill_name" ]; then
        RESULTS="$RESULTS\n  [FAIL] $skill_name - ディレクトリが存在しません: $SKILLS_DIR/$skill_name"
        FAIL_COUNT=$((FAIL_COUNT + 1))
        return
    fi

    # SKILL.md 存在チェック
    if [ ! -f "$skill_file" ]; then
        RESULTS="$RESULTS\n  [FAIL] $skill_name - SKILL.md が存在しません: $skill_file"
        FAIL_COUNT=$((FAIL_COUNT + 1))
        return
    fi

    # name フィールド存在チェック（YAML frontmatter または frontmatter セクション内）
    if ! grep -qE "^name:|^  name:" "$skill_file"; then
        RESULTS="$RESULTS\n  [FAIL] $skill_name - name フィールドがありません"
        FAIL_COUNT=$((FAIL_COUNT + 1))
        return
    fi

    # description フィールド存在チェック
    if ! grep -qE "^description:|^  description:" "$skill_file"; then
        RESULTS="$RESULTS\n  [FAIL] $skill_name - description フィールドがありません"
        FAIL_COUNT=$((FAIL_COUNT + 1))
        return
    fi

    # 最低限のコンテンツがあるか（20行以上）
    line_count=$(wc -l < "$skill_file" | tr -d ' ')
    if [ "$line_count" -lt 20 ]; then
        RESULTS="$RESULTS\n  [FAIL] $skill_name - コンテンツが少なすぎます (${line_count}行)"
        FAIL_COUNT=$((FAIL_COUNT + 1))
        return
    fi

    RESULTS="$RESULTS\n  [PASS] $skill_name - $description"
    PASS_COUNT=$((PASS_COUNT + 1))
}

# ==============================================================================
# 2. 各 Skill のテスト実行
# ==============================================================================

echo ""
echo "========================================"
echo "  Skill 動作保証テスト"
echo "========================================"
echo ""

test_skill "consent-process" "合意プロセス Skill"
test_skill "context-management" "コンテキスト管理 Skill"
test_skill "deploy-checker" "デプロイ確認 Skill"
test_skill "frontend-design" "フロントエンド設計 Skill"
test_skill "lint-checker" "lint チェック Skill"
test_skill "plan-management" "計画管理 Skill"
test_skill "post-loop" "POST_LOOP 実行 Skill"
test_skill "state" "状態管理 Skill"
test_skill "test-runner" "テスト実行 Skill"

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
if [ "$FAIL_COUNT" -eq 0 ] && [ "$PASS_COUNT" -eq 9 ]; then
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
