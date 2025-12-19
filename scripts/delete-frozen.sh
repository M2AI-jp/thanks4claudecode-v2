#!/bin/bash
# ============================================================
# delete-frozen.sh - 凍結期間が過ぎたファイルを削除
# ============================================================
# 目的: FREEZE_QUEUE から凍結期間が経過したファイルを安全に削除し、DELETE_LOG に記録
#
# 使用方法:
#   bash scripts/delete-frozen.sh [--days N] [--dry-run]
#   bash scripts/delete-frozen.sh --help
#
# オプション:
#   --days N   : 凍結期間を指定（デフォルト: state.md の freeze_period_days、なければ 7）
#   --dry-run  : 実際の削除なしで動作確認
#   --help     : ヘルプを表示
#
# 動作:
#   1. state.md の FREEZE_QUEUE から全エントリを取得
#   2. freeze_date から経過日数を計算
#   3. 凍結期間を超えたファイルを削除
#   4. DELETE_LOG に削除記録を追加
#   5. FREEZE_QUEUE からエントリを削除
#
# 関連:
#   - freeze-file.sh: ファイルを FREEZE_QUEUE に追加
#   - docs/freeze-then-delete.md: プロセス説明
# ============================================================

set -uo pipefail

# 色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# プロジェクトルート
PROJECT_ROOT="${CLAUDE_PROJECT_DIR:-$(pwd)}"
STATE_FILE="$PROJECT_ROOT/state.md"

# デフォルト値
DRY_RUN=false
FREEZE_DAYS=""

# ============================================================
# ヘルプ表示
# ============================================================
show_help() {
    cat << 'EOF'
delete-frozen.sh - 凍結期間が過ぎたファイルを削除

使用方法:
  bash scripts/delete-frozen.sh [options]

オプション:
  --days N     凍結期間を指定（デフォルト: state.md の freeze_period_days、なければ 7）
  --dry-run    実際の削除なしで動作確認
  --help       このヘルプを表示

例:
  bash scripts/delete-frozen.sh              # 凍結期間経過ファイルを削除
  bash scripts/delete-frozen.sh --dry-run    # 削除対象の確認のみ
  bash scripts/delete-frozen.sh --days 14    # 14日経過したファイルを削除

DELETE_LOG への記録:
  削除されたファイルは state.md の DELETE_LOG セクションに以下の形式で記録されます:
  - { path: "path/to/file", deleted_date: "YYYY-MM-DD", reason: "理由" }
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
        --days)
            if [[ -n "${2:-}" ]] && [[ "$2" =~ ^[0-9]+$ ]]; then
                FREEZE_DAYS="$2"
                shift 2
            else
                echo -e "${RED}ERROR${NC}: --days requires a numeric argument" >&2
                exit 1
            fi
            ;;
        -*)
            echo -e "${RED}ERROR${NC}: Unknown option: $1" >&2
            show_help
            exit 1
            ;;
        *)
            echo -e "${RED}ERROR${NC}: Unexpected argument: $1" >&2
            show_help
            exit 1
            ;;
    esac
done

# ============================================================
# バリデーション
# ============================================================

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

# DELETE_LOG セクションが存在するか
if ! grep -q 'DELETE_LOG' "$STATE_FILE"; then
    echo -e "${RED}ERROR${NC}: DELETE_LOG section not found in state.md" >&2
    exit 1
fi

# 凍結期間の決定
if [[ -z "$FREEZE_DAYS" ]]; then
    # state.md から freeze_period_days を取得
    FREEZE_DAYS=$(grep 'freeze_period_days:' "$STATE_FILE" 2>/dev/null | head -1 | sed 's/.*: *//' | tr -d ' ')
    if [[ -z "$FREEZE_DAYS" ]] || ! [[ "$FREEZE_DAYS" =~ ^[0-9]+$ ]]; then
        FREEZE_DAYS=7
    fi
fi

# ============================================================
# ユーティリティ関数
# ============================================================

# 日付差分を計算（日数）
days_since() {
    local freeze_date="$1"
    local today=$(date '+%Y-%m-%d')

    # macOS と Linux で異なる date コマンドに対応
    if [[ "$(uname)" == "Darwin" ]]; then
        local freeze_ts=$(date -j -f '%Y-%m-%d' "$freeze_date" '+%s' 2>/dev/null)
        local today_ts=$(date -j -f '%Y-%m-%d' "$today" '+%s' 2>/dev/null)
    else
        local freeze_ts=$(date -d "$freeze_date" '+%s' 2>/dev/null)
        local today_ts=$(date -d "$today" '+%s' 2>/dev/null)
    fi

    if [[ -z "$freeze_ts" ]] || [[ -z "$today_ts" ]]; then
        echo "0"
        return
    fi

    local diff_seconds=$((today_ts - freeze_ts))
    local diff_days=$((diff_seconds / 86400))
    echo "$diff_days"
}

# FREEZE_QUEUE からエントリを抽出
get_queue_entries() {
    # FREEZE_QUEUE セクションから queue: 以降のエントリを取得
    awk '/^## FREEZE_QUEUE/,/^## / {
        if (/^  - \{ path:/) print
    }' "$STATE_FILE"
}

# ============================================================
# メイン処理
# ============================================================

