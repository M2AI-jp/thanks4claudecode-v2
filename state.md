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
last_archived: plan/archive/playbook-m119-consent-guard-fix.md
```

---

## goal

```yaml
milestone: null
phase: null
done_when: []
next: null
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
self_complete: false     # LLM の自己申告（critic PASS で true）
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
last_start: 2025-12-21 01:48:36
last_clear: 2025-12-13 00:30:00
uncommitted_warning: false
```

---

## config

```yaml
security: admin
toolstack: A  # A: Claude Code only | B: +Codex | C: +Codex+CodeRabbit
roles:
  orchestrator: claudecode  # 監督・調整・設計（常に claudecode）
  worker: claudecode        # 実装担当（A: claudecode, B/C: codex）
  reviewer: claudecode      # レビュー担当（A/B: claudecode, C: coderabbit）
  human: user               # 人間の介入（常に user）
```

---

## COMPONENT_REGISTRY

```yaml
hooks: 22
agents: 3
skills: 7
commands: 8
last_verified: 2025-12-20
```

> **Single Source of Truth**: コンポーネント数の正規値。
> 正本は governance/core-manifest.yaml。

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
queue: []
freeze_period_days: 7
```

> **削除予定ファイルの凍結キュー**: 削除前に一定期間保持するファイルのリスト。
> freeze-file.sh でファイルを追加、delete-frozen.sh で凍結期間経過後に削除。
> 形式: `- { path: "path/to/file", freeze_date: "YYYY-MM-DD", reason: "理由" }`

---

## DELETE_LOG

```yaml
log: []
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
| docs/repository-map.yaml | 全ファイルマッピング（自動生成） |
| docs/folder-management.md | フォルダ管理ルール |
