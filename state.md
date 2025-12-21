# state.md

> **現在地を示す Single Source of Truth**
>
> LLM はセッション開始時に必ずこのファイルを読み、focus と playbook を確認すること。

---

## focus

```yaml
current: plan-template  # 現在作業中のプロジェクト名
session: task           # task | discussion
project: plan/project.md
```

---

## playbook

```yaml
active: plan/playbook-m126-flow-context-completeness.md
branch: feat/m126-flow-context-completeness
last_archived: plan/archive/playbook-m123-minor-fixes.md
```

---

## goal

```yaml
milestone: M126
phase: p1
done_when:
  - "cleanup-hook.sh から削除済みスクリプト/ファイル（generate-repository-map.sh, check-spec-sync.sh, repository-map.yaml）への参照が除去されている"
  - "全 Hook が存在するファイルのみを参照している"
  - "固定 6 Skill に対応する Command が存在する: lint-checker→lint.md, state→focus.md, post-loop→post-loop.md, context-management→compact.md, test-runner→test.md, plan-management→task-start.md"
  - "scripts/flow-integrity-test.sh が PASS する"
next: p1.1 cleanup-hook.sh から削除済みスクリプト参照を除去
```

---

## context

```yaml
mode: normal             # normal | interrupt
interrupt_reason: null
return_to: null
```

> **コンテキストモード**: 新しい要求が来た時の処理方法を制御。
> normal: 通常の作業続行
> interrupt: 現在の作業を中断して新要求を処理

---

## verification

```yaml
self_complete: true      # LLM の自己申告（critic PASS で true）
user_verified: false     # ユーザーの確認（明示的 OK で true）
```

> **報酬詐欺防止**: self_complete と user_verified の両方が true になるまで done にしない。

---

## states

```yaml
flow: pending → designing → implementing → reviewing → done
forbidden:
  - pending → done (without critic)
  - implementing → done (without reviewer)
  - * → done (without state_update)
```

> **状態遷移ルール**: 許可される遷移と禁止される遷移を定義。

---

## rules

```yaml
原則: focus.current のレイヤーのみ編集可能
例外: state.md の focus/context/verification は常に編集可能
保護: CLAUDE.md は HARD_BLOCK（管理者以外変更不可）
```

---

## session

```yaml
last_start: 2025-12-21 14:26:47
last_clear: 2025-12-13 00:30:00
uncommitted_warning: false
```

---

## config

```yaml
security: admin
toolstack: B  # A: Claude Code only | B: +Codex | C: +Codex+CodeRabbit
roles:
  orchestrator: claudecode  # 監督・調整・設計（常に claudecode）
  worker: codex             # 実装担当（A: claudecode, B/C: codex）
  reviewer: codex           # レビュー担当（M123: codex 指定）
  human: user               # 人間の介入（常に user）
```

---

## SPEC_SNAPSHOT

```yaml
readme:
  hooks: 22
  milestone_count: 50
project:
  total: 50
  achieved: 50
  pending: 0
last_checked: 2025-12-20
```

> **仕様同期スナップショット**: README/project.md の数値を記録。
> check-spec-sync.sh が実行時にこの値と実態を比較し、乖離があれば警告を出力する。

---

## FREEZE_QUEUE

```yaml
queue:
  # DISCARD判定（M122精査）
  - { path: "docs/current-definitions.md", freeze_date: "2025-12-21", reason: "M122 DISCARD - 一時的な整理用、役割終了" }
  - { path: "docs/deprecated-references.md", freeze_date: "2025-12-21", reason: "M122 DISCARD - 一時的な整理用、役割終了" }
  - { path: "docs/document-catalog.md", freeze_date: "2025-12-21", reason: "M122 DISCARD - essential-documents.md で代替" }
  - { path: "docs/flow-test-report.md", freeze_date: "2025-12-21", reason: "M122 DISCARD - M107完了報告、役割終了" }
  - { path: "docs/golden-path-verification-report.md", freeze_date: "2025-12-21", reason: "M122 DISCARD - M105完了報告、役割終了" }
  - { path: "docs/m106-critic-guard-patch.md", freeze_date: "2025-12-21", reason: "M122 DISCARD - M106パッチ、適用済み" }
  - { path: "docs/scenario-test-report.md", freeze_date: "2025-12-21", reason: "M122 DISCARD - M110完了報告、役割終了" }
  # MERGE済判定（M122精査）
  - { path: "docs/admin-contract.md", freeze_date: "2025-12-21", reason: "M122 MERGE済 → core-contract.md" }
  - { path: "docs/archive-operation-rules.md", freeze_date: "2025-12-21", reason: "M122 MERGE済 → folder-management.md" }
  - { path: "docs/artifact-management-rules.md", freeze_date: "2025-12-21", reason: "M122 MERGE済 → folder-management.md" }
  - { path: "docs/completion-criteria.md", freeze_date: "2025-12-21", reason: "M122 MERGE済 → verification-criteria.md" }
  - { path: "docs/orchestration-contract.md", freeze_date: "2025-12-21", reason: "M122 MERGE済 → ai-orchestration.md" }
  - { path: "docs/toolstack-patterns.md", freeze_date: "2025-12-21", reason: "M122 MERGE済 → ai-orchestration.md" }
  # MERGE判定（未統合、統合後にキュー入り）
  - { path: "docs/ARCHITECTURE.md", freeze_date: "2025-12-21", reason: "M122 MERGE → layer-architecture-design.md" }
  - { path: "docs/flow-document-map.md", freeze_date: "2025-12-21", reason: "M122 MERGE → essential-documents.md" }
  - { path: "docs/hook-registry.md", freeze_date: "2025-12-21", reason: "M122 MERGE → repository-map.yaml" }
  # M123 MERGE（機能把握の単一化）
  - { path: "docs/repository-map.yaml", freeze_date: "2025-12-21", reason: "M123 MERGE → essential-documents.md + core-manifest.yaml で代替" }
freeze_period_days: 7
```

> **削除予定ファイルの凍結キュー**: 削除前に一定期間保持するファイルのリスト。
> freeze-file.sh でファイルを追加、delete-frozen.sh で凍結期間経過後に削除。
> 形式: `- { path: "path/to/file", freeze_date: "YYYY-MM-DD", reason: "理由" }`

---

## DELETE_LOG

```yaml
log: []
# 注: 2025-12-21 に誤って削除された15ファイルは git checkout で復元済み
```

> **削除履歴ログ**: 削除されたファイルの記録。
> delete-frozen.sh が削除実行時に自動で記録。
> 形式: `- { path: "path/to/file", deleted_date: "YYYY-MM-DD", reason: "理由" }`

---

## 参照

| ファイル | 役割 |
|----------|------|
| CLAUDE.md | LLM の振る舞いルール |
| plan/project.md | プロジェクト計画 |
| docs/essential-documents.md | 動線単位の必須ドキュメント（自動生成） |
| governance/core-manifest.yaml | コンポーネント正本（手動） |
| docs/folder-management.md | フォルダ管理ルール |
