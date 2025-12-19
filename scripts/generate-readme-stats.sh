#!/bin/bash
# generate-readme-stats.sh - README の数値を自動集計・更新
#
# 使い方:
#   bash scripts/generate-readme-stats.sh          # 統計を表示
#   bash scripts/generate-readme-stats.sh --update # README.md を更新
#
# 目的:
#   手動で更新する数値は嘘の温床。自動生成で「嘘が生まれない仕組み」を実現。

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="${SCRIPT_DIR}/.."
README_FILE="${REPO_ROOT}/README.md"
STATE_FILE="${REPO_ROOT}/state.md"
PROJECT_FILE="${REPO_ROOT}/plan/project.md"

# 色定義
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# =============================================================================
# 統計収集
# =============================================================================

# Hook 数（.claude/hooks/*.sh をカウント、lib/ は除外）
count_hooks() {
    find "${REPO_ROOT}/.claude/hooks" -maxdepth 1 -name "*.sh" -type f 2>/dev/null | wc -l | tr -d ' '
}

# 登録済み Hook 数（settings.json から）
count_registered_hooks() {
    if [[ -f "${REPO_ROOT}/.claude/settings.json" ]]; then
        grep -c '"command":' "${REPO_ROOT}/.claude/settings.json" 2>/dev/null || echo "0"
    else
        echo "0"
    fi
}

# SubAgent 数
count_subagents() {
    find "${REPO_ROOT}/.claude/agents" -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' '
}

# Skill 数
count_skills() {
    find "${REPO_ROOT}/.claude/skills" -name "SKILL.md" -type f 2>/dev/null | wc -l | tr -d ' '
}

# Command 数
count_commands() {
    find "${REPO_ROOT}/.claude/commands" -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' '
}

# E2E テスト数
count_e2e_tests() {
    local test_script="${REPO_ROOT}/scripts/e2e-contract-test.sh"
    if [[ -f "$test_script" ]]; then
        grep -c 'test_' "$test_script" 2>/dev/null || echo "0"
    else
        echo "0"
    fi
}

# Milestone 数（project.md から）
count_milestones() {
    if [[ -f "$PROJECT_FILE" ]]; then
        grep -cE '^- id: M[0-9]+' "$PROJECT_FILE" 2>/dev/null || echo "0"
    else
        echo "0"
    fi
}

# Achieved milestone 数
count_achieved_milestones() {
    if [[ -f "$PROJECT_FILE" ]]; then
        # "  status: achieved" のみカウント（ドキュメント行を除外）
        grep -cE '^[[:space:]]+status: achieved$' "$PROJECT_FILE" 2>/dev/null || echo "0"
    else
        echo "0"
    fi
}

# アーカイブ済み playbook 数
count_archived_playbooks() {
    find "${REPO_ROOT}/plan/archive" -name "playbook-*.md" -type f 2>/dev/null | wc -l | tr -d ' '
}

# =============================================================================
# 統計表示
# =============================================================================

show_stats() {
    local hooks=$(count_hooks)
    local registered=$(count_registered_hooks)
    local subagents=$(count_subagents)
    local skills=$(count_skills)
    local commands=$(count_commands)
    local e2e=$(count_e2e_tests)
    local milestones=$(count_milestones)
    local achieved=$(count_achieved_milestones)
    local archived=$(count_archived_playbooks)

    echo "=========================================="
    echo "  README Stats (自動集計)"
    echo "=========================================="
    echo ""
    echo "  hooks: $hooks (registered: $registered)"
    echo "  subagents: $subagents"
    echo "  skills: $skills"
    echo "  commands: $commands"
    echo "  e2e_tests: $e2e"
    echo "  milestones: $milestones (achieved: $achieved)"
    echo "  archived_playbooks: $archived"
    echo ""
    echo "=========================================="
}

# =============================================================================
# README 更新
# =============================================================================

update_readme() {
    if [[ ! -f "$README_FILE" ]]; then
        echo -e "${YELLOW}[WARN]${NC} README.md not found" >&2
        exit 1
    fi

    # STATS タグが存在するか確認
    if ! grep -q '<!-- STATS_START -->' "$README_FILE"; then
        echo -e "${YELLOW}[WARN]${NC} <!-- STATS_START --> tag not found in README.md" >&2
        echo "Please add the following tags to README.md:" >&2
        echo "  <!-- STATS_START -->" >&2
        echo "  (stats will be inserted here)" >&2
        echo "  <!-- STATS_END -->" >&2
        exit 1
    fi

    local hooks=$(count_hooks)
    local registered=$(count_registered_hooks)
    local subagents=$(count_subagents)
    local skills=$(count_skills)
    local commands=$(count_commands)
    local e2e=$(count_e2e_tests)
    local milestones=$(count_milestones)
    local achieved=$(count_achieved_milestones)

    # STATS セクションを一時ファイルに生成
    local stats_file
    stats_file=$(mktemp)
    cat > "$stats_file" <<EOF
<!-- STATS_START -->
| 項目 | 数 | 備考 |
|------|-----|------|
| Hook | ${hooks} | 登録済: ${registered} |
| SubAgent | ${subagents} | |
| Skill | ${skills} | |
| Command | ${commands} | |
| E2E テスト | ${e2e} | |
| Milestone | ${milestones} | 達成: ${achieved} |
<!-- STATS_END -->
EOF

    # タグ間を置換（macOS/Linux 両対応）
    local tmp_file
    tmp_file=$(mktemp)
    awk -v statsfile="$stats_file" '
        /<!-- STATS_START -->/ {
            while ((getline line < statsfile) > 0) print line
            close(statsfile)
            skip=1
            next
        }
        /<!-- STATS_END -->/ { skip=0; next }
        !skip { print }
    ' "$README_FILE" > "$tmp_file"

    mv "$tmp_file" "$README_FILE"
    rm -f "$stats_file"

    echo -e "${GREEN}[OK]${NC} README.md updated with latest stats"
    show_stats
}

# =============================================================================
# メイン
# =============================================================================

case "${1:-}" in
    --update)
        update_readme
        ;;
    --help|-h)
        echo "Usage: $0 [--update]"
        echo ""
        echo "  (no args)  Show current stats"
        echo "  --update   Update README.md with current stats"
        ;;
    *)
        show_stats
        ;;
esac
