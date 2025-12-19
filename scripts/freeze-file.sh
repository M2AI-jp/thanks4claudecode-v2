#!/bin/bash
# ============================================================
# freeze-file.sh - ファイルを FREEZE_QUEUE に追加
# ============================================================
# 目的: 削除予定ファイルを凍結キューに追加し、一定期間後の安全な削除を可能にする
#
# 使用方法:
#   bash scripts/freeze-file.sh <file_path> [--reason "理由"]
#   bash scripts/freeze-file.sh <file_path> --dry-run
#   bash scripts/freeze-file.sh --help
#
# オプション:
#   --reason "理由"  : 凍結理由を指定（デフォルト: "deprecated"）
#   --dry-run        : 実際の変更なしで動作確認
#   --help           : ヘルプを表示
#
# 動作:
#   1. 指定されたファイルが存在するか確認
#   2. state.md の FREEZE_QUEUE セクションにエントリを追加
#   3. freeze_date として現在日付を記録
#
# 関連:
#   - delete-frozen.sh: 凍結期間が過ぎたファイルを削除
#   - docs/freeze-then-delete.md: プロセス説明
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

# デフォルト値
DRY_RUN=false
REASON="deprecated"
FILE_PATH=""

# ============================================================
# ヘルプ表示
# ============================================================
show_help() {
    cat << 'EOF'
freeze-file.sh - ファイルを FREEZE_QUEUE に追加

使用方法:
  bash scripts/freeze-file.sh <file_path> [options]

引数:
  <file_path>        凍結するファイルのパス

オプション:
  --reason "理由"    凍結理由を指定（デフォルト: "deprecated"）
  --dry-run          実際の変更なしで動作確認
  --help             このヘルプを表示

例:
  bash scripts/freeze-file.sh old-script.sh --reason "replaced by new-script.sh"
  bash scripts/freeze-file.sh deprecated.md --dry-run

FREEZE_QUEUE への追加:
  state.md の FREEZE_QUEUE セクションに以下の形式でエントリが追加されます:
  - { path: "path/to/file", freeze_date: "YYYY-MM-DD", reason: "理由" }

凍結期間（デフォルト 7 日）が経過したら、delete-frozen.sh で削除できます。
EOF
}

# ============================================================
# 引数パース
# ============================================================
while [[ $# -gt 0 ]]; do
    case "$1" in
        --help)
            show_help
            exit 0
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --reason)
            if [[ -n "${2:-}" ]]; then
                REASON="$2"
                shift 2
            else
                echo -e "${RED}ERROR${NC}: --reason requires an argument" >&2
                exit 1
            fi
            ;;
        -*)
            echo -e "${RED}ERROR${NC}: Unknown option: $1" >&2
            show_help
            exit 1
            ;;
        *)
            if [[ -z "$FILE_PATH" ]]; then
                FILE_PATH="$1"
            else
                echo -e "${RED}ERROR${NC}: Multiple file paths specified" >&2
                exit 1
            fi
            shift
            ;;
    esac
done

# ============================================================
# バリデーション
# ============================================================

# ファイルパスが指定されているか
if [[ -z "$FILE_PATH" ]]; then
    echo -e "${RED}ERROR${NC}: File path is required" >&2
    show_help
    exit 1
fi

# state.md が存在するか
if [[ ! -f "$STATE_FILE" ]]; then
    echo -e "${RED}ERROR${NC}: state.md not found at $STATE_FILE" >&2
    exit 1
fi

# FREEZE_QUEUE セクションが存在するか
if ! grep -q 'FREEZE_QUEUE' "$STATE_FILE"; then
    echo -e "${RED}ERROR${NC}: FREEZE_QUEUE section not found in state.md" >&2
    exit 1
fi

# 指定されたファイルが存在するか（警告のみ、存在しなくても続行可能）
if [[ ! -e "$PROJECT_ROOT/$FILE_PATH" ]] && [[ ! -e "$FILE_PATH" ]]; then
    echo -e "${YELLOW}WARNING${NC}: File does not exist: $FILE_PATH" >&2
    echo -e "${YELLOW}WARNING${NC}: Proceeding anyway (file may have been deleted or path is relative)" >&2
fi

# 既にキューに存在するか確認
if grep -q "path: \"$FILE_PATH\"" "$STATE_FILE" 2>/dev/null; then
    echo -e "${YELLOW}WARNING${NC}: File already in FREEZE_QUEUE: $FILE_PATH" >&2
    exit 0
fi

# ============================================================
# メイン処理
# ============================================================

TODAY=$(date '+%Y-%m-%d')
NEW_ENTRY="  - { path: \"$FILE_PATH\", freeze_date: \"$TODAY\", reason: \"$REASON\" }"

if [[ "$DRY_RUN" == "true" ]]; then
    echo -e "${GREEN}[DRY-RUN]${NC} Would add to FREEZE_QUEUE:"
    echo "$NEW_ENTRY"
    echo ""
    echo "File: $FILE_PATH"
    echo "Freeze date: $TODAY"
    echo "Reason: $REASON"
    exit 0
fi

# state.md の FREEZE_QUEUE セクションを更新
# queue: [] を queue:\n  - { ... } に変更、または既存のエントリの後に追加

if grep -q "^queue: \[\]" "$STATE_FILE"; then
    # 空のキューの場合
    if [[ "$(uname)" == "Darwin" ]]; then
        sed -i '' "s/^queue: \[\]/queue:\n$NEW_ENTRY/" "$STATE_FILE"
    else
        sed -i "s/^queue: \[\]/queue:\n$NEW_ENTRY/" "$STATE_FILE"
    fi
else
    # 既存エントリがある場合、freeze_period_days: の前に追加
    if [[ "$(uname)" == "Darwin" ]]; then
        sed -i '' "/^freeze_period_days:/i\\
$NEW_ENTRY
" "$STATE_FILE"
    else
        sed -i "/^freeze_period_days:/i $NEW_ENTRY" "$STATE_FILE"
    fi
fi

echo -e "${GREEN}SUCCESS${NC}: Added to FREEZE_QUEUE"
echo "  File: $FILE_PATH"
echo "  Freeze date: $TODAY"
echo "  Reason: $REASON"
echo ""
echo "Run 'bash scripts/delete-frozen.sh --dry-run' to check deletable files."

exit 0
