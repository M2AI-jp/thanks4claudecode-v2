#!/bin/bash
# ==============================================================================
# generate-repository-map.sh - 全ファイル自動マッピングシステム
# ==============================================================================
#
# 目的:
#   - リポジトリ内の全ファイルをスキャンしてマッピング
#   - カテゴリ・役割を自動抽出
#   - docs/repository-map.yaml として出力
#
# 実行タイミング:
#   - playbook 完了時（cleanup-hook.sh から呼び出し）
#   - 手動実行: bash .claude/hooks/generate-repository-map.sh
#
# 抽出ルール:
#   - .sh ファイル: 先頭コメントから description を抽出
#   - .md ファイル: 最初の > ブロックまたは # の次の行から抽出
#   - settings.json: Hooks のトリガー情報を抽出
#
# ==============================================================================

set -euo pipefail

# 日本語文字列処理のためのエンコーディング設定
export LC_ALL=C
export LANG=C

# ==============================================================================
# 設定
# ==============================================================================
PROJECT_ROOT="${CLAUDE_PROJECT_DIR:-$(pwd)}"
OUTPUT_FILE="$PROJECT_ROOT/docs/repository-map.yaml"
TEMP_FILE="$OUTPUT_FILE.tmp"

# 除外パターン
EXCLUDE_PATTERNS=(
    ".git"
    "node_modules"
    ".archive"
    "tmp"
    "*.log"
    "*.tmp"
    ".DS_Store"
)

# ==============================================================================
# ユーティリティ関数
# ==============================================================================

# ファイルから description を抽出（200文字まで）
extract_description() {
    local file="$1"
    local ext="${file##*.}"
    local desc=""
    local MAX_LEN=200

    case "$ext" in
        sh)
            # シェルスクリプト: 最初の # コメント行から抽出
            desc=$(grep -m1 "^# .*- " "$file" 2>/dev/null | sed 's/^# //' | head -c $MAX_LEN || echo "")
            ;;
        md)
            # Markdown: > ブロックまたは最初の段落から抽出
            desc=$(grep -m1 "^>" "$file" 2>/dev/null | sed 's/^> \*\*//' | sed 's/\*\*.*//' | head -c $MAX_LEN || echo "")
            if [[ -z "$desc" ]]; then
                desc=$(sed -n '3p' "$file" 2>/dev/null | head -c $MAX_LEN || echo "")
            fi
            ;;
        yaml|yml|json)
            # YAML/JSON: description フィールドから抽出
            desc=$(grep -m1 "description:" "$file" 2>/dev/null | sed 's/.*description: *//' | sed 's/"//g' | head -c $MAX_LEN || echo "")
            ;;
        *)
            desc=""
            ;;
    esac

    # 特殊文字をエスケープ
    echo "$desc" | sed 's/"/\\"/g' | tr -d '\n'
}

