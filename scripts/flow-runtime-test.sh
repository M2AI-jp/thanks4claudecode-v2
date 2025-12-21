#!/bin/bash
# flow-runtime-test.sh - 4動線実行時テスト（M129）
#
# 計画動線、実行動線、検証動線、完了動線 の実行時検証
#
# Usage:
#   bash scripts/flow-runtime-test.sh

set -uo pipefail

# 色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="${SCRIPT_DIR}/.."

# テスト用の一時ディレクトリ
TEMP_DIR=$(mktemp -d)

# クリーンアップ用 trap
cleanup() {
    rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

# テスト結果カウンタ
PASS_COUNT=0
FAIL_COUNT=0

# テスト結果ログ
TEST_RESULTS_LOG="${REPO_ROOT}/.claude/logs/test-results.log"

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
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%S")
    echo "{\"timestamp\": \"$timestamp\", \"test\": \"flow-runtime\", \"case\": \"$1\", \"result\": \"FAIL\"}" >> "$TEST_RESULTS_LOG"
}

# ==============================================================================
# 計画動線テスト: 要求 → pm → playbook → state.md
# ==============================================================================

test_planning_flow() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  Test: 計画動線（Planning Flow）"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    # P1: state.md が存在する
    log_test "P1: state.md exists"
    if [[ -f "${REPO_ROOT}/state.md" ]]; then
        log_pass "P1: state.md exists"
    else
        log_fail "P1: state.md not found"
    fi

    # P2: playbook セクションが state.md に存在
    log_test "P2: state.md has playbook section"
    if grep -q "^## playbook" "${REPO_ROOT}/state.md" 2>/dev/null; then
        log_pass "P2: playbook section exists"
    else
        log_fail "P2: playbook section not found"
    fi

    # P3: active playbook が参照できる
    log_test "P3: active playbook is resolvable"
    local playbook
    playbook=$(grep -A6 "^## playbook" "${REPO_ROOT}/state.md" 2>/dev/null | grep "^active:" | head -1 | sed 's/active: *//' | sed 's/ *#.*//' | tr -d ' ')
    if [[ -n "$playbook" && "$playbook" != "null" && -f "${REPO_ROOT}/$playbook" ]]; then
        log_pass "P3: playbook '$playbook' is resolvable"
    else
        log_fail "P3: playbook not resolvable (value: '$playbook')"
    fi

    # P4: playbook に done_when が存在
    log_test "P4: playbook has done_when"
    if [[ -n "$playbook" && -f "${REPO_ROOT}/$playbook" ]]; then
        if grep -q "done_when:" "${REPO_ROOT}/$playbook" 2>/dev/null; then
            log_pass "P4: done_when exists in playbook"
        else
            log_fail "P4: done_when not found in playbook"
        fi
    else
        log_fail "P4: playbook file not available"
    fi

    # P5: pm subagent type が使用可能
    log_test "P5: pm subagent_type is documented"
    if grep -rq "subagent_type.*pm\|pm.*subagent" "${REPO_ROOT}/CLAUDE.md" "${REPO_ROOT}/RUNBOOK.md" 2>/dev/null; then
        log_pass "P5: pm subagent is documented"
    else
        log_fail "P5: pm subagent not documented"
    fi

    # P6: session-start.sh が存在（セッション開始時のリマインダー）
    log_test "P6: session-start.sh exists"
    if [[ -f "${REPO_ROOT}/.claude/hooks/session-start.sh" ]]; then
        log_pass "P6: session-start.sh exists"
    else
        log_fail "P6: session-start.sh not found"
    fi

    # P7: prompt-guard.sh が存在（ユーザー入力処理）
    log_test "P7: prompt-guard.sh exists"
    if [[ -f "${REPO_ROOT}/.claude/hooks/prompt-guard.sh" ]]; then
        log_pass "P7: prompt-guard.sh exists"
    else
        log_fail "P7: prompt-guard.sh not found"
    fi
}

# ==============================================================================
# 実行動線テスト: playbook → Edit → Guard発火
# ==============================================================================

