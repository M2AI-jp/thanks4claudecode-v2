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
active: plan/playbook-m073-ai-orchestration.md
branch: feat/m073-ai-orchestration
last_archived: M072 playbook-m072-fix.md (2025-12-17)
```

---

## goal

```yaml
milestone: M073 AI エージェントオーケストレーション
phase: p_final
done_criteria:
  - state.md の config セクションに roles マッピングが追加されている
  - playbook-format.md に meta.roles セクションの説明が追加されている
  - role-resolver.sh が存在し、役割 -> executor 解決ロジックが実装されている
  - executor-guard.sh が role-resolver.sh を呼び出している
  - pm SubAgent が roles セクションについて記述している
  - docs/ai-orchestration.md が存在し、50行以上で文書化されている
```

---

## session

```yaml
last_start: 2025-12-17 23:00:26
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
