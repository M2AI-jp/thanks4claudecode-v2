#!/bin/bash
# feature-catalog-sync.sh - 機能カタログ同期チェック
#
# 目的: docs/feature-catalog.yaml と実ファイルの整合性を検証
# トリガー: SessionStart, --check オプション
#
# 使用方法:
#   bash .claude/hooks/feature-catalog-sync.sh          # 通常実行（サマリー出力）
#   bash .claude/hooks/feature-catalog-sync.sh --check  # 詳細チェック
#   bash .claude/hooks/feature-catalog-sync.sh --dry-run # スキャンのみ

set -euo pipefail

# カラー定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# パス
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CATALOG_FILE="$PROJECT_ROOT/docs/feature-catalog.yaml"
HOOKS_DIR="$PROJECT_ROOT/.claude/hooks"
AGENTS_DIR="$PROJECT_ROOT/.claude/agents"
SKILLS_DIR="$PROJECT_ROOT/.claude/skills"

# カウンター
HOOKS_ACTUAL=0
AGENTS_ACTUAL=0
SKILLS_ACTUAL=0
HOOKS_CATALOG=0
AGENTS_CATALOG=0
SKILLS_CATALOG=0
CHANGES_DETECTED=0

# ヘルプ
show_help() {
    echo "Usage: feature-catalog-sync.sh [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --check     詳細チェック（差分を表示）"
    echo "  --dry-run   スキャンのみ（変更なし）"
    echo "  --help      このヘルプを表示"
}

# スキャン: 実際のファイル数をカウント
scan_actual() {
    echo -e "${BLUE}Scanning actual files...${NC}"

    # Hooks (*.sh files)
    HOOKS_ACTUAL=$(find "$HOOKS_DIR" -maxdepth 1 -name "*.sh" -type f 2>/dev/null | wc -l | tr -d ' ')
    echo "  Hooks: $HOOKS_ACTUAL files"

    # Agents (*.md files, excluding CLAUDE.md)
    AGENTS_ACTUAL=$(find "$AGENTS_DIR" -maxdepth 1 -name "*.md" -type f ! -name "CLAUDE.md" 2>/dev/null | wc -l | tr -d ' ')
    echo "  Agents: $AGENTS_ACTUAL files"

    # Skills (directories)
    SKILLS_ACTUAL=$(find "$SKILLS_DIR" -maxdepth 1 -type d ! -path "$SKILLS_DIR" 2>/dev/null | wc -l | tr -d ' ')
    echo "  Skills: $SKILLS_ACTUAL directories"
}

# スキャン: カタログの数をカウント
scan_catalog() {
    if [[ ! -f "$CATALOG_FILE" ]]; then
        echo -e "${RED}ERROR: Catalog file not found: $CATALOG_FILE${NC}"
        return 1
    fi

    echo -e "${BLUE}Scanning catalog...${NC}"

    # Hooks count from catalog (count entries under hooks:)
    HOOKS_CATALOG=$(grep -c "^  - id: H" "$CATALOG_FILE" 2>/dev/null || echo "0")
    echo "  Hooks: $HOOKS_CATALOG entries"

    # Agents count from catalog
    AGENTS_CATALOG=$(grep -c "subagent_type:" "$CATALOG_FILE" 2>/dev/null || echo "0")
    echo "  Agents: $AGENTS_CATALOG entries"

    # Skills count from catalog
    SKILLS_CATALOG=$(grep -c "skill_dir:" "$CATALOG_FILE" 2>/dev/null || echo "0")
    echo "  Skills: $SKILLS_CATALOG entries"
}

