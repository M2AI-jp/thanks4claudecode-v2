#!/bin/bash
# session-start.sh - LLMの自己認識を形成し、LOOPを開始させる
#
# 設計方針（8.5 Hooks 設計ガイドライン準拠）:
#   - 軽量な出力のみ（1KB 目標）
#   - state.md, project.md, playbook は LLM に Read させる
#   - OOM 防止のため全文出力は禁止
#
# 自動更新機能:
#   - state.md の session_tracking.last_start を自動更新
#   - LLM の行動に依存しない
#
# トリガー対応:
#   - startup: 通常のセッション開始
#   - resume: セッション再開
#   - clear: /clear 後の再初期化
#   - compact: auto-compact 後の復元

set -e

# ==============================================================================
# state-schema.sh を source して state.md のスキーマを参照
# ==============================================================================
source .claude/schema/state-schema.sh

# === stdin から JSON を読み込み、trigger を検出 ===
INPUT=$(cat)
TRIGGER=$(echo "$INPUT" | jq -r '.trigger // "startup"' 2>/dev/null || echo "startup")

# === state.md の session_tracking を自動更新 ===
if [ -f "state.md" ]; then
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

    # last_start を更新（sed -i はmacOSでは -i '' が必要）
    if grep -q "last_start:" state.md; then
        sed -i '' "s/last_start: .*/last_start: $TIMESTAMP/" state.md 2>/dev/null || \
        sed -i "s/last_start: .*/last_start: $TIMESTAMP/" state.md 2>/dev/null || true
    fi

    # 前回 last_end が null でないか確認（正常終了判定）
    LAST_END=$(grep "last_end:" state.md | head -1 | sed 's/.*last_end: *//' | sed 's/ *#.*//')
    if [ "$LAST_END" = "null" ] || [ -z "$LAST_END" ]; then
        # 前回のセッションが正常終了していない可能性
        PREV_START=$(grep "last_start:" state.md | head -1 | sed 's/.*last_start: *//' | sed 's/ *#.*//')
        if [ "$PREV_START" != "null" ] && [ -n "$PREV_START" ]; then
            echo ""
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo "  ⚠️ 前回のセッションが正常終了していません"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo "  last_start: $PREV_START"
            echo "  last_end: (未設定)"
            echo ""
            echo "  → 前回の作業状態を確認してください"
            echo ""
        fi
    fi
fi

# === essential-documents.md 自動更新チェック ===
# core-manifest.yaml が essential-documents.md より新しい場合に再生成
MANIFEST="governance/core-manifest.yaml"
ESSENTIAL="docs/essential-documents.md"
GENERATOR="scripts/generate-essential-docs.sh"
if [ -f "$MANIFEST" ] && [ -f "$GENERATOR" ]; then
    if [ ! -f "$ESSENTIAL" ] || [ "$MANIFEST" -nt "$ESSENTIAL" ]; then
        bash "$GENERATOR" >/dev/null 2>&1 || true
    fi
fi

# === 共通変数 ===
SEP="━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
WS="$(pwd)"

# === 初期化ペンディングフラグの設定 ===
# init-guard.sh が必須ファイル Read 完了まで他ツールをブロックするために使用
INIT_DIR=".claude/.session-init"
mkdir -p "$INIT_DIR"
# user-intent.md は保持（compact 後の復元に必要）、セッション管理ファイルのみリセット
rm -f "$INIT_DIR/pending" "$INIT_DIR/required_playbook" 2>/dev/null || true
touch "$INIT_DIR/pending"

# === state.md から情報抽出 ===
[ ! -f "state.md" ] && echo "[WARN] state.md not found" && exit 0

