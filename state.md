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
active: plan/playbook-m056-completion-verification.md
branch: feat/m056-completion-verification
last_archived: M055 (achieved: 2025-12-17)
```

---

## goal

```yaml
milestone: M056
phase: p_final (done)
done_criteria:
  - playbook-format.md に完了検証フェーズ（p_final）が必須として追加されている ✓
  - archive-playbook.sh が done_when の test_command を再実行して検証する ✓
  - subtask-guard が final_tasks の status: done をブロックしない ✓
  - 既存の achieved milestone の done_when が実際に満たされているか再検証完了 ✓
  - V12 チェックボックス形式が全コンポーネントに適用されている ✓
```

---

## session

```yaml
last_start: 2025-12-17 02:59:27
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
