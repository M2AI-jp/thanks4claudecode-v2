#!/bin/bash
# contract.sh - Contract Validation Core
#
# 全ての契約判定を集約。Hooks はこのスクリプトを呼び出すだけ。
#
# Usage:
#   source scripts/contract.sh
#   contract_check_edit "/path/to/file"   # Edit/Write 用
#   contract_check_bash "command string"  # Bash 用
#
# Exit codes:
#   0 - ALLOW
#   1 - WARN (許可だが警告)
#   2 - BLOCK

# set -euo pipefail  # Disabled to allow sourcing in test scripts

# ==============================================================================
# 定数定義
# ==============================================================================

STATE_FILE="${STATE_FILE:-state.md}"

# HARD_BLOCK ファイル（admin でも回避不可）
HARD_BLOCK_FILES=(
    "CLAUDE.md"
    ".claude/protected-files.txt"
    ".claude/.session-init/consent"
    ".claude/.session-init/pending"
    ".claude/hooks/init-guard.sh"
    ".claude/hooks/critic-guard.sh"
    ".claude/hooks/scope-guard.sh"
    ".claude/hooks/executor-guard.sh"
    ".claude/hooks/playbook-guard.sh"
)

# Maintenance ホワイトリスト（admin + playbook=null で許可）
MAINTENANCE_WHITELIST=(
    "state.md"
    "plan/playbook-*.md"
    "plan/archive/*"
)

# 変更系 Bash パターン
MUTATION_PATTERNS='cat[[:space:]]+.*>|tee[[:space:]]|sed[[:space:]]+-i|git[[:space:]]+add|git[[:space:]]+commit|mkdir[[:space:]]|touch[[:space:]]|mv[[:space:]]|cp[[:space:]]|rm[[:space:]]'

# ==============================================================================
# 状態取得関数
# ==============================================================================

# state.md から値を取得
get_state_value() {
    local key="$1"
    local default="${2:-}"

    if [[ ! -f "$STATE_FILE" ]]; then
        echo "$default"
        return
    fi

    case "$key" in
        playbook)
            grep -A6 "^## playbook" "$STATE_FILE" 2>/dev/null | \
                grep "^active:" | head -1 | sed 's/active: *//' | sed 's/ *#.*//' | tr -d ' '
            ;;
        security)
            grep -A3 "^## config" "$STATE_FILE" 2>/dev/null | \
                grep "security:" | head -1 | sed 's/security: *//' | tr -d ' '
            ;;
        *)
            echo "$default"
            ;;
    esac
}

# ==============================================================================
# 判定関数
# ==============================================================================

# パスが HARD_BLOCK か判定
is_hard_block() {
    local path="$1"
    local relative_path="${path#$PWD/}"

    for blocked in "${HARD_BLOCK_FILES[@]}"; do
        if [[ "$relative_path" == "$blocked" ]]; then
            return 0
        fi
    done
    return 1
}

# パスが Maintenance ホワイトリスト内か判定
is_maintenance_allowed() {
    local path="$1"
    local relative_path="${path#$PWD/}"

    for pattern in "${MAINTENANCE_WHITELIST[@]}"; do
        # shellcheck disable=SC2053
        if [[ "$relative_path" == $pattern ]]; then
            return 0
        fi
    done
    return 1
}

# パスが playbook ファイルか判定（Bootstrap 例外）
is_playbook_file() {
    local path="$1"
    [[ "$path" == *"plan/playbook-"*.md ]] || [[ "$path" == *"plan/active/playbook-"*.md ]]
}

# パスが state.md か判定
is_state_file() {
    local path="$1"
    [[ "$path" == *"state.md" ]]
}

# ==============================================================================
# メイン判定関数
# ==============================================================================

