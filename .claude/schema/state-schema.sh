#!/bin/bash
# ==============================================================================
# state-schema.sh - state.md のスキーマ定義と getter 関数
# ==============================================================================
#
# 目的:
#   state.md のセクション構造を単一定義源として管理し、
#   Hook や他のスクリプトが参照する際の仕様遵守を強制する。
#
# 使い方:
#   source /path/to/.claude/schema/state-schema.sh
#   value=$(get_focus_current)
#
# ==============================================================================

set -euo pipefail

# ==============================================================================
# セクション定義
# ==============================================================================
#
# state.md の各セクション名を定数として定義。
# Hook はハードコードせず、これらの定数を参照する。

SECTION_FOCUS="focus"
SECTION_PLAYBOOK="playbook"
SECTION_GOAL="goal"
SECTION_SESSION="session"
SECTION_CONFIG="config"

# ==============================================================================
# Getter 関数群
# ==============================================================================
#
# 各セクションから値を抽出する関数。
# awk を使って Markdown セクションを抽出し、grep で特定のフィールドを取得。

# get_focus_current: focus.current の値を取得
get_focus_current() {
    awk "/^## $SECTION_FOCUS/,/^## [^f]/" state.md 2>/dev/null | \
    grep "current:" | head -1 | sed 's/.*: *//' | sed 's/ *#.*//' || echo ""
}

# get_playbook_active: playbook.active の値を取得
get_playbook_active() {
    awk "/^## $SECTION_PLAYBOOK/,/^## [^p]/" state.md 2>/dev/null | \
    grep "active:" | head -1 | sed 's/.*: *//' | sed 's/ *#.*//' || echo ""
}

# get_playbook_branch: playbook.branch の値を取得
get_playbook_branch() {
    awk "/^## $SECTION_PLAYBOOK/,/^## [^p]/" state.md 2>/dev/null | \
    grep "branch:" | head -1 | sed 's/.*: *//' | sed 's/ *#.*//' || echo ""
}

# get_goal_milestone: goal.milestone の値を取得
get_goal_milestone() {
    awk "/^## $SECTION_GOAL/,/^## [^g]/" state.md 2>/dev/null | \
    grep "milestone:" | head -1 | sed 's/.*: *//' | sed 's/ *#.*//' || echo ""
}

# get_goal_phase: goal.phase の値を取得
get_goal_phase() {
    awk "/^## $SECTION_GOAL/,/^## [^g]/" state.md 2>/dev/null | \
    grep "phase:" | head -1 | sed 's/.*: *//' | sed 's/ *#.*//' || echo ""
}

# get_session_last_start: session.last_start の値を取得
get_session_last_start() {
    awk "/^## $SECTION_SESSION/,/^## [^s]/" state.md 2>/dev/null | \
    grep "last_start:" | head -1 | sed 's/.*: *//' | sed 's/ *#.*//' || echo ""
}

# get_session_last_clear: session.last_clear の値を取得
get_session_last_clear() {
    awk "/^## $SECTION_SESSION/,/^## [^s]/" state.md 2>/dev/null | \
    grep "last_clear:" | head -1 | sed 's/.*: *//' | sed 's/ *#.*//' || echo ""
}

# get_config_security: config.security の値を取得
get_config_security() {
    awk "/^## $SECTION_CONFIG/,/^## [^c]/" state.md 2>/dev/null | \
    grep "security:" | head -1 | sed 's/.*: *//' | sed 's/ *#.*//' || echo ""
}

# ==============================================================================
# ヘルパー関数
# ==============================================================================

# check_section_exists: セクションが state.md に存在するか確認
check_section_exists() {
    local section="$1"
    grep -q "^## $section" state.md 2>/dev/null && return 0 || return 1
}

# ==============================================================================
# 拡張性ガイド
# ==============================================================================
#
# 新しいセクションを state.md に追加する場合:
#
# 1. このファイルに SECTION_* 定数を追加:
#    SECTION_NEWSECTION="newsection"
#
# 2. 対応する getter 関数を追加:
#    get_newsection_field() {
#        awk "/^## $SECTION_NEWSECTION/,/^## [^n]/" state.md | \
#        grep "field:" | head -1 | sed 's/.*: *//' || echo ""
#    }
#
# 3. state.md に新セクションを追加:
#    ## newsection
#    ```yaml
#    field: value
#    ```
#
# 4. Hook で参照:
#    source .claude/schema/state-schema.sh
#    value=$(get_newsection_field)
#

# ==============================================================================
# 動作確認用テスト関数
# ==============================================================================

# test_schema: すべての getter 関数が値を返すか確認
test_schema() {
    echo "Testing state-schema.sh..."

    echo "  focus.current: $(get_focus_current)"
    echo "  playbook.active: $(get_playbook_active)"
    echo "  playbook.branch: $(get_playbook_branch)"
    echo "  goal.milestone: $(get_goal_milestone)"
    echo "  goal.phase: $(get_goal_phase)"
    echo "  session.last_start: $(get_session_last_start)"
    echo "  session.last_clear: $(get_session_last_clear)"
    echo "  config.security: $(get_config_security)"

    echo ""
    echo "All getters executed successfully."
}

# main: このスクリプトが直接実行された場合
if [[ "${BASH_SOURCE[0]:-}" == "${0}" ]]; then
    test_schema
fi
