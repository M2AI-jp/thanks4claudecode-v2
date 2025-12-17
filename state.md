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
active: plan/playbook-m062-fraud-investigation-e2e.md
branch: feat/m062-fraud-investigation-e2e
last_archived: M061 playbook-m061-done-when-correction.md (2025-12-17)
```

---

## goal

```yaml
milestone: M062
phase: p1
done_criteria:
  - M001-M061 の全 milestone に対して done_when の達成状況が検証されている
  - archive-playbook.sh に subtask 単位の完了チェックが追加されている
  - docs/e2e-simulation-log.md に全 Hook/SubAgent/Skill の動作確認ログが記録されている
  - 発見された報酬詐欺（done_when 未達成）が 0 件、または修正済みである
```

---

## session

```yaml
last_start: 2025-12-17 04:32:26
last_clear: 2025-12-13 00:30:00
```

---

## config

```yaml
security: admin
toolstack: A  # A: Claude Code only | B: +Codex | C: +Codex+CodeRabbit
```

---

## 参照

| ファイル | 役割 |
|----------|------|
| CLAUDE.md | LLM の振る舞いルール |
| plan/project.md | プロジェクト計画 |
| docs/repository-map.yaml | 全ファイルマッピング（自動生成） |
| docs/folder-management.md | フォルダ管理ルール |
