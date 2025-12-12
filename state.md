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
phase: p2        # /clear 後の発火テストと条件分岐
done_criteria:
  - "state.md の playbook=null の場合のログが有る"
  - "/clear 後に test-injection.sh を実行して動作確認した"
  - "systemMessage が state=null, goal=null でも正しく出力される"
  - "playbook がない場合と、ある場合の両方で動作確認済み"
  - "/clear コマンドの前後で state.md の内容が変わることを確認"
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
