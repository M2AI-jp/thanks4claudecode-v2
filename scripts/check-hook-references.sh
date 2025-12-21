#!/usr/bin/env bash
#
# check-hook-references.sh
# M126: Hook 内部参照の整合性チェック
#
# 検証内容:
#   1. 各 Hook が参照するスクリプトファイルが存在するか
#   2. 削除済みファイル（FREEZE_QUEUE）への参照がないか
#   3. 存在しないドキュメントへの参照がないか
#

set -uo pipefail

PASS=0
FAIL=0
HOOKS_DIR=".claude/hooks"

# 色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

# 削除済み/FREEZE_QUEUE ファイル
DELETED_FILES=(
    "generate-repository-map.sh"
    "check-spec-sync.sh"
    "audit-unused.sh"
    "check-integrity.sh"
    "create-pr.sh"
    "merge-pr.sh"
    "playbook-validator.sh"
    "test-done-criteria.sh"
    "test-hooks.sh"
    "repository-map.yaml"
    "document-catalog.md"
    "ARCHITECTURE.md"
    "hook-registry.md"
)

# HARD_BLOCK ファイル内のグレースフル参照（存在チェック付き、手動削除待ち）
# これらは機能に影響しないため警告のみ
GRACEFUL_REFS=(
    "playbook-guard.sh:failure-logger.sh"
    "session-start.sh:system-health-check.sh"
)

check_hook() {
    local hook="$1"
    local hook_name=$(basename "$hook")
    local issues=0

    # 削除済みファイルへの参照をチェック
    for deleted in "${DELETED_FILES[@]}"; do
        if grep -q "$deleted" "$hook" 2>/dev/null; then
            # グレースフル参照リストに含まれているかチェック
            local is_graceful=false
            for graceful in "${GRACEFUL_REFS[@]}"; do
                if [[ "$graceful" == "$hook_name:$deleted" ]]; then
                    is_graceful=true
                    break
                fi
            done

            if $is_graceful; then
                echo -e "${YELLOW}⚠${NC} $hook_name: グレースフル参照（HARD_BLOCK、手動削除待ち）→ $deleted"
            else
                echo -e "${RED}✗${NC} $hook_name: 削除済みファイル参照 → $deleted"
                ((issues++))
            fi
        fi
    done

    # 他の Hook スクリプトへの参照をチェック
    local script_refs=$(grep -oE '\$SCRIPT_DIR/[a-z-]+\.sh' "$hook" 2>/dev/null | sed 's/\$SCRIPT_DIR\///' | sort -u)
    for ref in $script_refs; do
        if [[ ! -f "$HOOKS_DIR/$ref" ]]; then
            echo -e "${RED}✗${NC} $hook_name: 存在しないスクリプト参照 → $ref"
            ((issues++))
        fi
    done

    return $issues
}

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  M126: Hook 内部参照チェック"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo

# 全 Hook をチェック
for hook in "$HOOKS_DIR"/*.sh; do
    if [[ -f "$hook" ]]; then
        if check_hook "$hook"; then
            ((PASS++))
        else
            ((FAIL++))
        fi
    fi
done

echo
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Summary: $PASS hooks OK, $FAIL hooks with issues"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [[ $FAIL -eq 0 ]]; then
    echo -e "${GREEN}ALL HOOKS CLEAN${NC}"
    exit 0
else
    echo -e "${RED}ISSUES FOUND${NC}"
    exit 1
fi
