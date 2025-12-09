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
branch: main
```

---

## goal

```yaml
phase: p7
name: playbook-pr-automation / ドキュメント更新とクリーンアップ
task: PR 自動化機能の実装完了をドキュメントに反映
assignee: claudecode

done_criteria:
  - docs/git-operations.md の「PR 作成・マージ」セクションを「実装済み」に更新
  - docs/current-implementation.md が自動更新されている
  - 実装関連のメモファイルが削除されている（temp-*.md など）
  - README.md に「PR 自動化」機能を追加
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
