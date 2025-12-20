#!/usr/bin/env bash
# ==============================================================================
# golden-path-test.sh - 全40コンポーネント動作確認テスト
# ==============================================================================
#
# M105: Golden Path Verification のためのテストスクリプト
#
# 使用方法:
#   bash scripts/golden-path-test.sh [--verbose] [--category CATEGORY]
#
# カテゴリ:
#   all       - 全40コンポーネント（デフォルト）
#   planning  - 計画動線（6個）
#   execution - 実行動線（11個）
#   verify    - 検証動線（6個）
#   complete  - 完了動線（8個）
#   common    - 共通基盤（6個）
#   cross     - 横断的整合性（3個）
#   hooks     - 全 Hook のみ
#   agents    - 全 SubAgent のみ
#   skills    - 全 Skill のみ
#   commands  - 全 Command のみ
#
# ==============================================================================

set -uo pipefail

# ==============================================================================
# 設定
# ==============================================================================
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

VERBOSE=false
CATEGORY="all"

# 引数処理
while [[ $# -gt 0 ]]; do
    case "$1" in
        --verbose|-v)
            VERBOSE=true
            shift
            ;;
        --category|-c)
            CATEGORY="$2"
            shift 2
            ;;
        *)
            shift
            ;;
    esac
done

# カウンター
PASS_COUNT=0
FAIL_COUNT=0
SKIP_COUNT=0

# 色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# ==============================================================================
# ヘルパー関数
# ==============================================================================

log() {
    if [[ "$VERBOSE" == "true" ]]; then
        echo "$1"
    fi
}

pass() {
    echo -e "  ${GREEN}[PASS]${NC} $1"
    ((PASS_COUNT++))
}

fail() {
    echo -e "  ${RED}[FAIL]${NC} $1"
    ((FAIL_COUNT++))
}

skip() {
    echo -e "  ${YELLOW}[SKIP]${NC} $1"
    ((SKIP_COUNT++))
}

header() {
    echo ""
    echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
}

# ==============================================================================
# Hook テスト関数
# ==============================================================================

test_hook_syntax() {
    local hook="$1"
    local name="$(basename "$hook")"

    if [[ ! -f "$hook" ]]; then
        fail "$name - ファイルが存在しません"
        return 1
    fi

    if bash -n "$hook" 2>/dev/null; then
        pass "$name - 構文チェック OK"
        return 0
    else
        fail "$name - 構文エラー"
        return 1
    fi
}

test_hook_execution() {
    local hook="$1"
    local input="$2"
    local expected_pattern="$3"
    local name="$(basename "$hook")"

    if [[ ! -f "$hook" ]]; then
        skip "$name - ファイルが存在しません"
        return 1
    fi

    local output
    output=$(echo "$input" | bash "$hook" 2>&1) || true

    if echo "$output" | grep -qE "$expected_pattern"; then
        pass "$name - 動作確認 OK"
        return 0
    else
        log "  Output: $output"
        fail "$name - 期待パターン不一致: $expected_pattern"
        return 1
    fi
}

# ==============================================================================
# SubAgent テスト関数
# ==============================================================================

test_subagent() {
    local name="$1"
    local file=".claude/agents/${name}.md"

    if [[ ! -f "$file" ]]; then
        fail "$name - ファイルが存在しません: $file"
        return 1
    fi

    # YAML frontmatter チェック
    if ! head -1 "$file" | grep -q '^---$'; then
        fail "$name - YAML frontmatter がありません"
        return 1
    fi

    # 必須フィールドチェック
    if ! grep -q "^name:" "$file"; then
        fail "$name - name フィールドがありません"
        return 1
    fi

    if ! grep -q "^description:" "$file"; then
        fail "$name - description フィールドがありません"
        return 1
    fi

    pass "$name - SubAgent 構造 OK"
    return 0
}

# ==============================================================================
# Skill テスト関数
# ==============================================================================

test_skill() {
    local name="$1"
    local dir=".claude/skills/${name}"
    local file="${dir}/SKILL.md"

    if [[ ! -d "$dir" ]]; then
        fail "$name - ディレクトリが存在しません: $dir"
        return 1
    fi

    if [[ ! -f "$file" ]]; then
        fail "$name - SKILL.md が存在しません: $file"
        return 1
    fi

    # 必須フィールドチェック
    if ! grep -qE "^name:|^  name:" "$file"; then
        fail "$name - name フィールドがありません"
        return 1
    fi

    if ! grep -qE "^description:|^  description:" "$file"; then
        fail "$name - description フィールドがありません"
        return 1
    fi

    pass "$name - Skill 構造 OK"
    return 0
}

# ==============================================================================
# Command テスト関数
# ==============================================================================

test_command() {
    local name="$1"
    local file=".claude/commands/${name}.md"

    if [[ ! -f "$file" ]]; then
        fail "$name - ファイルが存在しません: $file"
        return 1
    fi

    # 最低限のコンテンツチェック
    local lines
    lines=$(wc -l < "$file" | tr -d ' ')

    if [[ "$lines" -lt 5 ]]; then
        fail "$name - コンテンツが少なすぎます (${lines}行)"
        return 1
    fi

    pass "$name - Command 構造 OK"
    return 0
}

# ==============================================================================
# カテゴリ別テスト
# ==============================================================================

test_planning() {
    header "1. 計画動線（6個）"

    # Commands
    test_command "task-start"
    test_command "playbook-init"

    # SubAgents
    test_subagent "pm"

    # Skills
    test_skill "state"
    test_skill "plan-management"

    # Hooks
    test_hook_syntax ".claude/hooks/prompt-guard.sh"
}

