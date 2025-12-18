#!/bin/bash
# pre-bash-check.sh - Bash コマンド実行前のチェック
#
# PreToolUse(Bash) フックとして実行される。
# 1. 保護ファイルへの書き込みコマンドをブロック
# 2. git commit コマンドの場合は整合性チェックを実行
#
# 注意: 変数経由のファイルアクセス（export F=file && cat > "$F"）は
#       検出困難なため、HARD_BLOCK ファイルへの直接参照のみチェックする。
#       完全な保護は check-protected-edit.sh（Edit/Write）側で担保。

set -e

# 色定義
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# ============================================================
# M079: コア契約は回避不可（HARD_BLOCK + playbook チェック維持）
# ============================================================
STATE_FILE="state.md"
SECURITY=""
PLAYBOOK=""
if [ -f "$STATE_FILE" ]; then
    SECURITY=$(grep -A3 "^## config" "$STATE_FILE" 2>/dev/null | grep "security:" | head -1 | sed 's/security: *//' | tr -d ' ')
    PLAYBOOK=$(grep -A6 "^## playbook" "$STATE_FILE" 2>/dev/null | grep "^active:" | head -1 | sed 's/active: *//' | sed 's/ *#.*//' | tr -d ' ')
fi
# 特権モードでも HARD_BLOCK と playbook チェックは維持（コア契約）

# stdin から JSON を読み込む
INPUT=$(cat)

# jq がない場合はスキップ
if ! command -v jq &> /dev/null; then
    exit 0
fi

# tool_input.command を取得
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // ""')

# === HARD_BLOCK ファイルへのアクセス検出 ===
# これらのファイルは security_mode に関係なく常に保護
# CONTEXT.md は .archive に退避済み（開発履歴）
HARD_BLOCK_FILES=(
    "CLAUDE.md"
    ".claude/protected-files.txt"
    ".claude/.session-init/consent"
    ".claude/.session-init/pending"
)

# BLOCK ファイル（strict モードでのみ保護）
BLOCK_FILES=(
    ".claude/settings.json"
    ".claude/hooks/"
    "plan/template/"
)

# 書き込み・削除系パターン
WRITE_PATTERNS=(
    "sed -i"
    "sed -i ''"
    "perl -i"
    "perl -pi"
    "echo.*>"
    "cat.*>"
    "printf.*>"
    "tee "
    " > "
    " >> "
    "rm "
    "rm -f"
    "rm -rf"
)

# /dev/null への出力は許可（誤検出防止）
if [[ "$COMMAND" == *"> /dev/null"* ]] || [[ "$COMMAND" == *">/dev/null"* ]]; then
    # /dev/null 以外の書き込みがないかチェック
    COMMAND_WITHOUT_NULL=$(echo "$COMMAND" | sed 's/>[[:space:]]*\/dev\/null//g; s/2>&1//g')
    COMMAND="$COMMAND_WITHOUT_NULL"
fi

# HARD_BLOCK チェック（常時ブロック）
for protected in "${HARD_BLOCK_FILES[@]}"; do
    if [[ "$COMMAND" == *"$protected"* ]]; then
        for write_pattern in "${WRITE_PATTERNS[@]}"; do
            if [[ "$COMMAND" == *$write_pattern* ]]; then
                echo "========================================" >&2
                echo -e "${RED}[HARD_BLOCK]${NC} Bash による絶対守護ファイルへの書き込み" >&2
                echo "========================================" >&2
                echo "" >&2
                echo "コマンド: $COMMAND" >&2
                echo "" >&2
                echo "検出されたパターン:" >&2
                echo "  - 保護ファイル: $protected" >&2
                echo "  - 書き込み操作: $write_pattern" >&2
                echo "" >&2
                echo "HARD_BLOCK ファイルは security_mode に関係なく" >&2
                echo "常に保護されています。" >&2
                echo "" >&2
                echo "========================================" >&2
                exit 2
            fi
        done
    fi
done

# security.mode を取得（strict | trusted）
STATE_FILE="state.md"
SECURITY_MODE="strict"
if [ -f "$STATE_FILE" ]; then
    MODE_LINE=$(grep -A 1 "^## security" "$STATE_FILE" 2>/dev/null | grep "mode:" | head -1 || echo "")
    if [[ "$MODE_LINE" =~ mode:\ *([a-z]+) ]]; then
        SECURITY_MODE="${BASH_REMATCH[1]}"
    fi
