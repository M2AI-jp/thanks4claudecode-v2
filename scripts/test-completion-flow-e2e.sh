#!/bin/bash
# test-completion-flow-e2e.sh - 完了動線のE2Eテスト

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
    echo "[ERROR] jq is required for archive hook simulation" >&2
    echo "SOME TESTS FAILED"
    exit 1
fi

TEMP_REPO=$(mktemp -d)
cleanup() {
    rm -rf "$TEMP_REPO"
}
trap cleanup EXIT

# plan/archive の存在確認
if [[ -d "plan/archive" ]]; then
    pass "C1: plan/archive directory exists"
else
    fail "C1: plan/archive directory missing"
fi

# archive-playbook.sh の動作確認（完了済み playbook をシミュレート）
mkdir -p "$TEMP_REPO/plan/archive"

cat > "$TEMP_REPO/state.md" << 'EOF'
# state (simulated for archive)

## playbook

```yaml
active: null
branch: feat/archive-sim
last_archived: plan/archive/placeholder.md
```
EOF

PLAYBOOK_PATH="$TEMP_REPO/plan/playbook-complete.md"
cat > "$PLAYBOOK_PATH" << 'EOF'
# playbook (archive simulation)
meta:
  derives_from: M999
  reviewed: true

goal:
  done_when:
    - "All tasks done"

### p1: prep
  status: done

### p_final: closeout
  status: done
  test_command: "echo PASS"

## final_tasks
- [x] **ft1**: archive proposal emitted
EOF

ARCHIVE_PAYLOAD=$(cat << EOF
{"tool_name":"Edit","tool_input":{"file_path":"$PLAYBOOK_PATH"}}
EOF
)

ARCHIVE_OUTPUT=$(cd "$TEMP_REPO" && CLAUDE_PROJECT_DIR="$TEMP_REPO" bash "$REPO_ROOT/.claude/hooks/archive-playbook.sh" <<< "$ARCHIVE_PAYLOAD" 2>&1)
if echo "$ARCHIVE_OUTPUT" | grep -q "\[PASS\] archive-playbook"; then
    pass "C2: archive-playbook.sh detects completed playbook and emits archive instructions"
else
    fail "C2: archive-playbook.sh did not report PASS (output: $ARCHIVE_OUTPUT)"
fi

# state.md の playbook.active が null になる流れ（現状/想定経路を確認）
STATE_FILE="state.md"
ACTIVE_PLAYBOOK=$(grep -A6 "^## playbook" "$STATE_FILE" 2>/dev/null | grep "^active:" | head -1 | sed 's/active: *//' | sed 's/ *#.*//' | tr -d ' ')
LAST_ARCHIVED=$(grep -A6 "^## playbook" "$STATE_FILE" 2>/dev/null | grep "^last_archived:" | head -1 | sed 's/last_archived: *//' | sed 's/ *#.*//' | tr -d ' ')

if [[ "$ACTIVE_PLAYBOOK" == "null" ]]; then
    pass "C3: state.md already shows playbook.active = null (post-archive state)"
else
    TARGET_PATH="plan/archive/$(basename "$ACTIVE_PLAYBOOK")"
    if [[ -n "$LAST_ARCHIVED" && "$LAST_ARCHIVED" == plan/archive/* ]]; then
        pass "C3: state.md tracks last_archived ($LAST_ARCHIVED); active can transition to null via $TARGET_PATH"
    else
        fail "C3: state.md missing last_archived entry for archiving (active=$ACTIVE_PLAYBOOK)"
    fi
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