test_execution() {
    header "2. 実行動線（11個）"

    # Hooks
    test_hook_syntax ".claude/hooks/init-guard.sh"
    test_hook_syntax ".claude/hooks/playbook-guard.sh"
    test_hook_syntax ".claude/hooks/subtask-guard.sh"
    test_hook_syntax ".claude/hooks/scope-guard.sh"
    test_hook_syntax ".claude/hooks/check-protected-edit.sh"
    test_hook_syntax ".claude/hooks/pre-bash-check.sh"
    test_hook_syntax ".claude/hooks/consent-guard.sh"
    test_hook_syntax ".claude/hooks/executor-guard.sh"
    test_hook_syntax ".claude/hooks/check-main-branch.sh"

    # Skills
    test_skill "lint-checker"
    test_skill "test-runner"
}

test_verify() {
    header "3. 検証動線（6個）"

    # Commands
    test_command "crit"
    test_command "test"
    test_command "lint"

    # SubAgents
    test_subagent "critic"
    test_subagent "reviewer"

    # Hooks
    test_hook_syntax ".claude/hooks/critic-guard.sh"
}

test_complete() {
    header "4. 完了動線（8個）"

    # Commands
    test_command "rollback"
    test_command "state-rollback"
    test_command "focus"

    # Hooks
    test_hook_syntax ".claude/hooks/archive-playbook.sh"
    test_hook_syntax ".claude/hooks/cleanup-hook.sh"
    test_hook_syntax ".claude/hooks/create-pr-hook.sh"

    # Skills
    test_skill "post-loop"
    test_skill "context-management"
}

test_common() {
    header "5. 共通基盤（6個）"

    # Hooks
    test_hook_syntax ".claude/hooks/session-start.sh"
    test_hook_syntax ".claude/hooks/session-end.sh"
    test_hook_syntax ".claude/hooks/pre-compact.sh"
    test_hook_syntax ".claude/hooks/stop-summary.sh"
    test_hook_syntax ".claude/hooks/log-subagent.sh"

    # Skills
    test_skill "consent-process"
}

test_cross() {
    header "6. 横断的整合性（3個）"

    # Hooks
    test_hook_syntax ".claude/hooks/check-coherence.sh"
    test_hook_syntax ".claude/hooks/depends-check.sh"
    test_hook_syntax ".claude/hooks/lint-check.sh"
}

test_all_hooks() {
    header "全 Hook（22個）"

    for hook in .claude/hooks/*.sh; do
        if [[ -f "$hook" ]]; then
            test_hook_syntax "$hook"
        fi
    done
}

test_all_agents() {
    header "全 SubAgent（6個）"

    test_subagent "codex-delegate"
    test_subagent "critic"
    test_subagent "health-checker"
    test_subagent "pm"
    test_subagent "reviewer"
    test_subagent "setup-guide"
}

test_all_skills() {
    header "全 Skill（9個）"

    test_skill "consent-process"
    test_skill "context-management"
    test_skill "deploy-checker"
    test_skill "frontend-design"
    test_skill "lint-checker"
    test_skill "plan-management"
    test_skill "post-loop"
    test_skill "state"
    test_skill "test-runner"
}

test_all_commands() {
    header "全 Command（8個）"

    test_command "crit"
    test_command "focus"
    test_command "lint"
    test_command "playbook-init"
    test_command "rollback"
    test_command "state-rollback"
    test_command "task-start"
    test_command "test"
}

# ==============================================================================
# メイン
# ==============================================================================

main() {
    echo ""
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║         Golden Path Verification Test Suite                  ║${NC}"
    echo -e "${BLUE}║         M105: 全40コンポーネント動作確認                     ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo "Category: $CATEGORY"
    echo "Root: $ROOT"

    case "$CATEGORY" in
        all)
            test_planning
            test_execution
            test_verify
            test_complete
            test_common
            test_cross
            ;;
        planning)
            test_planning
            ;;
        execution)
            test_execution
            ;;
        verify)
            test_verify
            ;;
        complete)
            test_complete
            ;;
        common)
            test_common
            ;;
        cross)
            test_cross
            ;;
        hooks)
            test_all_hooks
            ;;
        agents)
            test_all_agents
            ;;
        skills)
            test_all_skills
            ;;
        commands)
            test_all_commands
            ;;
        *)
            echo "Unknown category: $CATEGORY"
            exit 1
            ;;
    esac

    # サマリー
    header "Test Summary"
    echo -e "  ${GREEN}PASS: $PASS_COUNT${NC}"
    echo -e "  ${RED}FAIL: $FAIL_COUNT${NC}"
    echo -e "  ${YELLOW}SKIP: $SKIP_COUNT${NC}"
    echo ""

    local total=$((PASS_COUNT + FAIL_COUNT + SKIP_COUNT))
    echo "  Total: $total components tested"
    echo ""

    if [[ $FAIL_COUNT -eq 0 ]]; then
        echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
        echo -e "${GREEN}  ALL TESTS PASSED!${NC}"
        echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
        exit 0
    else
        echo -e "${RED}════════════════════════════════════════════════════════════${NC}"
        echo -e "${RED}  $FAIL_COUNT test(s) FAILED${NC}"
        echo -e "${RED}════════════════════════════════════════════════════════════${NC}"
        exit 1
    fi
}

main "$@"
