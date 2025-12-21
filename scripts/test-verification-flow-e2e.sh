#!/bin/bash
# test-verification-flow-e2e.sh - 検証動線のE2Eテスト

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
    echo "[ERROR] jq is required for critic-guard simulation" >&2
    echo "SOME TESTS FAILED"
    exit 1
fi

TEMP_DIR=$(mktemp -d)
cleanup() {
    rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

STATE_BLOCK="${TEMP_DIR}/state-block.md"
cat > "$STATE_BLOCK" << 'EOF'
# state (self_complete=false)
self_complete: false
EOF

STATE_PASS="${TEMP_DIR}/state-pass.md"
cat > "$STATE_PASS" << 'EOF'
# state (self_complete=true)
self_complete: true
EOF

COMPLETION_PAYLOAD='{"tool_name":"Edit","tool_input":{"file_path":"state.md","new_string":"state: done"}}'

# critic SubAgent の存在確認
if [[ -f ".claude/agents/critic.md" ]]; then
    pass "V1: critic subagent exists"
else
    fail "V1: critic subagent definition not found"
fi

# /crit コマンドの存在確認
if [[ -f ".claude/commands/crit.md" ]]; then
    pass "V2: /crit command exists"
else
    fail "V2: /crit command file not found"
fi

# critic-guard.sh が self_complete=false でブロックすること
if echo "$COMPLETION_PAYLOAD" | STATE_FILE="$STATE_BLOCK" bash ".claude/hooks/critic-guard.sh" >/dev/null 2>&1; then
    fail "V3: critic-guard should block when self_complete is false"
else
    pass "V3: critic-guard blocks completion without self_complete"
fi

# self_complete=true なら完了変更を許可すること
if echo "$COMPLETION_PAYLOAD" | STATE_FILE="$STATE_PASS" bash ".claude/hooks/critic-guard.sh" >/dev/null 2>&1; then
    pass "V4: critic-guard allows completion when self_complete is true"
else
    fail "V4: critic-guard should allow when self_complete is true"
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
