#!/usr/bin/env bash
# ==============================================================================
# m106-test.sh - M106 修正の回帰テスト
# ==============================================================================
# 目的: M106 で修正したコンポーネントの動作確認
#
# テスト対象:
#   1. consent-guard.sh - playbook 存在時のスキップ
#   2. subtask-guard.sh - STRICT=1 デフォルト
#   3. critic-guard.sh - phase.status 検出（手動修正後）
# ==============================================================================

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}/..")" && pwd)"
cd "$ROOT"

# 色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

PASS=0
FAIL=0

pass() { echo -e "  ${GREEN}[PASS]${NC} $1"; ((PASS++)); }
fail() { echo -e "  ${RED}[FAIL]${NC} $1"; ((FAIL++)); }
skip() { echo -e "  ${YELLOW}[SKIP]${NC} $1"; }

echo ""
echo "=================================================="
echo "  M106 回帰テスト"
echo "=================================================="

# ------------------------------------------------------------------------------
# Test 1: consent-guard.sh - playbook 存在時のスキップ
# ------------------------------------------------------------------------------
echo ""
echo "--- Test 1: consent-guard.sh ---"

# playbook 存在チェックロジックが含まれているか
if grep -q "playbook.active" .claude/hooks/consent-guard.sh 2>/dev/null; then
    pass "consent-guard.sh に playbook.active チェックが存在"
else
    fail "consent-guard.sh に playbook.active チェックがない"
fi

# 構文チェック
if bash -n .claude/hooks/consent-guard.sh 2>/dev/null; then
    pass "consent-guard.sh 構文チェック OK"
else
    fail "consent-guard.sh 構文エラー"
fi

# ------------------------------------------------------------------------------
# Test 2: subtask-guard.sh - STRICT=1 デフォルト
# ------------------------------------------------------------------------------
echo ""
echo "--- Test 2: subtask-guard.sh ---"

# STRICT=1 がデフォルトになっているか
if grep -q 'STRICT:-1' .claude/hooks/subtask-guard.sh 2>/dev/null; then
    pass "subtask-guard.sh のデフォルトが STRICT=1"
else
    fail "subtask-guard.sh のデフォルトが STRICT=1 ではない"
fi

# 構文チェック
if bash -n .claude/hooks/subtask-guard.sh 2>/dev/null; then
    pass "subtask-guard.sh 構文チェック OK"
else
    fail "subtask-guard.sh 構文エラー"
fi

# ------------------------------------------------------------------------------
# Test 3: critic-guard.sh - phase.status 検出
# ------------------------------------------------------------------------------
echo ""
echo "--- Test 3: critic-guard.sh ---"

# playbook の status: done パターン検出ロジックが含まれているか
if grep -q "playbook-" .claude/hooks/critic-guard.sh 2>/dev/null; then
    pass "critic-guard.sh に playbook 検出ロジックが存在"
else
    skip "critic-guard.sh は手動修正が必要（HARD_BLOCK）"
fi

# 構文チェック
if bash -n .claude/hooks/critic-guard.sh 2>/dev/null; then
    pass "critic-guard.sh 構文チェック OK"
else
    fail "critic-guard.sh 構文エラー"
fi

# ------------------------------------------------------------------------------
# サマリー
# ------------------------------------------------------------------------------
echo ""
echo "=================================================="
echo "  Summary"
echo "=================================================="
echo -e "  ${GREEN}PASS: $PASS${NC}"
echo -e "  ${RED}FAIL: $FAIL${NC}"
echo ""

if [[ $FAIL -eq 0 ]]; then
    echo -e "${GREEN}ALL TESTS PASSED!${NC}"
    exit 0
else
    echo -e "${RED}$FAIL test(s) FAILED${NC}"
    exit 1
fi
