#!/bin/bash
# ==============================================================================
# check-file-dependencies.sh - ファイル依存関係チェック Hook
# ==============================================================================
# トリガー: PreToolUse(Edit/Write)
# 目的: 編集対象ファイルの依存先を表示し、関連ファイルの更新漏れを防ぐ
#
# 動作:
#   1. 編集対象ファイルを取得
#   2. file-dependencies.yaml から依存先を検索
#   3. 依存先がある場合、WARNING を表示
#   4. ブロックはしない（情報提供のみ）
# ==============================================================================

set -euo pipefail

# 共通ライブラリを読み込み
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
if [ -f "$SCRIPT_DIR/lib/common.sh" ]; then
    source "$SCRIPT_DIR/lib/common.sh"
else
    # フォールバック: 共通ライブラリがない場合の最小定義
    WORKSPACE_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
    RED='\033[0;31m'
    YELLOW='\033[1;33m'
    CYAN='\033[0;36m'
    NC='\033[0m'
fi

FILE_DEPS="${FILE_DEPS:-$WORKSPACE_ROOT/.claude/file-dependencies.yaml}"

# ------------------------------------------------------------------------------
# メイン処理
# ------------------------------------------------------------------------------

# stdin から JSON を読み込み
INPUT=$(cat)

# tool_input.file_path を取得
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null)

if [ -z "$FILE_PATH" ]; then
    # file_path がない場合はスキップ
    exit 0
fi

# 相対パスに変換
REL_PATH="${FILE_PATH#$WORKSPACE_ROOT/}"

# 依存関係ファイルが存在しない場合はスキップ
if [ ! -f "$FILE_DEPS" ]; then
    exit 0
fi

# ------------------------------------------------------------------------------
# 依存先を検索
# ------------------------------------------------------------------------------

# file-dependencies.yaml から該当ファイルの affects を検索
# YAML パース（簡易版: grep + sed）
find_dependencies() {
    local search_file="$1"
    local found=0
    local in_affects=0
    local affects_items=""
    local reason_line=""
    local check_level=""

    while IFS= read -r line; do
        # セクション開始を検出（"ファイルパス": の形式）
        if echo "$line" | grep -qE "^\s+\"[^\"]+\":$"; then
            # 前のセクションが対象ファイルだった場合、結果を出力
            if [ $found -eq 1 ]; then
                echo "AFFECTS:$affects_items"
                echo "REASON:$reason_line"
                echo "LEVEL:$check_level"
                return 0
            fi

            # 新しいセクションが対象ファイルかチェック
            local section_file=$(echo "$line" | sed 's/.*"\([^"]*\)".*/\1/')
            if [ "$section_file" = "$search_file" ]; then
                found=1
            else
                # ワイルドカードマッチング
                case "$search_file" in
                    ${section_file})
                        found=1
                        ;;
                esac
            fi
            affects_items=""
            reason_line=""
            check_level=""
            in_affects=0
            continue
        fi

        # セクション内の属性を取得
        if [ $found -eq 1 ]; then
            # affects: を検出（値がインライン or 次行配列）
            if echo "$line" | grep -q "affects:"; then
                # インライン配列 [a, b, c] の場合
                local inline_val=$(echo "$line" | sed 's/.*affects:\s*//' | tr -d '[]')
                if [ -n "$inline_val" ]; then
                    affects_items="$inline_val"
                    in_affects=0
                else
                    # 次行から配列が始まる
                    in_affects=1
                fi
            # 配列項目 "- item" を収集
            elif [ $in_affects -eq 1 ] && echo "$line" | grep -qE "^\s+-\s"; then
                local item=$(echo "$line" | sed 's/^[[:space:]]*-[[:space:]]*//' | tr -d '"')
                if [ -n "$affects_items" ]; then
                    affects_items="$affects_items, $item"
                else
                    affects_items="$item"
                fi
            # 他の属性が来たら affects 収集終了
            elif echo "$line" | grep -qE "^\s+[a-z_]+:"; then
                in_affects=0
                if echo "$line" | grep -q "reason:"; then
                    # reason: "value" から value を抽出（POSIX 互換）
                    reason_line=$(echo "$line" | sed 's/^[[:space:]]*reason:[[:space:]]*"//' | sed 's/"[[:space:]]*$//')
                fi
                if echo "$line" | grep -q "check_level:"; then
                    check_level=$(echo "$line" | sed 's/.*check_level:\s*//')
                fi
            fi
        fi
    done < "$FILE_DEPS"

    # 最後のセクションが対象だった場合
    if [ $found -eq 1 ]; then
        echo "AFFECTS:$affects_items"
        echo "REASON:$reason_line"
        echo "LEVEL:$check_level"
        return 0
    fi

    return 1
}

# パターンマッチングで依存先を検索
search_dependencies() {
    local file="$1"

    # 完全一致で検索
    local result=$(find_dependencies "$file")
    if [ -n "$result" ]; then
        echo "$result"
        return 0
    fi

    # playbook-*.md パターンでマッチ
    if [[ "$file" == plan/playbook-*.md ]]; then
        result=$(find_dependencies "plan/playbook-*.md")
        if [ -n "$result" ]; then
            echo "$result"
            return 0
        fi
    fi

    # hooks/*.sh パターンでマッチ
    if [[ "$file" == .claude/hooks/*.sh ]]; then
        result=$(find_dependencies ".claude/hooks/*.sh")
        if [ -n "$result" ]; then
            echo "$result"
            return 0
        fi
    fi

    return 1
}

# ------------------------------------------------------------------------------
# 依存先を表示
# ------------------------------------------------------------------------------

DEPS_INFO=$(search_dependencies "$REL_PATH" 2>/dev/null || true)

if [ -n "$DEPS_INFO" ]; then
    AFFECTS=$(echo "$DEPS_INFO" | grep "^AFFECTS:" | sed 's/^AFFECTS://' | tr -s ' ' | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
    REASON=$(echo "$DEPS_INFO" | grep "^REASON:" | sed 's/^REASON://')
    LEVEL=$(echo "$DEPS_INFO" | grep "^LEVEL:" | sed 's/^LEVEL://' | tr -d ' ')

    # affects が空でない場合のみ表示
    if [ -n "$AFFECTS" ] && [ "$AFFECTS" != "[]" ]; then
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo -e "  ${CYAN}[依存関係]${NC} $REL_PATH"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "  このファイルを変更すると、以下も確認が必要です:"
        echo ""

        # カンマ区切りを改行に変換して表示
        echo "$AFFECTS" | tr ',' '\n' | while read -r dep; do
            dep=$(echo "$dep" | tr -d ' ')
            if [ -n "$dep" ]; then
                echo -e "    ${YELLOW}→${NC} $dep"
            fi
        done

        echo ""
        if [ -n "$REASON" ]; then
            echo -e "  理由: $REASON"
        fi

        case "$LEVEL" in
            required)
                echo -e "  ${RED}[必須]${NC} これらのファイルの更新を忘れないでください"
                ;;
            recommended)
                echo -e "  ${YELLOW}[推奨]${NC} これらのファイルも確認してください"
                ;;
            optional)
                echo -e "  [任意] 必要に応じて確認してください"
                ;;
        esac
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    fi
fi

# 常に PASS（情報提供のみ、ブロックしない）
exit 0
