#!/bin/bash
# ==============================================================================
# log-subagent.sh - Subagent 発動ログ記録
# ==============================================================================
# 目的: Task ツール使用後に subagent の発動をログに記録
# トリガー: PostToolUse(Task)
# ==============================================================================

set -euo pipefail

LOG_DIR=".claude/logs"
LOG_FILE="$LOG_DIR/subagent-dispatch.log"

# ログディレクトリ確保
mkdir -p "$LOG_DIR"

# 入力JSONを読み取り（PostToolUse の tool_result）
INPUT=$(cat)

# tool_input から subagent_type を抽出
SUBAGENT_TYPE=$(echo "$INPUT" | jq -r '.tool_input.subagent_type // "unknown"')
DESCRIPTION=$(echo "$INPUT" | jq -r '.tool_input.description // ""')

# 結果の有無を確認
TOOL_RESULT=$(echo "$INPUT" | jq -r '.tool_result // ""')
if [ -n "$TOOL_RESULT" ] && [ "$TOOL_RESULT" != "null" ]; then
    RESULT="SUCCESS"
else
    RESULT="COMPLETED"
fi

# ISO8601 形式のタイムスタンプ
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# ログエントリを記録
echo "$TIMESTAMP | $SUBAGENT_TYPE | $DESCRIPTION | $RESULT" >> "$LOG_FILE"

# 正常終了（PostToolUse はブロックできないが、exit 0 で成功を示す）
exit 0
