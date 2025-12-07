#!/bin/bash
# check-playbook-quality.sh - playbook の構造品質を検証
# 自然言語ルールではなく、機械的にブロックする

set -e

PLAYBOOK="$1"
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

if [ -z "$PLAYBOOK" ] || [ ! -f "$PLAYBOOK" ]; then
    echo "Usage: check-playbook-quality.sh <playbook.md>"
    exit 1
fi

ERRORS=0

echo "Checking playbook quality: $PLAYBOOK"
echo "=========================================="

# 1. done_criteria が構造化形式か（criterion: が必須）
echo -n "1. done_criteria 構造化形式: "
if grep -q "criterion:" "$PLAYBOOK"; then
    echo "PASS"
else
    echo -e "${RED}FAIL${NC} - criterion: フィールドがありません"
    ERRORS=$((ERRORS + 1))
fi

# 2. test フィールドが存在するか
echo -n "2. test フィールド: "
if grep -q "test:" "$PLAYBOOK"; then
    echo "PASS"
else
    echo -e "${RED}FAIL${NC} - test: フィールドがありません"
    ERRORS=$((ERRORS + 1))
fi

# 3. evidence フィールドが存在するか
echo -n "3. evidence フィールド: "
if grep -q "evidence:" "$PLAYBOOK"; then
    echo "PASS"
else
    echo -e "${RED}FAIL${NC} - evidence: フィールドがありません"
    ERRORS=$((ERRORS + 1))
fi

# 4. checkpoint が存在するか
echo -n "4. checkpoint 定義: "
if grep -q "checkpoint:" "$PLAYBOOK"; then
    echo "PASS"
else
    echo -e "${RED}FAIL${NC} - checkpoint: がありません"
    ERRORS=$((ERRORS + 1))
fi

# 5. 検証不可能な表現がないか
echo -n "5. 検証不可能表現チェック: "
BAD_PATTERNS=$(grep -E "^\s*-\s+\"?(設定した|完了した|テストする|作成する|実装する)\"?\s*$" "$PLAYBOOK" 2>/dev/null | wc -l | tr -d ' ')
if [ "$BAD_PATTERNS" -gt 0 ]; then
    echo -e "${RED}FAIL${NC} - 検証不可能な表現が ${BAD_PATTERNS} 件あります"
    ERRORS=$((ERRORS + 1))
else
    echo "PASS"
fi

# 6. branch フィールドが存在するか
echo -n "6. branch フィールド: "
if grep -q "branch:" "$PLAYBOOK"; then
    echo "PASS"
else
    echo -e "${YELLOW}WARN${NC} - branch: フィールドがありません"
fi

echo "=========================================="

if [ "$ERRORS" -gt 0 ]; then
    echo -e "${RED}QUALITY CHECK FAILED: ${ERRORS} errors${NC}"
    echo ""
    echo "playbook は V7 構造化形式に従う必要があります:"
    echo "  done_criteria:"
    echo "    - criterion: \"〇〇が存在する\""
    echo "      test: \"ls -la 〇〇\""
    echo "      evidence: null"
    echo "  checkpoint:"
    echo "    trigger: \"全 done_criteria の evidence 記録後\""
    echo "    action: \"critic agent を呼び出す\""
    exit 1
else
    echo "QUALITY CHECK PASSED"
    exit 0
fi
