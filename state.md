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
active: plan/playbook-m092-ssc-phase2.md
branch: feat/m092-ssc-phase2
last_archived: plan/archive/playbook-m091-ssc-phase1.md
```

---

## goal

```yaml
milestone: M092
phase: p1
done_when:
  - state.md に SPEC_SNAPSHOT セクションが存在する
  - playbook 完了時に SPEC_SNAPSHOT が自動更新される
  - README/project.md と実態の乖離検出時に警告が出力される
```

---

## session

```yaml
last_start: 2025-12-19 15:06:14
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
hooks: 33
agents: 6
skills: 9
commands: 8
last_verified: 2025-12-19
```

> **Single Source of Truth**: コンポーネント数の正規値。
> generate-repository-map.sh が実行時にこの値と比較し、差分があれば警告を出力する。

---

## SPEC_SNAPSHOT

```yaml
readme:
  hooks: 33
  milestone_count: 45
project:
  total: 45
  achieved: 43
  pending: 2
last_checked: 2025-12-19
```

> **仕様同期スナップショット**: README/project.md の数値を記録。
> check-spec-sync.sh が実行時にこの値と実態を比較し、乖離があれば警告を出力する。

---

## 参照

| ファイル | 役割 |
|----------|------|
| CLAUDE.md | LLM の振る舞いルール |
| plan/project.md | プロジェクト計画 |
| docs/repository-map.yaml | 全ファイルマッピング（自動生成） |
| docs/folder-management.md | フォルダ管理ルール |
