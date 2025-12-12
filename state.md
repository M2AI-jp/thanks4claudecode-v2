# state.md

> **現在地を示す Single Source of Truth**
>
> LLM はセッション開始時に必ずこのファイルを読み、focus と playbook を確認すること。

---

## focus

```yaml
current: thanks4claudecode  # 現在作業中のプロジェクト名
project: plan/project.md
```

---

## playbook

```yaml
active: plan/active/playbook-state-injection.md
branch: feat/state-injection
```

---

## goal

```yaml
milestone: M005  # 確実な初期化システム（StateInjection）
phase: p4        # ドキュメント更新とクリーンアップ
done_criteria:
  - "docs/state-injection-guide.md が作成されている"
  - "systemMessage の注入フロー、注入する情報、フォーマットが記載されている"
  - "draft-injection-design.md が削除されている"
  - "test-injection.sh, test-no-read.sh が削除されている"
  - "state.md の playbook と goal が正しく設定されている"
  - "実際に動作確認済み（test_method 実行）"
```

---

## session

```yaml
last_start: 2025-12-13 00:52:06
last_clear: 2025-12-13 00:30:00
```

---

## config

```yaml
security: admin
learning:
  operator: hybrid
  expertise: intermediate
```

---

## 参照

| ファイル | 役割 |
|----------|------|
| CLAUDE.md | LLM の振る舞いルール |
| plan/project.md | プロジェクト計画 |
| docs/feature-map.md | 機能マップ |
