#!/bin/bash
# test-execution-flow-e2e.sh - 実行動線のE2Eテスト

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="${SCRIPT_DIR}/.."
cd "$REPO_ROOT"

PASS_COUNT=0
FAIL_COUNT=0

pass() {
    echo "[PASS] $1"
    ((PASS_COUNT++))
}

fail() {
    echo "[FAIL] $1"
    ((FAIL_COUNT++))
}

if ! command -v jq >/dev/null 2>&1; then
    echo "[ERROR] jq is required for hook execution tests" >&2
    echo "SOME TESTS FAILED"
    exit 1
fi

TEMP_DIR=$(mktemp -d)
cleanup() {
    rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

ACTIVE_PLAYBOOK="${TEMP_DIR}/playbook-active.md"
cat > "$ACTIVE_PLAYBOOK" << 'EOF'
reviewed: true
EOF

STATE_ACTIVE="${TEMP_DIR}/state-active.md"
cat > "$STATE_ACTIVE" << EOF
# state (active playbook)

## focus
current: plan-template

## playbook
active: $ACTIVE_PLAYBOOK
branch: feat/execution-e2e

## config
security: strict
EOF

STATE_NULL="${TEMP_DIR}/state-null.md"
cat > "$STATE_NULL" << 'EOF'
# state (playbook=null)

## focus
current: plan-template

## playbook
active: null
branch: main

## config
security: strict
EOF

make_edit_payload() {
    local path="$1"
    echo "{\"tool_name\":\"Edit\",\"tool_input\":{\"file_path\":\"$path\"}}"
}

make_bash_payload() {
    local command="$1"
    echo "{\"tool_name\":\"Bash\",\"tool_input\":{\"command\":\"$command\"}}"
}

# シナリオ1: playbook=active で Edit 許可
payload=$(make_edit_payload "tmp/e2e.txt")
if echo "$payload" | STATE_FILE="$STATE_ACTIVE" bash ".claude/hooks/playbook-guard.sh" >/dev/null 2>&1; then
    pass "E1: playbook=active allows Edit (Hook exit 0)"
else
    fail "E1: playbook=active should allow Edit"
fi

# シナリオ2: playbook=null で Edit ブロック
if echo "$payload" | STATE_FILE="$STATE_NULL" bash ".claude/hooks/playbook-guard.sh" >/dev/null 2>&1; then
    fail "E2: playbook=null should block Edit (expected exit 2)"
else
    pass "E2: playbook=null correctly blocked Edit"
fi

# シナリオ3: 保護ファイルへの Edit がブロックされるか
protected_payload=$(make_edit_payload "CLAUDE.md")
if echo "$protected_payload" | STATE_FILE="$STATE_ACTIVE" bash ".claude/hooks/check-protected-edit.sh" >/dev/null 2>&1; then
    fail "E3: Protected file edit should be blocked by check-protected-edit.sh"
else
    pass "E3: Protected file edit blocked as expected"
fi

# シナリオ4: rm -rf がブロックされるか
bash_payload=$(make_bash_payload "rm -rf /")
if echo "$bash_payload" | STATE_FILE="$STATE_ACTIVE" bash ".claude/hooks/pre-bash-check.sh" >/dev/null 2>&1; then
    fail "E4: Dangerous rm -rf should be blocked by pre-bash-check.sh"
else
    pass "E4: Dangerous rm -rf blocked (exit != 0)"
fi

echo ""
echo "PASS: $PASS_COUNT"
echo "FAIL: $FAIL_COUNT"
if [[ $FAIL_COUNT -eq 0 ]]; then
    echo "ALL TESTS PASS"
    exit 0
else
    echo "SOME TESTS FAILED"
    exit 1
fi