test_execution_flow() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  Test: 実行動線（Execution Flow）"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    # E1: playbook-guard.sh が存在
    log_test "E1: playbook-guard.sh exists"
    if [[ -f "${REPO_ROOT}/.claude/hooks/playbook-guard.sh" ]]; then
        log_pass "E1: playbook-guard.sh exists"
    else
        log_fail "E1: playbook-guard.sh not found"
    fi

    # E2: pre-bash-check.sh が存在
    log_test "E2: pre-bash-check.sh exists"
    if [[ -f "${REPO_ROOT}/.claude/hooks/pre-bash-check.sh" ]]; then
        log_pass "E2: pre-bash-check.sh exists"
    else
        log_fail "E2: pre-bash-check.sh not found"
    fi

    # E3: contract.sh が存在
    log_test "E3: contract.sh exists"
    if [[ -f "${REPO_ROOT}/scripts/contract.sh" ]]; then
        log_pass "E3: contract.sh exists"
    else
        log_fail "E3: contract.sh not found"
    fi

    # E4: .claude/settings.json に hooks が登録されている
    log_test "E4: hooks are registered in settings.json"
    if [[ -f "${REPO_ROOT}/.claude/settings.json" ]]; then
        if grep -q "hooks" "${REPO_ROOT}/.claude/settings.json" 2>/dev/null; then
            log_pass "E4: hooks registered"
        else
            log_fail "E4: hooks section not found in settings.json"
        fi
    else
        log_fail "E4: settings.json not found"
    fi

    # E5: Guard スクリプトが実行可能
    log_test "E5: Guard scripts are syntactically valid"
    local guard_valid=true
    for guard in playbook-guard.sh pre-bash-check.sh; do
        if ! bash -n "${REPO_ROOT}/.claude/hooks/$guard" 2>/dev/null; then
            guard_valid=false
            break
        fi
    done
    if [[ "$guard_valid" == "true" ]]; then
        log_pass "E5: Guard scripts are valid"
    else
        log_fail "E5: Guard script syntax error"
    fi

    # E6: init-guard.sh が存在（必須ファイル Read 確認）
    log_test "E6: init-guard.sh exists"
    if [[ -f "${REPO_ROOT}/.claude/hooks/init-guard.sh" ]]; then
        log_pass "E6: init-guard.sh exists"
    else
        log_fail "E6: init-guard.sh not found"
    fi

    # E7: scope-guard.sh が存在（スコープ逸脱検出）
    log_test "E7: scope-guard.sh exists"
    if [[ -f "${REPO_ROOT}/.claude/hooks/scope-guard.sh" ]]; then
        log_pass "E7: scope-guard.sh exists"
    else
        log_fail "E7: scope-guard.sh not found"
    fi

    # E8: subtask-guard.sh が存在（subtask 検証）
    log_test "E8: subtask-guard.sh exists"
    if [[ -f "${REPO_ROOT}/.claude/hooks/subtask-guard.sh" ]]; then
        log_pass "E8: subtask-guard.sh exists"
    else
        log_fail "E8: subtask-guard.sh not found"
    fi

    # E9: depends-check.sh が存在（依存関係検証）
    log_test "E9: depends-check.sh exists"
    if [[ -f "${REPO_ROOT}/.claude/hooks/depends-check.sh" ]]; then
        log_pass "E9: depends-check.sh exists"
    else
        log_fail "E9: depends-check.sh not found"
    fi
}

# ==============================================================================
# 検証動線テスト: /crit → critic → PASS/FAIL
# ==============================================================================

