#!/bin/bash
#
# check-state-update.sh
# git commit 前に state.md の更新をチェックする Hook
#
# 動作:
#   - session: discussion → 常に OK
#   - session: task → state.md が staged されているかチェック
#

set -e

STATE_FILE="state.md"

# state.md が存在しない場合はスキップ
if [ ! -f "$STATE_FILE" ]; then
    exit 0
fi

# session を取得
SESSION=$(grep "session:" "$STATE_FILE" | head -1 | sed 's/.*session: *//' | sed 's/ *#.*//')

# discussion なら常に OK
if [ "$SESSION" = "discussion" ]; then
    exit 0
fi

# task の場合、state.md が staged されているかチェック
if [ "$SESSION" = "task" ]; then
    if ! git diff --cached --name-only 2>/dev/null | grep -q "state.md"; then
        echo "" >&2
        echo "========================================" >&2
        echo " ERROR: state.md が更新されていません" >&2
        echo "========================================" >&2
        echo "" >&2
        echo " session: task なので、commit 前に" >&2
        echo " state.md を更新する必要があります。" >&2
        echo "" >&2
        echo " 対処法:" >&2
        echo "   1. state.md を更新してステージング" >&2
        echo "   2. または session を discussion に変更" >&2
        echo "" >&2
        exit 2
    fi
fi

exit 0
