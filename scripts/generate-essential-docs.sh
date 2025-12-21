#!/bin/bash
#
# generate-essential-docs.sh
#
# essential-documents.md を core-manifest.yaml と state.md から自動生成する
#
# Usage: ./scripts/generate-essential-docs.sh
#

set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
MANIFEST="$ROOT_DIR/governance/core-manifest.yaml"
STATE="$ROOT_DIR/state.md"
OUTPUT="$ROOT_DIR/docs/essential-documents.md"

GREEN='\033[0;32m'
NC='\033[0m'
log_info() { echo -e "${GREEN}[INFO]${NC} $1" >&2; }

# core-manifest.yaml からコンポーネントテーブルを抽出
extract_section_components() {
    local start_pattern=$1
    local end_pattern=$2

    awk -v start="$start_pattern" -v end="$end_pattern" '
    $0 ~ start { capture = 1 }
    capture && /^      - name:/ {
        name = $0
        gsub(/^      - name: /, "", name)
    }
    capture && /^        type:/ {
        type = $0
        gsub(/^        type: /, "", type)
    }
    capture && /^        role:/ {
        role = $0
        gsub(/^        role: /, "", role)
        type_cap = toupper(substr(type, 1, 1)) substr(type, 2)
        print "| `" name "` | " type_cap " | " role " |"
    }
    capture && $0 ~ end { capture = 0 }
    ' "$MANIFEST"
}