# settings.json から Hook のトリガー情報を取得
get_hook_trigger() {
    local hook_name="$1"
    local settings_file="$PROJECT_ROOT/.claude/settings.json"

    if [[ ! -f "$settings_file" ]]; then
        echo "unknown"
        return
    fi

    # jq がある場合は使用
    if command -v jq &> /dev/null; then
        local result
        result=$(jq -r --arg name "$hook_name" '
            .hooks | to_entries[] |
            .value[] |
            select(.hooks != null) |
            .hooks[] |
            select(.command | contains($name)) |
            empty
        ' "$settings_file" 2>/dev/null)

        # フォールバック: 直接マッチング
        if [[ -z "$result" ]]; then
            # PreToolUse チェック
            if jq -e --arg name "$hook_name" '.hooks.PreToolUse[]?.hooks[]? | select(.command | contains($name))' "$settings_file" &>/dev/null; then
                local matcher
                matcher=$(jq -r --arg name "$hook_name" '
                    .hooks.PreToolUse[] |
                    select(.hooks[]?.command | contains($name)) |
                    .matcher
                ' "$settings_file" 2>/dev/null | head -1)
                echo "PreToolUse:${matcher:-*}"
                return
            fi
            # PostToolUse チェック
            if jq -e --arg name "$hook_name" '.hooks.PostToolUse[]?.hooks[]? | select(.command | contains($name))' "$settings_file" &>/dev/null; then
                local matcher
                matcher=$(jq -r --arg name "$hook_name" '
                    .hooks.PostToolUse[] |
                    select(.hooks[]?.command | contains($name)) |
                    .matcher
                ' "$settings_file" 2>/dev/null | head -1)
                echo "PostToolUse:${matcher:-*}"
                return
            fi
            # SessionStart チェック
            if jq -e --arg name "$hook_name" '.hooks.SessionStart[]?.hooks[]? | select(.command | contains($name))' "$settings_file" &>/dev/null; then
                echo "SessionStart:*"
                return
            fi
            # UserPromptSubmit チェック
            if jq -e --arg name "$hook_name" '.hooks.UserPromptSubmit[]?.hooks[]? | select(.command | contains($name))' "$settings_file" &>/dev/null; then
                echo "UserPromptSubmit:*"
                return
            fi
            # SessionEnd チェック
            if jq -e --arg name "$hook_name" '.hooks.SessionEnd[]?.hooks[]? | select(.command | contains($name))' "$settings_file" &>/dev/null; then
                echo "SessionEnd:*"
                return
            fi
            # Stop チェック
            if jq -e --arg name "$hook_name" '.hooks.Stop[]?.hooks[]? | select(.command | contains($name))' "$settings_file" &>/dev/null; then
                echo "Stop:*"
                return
            fi
            # PreCompact チェック
            if jq -e --arg name "$hook_name" '.hooks.PreCompact[]?.hooks[]? | select(.command | contains($name))' "$settings_file" &>/dev/null; then
                echo "PreCompact:*"
                return
            fi
        fi
        echo "utility"
    else
        # jq がない場合は grep で簡易抽出
        local event
        event=$(grep -B10 "$hook_name" "$settings_file" 2>/dev/null | grep -oE '"(PreToolUse|PostToolUse|SessionStart|UserPromptSubmit|SessionEnd|Stop|PreCompact)"' | tr -d '"' | tail -1 || echo "")
        if [[ -n "$event" ]]; then
            echo "$event:*"
        else
            echo "utility"
        fi
    fi
}

# ファイル数をカウント（ディレクトリが存在しない場合は 0 を返す）
count_files() {
    local dir="$1"
    local pattern="$2"
    if [[ -d "$dir" ]]; then
        find "$dir" -maxdepth 1 -type f -name "$pattern" 2>/dev/null | wc -l | tr -d ' '
    else
        echo "0"
    fi
}

# ==============================================================================
# M025: system_specification 生成関数
# ==============================================================================

# CLAUDE.md から INIT フローを抽出
extract_init_flow() {
    local claude_md="$PROJECT_ROOT/CLAUDE.md"
    if [[ ! -f "$claude_md" ]]; then
        echo "      - state.md"
        echo "      - plan/project.md"
        echo "      - playbook (from state.md)"
        echo "      - docs/repository-map.yaml"
        return
    fi

    # INIT セクションから必須 Read を抽出
    grep -A50 "^## INIT" "$claude_md" 2>/dev/null | \
        grep -E "^\s+[0-9]+\. Read:" | \
        sed 's/.*Read: */      - /' | \
        head -5 || echo "      - state.md"
}

# Hook 連鎖を抽出（settings.json から同一トリガーの Hook を連鎖として出力）
extract_hook_chain() {
    local settings_file="$PROJECT_ROOT/.claude/settings.json"
    local trigger="$1"

    if [[ ! -f "$settings_file" ]] || ! command -v jq &> /dev/null; then
        echo "      - unknown"
        return
    fi

    # 指定トリガーの Hook 一覧を取得
    jq -r --arg trigger "$trigger" '
        .hooks[$trigger][]? |
        .hooks[]? |
        .command |
        split("/") | .[-1]
    ' "$settings_file" 2>/dev/null | while read -r hook; do
        [[ -n "$hook" ]] && echo "        - $hook"
    done
}

# CLAUDE.md から禁止事項を抽出
extract_behavior_rules() {
    local claude_md="$PROJECT_ROOT/CLAUDE.md"
    if [[ ! -f "$claude_md" ]]; then
        echo "      - playbook=null で Edit/Write 禁止"
        return
    fi

    # 禁止事項セクションから抽出
    grep -A20 "^## 禁止事項" "$claude_md" 2>/dev/null | \
        grep "^❌" | \
        sed 's/❌ /      - /' | \
        head -10 || echo "      - (抽出失敗)"
}

# system_specification セクションを生成
generate_system_specification() {
    cat >> "$TEMP_FILE" << 'SPEC_HEADER'

# ==============================================================================
# System Specification (M025)
# Claude の行動ルールと自己認識に必要な情報
# ==============================================================================

system_specification:
  description: "Claude の行動ルールと Hook 連鎖の Single Source of Truth"

  init_flow:
    description: "セッション開始時の必須フロー"
    required_reads:
SPEC_HEADER

    # INIT フローの必須 Read を出力
    extract_init_flow >> "$TEMP_FILE"

    cat >> "$TEMP_FILE" << 'SPEC_STEPS'
    steps:
      - "必須ファイル Read"
      - "git branch/status 取得"
      - "playbook=null → pm SubAgent"
      - "[自認] 出力"
      - "LOOP 開始"

  loop_flow:
    description: "作業ループのフロー"
    steps:
      - "subtasks を読む"
      - "executor に応じて実行"
      - "test_command で PASS/FAIL 判定"
      - "全 PASS → CRITIQUE()"
      - "PASS → 次 phase、FAIL → 修正"

  post_loop_flow:
    description: "playbook 完了後のフロー"
    steps:
      - "自動コミット"
      - "playbook アーカイブ"
      - "project.milestone 更新"
      - "/clear 推奨アナウンス"
      - "次 milestone → pm"

  hook_chains:
    description: "Hook の発火順序と連鎖関係"
SPEC_STEPS

    # Hook 連鎖を出力
    cat >> "$TEMP_FILE" << 'HOOK_CHAINS'
    PreToolUse_Edit:
      trigger: "PreToolUse:Edit"
      order:
HOOK_CHAINS
    extract_hook_chain "PreToolUse" >> "$TEMP_FILE"

    cat >> "$TEMP_FILE" << 'HOOK_CHAINS2'
    PostToolUse_Edit:
      trigger: "PostToolUse:Edit"
      order:
HOOK_CHAINS2
    extract_hook_chain "PostToolUse" >> "$TEMP_FILE"

    cat >> "$TEMP_FILE" << 'HOOK_CHAINS3'
    SessionStart:
      trigger: "SessionStart"
      order:
HOOK_CHAINS3
    extract_hook_chain "SessionStart" >> "$TEMP_FILE"

    cat >> "$TEMP_FILE" << 'BEHAVIOR'

  behavior_rules:
    description: "CLAUDE.md から抽出した行動ルール"
    core_principles:
      - "pdca_autonomy: playbook 完了 → milestone 更新 → 次 playbook 自動作成"
      - "tdd_first: done_criteria = テスト仕様、根拠必須"
      - "validation: critic は frameworks/ を参照"
      - "plan_based: playbook=null で Edit/Write → ブロック"
      - "git_branch_sync: 1 playbook = 1 branch"
    mandatory_outputs:
      - "[自認]: セッション開始時"
      - "[理解確認]: Edit/Write 前"
    prohibited_actions:
BEHAVIOR
    extract_behavior_rules >> "$TEMP_FILE"
}

# ==============================================================================
# メイン処理
# ==============================================================================

echo "Generating repository map..."

# 出力開始
cat > "$TEMP_FILE" << 'HEADER'
# Repository Map
#
# リポジトリ内の全ファイルマッピング（自動生成）
#
# 生成スクリプト: .claude/hooks/generate-repository-map.sh
# 更新タイミング: playbook 完了時
#
# このファイルは自動生成されます。手動編集は上書きされます。

HEADER

# メタ情報
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
TOTAL_FILES=$(find "$PROJECT_ROOT" -type f \
    ! -path "*/.git/*" \
    ! -path "*/.archive/*" \
    ! -path "*/node_modules/*" \
    ! -name "*.log" \
    ! -name ".DS_Store" \
    2>/dev/null | wc -l | tr -d ' ')

cat >> "$TEMP_FILE" << EOF
meta:
  generated: "$TIMESTAMP"
  generator: ".claude/hooks/generate-repository-map.sh"
  total_files: $TOTAL_FILES

EOF

# ==============================================================================
# Hooks
# ==============================================================================
echo "  Scanning hooks..."
HOOKS_DIR="$PROJECT_ROOT/.claude/hooks"
HOOKS_COUNT=$(count_files "$HOOKS_DIR" "*.sh")

cat >> "$TEMP_FILE" << EOF
hooks:
  directory: .claude/hooks/
  count: $HOOKS_COUNT
  files:
EOF

if [[ -d "$HOOKS_DIR" ]]; then
    for hook in "$HOOKS_DIR"/*.sh; do
        [[ -f "$hook" ]] || continue
        name=$(basename "$hook")
        desc=$(extract_description "$hook")
        trigger=$(get_hook_trigger "$name")

        cat >> "$TEMP_FILE" << EOF
    - name: "$name"
      trigger: "${trigger:-unknown}"
      description: "$desc"
EOF
    done
fi

# ==============================================================================
# SubAgents
# ==============================================================================
echo "  Scanning agents..."
AGENTS_DIR="$PROJECT_ROOT/.claude/agents"
AGENTS_COUNT=$(count_files "$AGENTS_DIR" "*.md")

cat >> "$TEMP_FILE" << EOF

agents:
  directory: .claude/agents/
  count: $AGENTS_COUNT
  files:
EOF

if [[ -d "$AGENTS_DIR" ]]; then
    for agent in "$AGENTS_DIR"/*.md; do
        [[ -f "$agent" ]] || continue
        name=$(basename "$agent" .md)
        [[ "$name" == "CLAUDE" ]] && continue  # CLAUDE.md は除外
        desc=$(extract_description "$agent")

        cat >> "$TEMP_FILE" << EOF
    - name: "$name"
      description: "$desc"
EOF
    done
fi

# ==============================================================================
# Skills
# ==============================================================================
echo "  Scanning skills..."
SKILLS_DIR="$PROJECT_ROOT/.claude/skills"
SKILLS_COUNT=0

cat >> "$TEMP_FILE" << EOF

skills:
  directory: .claude/skills/
EOF

if [[ -d "$SKILLS_DIR" ]]; then
    skills_list=()
    for skill_dir in "$SKILLS_DIR"/*/; do
        [[ -d "$skill_dir" ]] || continue
        skill_name=$(basename "$skill_dir")
        skill_file=""

        # SKILL.md または skill.md を探す
        if [[ -f "$skill_dir/SKILL.md" ]]; then
            skill_file="$skill_dir/SKILL.md"
        elif [[ -f "$skill_dir/skill.md" ]]; then
            skill_file="$skill_dir/skill.md"
        fi

        if [[ -n "$skill_file" ]]; then
            ((SKILLS_COUNT++))
            desc=$(extract_description "$skill_file")
            skills_list+=("    - name: \"$skill_name\"\n      description: \"$desc\"")
        fi
    done

    echo "  count: $SKILLS_COUNT" >> "$TEMP_FILE"
    echo "  files:" >> "$TEMP_FILE"
    for item in "${skills_list[@]}"; do
        echo -e "$item" >> "$TEMP_FILE"
    done
fi

# ==============================================================================
# Frameworks
# ==============================================================================
echo "  Scanning frameworks..."
FRAMEWORKS_DIR="$PROJECT_ROOT/.claude/rules/frameworks"
FRAMEWORKS_COUNT=0

cat >> "$TEMP_FILE" << EOF

frameworks:
  directory: .claude/rules/frameworks/
EOF

if [[ -d "$FRAMEWORKS_DIR" ]]; then
    FRAMEWORKS_COUNT=$(count_files "$FRAMEWORKS_DIR" "*.md")
    echo "  count: $FRAMEWORKS_COUNT" >> "$TEMP_FILE"
    echo "  files:" >> "$TEMP_FILE"

    for fw in "$FRAMEWORKS_DIR"/*.md; do
        [[ -f "$fw" ]] || continue
        name=$(basename "$fw" .md)
        [[ "$name" == "CLAUDE" ]] && continue
        desc=$(extract_description "$fw")

        cat >> "$TEMP_FILE" << EOF
    - name: "$name"
      description: "$desc"
EOF
    done
else
    echo "  count: 0" >> "$TEMP_FILE"
    echo "  files: []" >> "$TEMP_FILE"
fi

# ==============================================================================
# Commands
# ==============================================================================
echo "  Scanning commands..."
COMMANDS_DIR="$PROJECT_ROOT/.claude/commands"
COMMANDS_COUNT=$(count_files "$COMMANDS_DIR" "*.md")

cat >> "$TEMP_FILE" << EOF

commands:
  directory: .claude/commands/
  count: $COMMANDS_COUNT
  files:
EOF

if [[ -d "$COMMANDS_DIR" ]]; then
    for cmd in "$COMMANDS_DIR"/*.md; do
        [[ -f "$cmd" ]] || continue
        name=$(basename "$cmd" .md)
        desc=$(extract_description "$cmd")

        cat >> "$TEMP_FILE" << EOF
    - name: "/$name"
      description: "$desc"
EOF
    done
fi

# ==============================================================================
# Docs
# ==============================================================================
echo "  Scanning docs..."
DOCS_DIR="$PROJECT_ROOT/docs"
DOCS_COUNT=$(count_files "$DOCS_DIR" "*.md")
DOCS_YAML_COUNT=$(count_files "$DOCS_DIR" "*.yaml")
DOCS_TOTAL=$((DOCS_COUNT + DOCS_YAML_COUNT))

cat >> "$TEMP_FILE" << EOF

docs:
  directory: docs/
  count: $DOCS_TOTAL
  files:
EOF

if [[ -d "$DOCS_DIR" ]]; then
    for doc in "$DOCS_DIR"/*.md "$DOCS_DIR"/*.yaml; do
        [[ -f "$doc" ]] || continue
        name=$(basename "$doc")
        [[ "$name" == "repository-map.yaml" ]] && continue  # 自身は除外
        desc=$(extract_description "$doc")

        cat >> "$TEMP_FILE" << EOF
    - name: "$name"
      description: "$desc"
EOF
    done
fi

# ==============================================================================
# Plan
# ==============================================================================
echo "  Scanning plan..."
PLAN_DIR="$PROJECT_ROOT/plan"

cat >> "$TEMP_FILE" << EOF

plan:
  directory: plan/
  subdirectories:
    active:
      description: "進行中の playbook"
EOF

# plan/active が存在しない場合は 0 を返す
if [[ -d "$PLAN_DIR/active" ]]; then
    ACTIVE_COUNT=$(find "$PLAN_DIR/active" -maxdepth 1 -name "playbook-*.md" 2>/dev/null | wc -l | tr -d ' ')
else
    ACTIVE_COUNT=0
fi
echo "      count: $ACTIVE_COUNT" >> "$TEMP_FILE"

cat >> "$TEMP_FILE" << EOF
    archive:
      description: "完了した playbook のアーカイブ"
EOF

# plan/archive が存在しない場合は 0 を返す
if [[ -d "$PLAN_DIR/archive" ]]; then
    ARCHIVE_COUNT=$(find "$PLAN_DIR/archive" -maxdepth 1 -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
else
    ARCHIVE_COUNT=0
fi
echo "      count: $ARCHIVE_COUNT" >> "$TEMP_FILE"

cat >> "$TEMP_FILE" << EOF
    template:
      description: "playbook テンプレート"
EOF

TEMPLATE_COUNT=$(count_files "$PLAN_DIR/template" "*.md")
echo "      count: $TEMPLATE_COUNT" >> "$TEMP_FILE"

# ==============================================================================
# Root Files
# ==============================================================================
echo "  Scanning root files..."

cat >> "$TEMP_FILE" << EOF

root:
  description: "ルートディレクトリの主要ファイル"
  files:
EOF

for root_file in CLAUDE.md AGENTS.md README.md state.md .gitignore .mcp.json; do
    if [[ -f "$PROJECT_ROOT/$root_file" ]]; then
        desc=$(extract_description "$PROJECT_ROOT/$root_file")
        cat >> "$TEMP_FILE" << EOF
    - name: "$root_file"
      description: "$desc"
EOF
    fi
done

# ==============================================================================
# 統計サマリー
# ==============================================================================
cat >> "$TEMP_FILE" << EOF

summary:
  hooks: $HOOKS_COUNT
  agents: $AGENTS_COUNT
  skills: $SKILLS_COUNT
  frameworks: $FRAMEWORKS_COUNT
  commands: $COMMANDS_COUNT
  docs: $DOCS_TOTAL
  plan_active: $ACTIVE_COUNT
  plan_archive: $ARCHIVE_COUNT
  plan_template: $TEMPLATE_COUNT
  total: $TOTAL_FILES
EOF

# ==============================================================================
# System Specification (M025)
# ==============================================================================
echo "  Generating system specification..."
generate_system_specification

cat >> "$TEMP_FILE" << EOF

# ==============================================================================
# 変更履歴
# ==============================================================================
changelog:
  - date: "$TIMESTAMP"
    action: "auto-generated"
    description: "playbook 完了時に自動生成"
EOF

# 出力ファイルを更新
mv "$TEMP_FILE" "$OUTPUT_FILE"

echo "Repository map generated: $OUTPUT_FILE"
echo "  Total files: $TOTAL_FILES"
echo "  Hooks: $HOOKS_COUNT | Agents: $AGENTS_COUNT | Skills: $SKILLS_COUNT"
