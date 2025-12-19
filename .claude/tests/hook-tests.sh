#!/bin/bash
# ============================================================
# hook-tests.sh - ローカル Hook テストスイート
# ============================================================
# 目的: 全 Hook の構文チェックと主要 Hook の基本動作テストを実行
#
# 使用方法:
#   bash .claude/tests/hook-tests.sh
#
# 設計原則:
#   - ローカル完結（CI 依存なし）
#   - M082 契約準拠の検証
#   - 擬似入力での基本動作テスト
#
# M087: ローカル Hook テストスイートの整備
# ============================================================

set -uo pipefail

# ============================================================
# 設定
# ============================================================
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
HOOKS_DIR="$REPO_ROOT/.claude/hooks"
PASS_COUNT=0
FAIL_COUNT=0

# 色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# ============================================================
# ヘルパー関数
# ============================================================
print_header() {
    echo ""
    echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
}

print_pass() {
    echo -e "  ${GREEN}[PASS]${NC} $1"
    ((PASS_COUNT++))
}

print_fail() {
    echo -e "  ${RED}[FAIL]${NC} $1"
    ((FAIL_COUNT++))
}

print_skip() {
    echo -e "  ${YELLOW}[SKIP]${NC} $1"
}

# ============================================================
# 1. 構文チェック（bash -n）
# ============================================================
test_syntax() {
    print_header "1. Syntax Check (bash -n)"

    local hooks=("$HOOKS_DIR"/*.sh)
    local syntax_errors=0

    for hook in "${hooks[@]}"; do
        if [ -f "$hook" ]; then
            hook_name=$(basename "$hook")
            if bash -n "$hook" 2>/dev/null; then
                print_pass "$hook_name"
            else
                print_fail "$hook_name - syntax error"
                ((syntax_errors++))
            fi
        fi
    done

    echo ""
    if [ $syntax_errors -eq 0 ]; then
        echo -e "  ${GREEN}Syntax Check: All hooks passed${NC}"
    else
        echo -e "  ${RED}Syntax Check: $syntax_errors hook(s) failed${NC}"
    fi
}

# ============================================================
# 2. subtask-guard.sh テスト
# ============================================================
test_subtask_guard() {
    print_header "2. subtask-guard.sh Tests"

    local hook="$HOOKS_DIR/subtask-guard.sh"

    if [ ! -f "$hook" ]; then
        print_skip "subtask-guard.sh not found"
        return
    fi

    # Test 2.1: パース失敗時に exit 0
    echo 'invalid json' | bash "$hook" > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        print_pass "Parse failure returns exit 0"
    else
        print_fail "Parse failure should return exit 0"
    fi

    # Test 2.2: Edit 以外のツールは SKIP
    echo '{"tool_name":"Read"}' | bash "$hook" > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        print_pass "Non-Edit tool returns exit 0 (SKIP)"
    else
        print_fail "Non-Edit tool should return exit 0"
    fi

    # Test 2.3: STRICT モードの存在確認
    if grep -q 'STRICT' "$hook"; then
        print_pass "STRICT mode variable exists"
    else
        print_fail "STRICT mode variable not found"
    fi
}

# ============================================================
# 3. consent-guard.sh テスト
# ============================================================
test_consent_guard() {
    print_header "3. consent-guard.sh Tests"

    local hook="$HOOKS_DIR/consent-guard.sh"

    if [ ! -f "$hook" ]; then
        print_skip "consent-guard.sh not found"
        return
    fi

    # Test 3.1: Edit 以外のツールは SKIP
    echo '{"tool_name":"Read"}' | bash "$hook" > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        print_pass "Non-Edit tool returns exit 0 (SKIP)"
    else
        print_fail "Non-Edit tool should return exit 0"
    fi

    # Test 3.2: jq 不存在時の処理確認
    if grep -q 'command -v jq' "$hook"; then
        print_pass "jq existence check implemented"
    else
        print_fail "jq existence check not found"
    fi

    # Test 3.3: M082 契約準拠（SKIP/BLOCK/PASS 出力）
    if grep -qE '\[SKIP\]|\[BLOCK\]|\[PASS\]' "$hook"; then
        print_pass "M082 contract output format"
    else
        print_fail "M082 contract output format not found"
    fi
}

# ============================================================
# 4. archive-playbook.sh テスト
# ============================================================
test_archive_playbook() {
    print_header "4. archive-playbook.sh Tests"

    local hook="$HOOKS_DIR/archive-playbook.sh"

    if [ ! -f "$hook" ]; then
        print_skip "archive-playbook.sh not found"
        return
    fi

    # Test 4.1: 空入力で exit 0
    echo '{}' | bash "$hook" > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        print_pass "Empty input returns exit 0"
    else
        print_fail "Empty input should return exit 0"
    fi

    # Test 4.2: M082 契約準拠
    if grep -qE '\[SKIP\]|\[PASS\]|\[INFO\]' "$hook"; then
        print_pass "M082 contract output format"
    else
        print_fail "M082 contract output format not found"
    fi

    # Test 4.3: project.md 更新ロジックの存在
    if grep -q 'project.md' "$hook"; then
        print_pass "project.md update logic exists"
    else
        print_fail "project.md update logic not found"
    fi
}

# ============================================================
# 5. playbook-validator.sh テスト
# ============================================================
test_playbook_validator() {
    print_header "5. playbook-validator.sh Tests"

    local hook="$HOOKS_DIR/playbook-validator.sh"

    if [ ! -f "$hook" ]; then
        print_skip "playbook-validator.sh not found"
        return
    fi

    # Test 5.1: 引数なしで SKIP
    bash "$hook" > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        print_pass "No arguments returns exit 0 (SKIP)"
    else
        print_fail "No arguments should return exit 0"
    fi

    # Test 5.2: 存在しないファイルで SKIP
    bash "$hook" /nonexistent/file.md > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        print_pass "Nonexistent file returns exit 0 (SKIP)"
    else
        print_fail "Nonexistent file should return exit 0"
    fi

    # Test 5.3: Schema v2 検証ロジックの存在
    if grep -q 'schema_version' "$hook" || grep -q 'Schema' "$hook"; then
        print_pass "Schema v2 validation logic exists"
    else
        print_fail "Schema v2 validation logic not found"
    fi
}

# ============================================================
# 6. create-pr-hook.sh テスト
# ============================================================
test_create_pr_hook() {
    print_header "6. create-pr-hook.sh Tests"

    local hook="$HOOKS_DIR/create-pr-hook.sh"

    if [ ! -f "$hook" ]; then
        print_skip "create-pr-hook.sh not found"
        return
    fi

    # Test 6.1: gh コマンドチェックの存在
    if grep -q 'command -v gh' "$hook"; then
        print_pass "gh command check implemented"
    else
        print_fail "gh command check not found"
    fi

    # Test 6.2: M082 契約準拠
    if grep -qE '\[SKIP\]|\[WARN\]|\[PASS\]' "$hook"; then
        print_pass "M082 contract output format"
    else
        print_fail "M082 contract output format not found"
    fi

    # Test 6.3: main ブランチチェックの存在
    if grep -q 'main\|master' "$hook"; then
        print_pass "Main branch check exists"
    else
        print_fail "Main branch check not found"
    fi
}

# ============================================================
# メイン実行
# ============================================================
main() {
    echo ""
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║           Hook Test Suite - Local Execution                  ║${NC}"
    echo -e "${BLUE}║           M087: ローカル Hook テストスイート                 ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"

    # テスト実行
    test_syntax
    test_subtask_guard
    test_consent_guard
    test_archive_playbook
    test_playbook_validator
    test_create_pr_hook

    # サマリー
    print_header "Test Summary"
    echo -e "  ${GREEN}PASS: $PASS_COUNT${NC}"
    echo -e "  ${RED}FAIL: $FAIL_COUNT${NC}"
    echo ""

    if [ $FAIL_COUNT -eq 0 ]; then
        echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
        echo -e "${GREEN}  All tests passed!${NC}"
        echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
        exit 0
    else
        echo -e "${RED}════════════════════════════════════════════════════════════${NC}"
        echo -e "${RED}  Some tests failed. Please review the output above.${NC}"
        echo -e "${RED}════════════════════════════════════════════════════════════${NC}"
        exit 1
    fi
}

main "$@"
