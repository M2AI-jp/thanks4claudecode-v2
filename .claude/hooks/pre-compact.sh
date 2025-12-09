#!/bin/bash
# ==============================================================================
# pre-compact.sh - PreCompact Hook: 一時コンテキスト保持
# ==============================================================================
#
# 目的:
#   - compact 前に重要なコンテキストを保持
#   - ユーザー意図（user-intent.md）を compact サマリーに含める
#   - セッション状態の snapshot を作成
#
# 発火: PreCompact イベント（会話履歴がコンパクト化される前）
# 入力: { "conversation_length": number, ... }
# 出力:
#   - stdout: compact に含めるべき追加コンテキスト（JSON の additionalContext）
#   - exit 0: 正常
#
# ==============================================================================

set -e

# stdin から JSON を読み込む
INPUT=$(cat)

INTENT_FILE=".claude/.session-init/user-intent.md"
STATE_FILE="state.md"
PLAYBOOK_DIR="plan"

# ==============================================================================
# 保持すべきコンテキストを収集
# ==============================================================================

# 1. ユーザー意図（user-intent.md）の最新5件
USER_INTENTS=""
if [ -f "$INTENT_FILE" ]; then
    # 最新5件のプロンプトを抽出（## [ で始まるブロック）
    USER_INTENTS=$(awk '/^## \[/{ if(count<5){ block=$0; getline; while(!/^## \[/ && !/^---$/){ block=block"\n"$0; getline } print block"\n---"; count++ } }' "$INTENT_FILE" 2>/dev/null | head -100)
fi

# 2. 現在の focus と playbook
FOCUS=""
PLAYBOOK_PATH=""
CURRENT_PHASE=""
DONE_CRITERIA=""

if [ -f "$STATE_FILE" ]; then
    FOCUS=$(grep -A5 "## focus" "$STATE_FILE" 2>/dev/null | grep "current:" | head -1 | sed 's/.*current: *//' | sed 's/ *#.*//')

    # playbook パス取得（新構造: plan/playbook-*.md）
    PLAYBOOK_PATH=$(grep -A5 "## playbook" "$STATE_FILE" 2>/dev/null | grep "active:" | head -1 | sed 's/.*active: *//' | sed 's/ *#.*//')
fi

# 3. playbook の現在 Phase と done_criteria
if [ -n "$PLAYBOOK_PATH" ] && [ "$PLAYBOOK_PATH" != "null" ] && [ -f "$PLAYBOOK_PATH" ]; then
    CURRENT_PHASE=$(grep -E "status: in_progress" "$PLAYBOOK_PATH" -B20 2>/dev/null | grep -E "^- id: p[0-9]" | tail -1 | sed 's/.*id: *//')

    # done_criteria を抽出
    DONE_CRITERIA=$(grep -A20 "status: in_progress" "$PLAYBOOK_PATH" 2>/dev/null | grep -E "^    - " | head -10 | sed 's/^    //')
fi

# ==============================================================================
# compact に含める追加コンテキストを JSON で出力
# ==============================================================================

# JSON エスケープ関数
json_escape() {
    echo -n "$1" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))' 2>/dev/null || echo '""'
}

# 追加コンテキストを構築
ADDITIONAL_CONTEXT="## 保持すべきコンテキスト（compact 前に保存）

### ユーザー意図（最新の指示）
$USER_INTENTS

### 現在の作業状態
- focus: $FOCUS
- playbook: $PLAYBOOK_PATH
- current_phase: $CURRENT_PHASE

### done_criteria（現在 Phase）
$DONE_CRITERIA

---
この情報は compact 前に自動保存されました。元の指示を忘れずに作業を続けてください。"

# JSON 出力
ESCAPED_CONTEXT=$(json_escape "$ADDITIONAL_CONTEXT")
cat << EOF
{
  "additionalContext": $ESCAPED_CONTEXT
}
EOF

exit 0
