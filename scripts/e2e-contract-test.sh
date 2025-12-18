#!/bin/bash
# e2e-contract-test.sh - Contract E2E Test Suite
#
# Usage:
#   bash scripts/e2e-contract-test.sh [scenario]
#
# Scenarios:
#   scenario_a  - playbook=null & non-admin: 全ての変更がブロックされる
#   scenario_b  - playbook=null & admin: Maintenance 操作のみ許可
#   scenario_c  - playbook=active: Golden Path が通る
#   session_end - セッション終了処理が完遂できる
#   all         - 全シナリオ実行

set -uo pipefail
# Note: Not using -e because we expect some commands to fail during testing

# 色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="${SCRIPT_DIR}/.."
CONTRACT_SCRIPT="${SCRIPT_DIR}/contract.sh"

# テスト用の一時 state.md を使用（実際の state.md を変更しない）
TEMP_DIR=$(mktemp -d)
STATE_FILE="${TEMP_DIR}/state.md"
export STATE_FILE

# クリーンアップ用 trap
cleanup() {
    rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

# テスト結果カウンタ
PASS_COUNT=0
FAIL_COUNT=0

# ==============================================================================
# ヘルパー関数
# ==============================================================================

log_test() {
    echo -e "${YELLOW}[TEST]${NC} $1"
}

log_pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
    ((PASS_COUNT++))
}

log_fail() {
    echo -e "${RED}[FAIL]${NC} $1"
    ((FAIL_COUNT++))
}

