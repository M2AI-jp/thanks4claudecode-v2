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
active: plan/playbook-m082-hook-contract.md
branch: feat/m082-hook-contract
last_archived: plan/archive/playbook-m082-archive-check.md
```

---

## goal

```yaml
milestone: M082
phase: p_final (done)
done_criteria:
  - "[x] docs/hook-exit-code-contract.md が存在し、WARN/BLOCK/INTERNAL ERROR の定義が明記されている"
  - "[x] subtask-guard.sh がパース失敗時に exit 0 + stderr メッセージを出す"
  - "[x] create-pr-hook.sh が PR 未作成時に SKIP 理由を stderr に出す"
  - "[x] archive-playbook.sh が SKIP 時に理由を stderr に出す"
  - "[x] 全対象 Hook で 'No stderr output' が再現しない"
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