FOCUS=$(grep -A5 "## focus" state.md | grep "current:" | sed 's/.*: *//' | sed 's/ *#.*//')
PHASE=$(grep -A5 "## goal" state.md | grep "phase:" | head -1 | sed 's/.*: *//' | sed 's/ *#.*//')
CRITERIA=$(awk '/## goal/,/^## [^g]/' state.md | grep -A20 "done_criteria:" | grep "^  -" | head -6)
BRANCH=$(git branch --show-current 2>/dev/null || echo "")

# playbook 取得（## playbook セクションから active を読み取り）
PLAYBOOK=$(awk '/## playbook/,/^---/' state.md | grep "^active:" | head -1 | sed 's/active: *//' | sed 's/ *#.*//')
[ -z "$PLAYBOOK" ] && PLAYBOOK="null"

# init-guard.sh 用に playbook パスを記録
echo "$PLAYBOOK" > "$INIT_DIR/required_playbook"

# roadmap 取得（workspace 用）
ROADMAP=$(grep -A10 "## plan_hierarchy" state.md 2>/dev/null | grep "roadmap:" | sed 's/.*: *//' | sed 's/ *#.*//')
# null または空の場合はデフォルト値を使用
[ -z "$ROADMAP" ] || [ "$ROADMAP" = "null" ] && ROADMAP="plan/roadmap.md"
MILESTONE=$(grep -A10 "## plan_hierarchy" state.md 2>/dev/null | grep "current_milestone:" | sed 's/.*: *//' | sed 's/ *#.*//')

# project_context 取得（setup/product 用）
PROJECT_GENERATED=$(grep -A10 "## project_context" state.md 2>/dev/null | grep "generated:" | sed 's/.*: *//' | sed 's/ *#.*//')
PROJECT_PLAN=$(grep -A10 "## project_context" state.md 2>/dev/null | grep "project_plan:" | sed 's/.*: *//' | sed 's/ *#.*//')

# === 警告出力（条件付き）===
echo ""

# === MISSION セクション削除（CLAUDE.md/project.md で読める）===

# システム健全性チェック（軽量、SessionStart 統合）
if [ -f ".claude/hooks/system-health-check.sh" ]; then
    bash .claude/hooks/system-health-check.sh 2>/dev/null || true
fi

# === ドキュメント自動更新: 変更が蓄積されていれば自動実行 ===
CHANGE_LOG=".claude/logs/changes.log"
GEN_SCRIPT=".claude/hooks/generate-implementation-doc.sh"
if [ -f "$CHANGE_LOG" ] && [ -f "$GEN_SCRIPT" ]; then
    CHANGE_COUNT=$(wc -l < "$CHANGE_LOG" | tr -d ' ')
    if [ "$CHANGE_COUNT" -ge 3 ]; then
        # 自動実行（提案ではなく実行）
        bash "$GEN_SCRIPT" > /dev/null 2>&1 || true
        # ログをクリア
        rm -f "$CHANGE_LOG"
        cat <<EOF
$SEP
  ✅ ドキュメント自動更新完了
$SEP
$CHANGE_COUNT 件の変更を検知し、current-implementation.md を自動更新しました。
（Self-Healing: 自律的なドキュメントメンテナンス）

EOF
    fi
fi

# === 失敗学習ループ: 繰り返し発生している問題を警告 ===
FAILURE_LOG=".claude/logs/failures.log"
if [ -f "$FAILURE_LOG" ]; then
    # 3回以上繰り返された失敗パターンを抽出
    REPEATED_FAILURES=$(awk -F'"' '{print $4":"$8}' "$FAILURE_LOG" 2>/dev/null | sort | uniq -c | sort -rn | head -5 | awk '$1 >= 3 {print "  ⚠️ " $2 " (" $1 "回)"}')

    if [ -n "$REPEATED_FAILURES" ]; then
        cat <<EOF
$SEP
  🔄 過去の失敗パターン（学習）
$SEP
以下の問題が繰り返し発生しています:
$REPEATED_FAILURES

同じ失敗を繰り返さないよう注意してください。
詳細: $FAILURE_LOG

EOF
    fi
