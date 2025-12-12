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
phase: p0        # 現状分析と systemMessage 設計
done_criteria:
  - "prompt-guard.sh が systemMessage を JSON で返す仕組みを理解している"
  - "state.md, project.md, playbook から注入すべき情報をリスト化している"
  - "systemMessage の構造（focus, goal, phase, remaining）を設計している"
  - "実際に prompt-guard.sh の実行結果を確認した"
  - "実際に動作確認済み（test_method 実行）"
```

---

## session

```yaml
last_start: 2025-12-12 23:57:49
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
