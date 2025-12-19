#!/bin/bash
# ============================================================
# check-spec-sync.sh - 仕様同期チェック (SSC Phase 2)
# ============================================================
# 目的: README/project.md と実態の乖離を検出・警告
#
# 機能:
#   1. README.md から Hook 数、Milestone 数を抽出
#   2. project.md から Milestone 数（total/achieved/pending）を抽出
#   3. SPEC_SNAPSHOT と比較し、乖離があれば WARNING を出力
#   4. --update オプションで SPEC_SNAPSHOT を更新
#
# 使用方法:
#   bash .claude/hooks/check-spec-sync.sh           # チェックのみ
#   bash .claude/hooks/check-spec-sync.sh --update  # チェック + 更新
#   bash .claude/hooks/check-spec-sync.sh --extract-readme   # README から抽出
#   bash .claude/hooks/check-spec-sync.sh --extract-project  # project.md から抽出
#
# 戻り値:
#   0: 常に成功（警告があっても exit 0）
# ============================================================

set -uo pipefail

# 色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# プロジェクトルート
PROJECT_ROOT="${CLAUDE_PROJECT_DIR:-$(pwd)}"
STATE_FILE="$PROJECT_ROOT/state.md"
README_FILE="$PROJECT_ROOT/README.md"
PROJECT_FILE="$PROJECT_ROOT/plan/project.md"

# ============================================================
# 抽出関数
# ============================================================

# README.md から Hook 数を抽出
extract_readme_hooks() {
    if [[ ! -f "$README_FILE" ]]; then
        echo "0"
        return
    fi
    grep -oE 'Hook（[0-9]+個' "$README_FILE" 2>/dev/null | grep -oE '[0-9]+' | head -1 || echo "0"
}

# README.md から Milestone 数を抽出
extract_readme_milestones() {
    if [[ ! -f "$README_FILE" ]]; then
        echo "0"
        return
    fi
    grep -oE '[0-9]+ milestone' "$README_FILE" 2>/dev/null | grep -oE '[0-9]+' | head -1 || echo "0"
}

# project.md から Milestone 総数を抽出
extract_project_total() {
    if [[ ! -f "$PROJECT_FILE" ]]; then
        echo "0"
        return
    fi
    grep -c '^- id: M' "$PROJECT_FILE" 2>/dev/null || echo "0"
}

# project.md から achieved Milestone 数を抽出
extract_project_achieved() {
    if [[ ! -f "$PROJECT_FILE" ]]; then
        echo "0"
        return
    fi
    grep -E '^\s+status: achieved$' "$PROJECT_FILE" 2>/dev/null | wc -l | tr -d ' '
}

# project.md から pending Milestone 数を抽出
extract_project_pending() {
    if [[ ! -f "$PROJECT_FILE" ]]; then
        echo "0"
        return
    fi
    grep -E '^\s+status: pending$' "$PROJECT_FILE" 2>/dev/null | wc -l | tr -d ' '
}

# SPEC_SNAPSHOT から値を取得
get_snapshot_value() {
    local key="$1"
    if [[ ! -f "$STATE_FILE" ]]; then
        echo ""
        return
    fi
    grep -A 15 "## SPEC_SNAPSHOT" "$STATE_FILE" 2>/dev/null | grep "$key:" | head -1 | sed 's/.*: *//' | tr -d ' '
}

# ============================================================
# メイン処理
# ============================================================

# オプション処理
case "${1:-}" in
    --extract-readme)
        echo "hooks: $(extract_readme_hooks)"
        echo "milestone_count: $(extract_readme_milestones)"
        exit 0
        ;;
    --extract-project)
        echo "total: $(extract_project_total)"
        echo "achieved: $(extract_project_achieved)"
        echo "pending: $(extract_project_pending)"
        exit 0
        ;;
esac

# 現在値を取得
CURRENT_README_HOOKS=$(extract_readme_hooks)
CURRENT_README_MILESTONES=$(extract_readme_milestones)
CURRENT_PROJECT_TOTAL=$(extract_project_total)
CURRENT_PROJECT_ACHIEVED=$(extract_project_achieved)
CURRENT_PROJECT_PENDING=$(extract_project_pending)

