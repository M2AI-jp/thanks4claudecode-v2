#!/bin/bash
# test-planning-flow-e2e.sh - 計画動線のE2Eテスト（シナリオ1中心）

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

require_file() {
    local path="$1"
    local label="$2"
    if [[ ! -f "$path" ]]; then
        fail "$label not found at $path"
        return 1
    fi
    return 0
}

if ! command -v jq >/dev/null 2>&1; then
    echo "[ERROR] jq is required for hook simulation" >&2
    echo "SOME TESTS FAILED"
    exit 1
fi

TEMP_DIR=$(mktemp -d)
cleanup() {
    rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

state_file="state.md"
require_file "$state_file" "state.md"

# シナリオ1: playbook=null から作成までの流れをシミュレート（ガード発火確認）
simulate_null_state="$TEMP_DIR/state-null.md"
cat > "$simulate_null_state" << 'EOF'
# state (simulated)

## focus

```yaml
current: plan-template
```

## playbook

```yaml
active: null
branch: main
```
EOF

edit_payload='{"tool_name":"Edit","tool_input":{"file_path":"tmp/dummy.txt"}}'
if echo "$edit_payload" | STATE_FILE="$simulate_null_state" bash ".claude/hooks/playbook-guard.sh" >/dev/null 2>&1; then
    fail "P1: playbook=null should block Edit and prompt pm creation"
else
    pass "P1: playbook=null correctly blocked (planning gate triggered)"
fi

# playbook.active と実体を確認
ACTIVE_PLAYBOOK=$(grep -A6 "^## playbook" "$state_file" 2>/dev/null | grep "^active:" | head -1 | sed 's/active: *//' | sed 's/ *#.*//' | tr -d ' ')
if [[ -n "$ACTIVE_PLAYBOOK" && "$ACTIVE_PLAYBOOK" != "null" && -f "$ACTIVE_PLAYBOOK" ]]; then
    pass "P2: playbook.active points to existing file ($ACTIVE_PLAYBOOK)"
else
    fail "P2: playbook.active is missing or invalid (value='$ACTIVE_PLAYBOOK')"
fi

# goal.milestone が設定されているか確認
MILESTONE=$(grep -A6 "^## goal" "$state_file" 2>/dev/null | grep "milestone:" | head -1 | sed 's/milestone: *//' | sed 's/ *#.*//' | tr -d ' ')
if [[ -n "$MILESTONE" ]]; then
    pass "P3: goal.milestone is set ($MILESTONE)"
else
    fail "P3: goal.milestone is not set"
fi

# ブランチが main でないことを確認（state と git の両方）
STATE_BRANCH=$(grep -A6 "^## playbook" "$state_file" 2>/dev/null | grep "^branch:" | head -1 | sed 's/branch: *//' | sed 's/ *#.*//' | tr -d ' ')
CURRENT_BRANCH=$(git -C "$REPO_ROOT" branch --show-current 2>/dev/null || echo "")
if [[ -n "$CURRENT_BRANCH" && "$CURRENT_BRANCH" != "main" && "$CURRENT_BRANCH" != "master" ]]; then
    if [[ -n "$STATE_BRANCH" && "$STATE_BRANCH" != "main" && "$STATE_BRANCH" != "master" && "$STATE_BRANCH" == "$CURRENT_BRANCH" ]]; then
        pass "P4: working branch is not main and matches state.md ($CURRENT_BRANCH)"
    else
        fail "P4: branch mismatch (git='$CURRENT_BRANCH', state='$STATE_BRANCH')"
    fi
else
    fail "P4: current branch is main/master or undetected (git='$CURRENT_BRANCH')"
fi

# pm SubAgent が存在し、playbook 作成が可能な状態か
if [[ -f ".claude/agents/pm.md" ]]; then
    pass "P5: pm subagent is available for playbook creation"
else
    fail "P5: pm subagent definition not found"
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
