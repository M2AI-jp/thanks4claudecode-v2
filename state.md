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
product: plan/active/playbook-pr-automation.md
setup: null
workspace: null
```

---

## playbook

```yaml
active: plan/active/playbook-pr-automation.md
branch: feat/pr-automation
```

---

## goal

```yaml
phase: p1
name: playbook-pr-automation / 現状分析と設計
task: PR 作成・マージフローの現状分析
assignee: claudecode

done_criteria:
  - docs/git-operations.md の「PR 作成・マージ」セクションを読んだ
  - CLAUDE.md の「POST_LOOP」セクションを読んだ
  - GitHub API vs gh CLI の比較表を作成した
  - 実装方針（gh CLI 使用）を決定した
  - 実装予定の Phase を列挙した
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
last_start: 2025-12-10 04:00:44
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
