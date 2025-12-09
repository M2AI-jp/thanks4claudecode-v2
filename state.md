# state.md

> **現在地を示す Single Source of Truth**
>
> LLM はセッション開始時に必ずこのファイルを読み、focus と playbook を確認すること。

---

## focus

```yaml
current: product
```

---

## active_playbooks

```yaml
product: plan/active/playbook-full-autonomy.md
setup: null
workspace: null
```

---

## playbook

```yaml
active: plan/active/playbook-full-autonomy.md
branch: feat/full-autonomy-implementation
```

---

## goal

```yaml
phase: p8
name: 最終コミット
task: 全変更をコミットし、playbook をアーカイブ
assignee: claudecode

done_criteria:
  - git commit が成功
  - mission.md の success_criteria が全てチェック済み
  - playbook が .archive/ に移動
```

---

## verification

```yaml
self_complete: true
user_verified: false
```

---

## session

```yaml
last_start: 2025-12-10 03:25:05
last_end: 2025-12-09 21:22:42
```

---

## config

```yaml
security: admin          # strict | trusted | developer | admin
learning:
  operator: hybrid       # human | hybrid | llm
  expertise: intermediate  # beginner | intermediate | expert
```

---

## 参照

| ファイル | 役割 |
|----------|------|
| CLAUDE.md | LLM の振る舞いルール |
| plan/project.md | Macro 計画 |
| docs/current-implementation.md | 実装仕様書 |
| .claude/context/history.md | 詳細履歴 |