fi

# 未コミット変更警告（state-plan-git-branch 4つ組連動の担保）
UNCOMMITTED=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
if [ "$UNCOMMITTED" -gt 0 ]; then
    cat <<EOF
$SEP
  ⚠️ 未コミット変更が ${UNCOMMITTED} 件あります
$SEP
  前回のセッションで変更がコミットされていません。
  作業開始前に確認してください:
    git status
    git add -A && git commit -m "..."

EOF
fi

# 残存 playbook 警告（setup/product は新規ユーザーのため除外）
if [ "$FOCUS" != "setup" ] && [ "$FOCUS" != "product" ]; then
    PLAYBOOK_COUNT=$(find plan -maxdepth 1 -name "playbook-*.md" -type f 2>/dev/null | wc -l | tr -d ' ')
    if [ "$PLAYBOOK_COUNT" -ge 2 ]; then
        PLAYBOOK_FILES=$(find plan -maxdepth 1 -name "playbook-*.md" -type f 2>/dev/null | sort)
        cat <<EOF
$SEP
  ⚠️ plan/ に複数の playbook が残存しています（${PLAYBOOK_COUNT}件）
$SEP
  以下のファイルを確認してください:
EOF
        echo "$PLAYBOOK_FILES" | while read -r f; do
            echo "    - $f"
        done
        cat <<EOF

  完了済みなら plan/archive/ に移動してください:
    mv plan/playbook-xxx.md plan/archive/

EOF
    fi
fi

# tmp/ 残存ファイル警告（README.md は除外）
if [ -d "tmp" ]; then
    TMP_COUNT=$(find tmp -mindepth 1 -maxdepth 1 ! -name "README.md" 2>/dev/null | wc -l | tr -d ' ')
    if [ "$TMP_COUNT" -ge 1 ]; then
        TMP_FILES=$(find tmp -mindepth 1 -maxdepth 1 ! -name "README.md" 2>/dev/null | sort)
        cat <<EOF
$SEP
  ⚠️ tmp/ に一時ファイルが残存しています（${TMP_COUNT}件）
$SEP
  以下のファイル/ディレクトリを確認してください:
EOF
        echo "$TMP_FILES" | while read -r f; do
            echo "    - $f"
        done
        cat <<EOF

  不要なら削除してください:
    rm -rf tmp/xxx
  （README.md は保持されます）

EOF
    fi
fi

# === compact トリガー時の特別処理 ===
SNAPSHOT_FILE=".claude/.session-init/snapshot.json"
if [ "$TRIGGER" = "compact" ]; then
    cat <<EOF
$SEP
  📦 Auto-Compact からの復元
$SEP
コンテキストウィンドウが上限に達したため、auto-compact が実行されました。
以下の状態から作業を継続してください。

EOF

    # snapshot.json から状態を復元
    if [ -f "$SNAPSHOT_FILE" ]; then
        SNAP_FOCUS=$(jq -r '.focus // "unknown"' "$SNAPSHOT_FILE" 2>/dev/null)
        SNAP_PHASE=$(jq -r '.current_phase // "null"' "$SNAPSHOT_FILE" 2>/dev/null)
        SNAP_GOAL=$(jq -r '.phase_goal // "null"' "$SNAPSHOT_FILE" 2>/dev/null)
        SNAP_PLAYBOOK=$(jq -r '.playbook // "null"' "$SNAPSHOT_FILE" 2>/dev/null)
        SNAP_BRANCH=$(jq -r '.branch // "unknown"' "$SNAPSHOT_FILE" 2>/dev/null)
        SNAP_UNCOMMITTED=$(jq -r '.uncommitted_count // "0"' "$SNAPSHOT_FILE" 2>/dev/null)
        SNAP_CRITERIA=$(jq -r '.done_criteria // ""' "$SNAPSHOT_FILE" 2>/dev/null)
        SNAP_TIMESTAMP=$(jq -r '.timestamp // ""' "$SNAPSHOT_FILE" 2>/dev/null)

        cat <<EOF
