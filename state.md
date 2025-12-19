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
active: plan/playbook-m084-playbook-schema-v2.md
branch: feat/m084-playbook-schema-v2
last_archived: plan/archive/playbook-m083-state-sync-fix.md
```

---

## goal

```yaml
milestone: M084
phase: p1
done_when:
  - "[ ] plan/template/playbook-format.md に Schema v2 マーカーが存在する"
  - "[ ] .claude/hooks/playbook-validator.sh が存在し実行可能"
  - "[ ] playbook-validator.sh が不正形式を検出して exit 非0 を返す"
  - "[ ] 既存の active playbook が Schema v2 に準拠している"
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

## 参照

| ファイル | 役割 |
|----------|------|
| CLAUDE.md | LLM の振る舞いルール |
| plan/project.md | プロジェクト計画 |
| docs/repository-map.yaml | 全ファイルマッピング（自動生成） |
| docs/folder-management.md | フォルダ管理ルール |
