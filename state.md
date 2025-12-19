# state.md

> **現在地を示す Single Source of Truth**
>
> LLM はセッション開始時に必ずこのファイルを読み、focus と playbook を確認すること。

---

## focus

```yaml
current: plan-template  # 現在作業中のプロジェクト名
project: plan/project.md
```

---

## playbook

```yaml
active: plan/playbook-m097-anti-lie-system.md
branch: feat/m097-anti-lie-system
last_archived: plan/archive/playbook-m096-pre-bash-deadlock-fix.md
```

---

## goal

```yaml
milestone: M097
phase: done
done_when:
  - "[x] scripts/generate-readme-stats.sh が存在し実行可能"
  - "[x] README.md の数値部分が STATS タグで囲まれスクリプトで更新可能"
  - "[x] .claude/component-tiers.yaml に Core/Optional/Experimental 分類が存在"
  - "[x] docs/completion-criteria.md に 5 つのシナリオが定義されている"
```

---

## session

```yaml
last_start: 2025-12-20 00:21:30
last_clear: 2025-12-13 00:30:00
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
hooks: 34
agents: 6
skills: 9
commands: 8
last_verified: 2025-12-20
```

> **Single Source of Truth**: コンポーネント数の正規値。
> generate-repository-map.sh が実行時にこの値と比較し、差分があれば警告を出力する。

---

## SPEC_SNAPSHOT

```yaml
readme:
  hooks: 34
  milestone_count: 46
project:
  total: 45
  achieved: 45
  pending: 0
last_checked: 2025-12-19
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