【Compact 前の状態】($SNAP_TIMESTAMP)
  focus: $SNAP_FOCUS
  phase: $SNAP_PHASE
  phase_goal: $SNAP_GOAL
  playbook: $SNAP_PLAYBOOK
  branch: $SNAP_BRANCH
  uncommitted: $SNAP_UNCOMMITTED 件

【done_criteria】
$SNAP_CRITERIA

EOF
    fi
fi

# === user-intent.md からユーザー意図を復元（簡素化：通常1件、compact時3件）===
INTENT_FILE=".claude/.session-init/user-intent.md"
if [ -f "$INTENT_FILE" ]; then
    if [ "$TRIGGER" = "compact" ]; then
        # compact 時は3件
        LATEST_INTENTS=$(awk '/^## \[/{count++; if(count>3) exit} {print}' "$INTENT_FILE" 2>/dev/null | head -50)
        if [ -n "$LATEST_INTENTS" ]; then
            cat <<EOF
$SEP
  🎯 【重要】元のユーザー指示（必ず継続）
$SEP
$LATEST_INTENTS
EOF
        fi
    else
        # 通常時は1件のみ
        LATEST_INTENT=$(awk '/^## \[/{count++; if(count>1) exit} {print}' "$INTENT_FILE" 2>/dev/null | head -20)
        if [ -n "$LATEST_INTENT" ]; then
            cat <<EOF
$SEP
  📝 前回の指示
$SEP
$LATEST_INTENT
EOF
        fi
    fi
fi

# main ブランチ警告（workspace のみ - setup/product は main で作業可能）
if [ "$BRANCH" = "main" ] && [ "$FOCUS" = "workspace" ]; then
    cat <<EOF
$SEP
  🚨 main ブランチで作業中（禁止）
$SEP
  git checkout -b {fix|feat|refactor}/{description}

EOF
fi

# playbook/branch 不一致警告（branch: null は除外）
if [ "$PLAYBOOK" != "null" ] && [ -f "$PLAYBOOK" ]; then
    EXP_BR=$(grep -E "^branch:" "$PLAYBOOK" 2>/dev/null | head -1 | sed 's/branch: *//' | sed 's/ *#.*//')
    if [ -n "$EXP_BR" ] && [ "$EXP_BR" != "null" ] && [ "$BRANCH" != "$EXP_BR" ]; then
        cat <<EOF
$SEP
  ⚠️ ブランチ不一致: 期待=$EXP_BR / 現在=$BRANCH
$SEP
  git checkout $EXP_BR

EOF
    fi
fi

# playbook 未作成時は pm 呼び出しを強制指示（setup では抑制）
if [ "$PLAYBOOK" = "null" ] && [ "$FOCUS" != "setup" ]; then
    cat <<EOF
$SEP
  🚨 playbook 未作成 - pm を呼び出してください
$SEP
  以下を実行してください（構造的に強制されます）:

  Task(subagent_type='pm', prompt='playbook を作成')

  ⚠️ pm 呼び出し以外のツールはブロックされます

EOF
fi