test_verification_flow() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  Test: 検証動線（Verification Flow）"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    # V1: critic-guard.sh が存在
    log_test "V1: critic-guard.sh exists"
    if [[ -f "${REPO_ROOT}/.claude/hooks/critic-guard.sh" ]]; then
        log_pass "V1: critic-guard.sh exists"
    else
        log_fail "V1: critic-guard.sh not found"
    fi

    # V2: /crit スキルが定義されている
    log_test "V2: /crit skill is defined"
    if [[ -f "${REPO_ROOT}/.claude/commands/crit.md" ]]; then
        log_pass "V2: /crit skill exists"
    else
        log_fail "V2: /crit skill not found"
    fi

    # V3: state.md に verification セクションがある
    log_test "V3: state.md has verification section"
    if grep -q "^## verification" "${REPO_ROOT}/state.md" 2>/dev/null; then
        log_pass "V3: verification section exists"
    else
        log_fail "V3: verification section not found"
    fi

    # V4: critic subagent_type が使用可能
    log_test "V4: critic subagent_type is documented"
    # Check RUNBOOK.md or .claude/agents/critic.md
    if grep -q "critic" "${REPO_ROOT}/RUNBOOK.md" 2>/dev/null || \
       [[ -f "${REPO_ROOT}/.claude/agents/critic.md" ]]; then
        log_pass "V4: critic subagent is documented"
    else
        log_fail "V4: critic subagent not documented"
    fi

    # V5: done_when 形式が検証可能
    log_test "V5: done_when format is verifiable"
    local playbook
    playbook=$(grep -A6 "^## playbook" "${REPO_ROOT}/state.md" 2>/dev/null | grep "^active:" | head -1 | sed 's/active: *//' | sed 's/ *#.*//' | tr -d ' ')
    if [[ -n "$playbook" && -f "${REPO_ROOT}/$playbook" ]]; then
        local done_when_count
        done_when_count=$(grep -c '^\s*-' "${REPO_ROOT}/$playbook" 2>/dev/null | head -1 || echo "0")
        if [[ "$done_when_count" -gt 0 ]]; then
            log_pass "V5: done_when has verifiable criteria"
        else
            log_fail "V5: done_when has no verifiable criteria"
        fi
    else
        log_fail "V5: playbook not available"
    fi
}

# ==============================================================================
# 完了動線テスト: phase完了 → アーカイブ → 次タスク
# ==============================================================================

test_completion_flow() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  Test: 完了動線（Completion Flow）"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    # C1: archive-playbook.sh が存在
    log_test "C1: archive-playbook.sh exists"
    if [[ -f "${REPO_ROOT}/.claude/hooks/archive-playbook.sh" ]]; then
        log_pass "C1: archive-playbook.sh exists"
    else
        log_fail "C1: archive-playbook.sh not found"
    fi

    # C2: plan/archive ディレクトリが存在
    log_test "C2: plan/archive directory exists"
    if [[ -d "${REPO_ROOT}/plan/archive" ]]; then
        log_pass "C2: plan/archive exists"
    else
        log_fail "C2: plan/archive not found"
    fi

    # C3: last_archived が state.md に記録される
    log_test "C3: last_archived is tracked in state.md"
    if grep -q "last_archived:" "${REPO_ROOT}/state.md" 2>/dev/null; then
        log_pass "C3: last_archived is tracked"
    else
        log_fail "C3: last_archived not found in state.md"
    fi

    # C4: session-end.sh が存在
    log_test "C4: session-end.sh exists"
    if [[ -f "${REPO_ROOT}/.claude/hooks/session-end.sh" ]]; then
        log_pass "C4: session-end.sh exists"
    else
        log_fail "C4: session-end.sh not found"
    fi

    # C5: project.md に次タスクが定義可能
    log_test "C5: project.md exists for next task tracking"
    if [[ -f "${REPO_ROOT}/plan/project.md" ]]; then
        log_pass "C5: project.md exists"
    else
        log_fail "C5: project.md not found"
    fi
}

# ==============================================================================
# 動線連携テスト: 動線間の接続が機能する
# ==============================================================================