# Edit/Write の契約チェック
# Returns: 0=ALLOW, 1=WARN, 2=BLOCK
# Outputs: エラー/警告メッセージを stderr に出力
contract_check_edit() {
    local file_path="$1"
    local relative_path="${file_path#$PWD/}"

    # Fail-closed: state.md が存在しない場合
    if [[ ! -f "$STATE_FILE" ]]; then
        echo "[FAIL-CLOSED] state.md not found" >&2
        return 2
    fi

    local playbook
    local security
    playbook=$(get_state_value "playbook" "null")
    security=$(get_state_value "security" "strict")

    # 1. HARD_BLOCK チェック（最優先、admin でも回避不可）
    if is_hard_block "$file_path"; then
        cat >&2 <<EOF
========================================
  [HARD_BLOCK] 絶対守護ファイル
========================================

  ファイル: $relative_path

  このファイルは security モードに関係なく
  常に保護されています。

  編集するには直接手動で編集してください。

========================================
EOF
        return 2
    fi

    # 2. Bootstrap 例外: state.md は常に許可
    if is_state_file "$file_path"; then
        return 0
    fi

    # 3. Bootstrap 例外: playbook ファイルは常に許可
    if is_playbook_file "$file_path"; then
        return 0
    fi

    # 4. playbook=null の場合
    if [[ -z "$playbook" || "$playbook" == "null" ]]; then
        # 4a. admin モードで Maintenance ホワイトリスト内なら許可
        if [[ "$security" == "admin" ]] && is_maintenance_allowed "$file_path"; then
            echo "[ADMIN-MAINTENANCE] 許可: $relative_path" >&2
            return 0
        fi

        # 4b. それ以外はブロック
        cat >&2 <<EOF
========================================
  [BLOCK] playbook 必須
========================================

  ファイル: $relative_path
  playbook: null
  security: $security

  playbook=null の状態では編集できません。

  対処法:
    Task(subagent_type='pm', prompt='playbook を作成')

========================================
EOF
        return 2
    fi

    # 5. playbook=active なら許可
    return 0
}

# Bash コマンドの契約チェック
# Returns: 0=ALLOW, 1=WARN, 2=BLOCK
contract_check_bash() {
    local command="$1"

    # Fail-closed: state.md が存在しない場合
    if [[ ! -f "$STATE_FILE" ]]; then
        echo "[FAIL-CLOSED] state.md not found" >&2
        return 2
    fi

    local playbook
    local security
    playbook=$(get_state_value "playbook" "null")
    security=$(get_state_value "security" "strict")

    # 1. HARD_BLOCK ファイルへの書き込みチェック
    for blocked in "${HARD_BLOCK_FILES[@]}"; do
        if [[ "$command" == *"$blocked"* ]]; then
            # 書き込みパターンを含むか確認
            if [[ "$command" =~ (sed\ -i|>|tee|rm\ ) ]]; then
                cat >&2 <<EOF
========================================
  [HARD_BLOCK] Bash による絶対守護ファイルへの書き込み
========================================

  コマンド: $command
  保護ファイル: $blocked

  HARD_BLOCK ファイルは Bash からも保護されています。

========================================
EOF
                return 2
            fi
        fi
    done

    # 2. 変更系コマンドでない場合は許可
    if ! [[ "$command" =~ $MUTATION_PATTERNS ]]; then
        return 0
    fi

    # 3. playbook=null の場合
    if [[ -z "$playbook" || "$playbook" == "null" ]]; then
        # 3a. admin + Maintenance ホワイトリスト内なら許可
        if [[ "$security" == "admin" ]]; then
            # mv plan/playbook-*.md plan/archive/ パターン
            if [[ "$command" =~ mv[[:space:]]+plan/playbook-.*\.md[[:space:]]+plan/archive/ ]]; then
                echo "[ADMIN-MAINTENANCE] 許可: playbook アーカイブ" >&2
                return 0
            fi
            # mkdir plan/archive パターン
            if [[ "$command" =~ mkdir.*plan/archive ]]; then
                echo "[ADMIN-MAINTENANCE] 許可: archive ディレクトリ作成" >&2
                return 0
            fi
            # git add state.md または plan/archive
            if [[ "$command" =~ git[[:space:]]+add[[:space:]]+(state\.md|plan/archive) ]]; then
                echo "[ADMIN-MAINTENANCE] 許可: git add (maintenance)" >&2
                return 0
            fi
            # git commit (内容は別途検証が必要だが基本許可)
            if [[ "$command" =~ git[[:space:]]+commit ]]; then
                echo "[ADMIN-MAINTENANCE] 許可: git commit (maintenance)" >&2
                return 0
            fi
        fi

        # 3b. それ以外はブロック
        cat >&2 <<EOF
========================================
  [BLOCK] playbook=null で変更系 Bash をブロック
========================================

  コマンド: $command
  playbook: null
  security: $security

  playbook=null の状態では変更系コマンドは実行できません。

  対処法:
    Task(subagent_type='pm', prompt='playbook を作成')

========================================
EOF
        return 2
    fi

    # 4. playbook=active なら許可
    return 0
}

# ==============================================================================
# エクスポート（source された場合に使用可能にする）
# ==============================================================================

export -f get_state_value
export -f is_hard_block
export -f is_maintenance_allowed
export -f is_playbook_file
export -f is_state_file
export -f contract_check_edit
export -f contract_check_bash
