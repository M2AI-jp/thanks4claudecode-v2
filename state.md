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
active: null
branch: null
last_archived: plan/archive/playbook-m156-pipeline-completeness-audit.md
```

---

## goal

```yaml
milestone: M156
phase: p_final
done_when:
  - "4動線すべてがE2Eで PASS（flow-runtime-test.sh が 25/25 PASS）"
  - "不要なファイル/フォルダがゼロ（deletion_candidates が全て処理済み）"
  - "全ファイルが「なぜ存在するか」を1文で説明できる（core-manifest.yaml で網羅）"
  - "project.md が実態と完全同期（M142-M155 の achieved_at 設定、M156 追加）"
next: p1
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
self_complete: false      # LLM の自己申告（critic PASS で true）
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
last_start: 2025-12-22 01:21:41
last_clear: 2025-12-13 00:30:00
uncommitted_warning: true
deep_audit_completed: 2025-12-21
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
  # M148 KEEP（依存関係情報として保持）
  - { path: "docs/hook-registry.md", freeze_date: "2025-12-21", reason: "KEEP - 呼び出し元・削除可否の固有情報あり、core-manifest.yaml で代替不可" }
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
log:
  # M148 MERGE予定ドキュメント統合（2025-12-21）
  - { path: "docs/flow-document-map.md", deleted_date: "2025-12-21", reason: "M148 DISCARD → essential-documents.md で完全カバー" }
  - { path: "docs/ARCHITECTURE.md", deleted_date: "2025-12-21", reason: "M148 MIGRATE → layer-architecture-design.md に付録として移行" }
  # M147 MERGE済ドキュメント削除（2025-12-21）
  - { path: "docs/admin-contract.md", deleted_date: "2025-12-21", reason: "M147 MERGE済 → core-contract.md に統合" }
  - { path: "docs/archive-operation-rules.md", deleted_date: "2025-12-21", reason: "M147 MERGE済 → folder-management.md に統合" }
  - { path: "docs/artifact-management-rules.md", deleted_date: "2025-12-21", reason: "M147 MERGE済 → folder-management.md に統合" }
  - { path: "docs/completion-criteria.md", deleted_date: "2025-12-21", reason: "M147 MERGE済 → verification-criteria.md に統合" }
  - { path: "docs/orchestration-contract.md", deleted_date: "2025-12-21", reason: "M147 MERGE済 → ai-orchestration.md に統合" }
  - { path: "docs/toolstack-patterns.md", deleted_date: "2025-12-21", reason: "M147 MERGE済 → ai-orchestration.md に統合" }
  # M146 コンテキスト収束（2025-12-21）
  - { path: "plan/playbook-m127-playbook-reviewer-automation.md", deleted_date: "2025-12-21", reason: "M146 - archive/ に正本あり（重複削除）" }
  - { path: "plan/playbook-m142-hook-tests.md", deleted_date: "2025-12-21", reason: "M146 - archive/ に正本あり（重複削除）" }
  - { path: "docs/current-definitions.md", deleted_date: "2025-12-21", reason: "M146 DISCARD - 一時的な整理用、役割終了" }
  - { path: "docs/deprecated-references.md", deleted_date: "2025-12-21", reason: "M146 DISCARD - 一時的な整理用、役割終了" }
  - { path: "docs/document-catalog.md", deleted_date: "2025-12-21", reason: "M146 DISCARD - essential-documents.md で代替" }
  - { path: "docs/flow-test-report.md", deleted_date: "2025-12-21", reason: "M146 DISCARD - M107完了報告、役割終了" }
  - { path: "docs/golden-path-verification-report.md", deleted_date: "2025-12-21", reason: "M146 DISCARD - M105完了報告、役割終了" }
  - { path: "docs/m106-critic-guard-patch.md", deleted_date: "2025-12-21", reason: "M146 DISCARD - M106パッチ、適用済み" }
  - { path: "docs/scenario-test-report.md", deleted_date: "2025-12-21", reason: "M146 DISCARD - M110完了報告、役割終了" }
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