echo -e "${BLUE}=== Freeze Queue Check ===${NC}"
echo "Freeze period: $FREEZE_DAYS days"
echo ""

# キューエントリを取得
QUEUE_ENTRIES=$(get_queue_entries)

if [[ -z "$QUEUE_ENTRIES" ]]; then
    echo -e "${GREEN}No files in FREEZE_QUEUE${NC}"
    exit 0
fi

# 処理カウンター
TOTAL_COUNT=0
EXPIRED_COUNT=0
DELETED_COUNT=0

# 削除対象を処理
TODAY=$(date '+%Y-%m-%d')
ENTRIES_TO_DELETE=""

while IFS= read -r entry; do
    if [[ -z "$entry" ]]; then
        continue
    fi

    TOTAL_COUNT=$((TOTAL_COUNT + 1))

    # エントリをパース
    FILE_PATH=$(echo "$entry" | sed 's/.*path: "\([^"]*\)".*/\1/')
    FREEZE_DATE=$(echo "$entry" | sed 's/.*freeze_date: "\([^"]*\)".*/\1/')
    REASON=$(echo "$entry" | sed 's/.*reason: "\([^"]*\)".*/\1/')

    # 経過日数を計算
    DAYS_ELAPSED=$(days_since "$FREEZE_DATE")

    echo "File: $FILE_PATH"
    echo "  Freeze date: $FREEZE_DATE ($DAYS_ELAPSED days ago)"
    echo "  Reason: $REASON"

    if [[ "$DAYS_ELAPSED" -ge "$FREEZE_DAYS" ]]; then
        EXPIRED_COUNT=$((EXPIRED_COUNT + 1))
        echo -e "  Status: ${YELLOW}EXPIRED${NC} (ready for deletion)"

        if [[ "$DRY_RUN" == "true" ]]; then
            echo -e "  Action: ${BLUE}[DRY-RUN]${NC} Would delete and log"
        else
            # ファイルを削除
            FULL_PATH="$PROJECT_ROOT/$FILE_PATH"
            if [[ -e "$FULL_PATH" ]]; then
                rm -f "$FULL_PATH"
                echo -e "  Action: ${GREEN}DELETED${NC}"
                DELETED_COUNT=$((DELETED_COUNT + 1))
            elif [[ -e "$FILE_PATH" ]]; then
                rm -f "$FILE_PATH"
                echo -e "  Action: ${GREEN}DELETED${NC}"
                DELETED_COUNT=$((DELETED_COUNT + 1))
            else
                echo -e "  Action: ${YELLOW}File not found (already deleted?)${NC}"
                DELETED_COUNT=$((DELETED_COUNT + 1))
            fi

            # DELETE_LOG にエントリを追加
            LOG_ENTRY="  - { path: \"$FILE_PATH\", deleted_date: \"$TODAY\", reason: \"$REASON\" }"

            # log: [] を log:\n  - { ... } に変更、または既存のエントリの後に追加
            if grep -q "^log: \[\]" "$STATE_FILE"; then
                if [[ "$(uname)" == "Darwin" ]]; then
                    sed -i '' "s/^log: \[\]/log:\n$LOG_ENTRY/" "$STATE_FILE"
                else
                    sed -i "s/^log: \[\]/log:\n$LOG_ENTRY/" "$STATE_FILE"
                fi
            else
                # 既存エントリがある場合、DELETE_LOG セクション内の最後のエントリの後に追加
                # 簡易実装: log: の次の行に追加
                if [[ "$(uname)" == "Darwin" ]]; then
                    sed -i '' "/^log:/a\\
$LOG_ENTRY
" "$STATE_FILE"
                else
                    sed -i "/^log:/a $LOG_ENTRY" "$STATE_FILE"
                fi
            fi

            # FREEZE_QUEUE からエントリを削除
            ESCAPED_PATH=$(echo "$FILE_PATH" | sed 's/[\/&]/\\&/g')
            if [[ "$(uname)" == "Darwin" ]]; then
                sed -i '' "/path: \"$ESCAPED_PATH\"/d" "$STATE_FILE"
            else
                sed -i "/path: \"$ESCAPED_PATH\"/d" "$STATE_FILE"
            fi

            # queue: 配列が空になったら queue: [] に戻す
            if ! grep -q "^  - { path:" "$STATE_FILE" 2>/dev/null; then
                # FREEZE_QUEUE セクション内に queue: の後にエントリがなければ queue: [] に
                if [[ "$(uname)" == "Darwin" ]]; then
                    sed -i '' 's/^queue:$/queue: []/' "$STATE_FILE"
                else
                    sed -i 's/^queue:$/queue: []/' "$STATE_FILE"
                fi
            fi
        fi
    else
        REMAINING=$((FREEZE_DAYS - DAYS_ELAPSED))
        echo -e "  Status: ${GREEN}FROZEN${NC} ($REMAINING days remaining)"
    fi
    echo ""
done <<< "$QUEUE_ENTRIES"

# サマリー
echo -e "${BLUE}=== Summary ===${NC}"
echo "Total in queue: $TOTAL_COUNT"
echo "Expired: $EXPIRED_COUNT"

if [[ "$DRY_RUN" == "true" ]]; then
    echo -e "${BLUE}[DRY-RUN]${NC} No files were actually deleted"
else
    echo "Deleted: $DELETED_COUNT"
fi

exit 0
