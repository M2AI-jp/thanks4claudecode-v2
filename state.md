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

## playbook

```yaml
active: plan/active/playbook-system-foundation-redesign.md
branch: feat/system-foundation-redesign
```

---

## goal

```yaml
phase: p4
name: 最終検証
task: 全変更が正常に機能することを確認
assignee: claudecode

done_criteria:
  - project.md 200行以下
  - state.md 100行以下
  - エコシステム正常動作
  - critic PASS
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
last_start: 2025-12-10 00:52:39
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
