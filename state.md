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
active: plan/playbook-m089-component-registry-normalization.md
branch: feat/m089-component-registry
last_archived: plan/archive/playbook-m088-gap-fix.md
```

---

## goal

```yaml
milestone: M089
phase: p_final
done_when:
  - generate-repository-map.sh が exit 0 で完了する
  - repository-map.yaml の hooks が 33 と一致
  - repository-map.yaml の agents が 6 と一致
  - repository-map.yaml の skills が 9 と一致
  - repository-map.yaml の commands が 8 と一致
  - check-integrity.sh が PASS
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