# === Next milestone 候補の表示（project.md から抽出）===
PROJECT_FILE="plan/project.md"
if [ -f "$PROJECT_FILE" ]; then
    # status: not_started または in_progress のマイルストーンを抽出
    PENDING_MS=$(awk '
        /^- id: M[0-9]+/ { id=$3; name=""; status="" }
        /^  name:/ { gsub(/^  name: *"?|"?$/, ""); name=$0 }
        /^  status: (not_started|in_progress)/ {
            status=$2
            if (id != "" && name != "") {
                print "  - " id ": " name " [" status "]"
            }
        }
    ' "$PROJECT_FILE" 2>/dev/null | head -5)

    if [ -n "$PENDING_MS" ]; then
        cat <<EOF
$SEP
  📋 Next milestone 候補（project.md）
$SEP
$PENDING_MS

  → pm を呼び出して playbook を作成してください
  → 詳細は plan/project.md を Read

EOF
    fi
fi

# === 機能サマリー（repository-map.yaml）===
REPO_MAP="docs/repository-map.yaml"
if [ -f "$REPO_MAP" ]; then
    HOOKS_COUNT=$(grep "^  hooks:" "$REPO_MAP" 2>/dev/null | sed 's/.*: //' | tr -d ' ' || echo "0")
    AGENTS_COUNT=$(grep "^  agents:" "$REPO_MAP" 2>/dev/null | sed 's/.*: //' | tr -d ' ' || echo "0")
    SKILLS_COUNT=$(grep "^  skills:" "$REPO_MAP" 2>/dev/null | sed 's/.*: //' | tr -d ' ' || echo "0")

    # 実際のファイル数を取得して比較
    HOOKS_ACTUAL=$(find .claude/hooks -maxdepth 1 -name "*.sh" -type f 2>/dev/null | wc -l | tr -d ' ')
    AGENTS_ACTUAL=$(find .claude/agents -maxdepth 1 -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ')
    SKILLS_ACTUAL=$(find .claude/skills -maxdepth 1 -type d ! -path ".claude/skills" 2>/dev/null | wc -l | tr -d ' ')

    # 変更検出
    CATALOG_STATUS="OK"
    if [ "$HOOKS_ACTUAL" -ne "$HOOKS_COUNT" ] || [ "$AGENTS_ACTUAL" -ne "$AGENTS_COUNT" ] || [ "$SKILLS_ACTUAL" -ne "$SKILLS_COUNT" ]; then
        CATALOG_STATUS="OUTDATED"
    fi

    cat <<EOF
$SEP
  📦 Feature Catalog Summary
$SEP
  $HOOKS_COUNT Hooks | $AGENTS_COUNT SubAgents | $SKILLS_COUNT Skills
EOF

    if [ "$CATALOG_STATUS" = "OUTDATED" ]; then
        echo -e "  ⚠️ WARNING: 機能カタログが最新ではありません（変更検出）"
        echo "  → bash .claude/hooks/generate-repository-map.sh で更新"
    fi
    echo ""
fi

# === Essential Docs（必須ドキュメント数）===
ESSENTIAL_DOCS="docs/essential-documents.md"
if [ -f "$ESSENTIAL_DOCS" ]; then
    # total_essential_documents: から数値を抽出
    ESSENTIAL_COUNT=$(grep "total_essential_documents:" "$ESSENTIAL_DOCS" 2>/dev/null | sed 's/.*: *//' | tr -d ' ')
    [ -z "$ESSENTIAL_COUNT" ] && ESSENTIAL_COUNT="?"

    cat <<EOF
$SEP
  📚 Essential docs: $ESSENTIAL_COUNT files
$SEP
  参照: docs/essential-documents.md（動線単位で整理）

EOF
fi

# === CORE（動線単位の認識 - 最重要）===
cat <<EOF
$SEP
  🧠 CORE
$SEP
  pdca: playbook完了 → 自動次タスク
  tdd: done_criteria = テスト仕様（根拠必須）
  validation: critic → PASS で phase 完了
  plan: Edit/Write → playbook必須
  git: 1 playbook = 1 branch

$SEP
  🔄 動線単位で考える（CRITICAL）
$SEP
  全コンポーネントは「動線単位」で扱う:
    計画動線: 要求 → pm → playbook → state.md
    実行動線: playbook → Edit → Guard発火
    検証動線: /crit → critic → PASS/FAIL
    完了動線: phase完了 → アーカイブ → 次タスク

  Layer（動線ベース）:
    Core: 計画動線 + 検証動線（ないと破綻）
    Quality: 実行動線（品質低下）
    Extension: 完了動線 + 共通（手動代替可）

EOF

# === 必須 Read 指示（focus 別分岐）===
cat <<EOF
$SEP
  📖 【必須】Read 完了まで作業禁止
$SEP
EOF

case "$FOCUS" in
    setup)
        # setup: playbook-setup.md のみ読めば完結
        echo "  1. Read: $WS/state.md"
        echo "  2. Read: $WS/setup/playbook-setup.md"
        echo ""
        echo "  → Phase 0 から開始（ルート選択）"
        echo "  → CATALOG.md は必要な時だけ参照"
        ;;
    product)
        # product: plan/project.md を参照して開発
        echo "  1. Read: $WS/state.md"
        if [ "$PROJECT_GENERATED" = "true" ] && [ -n "$PROJECT_PLAN" ] && [ "$PROJECT_PLAN" != "null" ] && [ -f "$PROJECT_PLAN" ]; then
            echo "  2. Read: $WS/$PROJECT_PLAN"
        else
            echo "  ⚠️ plan/project.md が未生成（setup 未完了？）"
        fi
        [ "$PLAYBOOK" != "null" ] && echo "  3. Read: $WS/$PLAYBOOK" || echo "  3. /playbook-init を実行"
        ;;
    workspace|thanks4claudecode)
        # workspace/thanks4claudecode: roadmap を参照して開発
        echo "  1. Read: $WS/state.md"
        [ -f "$ROADMAP" ] && echo "  2. Read: $WS/$ROADMAP"
        [ "$PLAYBOOK" != "null" ] && echo "  3. Read: $WS/$PLAYBOOK" || echo "  3. /playbook-init を実行"
        ;;
    plan-template)
        # plan-template: テンプレート開発
        echo "  1. Read: $WS/state.md"
        [ "$PLAYBOOK" != "null" ] && echo "  2. Read: $WS/$PLAYBOOK"
        ;;
    *)
        # 不明な focus
        echo "  1. Read: $WS/state.md"
        ;;