# state.md から FREEZE_QUEUE を抽出
extract_freeze_queue() {
    awk '
    /^## FREEZE_QUEUE/,/^---/ {
        if (/path:/ && !/path\/to\/file/) {
            gsub(/.*path: "/, "")
            gsub(/".*/, "")
            if (length($0) > 0) print "  - " $0
        }
    }
    ' "$STATE"
}

# メイン生成関数
generate() {
    local today=$(date +%Y-%m-%d)
    local planning=6 verification=5 execution=10 completion=7 common=5 cross=3
    local core_total=$((planning + verification))
    local quality_total=$execution
    local extension_total=$((completion + common + cross))
    local grand_total=$((core_total + quality_total + extension_total))

    cat << 'STATIC1'
# Essential Documents - Claude が把握すべき必須ドキュメント

> **動線単位でドキュメントを整理した Single Source of Truth**
>
> このファイルは `scripts/generate-essential-docs.sh` により自動生成されます

---

## 概要

```yaml
STATIC1

    printf "source: governance/core-manifest.yaml\n"
    printf "generated_at: %s\n" "$today"
    printf "organization: 動線単位（計画・実行・検証・完了・共通）\n\n"
    printf "layer_summary:\n"
    printf "  Core Layer: %d コンポーネント（計画動線%d + 検証動線%d）\n" "$core_total" "$planning" "$verification"
    printf "  Quality Layer: %d コンポーネント（実行動線）\n" "$quality_total"
    printf "  Extension Layer: %d コンポーネント（完了%d + 共通%d + 横断%d）\n" "$extension_total" "$completion" "$common" "$cross"
    printf "  Total: %d コンポーネント\n" "$grand_total"

    cat << 'STATIC2'
```

---

## 計画動線（Planning Flow）

タスク開始から playbook 作成までの流れで参照するドキュメント。

### 必須ドキュメント

| ファイル | 役割 | 参照タイミング |
|----------|------|---------------|
| `state.md` | 現在の状態（SSOT） | セッション開始時、常に最初 |
| `plan/project.md` | プロジェクト計画、マイルストーン | タスク開始時 |
| `plan/playbook-*.md` | 現在のタスク詳細 | 作業中 |
| `CLAUDE.md` | LLM 行動規範（凍結憲法） | 迷った時 |
| `RUNBOOK.md` | 手順、ツール、例 | 操作手順確認時 |

STATIC2

    printf "### Core コンポーネント（計画動線 %d）\n\n" "$planning"
    printf "| コンポーネント | 種別 | 役割 |\n"
    printf "|---------------|------|------|\n"

    extract_section_components "planning_flow:" "verification_flow:"

    cat << 'STATIC3'

### 参考テンプレート

| ファイル | 役割 |
|----------|------|
| `plan/template/playbook-format.md` | playbook テンプレート（user_prompt_original 含む） |
| `plan/template/project-format.md` | project.md テンプレート |
| `plan/template/planning-rules.md` | pm 責務・計画フロー |
| `plan/design/mission.md` | 存在意義・core_values・anti-patterns |

---

## 実行動線（Execution Flow）

実装作業中に参照するドキュメント。

### 必須ドキュメント

| ファイル | 役割 | 参照タイミング |
|----------|------|---------------|
| `docs/core-contract.md` | Core Contract + Admin Contract | 保護・権限判断時 |
| `docs/folder-management.md` | フォルダ管理 + アーカイブ + 成果物ルール | ファイル配置時 |
| `docs/ai-orchestration.md` | 役割定義 + Orchestration + Toolstack | executor 選択時 |
| `docs/hook-responsibilities.md` | 各 Hook の責任定義 | Guard 発火時 |
| `docs/hook-exit-code-contract.md` | Hook の exit code 契約 | Hook エラー時 |

STATIC3

    printf "### Quality コンポーネント（実行動線 %d）\n\n" "$execution"
    printf "| コンポーネント | 種別 | 役割 |\n"
    printf "|---------------|------|------|\n"

    extract_section_components "execution_flow:" "# ═.*EXTENSION"

    cat << 'STATIC4'

---

## 検証動線（Verification Flow）

done_criteria 検証で参照するドキュメント。

### 必須ドキュメント

| ファイル | 役割 | 参照タイミング |
|----------|------|---------------|
| `docs/verification-criteria.md` | 検証基準 + Completion Criteria | critic 実行時 |
| `docs/criterion-validation-rules.md` | done_criteria 記述ルール | playbook 作成時 |

STATIC4

    printf "### Core コンポーネント（検証動線 %d）\n\n" "$verification"
    printf "| コンポーネント | 種別 | 役割 |\n"
    printf "|---------------|------|------|\n"

    extract_section_components "verification_flow:" "# ═.*QUALITY"

    cat << 'STATIC5'

### 評価フレームワーク

| ファイル | 役割 |
|----------|------|
| `.claude/frameworks/done-criteria-validation.md` | critic の固定評価フレームワーク（5項目） |
| `.claude/frameworks/playbook-review-criteria.md` | reviewer の評価基準（3段階検証） |

---

## 完了動線（Completion Flow）

Phase/playbook 完了時に参照するドキュメント。

### 必須ドキュメント

| ファイル | 役割 | 参照タイミング |
|----------|------|---------------|
| `docs/folder-management.md` | アーカイブ操作ルール（統合済み） | playbook 完了時 |
| `docs/freeze-then-delete.md` | 安全な削除プロセス（FREEZE_QUEUE） | ファイル削除時 |
| `docs/git-operations.md` | Git 操作リファレンス | マージ・ブランチ削除時 |

STATIC5

    printf "### Extension コンポーネント（完了動線 %d）\n\n" "$completion"
    printf "| コンポーネント | 種別 | 役割 |\n"
    printf "|---------------|------|------|\n"

    extract_section_components "completion_flow:" "common:"

    cat << 'STATIC6'

---

## 共通基盤（Common Infrastructure）

全動線で参照される基盤ドキュメント。

### 必須ドキュメント

| ファイル | 役割 | 参照タイミング |
|----------|------|---------------|
| `docs/repository-map.yaml` | 全ファイルマッピング（自動生成） | コンポーネント確認時 |
| `docs/extension-system.md` | Claude Code 公式リファレンス | Hook/Skill 実装時 |
| `docs/layer-architecture-design.md` | Layer アーキテクチャ設計 | システム理解時 |
| `docs/session-management.md` | セッション管理 | セッション問題時 |

### 正本マニフェスト

| ファイル | 役割 |
|----------|------|
STATIC6

    printf "| \`governance/core-manifest.yaml\` | 動線ベース Layer アーキテクチャ定義（%dコンポーネント正本） |\n" "$grand_total"

    cat << 'STATIC7'
| `governance/context-manifest.yaml` | コンテキスト階層定義（Core/Flow/Extended） |
| `governance/PROMPT_CHANGELOG.md` | CLAUDE.md 変更履歴 |

STATIC7

    printf "### Extension コンポーネント（共通 %d + 横断 %d）\n\n" "$common" "$cross"
    printf "| コンポーネント | 種別 | 役割 |\n"
    printf "|---------------|------|------|\n"

    extract_section_components "common:" "cross_cutting:"
    extract_section_components "cross_cutting:" "# ═.*削除候補"

    cat << 'STATIC8'

---

## 参照優先順位

```yaml
セッション開始時:
  1. state.md（必須）
  2. plan/project.md（推奨）
  3. 現在の playbook（active の場合）

作業中:
  1. 現在の playbook
  2. 関連する実行動線ドキュメント

迷った時:
  1. CLAUDE.md（原則確認）
  2. RUNBOOK.md（手順確認）
  3. docs/*.md（詳細確認）
```

---

## 非推奨ドキュメント（FREEZE_QUEUE）

以下のファイルは統合または廃止され、FREEZE_QUEUE に入っています:

```yaml
queue:
STATIC8

    extract_freeze_queue

    cat << 'STATIC9'
```

---

## 変更履歴

| 日時 | 内容 |
|------|------|
STATIC9

    printf "| %s | 自動生成（generate-essential-docs.sh） |\n" "$today"
}

# メイン
main() {
    log_info "Generating essential-documents.md..."

    if [[ ! -f "$MANIFEST" ]]; then
        echo "Error: $MANIFEST not found" >&2
        exit 1
    fi

    generate > "$OUTPUT"

    log_info "Generated: $OUTPUT"
}

main "$@"