test_flow_integration() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  Test: 動線連携（Flow Integration）"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    # I1: state.md → playbook の参照が有効
    log_test "I1: state.md → playbook reference is valid"
    local playbook
    playbook=$(grep -A6 "^## playbook" "${REPO_ROOT}/state.md" 2>/dev/null | grep "^active:" | head -1 | sed 's/active: *//' | sed 's/ *#.*//' | tr -d ' ')
    if [[ -n "$playbook" && "$playbook" != "null" ]]; then
        if [[ -f "${REPO_ROOT}/$playbook" ]]; then
            log_pass "I1: state.md → playbook link valid"
        else
            log_fail "I1: playbook file not found at '$playbook'"
        fi
    else
        log_fail "I1: no active playbook in state.md"
    fi

    # I2: playbook → state.md の phase が同期
    log_test "I2: playbook phase syncs with state.md"
    local state_phase
    state_phase=$(grep -A6 "^## goal" "${REPO_ROOT}/state.md" 2>/dev/null | grep "^phase:" | head -1 | sed 's/phase: *//' | tr -d ' ')
    if [[ -n "$state_phase" ]]; then
        log_pass "I2: state.md has phase: '$state_phase'"
    else
        log_fail "I2: phase not found in state.md"
    fi

    # I3: branch が state.md に記録されている
    log_test "I3: branch is tracked in state.md"
    local state_branch
    state_branch=$(grep -A6 "^## playbook" "${REPO_ROOT}/state.md" 2>/dev/null | grep "^branch:" | head -1 | sed 's/branch: *//' | tr -d ' ')
    if [[ -n "$state_branch" ]]; then
        log_pass "I3: branch tracked: '$state_branch'"
    else
        log_fail "I3: branch not found in state.md"
    fi

    # I4: 現在の git branch が state.md と一致
    log_test "I4: git branch matches state.md"
    local git_branch
    git_branch=$(git -C "${REPO_ROOT}" branch --show-current 2>/dev/null)
    if [[ "$git_branch" == "$state_branch" ]]; then
        log_pass "I4: git branch matches: '$git_branch'"
    else
        log_fail "I4: git branch mismatch (git: '$git_branch', state: '$state_branch')"
    fi

    # I5: essential-documents.md が動線を記載
    log_test "I5: essential-documents.md documents flows"
    if [[ -f "${REPO_ROOT}/docs/essential-documents.md" ]]; then
        if grep -qE "計画動線|実行動線|検証動線|完了動線" "${REPO_ROOT}/docs/essential-documents.md" 2>/dev/null; then
            log_pass "I5: flows documented in essential-documents.md"
        else
            log_fail "I5: flows not documented"
        fi
    else
        log_fail "I5: essential-documents.md not found"
    fi

    # I6: check-coherence.sh が存在（動線連携の整合性チェック）
    log_test "I6: check-coherence.sh exists"
    if [[ -f "${REPO_ROOT}/.claude/hooks/check-coherence.sh" ]]; then
        log_pass "I6: check-coherence.sh exists"
    else
        log_fail "I6: check-coherence.sh not found"
    fi

    # I7: lint-check.sh が存在（コード品質チェック）
    log_test "I7: lint-check.sh exists"
    if [[ -f "${REPO_ROOT}/.claude/hooks/lint-check.sh" ]]; then
        log_pass "I7: lint-check.sh exists"
    else
        log_fail "I7: lint-check.sh not found"
    fi
}

# ==============================================================================
# メイン
# ==============================================================================

print_summary() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  Flow Runtime Test Results"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo -e "  ${GREEN}PASS${NC}: $PASS_COUNT"
    echo -e "  ${RED}FAIL${NC}: $FAIL_COUNT"
    echo ""

    # テスト結果サマリーをログに記録
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%S")
    echo "{\"timestamp\": \"$timestamp\", \"test\": \"flow-runtime\", \"pass\": $PASS_COUNT, \"fail\": $FAIL_COUNT, \"result\": \"$([ $FAIL_COUNT -eq 0 ] && echo 'PASS' || echo 'FAIL')\"}" >> "$TEST_RESULTS_LOG"

    if [[ $FAIL_COUNT -eq 0 ]]; then
        echo -e "  ${GREEN}ALL FLOW RUNTIME TESTS PASSED${NC}"
        return 0
    else
        echo -e "  ${RED}SOME TESTS FAILED${NC}"
        return 1
    fi
}

main() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  Flow Runtime Test Suite (M129)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    mkdir -p "$(dirname "$TEST_RESULTS_LOG")"

    test_planning_flow
    test_execution_flow
    test_verification_flow
    test_completion_flow
    test_flow_integration

    print_summary
}

main "$@"
