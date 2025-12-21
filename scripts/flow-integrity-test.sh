#!/usr/bin/env bash
#
# flow-integrity-test.sh
# M126: 動線整合性テスト
#
# 検証内容:
#   1. Hook 内部参照の整合性（check-hook-references.sh）
#   2. Skill → Command 対応の完全性
#   3. cleanup-hook.sh から削除済み参照が除去されているか
#

set -uo pipefail

PASS=0
FAIL=0

# 色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

check() {
  local name="$1"
  local result="$2"
  if [[ "$result" == "PASS" ]]; then
    echo -e "${GREEN}✓${NC} $name"
    ((PASS++))
  else
    echo -e "${RED}✗${NC} $name"
    ((FAIL++))
  fi
}

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  M126: 動線整合性テスト"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Test 1: cleanup-hook.sh の削除済み参照
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo "=== cleanup-hook.sh 検証 ==="

result=$(grep -qE 'generate-repository-map\.sh|check-spec-sync\.sh|repository-map\.yaml' .claude/hooks/cleanup-hook.sh && echo FAIL || echo PASS)
check "削除済みスクリプト/ファイル参照がない" "$result"

echo

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Test 2: Hook 内部参照チェック
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo "=== Hook 内部参照チェック ==="

if [[ -f scripts/check-hook-references.sh ]]; then
  result=$(bash scripts/check-hook-references.sh >/dev/null 2>&1 && echo PASS || echo FAIL)
  check "全 Hook が有効なファイルのみ参照" "$result"
else
  echo -e "${RED}✗${NC} check-hook-references.sh が存在しない"
  ((FAIL++))
fi

echo

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Test 3: Skill → Command 対応
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo "=== Skill → Command 対応 ==="

# 各 Skill に対応する Command が存在するか
SKILLS="context-management:compact lint-checker:lint plan-management:task-start post-loop:post-loop state:focus test-runner:test"

for pair in $SKILLS; do
  skill="${pair%%:*}"
  cmd="${pair##*:}"
  if [[ -f ".claude/commands/${cmd}.md" ]]; then
    check "Skill: $skill → /$cmd" "PASS"
  else
    check "Skill: $skill → /$cmd" "FAIL"
  fi
done

echo

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Test 4: 必須 Commands 存在チェック
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo "=== 必須 Commands 存在チェック ==="

REQUIRED_CMDS="lint focus post-loop compact test task-start"
for cmd in $REQUIRED_CMDS; do
  if [[ -f ".claude/commands/${cmd}.md" ]]; then
    check "Required: /${cmd}" "PASS"
  else
    check "Required: /${cmd}" "FAIL"
  fi
done

echo

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Summary
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Summary: ${PASS} PASS, ${FAIL} FAIL"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [[ $FAIL -eq 0 ]]; then
  echo -e "${GREEN}ALL TESTS PASSED${NC}"
  exit 0
else
  echo -e "${RED}SOME TESTS FAILED${NC}"
  exit 1
fi