# SPEC_SNAPSHOT の値を取得
SNAPSHOT_README_HOOKS=$(get_snapshot_value "hooks")
SNAPSHOT_README_MILESTONES=$(get_snapshot_value "milestone_count")
SNAPSHOT_PROJECT_TOTAL=$(get_snapshot_value "total")
SNAPSHOT_PROJECT_ACHIEVED=$(get_snapshot_value "achieved")
SNAPSHOT_PROJECT_PENDING=$(get_snapshot_value "pending")

# 乖離チェック
HAS_MISMATCH=0

check_value() {
    local name="$1"
    local current="$2"
    local snapshot="$3"

    if [[ -z "$snapshot" ]]; then
        echo -e "${YELLOW}WARNING${NC}: $name のスナップショットが存在しません" >&2
        HAS_MISMATCH=1
        return
    fi

    if [[ "$current" != "$snapshot" ]]; then
        echo -e "${YELLOW}WARNING${NC}: $name が変更されています: $snapshot -> $current" >&2
        HAS_MISMATCH=1
    fi
}

echo "Checking spec sync..."

check_value "readme.hooks" "$CURRENT_README_HOOKS" "$SNAPSHOT_README_HOOKS"
check_value "readme.milestone_count" "$CURRENT_README_MILESTONES" "$SNAPSHOT_README_MILESTONES"
check_value "project.total" "$CURRENT_PROJECT_TOTAL" "$SNAPSHOT_PROJECT_TOTAL"
check_value "project.achieved" "$CURRENT_PROJECT_ACHIEVED" "$SNAPSHOT_PROJECT_ACHIEVED"
check_value "project.pending" "$CURRENT_PROJECT_PENDING" "$SNAPSHOT_PROJECT_PENDING"

# 更新オプション
if [[ "${1:-}" == "--update" ]]; then
    if [[ ! -f "$STATE_FILE" ]]; then
        echo -e "${YELLOW}WARNING${NC}: state.md not found, skipping SPEC_SNAPSHOT update" >&2
        exit 0
    fi

    # last_checked を現在日時で更新
    TODAY=$(date '+%Y-%m-%d')

    # SPEC_SNAPSHOT セクションを更新
    # sed でインプレース編集
    if [[ "$(uname)" == "Darwin" ]]; then
        # macOS
        sed -i '' "s/^  hooks: .*/  hooks: $CURRENT_README_HOOKS/" "$STATE_FILE"
        sed -i '' "s/^  milestone_count: .*/  milestone_count: $CURRENT_README_MILESTONES/" "$STATE_FILE"
        sed -i '' "s/^  total: .*/  total: $CURRENT_PROJECT_TOTAL/" "$STATE_FILE"
        sed -i '' "s/^  achieved: .*/  achieved: $CURRENT_PROJECT_ACHIEVED/" "$STATE_FILE"
        sed -i '' "s/^  pending: .*/  pending: $CURRENT_PROJECT_PENDING/" "$STATE_FILE"
        sed -i '' "s/^last_checked: .*/last_checked: $TODAY/" "$STATE_FILE"
    else
        # Linux
        sed -i "s/^  hooks: .*/  hooks: $CURRENT_README_HOOKS/" "$STATE_FILE"
        sed -i "s/^  milestone_count: .*/  milestone_count: $CURRENT_README_MILESTONES/" "$STATE_FILE"
        sed -i "s/^  total: .*/  total: $CURRENT_PROJECT_TOTAL/" "$STATE_FILE"
        sed -i "s/^  achieved: .*/  achieved: $CURRENT_PROJECT_ACHIEVED/" "$STATE_FILE"
        sed -i "s/^  pending: .*/  pending: $CURRENT_PROJECT_PENDING/" "$STATE_FILE"
        sed -i "s/^last_checked: .*/last_checked: $TODAY/" "$STATE_FILE"
    fi

    echo -e "${GREEN}INFO${NC}: SPEC_SNAPSHOT updated (last_checked: $TODAY)"
fi

# 結果出力
if [[ $HAS_MISMATCH -eq 0 ]]; then
    echo -e "${GREEN}PASS${NC}: Spec sync check passed (no mismatches)"
else
    echo -e "${YELLOW}WARNING${NC}: Spec sync check found mismatches (see above)"
fi

exit 0
