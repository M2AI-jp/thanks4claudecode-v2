#!/bin/bash
# check-spec-sync.sh - spec.yaml と実装の同期チェック
#
# .claude/ 配下のファイル変更時に spec.yaml との整合性を確認。
# 不整合があれば WARNING を出力。
#
# 設計方針:
#   - 軽量（OOM 対策）
#   - spec.yaml に宣言されていないファイルを検出
#   - 宣言されているが存在しないファイルを検出

set -e

SPEC="spec.yaml"
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

WARNINGS=0

# spec.yaml が存在しない場合はスキップ
if [ ! -f "$SPEC" ]; then
    exit 0
fi

# yq がない場合は警告してスキップ
if ! command -v yq &> /dev/null; then
    # yq がなくても基本的なチェックは可能（grep ベース）
    :
fi

echo ""
echo "=========================================="
echo "  Spec Sync Check"
echo "=========================================="
echo ""

# --- Hooks チェック ---
echo "--- Hooks ---"
for HOOK_FILE in .claude/hooks/*.sh; do
    if [ -f "$HOOK_FILE" ]; then
        BASENAME=$(basename "$HOOK_FILE" .sh)
        # spec.yaml に宣言されているか確認（簡易チェック）
        if ! grep -q "$BASENAME" "$SPEC" 2>/dev/null; then
            echo -e "  ${YELLOW}[WARN]${NC} $HOOK_FILE は spec.yaml に未宣言"
            WARNINGS=$((WARNINGS + 1))
        else
            echo -e "  ${GREEN}[OK]${NC} $BASENAME"
        fi
    fi
done

# --- Commands チェック ---
echo ""
echo "--- Commands ---"
for CMD_FILE in .claude/commands/*.md; do
    if [ -f "$CMD_FILE" ]; then
        BASENAME=$(basename "$CMD_FILE" .md)
        if ! grep -q "/$BASENAME" "$SPEC" 2>/dev/null; then
            echo -e "  ${YELLOW}[WARN]${NC} $CMD_FILE は spec.yaml に未宣言"
            WARNINGS=$((WARNINGS + 1))
        else
            echo -e "  ${GREEN}[OK]${NC} /$BASENAME"
        fi
    fi
done

# --- Skills チェック ---
echo ""
echo "--- Skills ---"
for SKILL_DIR in .claude/skills/*/; do
    if [ -d "$SKILL_DIR" ]; then
        BASENAME=$(basename "$SKILL_DIR")
        if ! grep -q "$BASENAME" "$SPEC" 2>/dev/null; then
            echo -e "  ${YELLOW}[WARN]${NC} $SKILL_DIR は spec.yaml に未宣言"
            WARNINGS=$((WARNINGS + 1))
        else
            echo -e "  ${GREEN}[OK]${NC} $BASENAME"
        fi
    fi
done

# --- Agents チェック ---
echo ""
echo "--- Agents ---"
if [ -d ".claude/agents" ]; then
    for AGENT_FILE in .claude/agents/*.md; do
        if [ -f "$AGENT_FILE" ]; then
            BASENAME=$(basename "$AGENT_FILE" .md)
            if ! grep -q "$BASENAME" "$SPEC" 2>/dev/null; then
                echo -e "  ${YELLOW}[WARN]${NC} $AGENT_FILE は spec.yaml に未宣言"
                WARNINGS=$((WARNINGS + 1))
            else
                echo -e "  ${GREEN}[OK]${NC} $BASENAME"
            fi
        fi
    done
else
    echo -e "  (agents ディレクトリなし)"
fi

# --- spec に宣言されているが存在しないファイル ---
echo ""
echo "--- Missing Files ---"

# hooks セクションのファイルをチェック
HOOK_FILES=$(grep -E "^\s+file: \.claude/hooks/" "$SPEC" 2>/dev/null | sed 's/.*file: //' | tr -d ' ' || true)
for F in $HOOK_FILES; do
    if [ ! -f "$F" ]; then
        echo -e "  ${YELLOW}[WARN]${NC} spec に宣言されているが存在しない: $F"
        WARNINGS=$((WARNINGS + 1))
    fi
done

# commands セクションのファイルをチェック
CMD_FILES=$(grep -E "^\s+file: \.claude/commands/" "$SPEC" 2>/dev/null | sed 's/.*file: //' | tr -d ' ' || true)
for F in $CMD_FILES; do
    if [ ! -f "$F" ]; then
        echo -e "  ${YELLOW}[WARN]${NC} spec に宣言されているが存在しない: $F"
        WARNINGS=$((WARNINGS + 1))
    fi
done

# agents セクションのファイルをチェック
AGENT_FILES=$(grep -E "^\s+file: \.claude/agents/" "$SPEC" 2>/dev/null | sed 's/.*file: //' | tr -d ' ' || true)
for F in $AGENT_FILES; do
    if [ ! -f "$F" ]; then
        echo -e "  ${YELLOW}[WARN]${NC} spec に宣言されているが存在しない: $F"
        WARNINGS=$((WARNINGS + 1))
    fi
done

if [ $WARNINGS -eq 0 ]; then
    echo -e "  ${GREEN}[OK]${NC} 全て存在"
fi

echo ""
echo "=========================================="
if [ $WARNINGS -gt 0 ]; then
    echo -e "${YELLOW}[WARN]${NC} $WARNINGS 件の不整合"
    echo ""
    echo "spec.yaml を更新してください。"
    echo "参照: .claude/spec.yaml"
    # WARNING は exit 0（ブロックしない）
    exit 0
else
    echo -e "${GREEN}[PASS]${NC} spec 同期 OK"
fi
echo "=========================================="

exit 0