esac

cat <<EOF

  → [自認] 宣言 → main なら branch 作成 → LOOP 開始

EOF

# === state.md 抜粋を削除（[自認] テンプレートに統合）===

# === 上位計画書抜粋を削除（Read で読むため事前表示不要）===

# === Playbook in_progress Phase 抽出 ===
if [ "$PLAYBOOK" != "null" ] && [ -f "$PLAYBOOK" ]; then
    # in_progress の phase を抽出（name, goal, done_criteria を表示）
    IN_PROGRESS=$(grep -n "status: in_progress" "$PLAYBOOK" 2>/dev/null | head -1 | cut -d: -f1)
    if [ -n "$IN_PROGRESS" ]; then
        cat <<EOF

$SEP
  🎯 現在の Phase（in_progress）
$SEP
EOF
        # in_progress 行の前後を抽出して name, goal, done_criteria を表示
        awk -v line="$IN_PROGRESS" 'NR>=line-10 && NR<=line+15' "$PLAYBOOK" | grep -E "^\s*(- id:|name:|goal:|done_criteria:|  - )" | head -12
        echo ""
        echo "→ done_criteria を「テスト」として扱い、証拠を集めてから完了判定"
    fi
fi

# === [自認] テンプレート（focus 別）===
cat <<EOF

$SEP
  🏷️ [自認] テンプレート
$SEP
what: $FOCUS
phase: $PHASE
branch: $BRANCH
EOF

# focus 別の追加フィールド
case "$FOCUS" in
    workspace)
        echo "milestone: $MILESTONE"
        ;;
    product)
        echo "project: $PROJECT_PLAN"
        ;;
    setup)
        # playbook は共通出力（下の cat <<EOF）で表示されるため省略
        ;;
esac

cat <<EOF
playbook: $PLAYBOOK
EOF

# === 利用可能機能を削除（必要時に参照可能）===

exit 0
