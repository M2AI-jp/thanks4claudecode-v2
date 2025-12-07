# state.md

> **統合状態管理ファイル（Single Source of Truth）**
>
> 4つのレイヤーを管理: plan-template → workspace → setup → product
> LLMはセッション開始時に必ずこのファイルを読み、`focus.current` を確認すること。

---

## focus

```yaml
current: setup               # plan-template | workspace | setup | product
session: discussion          # task | discussion
```

---

## security

```yaml
mode: trusted                # strict | trusted | developer | admin
```

---

## active_playbooks

```yaml
plan-template:    null
workspace:        null
setup:            setup/playbook-setup.md   # デフォルト playbook
product:          null                       # setup 完了後、product 開発用に作成
```

---

## context

```yaml
mode: normal                 # normal | interrupt
interrupt_reason: null
return_to: null
```

---

## plan_hierarchy

> **6 層レイヤー構造**: vision → meta-roadmap → CONTEXT.md → roadmap → playbook → task

```yaml
# 最上位レイヤー（WHY-ultimate）
vision: plan/vision.md

# roadmap 改善レイヤー（HOW-to-improve）
meta_roadmap: plan/meta-roadmap.md

# 中長期計画レイヤー（WHAT）
roadmap: plan/roadmap.md
current_phase: setup
current_milestone: null

# セッションタスクレイヤー（HOW）
playbook: setup/playbook-setup.md

# 完了タスク
completed_tasks: []

# 次のタスク
next_tasks:
  - Phase 0: ルート選択
  - Phase 1: プロジェクト設計
```

---

## project_context

> **setup 完了後に更新される。**

```yaml
generated: false             # true = setup 完了、plan/project.md 生成済み
project_plan: null           # 生成後: plan/project.md
```

---

## layer: plan-template

```yaml
state: done
sub: v3-complete
playbook: null
```

---

## layer: workspace

```yaml
state: done
sub: v7.2-readme-structure-updated
playbook: null
```

---

## layer: setup

```yaml
state: pending
sub: null
playbook: setup/playbook-setup.md
```

### 概要
> setup/playbook-setup.md に従って環境をセットアップする。
> Phase 0-8 を完了後、plan/project.md を生成し product レイヤーへ移行。
> CATALOG.md は必要な時だけ参照。

---

## layer: product

```yaml
state: pending               # setup 完了後に有効化
sub: null
playbook: null
```

### 概要
> ユーザーが実際にプロダクトを開発するためのレイヤー。
> setup 完了後、plan/project.md を参照して TDD で開発。

---

## goal

```yaml
phase: setup
milestone: Phase0
task: ルート選択
assignee: claude_code

done_criteria:
  - ユーザーが目的を選択した
```

### 次のステップ
```
Phase 0: ルート選択（チュートリアル or 本番開発）
Phase 1: プロジェクト設計（何を作るか）
```

---

## verification

```yaml
self_complete: false
user_verified: false
```

---

## states

```yaml
flow: pending → designing → implementing → [reviewing →] state_update → done
forbidden: [pending→implementing], [pending→done], [*→done without state_update]
```

---

## rules

```yaml
原則: focus.current のレイヤーのみ編集可能
例外: state.md の focus/context/verification は常に編集可能
保護: CLAUDE.md, CONTEXT.md は BLOCK（ユーザー許可必要）
```

---

## session_tracking

> **Hooks による自動更新。LLM の行動に依存しない。**

```yaml
last_start: 2025-12-07 23:32:55
last_end: null
uncommitted_warning: false
```

---

## 参照ファイル

| ファイル | 内容 |
|----------|------|
| CONTEXT.md | 唯一の真実源。設計思想、レイヤー構造、全コンテキスト |

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| - | フォーク直後の初期状態 |