# テスト用 state.md を作成
create_test_state() {
    local playbook="$1"
    local security="$2"

    cat > "$STATE_FILE" << EOF
# state.md (test)

## playbook

\`\`\`yaml
active: $playbook
\`\`\`

## config

\`\`\`yaml
security: $security
\`\`\`
EOF
}

# contract.sh を読み込み
source "$CONTRACT_SCRIPT"

# ==============================================================================
# シナリオ A: playbook=null & non-admin
# ==============================================================================

scenario_a() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  シナリオ A: playbook=null & non-admin"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    create_test_state "null" "strict"

    # テスト A1: Hook ファイルの編集がブロックされる
    log_test "A1: Edit .claude/hooks/test.sh → BLOCK expected"
    if contract_check_edit ".claude/hooks/test.sh" 2>/dev/null; then
        log_fail "A1: Should have been blocked"
    else
        log_pass "A1: Correctly blocked"
    fi

    # テスト A2: コードファイルの編集がブロックされる
    log_test "A2: Edit src/index.ts → BLOCK expected"
    if contract_check_edit "src/index.ts" 2>/dev/null; then
        log_fail "A2: Should have been blocked"
    else
        log_pass "A2: Correctly blocked"
    fi

    # テスト A3: 変更系 Bash がブロックされる
    log_test "A3: Bash 'mkdir test' → BLOCK expected"
    if contract_check_bash "mkdir test" 2>/dev/null; then
        log_fail "A3: Should have been blocked"
    else
        log_pass "A3: Correctly blocked"
    fi

    # テスト A4: git add がブロックされる
    log_test "A4: Bash 'git add .' → BLOCK expected"
    if contract_check_bash "git add ." 2>/dev/null; then
        log_fail "A4: Should have been blocked"
    else
        log_pass "A4: Correctly blocked"
    fi

    # テスト A5: state.md は許可される（Bootstrap 例外）
    log_test "A5: Edit state.md → ALLOW expected"
    if contract_check_edit "state.md" 2>/dev/null; then
        log_pass "A5: Correctly allowed"
    else
        log_fail "A5: Should have been allowed"
    fi

    # テスト A6: playbook ファイルは許可される（Bootstrap 例外）
    log_test "A6: Edit plan/playbook-test.md → ALLOW expected"
    if contract_check_edit "plan/playbook-test.md" 2>/dev/null; then
        log_pass "A6: Correctly allowed"
    else
        log_fail "A6: Should have been allowed"
    fi
}

# ==============================================================================
# シナリオ B: playbook=null & admin (Maintenance)
# ==============================================================================

scenario_b() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  シナリオ B: playbook=null & admin"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    create_test_state "null" "admin"

    # テスト B1: state.md の編集は許可
    log_test "B1: Edit state.md → ALLOW expected"
    if contract_check_edit "state.md" 2>/dev/null; then
        log_pass "B1: Correctly allowed"
    else
        log_fail "B1: Should have been allowed"
    fi

    # テスト B2: playbook アーカイブは許可
    log_test "B2: Bash 'mv plan/playbook-x.md plan/archive/' → ALLOW expected"
    if contract_check_bash "mv plan/playbook-x.md plan/archive/" 2>/dev/null; then
        log_pass "B2: Correctly allowed"
    else
        log_fail "B2: Should have been allowed"
    fi

    # テスト B3: archive ディレクトリ作成は許可
    log_test "B3: Bash 'mkdir -p plan/archive' → ALLOW expected"
    if contract_check_bash "mkdir -p plan/archive" 2>/dev/null; then
        log_pass "B3: Correctly allowed"
    else
        log_fail "B3: Should have been allowed"
    fi

    # テスト B4: git add state.md は許可
    log_test "B4: Bash 'git add state.md' → ALLOW expected"
    if contract_check_bash "git add state.md" 2>/dev/null; then
        log_pass "B4: Correctly allowed"
    else
        log_fail "B4: Should have been allowed"
    fi

    # テスト B5: コードファイルの編集はブロック（admin でも）
    log_test "B5: Edit src/index.ts → BLOCK expected (even admin)"
    if contract_check_edit "src/index.ts" 2>/dev/null; then
        log_fail "B5: Should have been blocked even in admin"
    else
        log_pass "B5: Correctly blocked"
    fi

    # テスト B6: HARD_BLOCK ファイルはブロック（admin でも）
    log_test "B6: Edit CLAUDE.md → BLOCK expected (HARD_BLOCK)"
    if contract_check_edit "CLAUDE.md" 2>/dev/null; then
        log_fail "B6: HARD_BLOCK should not be bypassed"
    else
        log_pass "B6: Correctly blocked (HARD_BLOCK)"
    fi
}

# ==============================================================================
# シナリオ C: playbook=active
# ==============================================================================

scenario_c() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  シナリオ C: playbook=active"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    create_test_state "plan/playbook-test.md" "strict"

    # テスト C1: コードファイルの編集は許可
    log_test "C1: Edit src/index.ts → ALLOW expected"
    if contract_check_edit "src/index.ts" 2>/dev/null; then
        log_pass "C1: Correctly allowed"
    else
        log_fail "C1: Should have been allowed with active playbook"
    fi

    # テスト C2: Hook ファイルの編集は許可（playbook あり）
    log_test "C2: Edit .claude/hooks/test.sh → ALLOW expected"
    if contract_check_edit ".claude/hooks/test.sh" 2>/dev/null; then
        log_pass "C2: Correctly allowed"
    else
        log_fail "C2: Should have been allowed with active playbook"
    fi

    # テスト C3: 変更系 Bash は許可
    log_test "C3: Bash 'mkdir test' → ALLOW expected"
    if contract_check_bash "mkdir test" 2>/dev/null; then
        log_pass "C3: Correctly allowed"
    else
        log_fail "C3: Should have been allowed with active playbook"
    fi

    # テスト C4: git add は許可
    log_test "C4: Bash 'git add .' → ALLOW expected"
    if contract_check_bash "git add ." 2>/dev/null; then
        log_pass "C4: Correctly allowed"
    else
        log_fail "C4: Should have been allowed with active playbook"
    fi

    # テスト C5: HARD_BLOCK は playbook があってもブロック
    log_test "C5: Edit CLAUDE.md → BLOCK expected (HARD_BLOCK)"
    if contract_check_edit "CLAUDE.md" 2>/dev/null; then
        log_fail "C5: HARD_BLOCK should always block"
    else
        log_pass "C5: Correctly blocked (HARD_BLOCK)"
    fi
}

# ==============================================================================
# シナリオ: セッション終了処理
# ==============================================================================

session_end() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  シナリオ: セッション終了処理"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    create_test_state "null" "admin"

    # セッション終了の全ステップをシミュレート
    log_test "Session End Step 1: mkdir -p plan/archive"
    if contract_check_bash "mkdir -p plan/archive" 2>/dev/null; then
        log_pass "Step 1: archive directory creation"
    else
        log_fail "Step 1: Should allow mkdir plan/archive"
    fi

    log_test "Session End Step 2: mv plan/playbook-x.md plan/archive/"
    if contract_check_bash "mv plan/playbook-x.md plan/archive/" 2>/dev/null; then
        log_pass "Step 2: playbook archive"
    else
        log_fail "Step 2: Should allow playbook archive"
    fi

    log_test "Session End Step 3: Edit state.md (playbook=null)"
    if contract_check_edit "state.md" 2>/dev/null; then
        log_pass "Step 3: state.md update"
    else
        log_fail "Step 3: Should allow state.md edit"
    fi

    log_test "Session End Step 4: git add state.md plan/archive/"
    if contract_check_bash "git add state.md plan/archive/" 2>/dev/null; then
        log_pass "Step 4: git add maintenance files"
    else
        log_fail "Step 4: Should allow git add for maintenance"
    fi

    log_test "Session End Step 5: git commit"
    if contract_check_bash "git commit -m 'chore: session end'" 2>/dev/null; then
        log_pass "Step 5: git commit"
    else
        log_fail "Step 5: Should allow git commit for maintenance"
    fi
}

# ==============================================================================
# 全シナリオ実行
# ==============================================================================

run_all() {
    scenario_a
    scenario_b
    scenario_c
    session_end
}

# ==============================================================================
# メイン
# ==============================================================================

print_summary() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  テスト結果サマリー"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo -e "  ${GREEN}PASS${NC}: $PASS_COUNT"
    echo -e "  ${RED}FAIL${NC}: $FAIL_COUNT"
    echo ""

    if [[ $FAIL_COUNT -eq 0 ]]; then
        echo -e "  ${GREEN}ALL TESTS PASSED${NC}"
        return 0
    else
        echo -e "  ${RED}SOME TESTS FAILED${NC}"
        return 1
    fi
}

main() {
    local scenario="${1:-all}"

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  E2E Contract Test Suite"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    case "$scenario" in
        scenario_a) scenario_a ;;
        scenario_b) scenario_b ;;
        scenario_c) scenario_c ;;
        session_end) session_end ;;
        all) run_all ;;
        *)
            echo "Unknown scenario: $scenario"
            echo "Usage: $0 [scenario_a|scenario_b|scenario_c|session_end|all]"
            exit 1
            ;;
    esac

    print_summary
}

main "$@"