fi

# BLOCK チェック（strict モードのみブロック）
if [ "$SECURITY_MODE" = "strict" ]; then
    for protected in "${BLOCK_FILES[@]}"; do
        if [[ "$COMMAND" == *"$protected"* ]]; then
            for write_pattern in "${WRITE_PATTERNS[@]}"; do
                if [[ "$COMMAND" == *$write_pattern* ]]; then
                    echo "========================================" >&2
                    echo -e "${RED}[BLOCK]${NC} Bash による保護ファイルへの書き込み" >&2
                    echo "========================================" >&2
                    echo "" >&2
                    echo "コマンド: $COMMAND" >&2
                    echo "モード: strict" >&2
                    echo "" >&2
                    echo "検出されたパターン:" >&2
                    echo "  - 保護ファイル: $protected" >&2
                    echo "  - 書き込み操作: $write_pattern" >&2
                    echo "" >&2
                    echo "対処法:" >&2
                    echo "  1. Edit ツールを使用（フック検証あり）" >&2
                    echo "  2. state.md の security.mode を trusted に変更" >&2
                    echo "" >&2
                    echo "========================================" >&2
                    exit 2
                fi
            done
        fi
    done
fi

# === M079: playbook=null で変更系コマンドをブロック ===
# CLAUDE.md Core Contract: "Playbook Gate" - playbook なしでの変更は禁止
if [ -z "$PLAYBOOK" ] || [ "$PLAYBOOK" = "null" ]; then
    # 変更系コマンドのパターン
    MUTATION_PATTERNS='cat[[:space:]]+.*>|tee[[:space:]]|sed[[:space:]]+-i|git[[:space:]]+add|git[[:space:]]+commit|mkdir[[:space:]]|touch[[:space:]]|mv[[:space:]]|cp[[:space:]]|rm[[:space:]]'

    if [[ "$COMMAND" =~ $MUTATION_PATTERNS ]]; then
        echo "========================================" >&2
        echo -e "${RED}[BLOCK]${NC} playbook=null で変更系 Bash をブロック" >&2
        echo "========================================" >&2
        echo "" >&2
        echo "コマンド: $COMMAND" >&2
        echo "" >&2
        echo "CLAUDE.md Core Contract により、playbook なしでの" >&2
        echo "変更系コマンドは禁止されています。" >&2
        echo "" >&2
        echo "対処法:" >&2
        echo "  1. pm を呼び出して playbook を作成:" >&2
        echo "     Task(subagent_type='pm', prompt='playbook を作成')" >&2
        echo "  2. または /playbook-init を実行" >&2
        echo "" >&2
        echo "========================================" >&2
        exit 2
    fi
fi

# === git commit チェック ===
# 注意: "commit" を含む文字列（コメント等）で誤発動しないよう、パターンを厳密に
# パターン: "git commit" で始まる、または "&&" や ";" の後に "git commit" がある
GIT_COMMIT_PATTERN='^git[[:space:]]+commit|&&[[:space:]]*git[[:space:]]+commit|;[[:space:]]*git[[:space:]]+commit'
if [[ "$COMMAND" =~ $GIT_COMMIT_PATTERN ]]; then
    # 回帰テストを実行（stdout 出力: stderr は Claude Code にエラーと解釈される）
    if [ -f ".claude/tests/regression-test.sh" ]; then
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "  🧪 回帰テスト実行中..."
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        if ! bash .claude/tests/regression-test.sh; then
            echo ""
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo -e "  ${RED}❌ 回帰テスト失敗 - コミットをブロック${NC}"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo ""
            echo "回帰テストが失敗しました。"
            echo "問題を修正してから再度コミットしてください。"
            echo ""
            exit 2
        fi
        echo ""
        echo -e "  ✅ 回帰テスト PASS"
        echo ""
    fi

    # 整合性チェックを実行
    bash .claude/hooks/check-coherence.sh

    # state 更新チェックを実行
    bash .claude/hooks/check-state-update.sh
fi

# 通常は通過
exit 0
