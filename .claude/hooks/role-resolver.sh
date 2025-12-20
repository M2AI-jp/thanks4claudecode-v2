#!/bin/bash
# role-resolver.sh - 抽象的な役割名を具体的な executor に解決
#
# 目的: playbook の executor フィールドで使用される役割名を
#       toolstack に応じた具体的な executor 名に解決する
#
# 使用例:
#   bash .claude/hooks/role-resolver.sh worker
#   echo 'worker' | bash .claude/hooks/role-resolver.sh
#
# 環境変数:
#   TOOLSTACK - A/B/C を指定（デフォルト: state.md から読み込み、なければ A）
#   STATE_FILE - state.md のパス（デフォルト: state.md）
#   PLAYBOOK_PATH - playbook のパス（オプション、meta.roles override 用）
#
# 解決優先順位:
#   1. playbook.meta.roles（playbook 固有の override）
#   2. state.md config.roles（プロジェクト全体のデフォルト）
#   3. ハードコードされたデフォルト（toolstack に応じた表）
#
# 出力: 解決された executor 名（claudecode, codex, coderabbit, user のいずれか）
#       役割名でない場合はそのまま返す

set -euo pipefail

STATE_FILE="${STATE_FILE:-state.md}"

# ============================================================
# 入力取得（引数または stdin）
# ============================================================
ROLE=""
if [[ $# -ge 1 ]]; then
    ROLE="$1"
else
    # stdin から読み込み（タイムアウト 1 秒）
    if read -t 1 -r INPUT 2>/dev/null; then
        ROLE="$INPUT"
    fi
fi

# 入力がない場合は終了
if [[ -z "$ROLE" ]]; then
    exit 0
fi

# 空白を除去
ROLE=$(echo "$ROLE" | tr -d ' \t\n\r')

# ============================================================
# 既に具体的な executor の場合はそのまま返す
# ============================================================
case "$ROLE" in
    claudecode|codex|coderabbit|user)
        echo "$ROLE"
        exit 0
        ;;
esac

# ============================================================
# 有効な役割名かチェック
# ============================================================
case "$ROLE" in
    orchestrator|worker|reviewer|human)
        # 有効な役割名
        ;;
    *)
        # 不明な役割名はそのまま返す（executor-guard.sh で処理）
        echo "$ROLE"
        exit 0
        ;;
esac

# ============================================================
# Toolstack 取得（環境変数 > state.md > デフォルト A）
# ============================================================
if [[ -z "${TOOLSTACK:-}" ]]; then
    TOOLSTACK="A"  # デフォルト
    if [[ -f "$STATE_FILE" ]]; then
        TS=$(grep -A5 "^## config" "$STATE_FILE" 2>/dev/null | grep "toolstack:" | head -1 | sed 's/toolstack: *//' | sed 's/ *#.*//' | tr -d ' ' || echo "")
        if [[ -n "$TS" && "$TS" =~ ^[ABC]$ ]]; then
            TOOLSTACK="$TS"
        fi
    fi
fi

# ============================================================
# 優先順位 1: playbook.meta.roles から取得
# ============================================================
RESOLVED=""
if [[ -n "${PLAYBOOK_PATH:-}" && -f "$PLAYBOOK_PATH" ]]; then
    # meta セクション内の roles を探す
    # 形式: roles:
    #         worker: claudecode
    IN_META=false
    IN_ROLES=false
    while IFS= read -r line; do
        # meta セクション検出
        if [[ "$line" =~ ^##[[:space:]]*meta ]]; then
            IN_META=true
            continue
        fi
        # 別のセクションに到達したら終了
        if [[ "$IN_META" == true && "$line" =~ ^##[[:space:]] ]]; then
            break
        fi
        # roles: 検出
        if [[ "$IN_META" == true && "$line" =~ ^[[:space:]]*roles: ]]; then
            IN_ROLES=true
            continue
        fi
        # roles 内の役割を探す
        if [[ "$IN_ROLES" == true ]]; then
            # インデントがなくなったら roles 終了
            if [[ ! "$line" =~ ^[[:space:]] ]]; then
                IN_ROLES=false
                continue
            fi
            # 役割名: executor 形式を探す
            if [[ "$line" =~ ^[[:space:]]+${ROLE}:[[:space:]]*([a-z]+) ]]; then
                RESOLVED="${BASH_REMATCH[1]}"
                break
            fi
        fi
    done < "$PLAYBOOK_PATH"
fi

# ============================================================
# 優先順位 2: state.md config.roles から取得
# ============================================================
if [[ -z "$RESOLVED" && -f "$STATE_FILE" ]]; then
    # config セクション内の roles を探す
    IN_CONFIG=false
    IN_ROLES=false
    while IFS= read -r line; do
        # config セクション検出
        if [[ "$line" =~ ^##[[:space:]]*config ]]; then
            IN_CONFIG=true
            continue
        fi
        # 別のセクションに到達したら終了
        if [[ "$IN_CONFIG" == true && "$line" =~ ^##[[:space:]] && ! "$line" =~ ^##[[:space:]]*config ]]; then
            break
        fi
        # roles: 検出
        if [[ "$IN_CONFIG" == true && "$line" =~ ^[[:space:]]*roles: ]]; then
            IN_ROLES=true
            continue
        fi
        # roles 内の役割を探す
        if [[ "$IN_ROLES" == true ]]; then
            # 役割名: executor 形式を探す
            if [[ "$line" =~ ^[[:space:]]+${ROLE}:[[:space:]]*([a-z]+) ]]; then
                RESOLVED="${BASH_REMATCH[1]}"
                break
            fi
            # 別のキー（roles と同じインデント）に到達したら終了
            if [[ "$line" =~ ^[[:space:]]{2}[a-z]+: && ! "$line" =~ ^[[:space:]]+${ROLE}: ]]; then
                # roles 内の他の役割は継続
                if [[ ! "$line" =~ ^[[:space:]]+(orchestrator|worker|reviewer|human): ]]; then
                    IN_ROLES=false
                fi
            fi
        fi
    done < "$STATE_FILE"
fi

# ============================================================
# 優先順位 3: ハードコードされたデフォルト（toolstack 別）
# ============================================================
if [[ -z "$RESOLVED" ]]; then
    case "$TOOLSTACK" in
        A)
            # Toolstack A: Claude Code only
            case "$ROLE" in
                orchestrator) RESOLVED="claudecode" ;;
                worker)       RESOLVED="claudecode" ;;
                reviewer)     RESOLVED="claudecode" ;;
                human)        RESOLVED="user" ;;
            esac
            ;;
        B)
            # Toolstack B: Claude Code + Codex
            case "$ROLE" in
                orchestrator) RESOLVED="claudecode" ;;
                worker)       RESOLVED="codex" ;;
                reviewer)     RESOLVED="claudecode" ;;
                human)        RESOLVED="user" ;;
            esac
            ;;
        C)
            # Toolstack C: Claude Code + Codex + CodeRabbit
            case "$ROLE" in
                orchestrator) RESOLVED="claudecode" ;;
                worker)       RESOLVED="codex" ;;
                reviewer)     RESOLVED="coderabbit" ;;
                human)        RESOLVED="user" ;;
            esac
            ;;
        *)
            # 未知の toolstack はデフォルト A として扱う
            case "$ROLE" in
                orchestrator) RESOLVED="claudecode" ;;
                worker)       RESOLVED="claudecode" ;;
                reviewer)     RESOLVED="claudecode" ;;
                human)        RESOLVED="user" ;;
            esac
            ;;
    esac
fi

# ============================================================
# 結果を出力
# ============================================================
echo "$RESOLVED"