# 比較: 差分を検出
compare() {
    echo ""
    echo -e "${BLUE}Comparing...${NC}"

    local status="OK"

    if [[ "$HOOKS_ACTUAL" -ne "$HOOKS_CATALOG" ]]; then
        echo -e "${YELLOW}  [MISMATCH] Hooks: actual=$HOOKS_ACTUAL, catalog=$HOOKS_CATALOG${NC}"
        CHANGES_DETECTED=$((CHANGES_DETECTED + 1))
        status="OUTDATED"
    else
        echo -e "${GREEN}  [OK] Hooks: $HOOKS_ACTUAL${NC}"
    fi

    if [[ "$AGENTS_ACTUAL" -ne "$AGENTS_CATALOG" ]]; then
        echo -e "${YELLOW}  [MISMATCH] Agents: actual=$AGENTS_ACTUAL, catalog=$AGENTS_CATALOG${NC}"
        CHANGES_DETECTED=$((CHANGES_DETECTED + 1))
        status="OUTDATED"
    else
        echo -e "${GREEN}  [OK] Agents: $AGENTS_ACTUAL${NC}"
    fi

    if [[ "$SKILLS_ACTUAL" -ne "$SKILLS_CATALOG" ]]; then
        echo -e "${YELLOW}  [MISMATCH] Skills: actual=$SKILLS_ACTUAL, catalog=$SKILLS_CATALOG${NC}"
        CHANGES_DETECTED=$((CHANGES_DETECTED + 1))
        status="OUTDATED"
    else
        echo -e "${GREEN}  [OK] Skills: $SKILLS_ACTUAL${NC}"
    fi

    echo ""
    if [[ "$status" == "OK" ]]; then
        echo -e "${GREEN}Status: OK - Catalog is up to date${NC}"
    else
        echo -e "${YELLOW}Status: OUTDATED - $CHANGES_DETECTED category changes detected${NC}"
        echo -e "${YELLOW}WARNING: 機能カタログが最新ではありません。${NC}"
        echo -e "${YELLOW}  → bash .claude/hooks/generate-repository-map.sh で更新${NC}"
    fi

    return 0
}

# 詳細チェック: 個別ファイルの差分を表示
detailed_check() {
    echo ""
    echo -e "${BLUE}=== Detailed Check ===${NC}"

    # Hooks の差分
    echo -e "\n${BLUE}Hooks:${NC}"
    local actual_hooks=$(find "$HOOKS_DIR" -maxdepth 1 -name "*.sh" -type f -exec basename {} \; 2>/dev/null | sort)
    local catalog_hooks=$(grep "name:.*\.sh" "$CATALOG_FILE" 2>/dev/null | sed 's/.*name: //' | tr -d '"' | sort)

    # 実際にあるがカタログにない
    local missing_in_catalog=$(comm -23 <(echo "$actual_hooks") <(echo "$catalog_hooks"))
    if [[ -n "$missing_in_catalog" ]]; then
        echo -e "${YELLOW}  New (not in catalog):${NC}"
        echo "$missing_in_catalog" | while read -r f; do
            [[ -n "$f" ]] && echo "    + $f"
        done
    fi

    # カタログにあるが実際にない
    local missing_in_actual=$(comm -13 <(echo "$actual_hooks") <(echo "$catalog_hooks"))
    if [[ -n "$missing_in_actual" ]]; then
        echo -e "${RED}  Removed (in catalog but not found):${NC}"
        echo "$missing_in_actual" | while read -r f; do
            [[ -n "$f" ]] && echo "    - $f"
        done
    fi

    [[ -z "$missing_in_catalog" && -z "$missing_in_actual" ]] && echo -e "  ${GREEN}All hooks match${NC}"
}

# メイン
main() {
    local mode="normal"

    # 引数解析
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --check)
                mode="check"
                shift
                ;;
            --dry-run)
                mode="dry-run"
                shift
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            *)
                echo "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  📦 Feature Catalog Sync Check"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    scan_actual
    echo ""
    scan_catalog

    if [[ "$mode" == "dry-run" ]]; then
        echo ""
        echo -e "${GREEN}Dry run complete. No changes made.${NC}"
        exit 0
    fi

    compare

    if [[ "$mode" == "check" ]]; then
        detailed_check
    fi

    # 結果コード
    if [[ $CHANGES_DETECTED -gt 0 ]]; then
        exit 1
    fi
    exit 0
}

main "$@"
