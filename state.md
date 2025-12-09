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
phase: p5
name: playbook-pr-automation / POST_LOOP 統合と CLAUDE.md 更新
task: PR 作成・マージフローの POST_LOOP 統合
assignee: claudecode

done_criteria:
  - CLAUDE.md の POST_LOOP セクションに PR 作成・マージフローを記載
  - 実行順序が明記されている（PR 作成 → PR マージ → 次タスク導出）
  - 各ステップの条件分岐を明記している（成功時・失敗時）
  - state.md と playbook との整合性を確認する処理を追加
  - CLAUDE.md の syntax が正しい（YAML/Markdown）
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
last_start: 2025-12-10 04:26:57
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
