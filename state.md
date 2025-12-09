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
phase: p3
name: playbook-pr-automation / PR 自動作成フック統合
task: create-pr-hook.sh 作成と settings.json 統合
assignee: claudecode

done_criteria:
  - create-pr-hook.sh が .claude/hooks/ に存在する
  - POST_LOOP で PR 作成が自動呼び出しされる
  - CLAUDE.md POST_LOOP セクションに「PR 作成」を記載
  - .claude/settings.json に hook 登録が追加される
  - settings.json の JSON 形式が正しい
  - check-coherence.sh が PASS する
  - 実際に動作確認済み（test_method 実行）
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
