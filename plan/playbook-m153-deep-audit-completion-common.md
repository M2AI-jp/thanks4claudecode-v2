# playbook-m153-deep-audit-completion-common.md

> **Deep Audit - 完了動線 + 共通基盤 + 横断的**
>
> 完了動線7 + 共通基盤6 + 横断的3 = 16ファイルを1つずつ精査

---

## meta

```yaml
schema_version: v2
project: deep-audit
branch: feat/m153-deep-audit-completion
created: 2025-12-21
issue: null
derives_from: M152
reviewed: false
roles:
  worker: claudecode
  reviewer: codex

user_prompt_original: |
  凍結対象の全ファイルを動線単位で1つずつ精査する
```

---

## goal

```yaml
summary: 完了動線+共通基盤+横断的の16ファイルを深く精査し、凍結判定を行う
done_when:
  - "全16ファイルが Read され、動作が理解されている"
  - "各ファイルに対して Codex レビューが完了している"
  - "各ファイルの処遇（Keep/Simplify/Delete）が決定している"
  - "動作確認テストが実施されている"
  - "精査結果が docs/deep-audit-completion-common.md に記録されている"
```

---

## phases

### p1: 完了動線（7ファイル）

**goal**: 完了動線の全ファイルを精査

#### subtasks

- [ ] **p1.1**: archive-playbook.sh 精査
  - executor: claudecode
  - test_command: `test -f .claude/hooks/archive-playbook.sh && bash -n .claude/hooks/archive-playbook.sh && echo PASS || echo FAIL`
  - note: "playbook アーカイブ処理、Codex レビュー必須"

- [ ] **p1.2**: cleanup-hook.sh 精査
  - executor: claudecode
  - test_command: `test -f .claude/hooks/cleanup-hook.sh && bash -n .claude/hooks/cleanup-hook.sh && echo PASS || echo FAIL`
  - note: "tmp/ クリーンアップ、Codex レビュー必須"

- [ ] **p1.3**: post-loop.md 精査
  - executor: claudecode
  - test_command: `test -f .claude/commands/post-loop.md && echo PASS || echo FAIL`
  - note: "完了後処理コマンド、Codex レビュー必須"

- [ ] **p1.4**: context-management/SKILL.md 精査
  - executor: claudecode
  - test_command: `test -f .claude/skills/context-management/SKILL.md && echo PASS || echo FAIL`
  - note: "コンテキスト管理、Codex レビュー必須"

- [ ] **p1.5**: rollback.md 精査
  - executor: claudecode
  - test_command: `test -f .claude/commands/rollback.md && echo PASS || echo FAIL`
  - note: "Git ロールバック、Codex レビュー必須"

- [ ] **p1.6**: state-rollback.md 精査
  - executor: claudecode
  - test_command: `test -f .claude/commands/state-rollback.md && echo PASS || echo FAIL`
  - note: "state.md ロールバック、Codex レビュー必須"

- [ ] **p1.7**: focus.md 精査
  - executor: claudecode
  - test_command: `test -f .claude/commands/focus.md && echo PASS || echo FAIL`
  - note: "focus 切り替え、Codex レビュー必須"

**status**: pending
**max_iterations**: 5

---

### p2: 共通基盤（6ファイル）

**goal**: 共通基盤の全ファイルを精査

#### subtasks

- [ ] **p2.1**: session-start.sh 精査
  - executor: claudecode
  - test_command: `test -f .claude/hooks/session-start.sh && bash -n .claude/hooks/session-start.sh && echo PASS || echo FAIL`
  - note: "セッション初期化、Core の可能性あり、Codex レビュー必須"

- [ ] **p2.2**: session-end.sh 精査
  - executor: claudecode
  - test_command: `test -f .claude/hooks/session-end.sh && bash -n .claude/hooks/session-end.sh && echo PASS || echo FAIL`
  - note: "セッション終了処理、Codex レビュー必須"

- [ ] **p2.3**: pre-compact.sh 精査
  - executor: claudecode
  - test_command: `test -f .claude/hooks/pre-compact.sh && bash -n .claude/hooks/pre-compact.sh && echo PASS || echo FAIL`
  - note: "コンパクト前処理、Codex レビュー必須"

- [ ] **p2.4**: stop-summary.sh 精査
  - executor: claudecode
  - test_command: `test -f .claude/hooks/stop-summary.sh && bash -n .claude/hooks/stop-summary.sh && echo PASS || echo FAIL`
  - note: "中断時サマリー、Codex レビュー必須"

- [ ] **p2.5**: log-subagent.sh 精査
  - executor: claudecode
  - test_command: `test -f .claude/hooks/log-subagent.sh && bash -n .claude/hooks/log-subagent.sh && echo PASS || echo FAIL`
  - note: "SubAgent ログ、Codex レビュー必須"

- [ ] **p2.6**: compact.md 精査
  - executor: claudecode
  - test_command: `test -f .claude/commands/compact.md && echo PASS || echo FAIL`
  - note: "コンテキスト管理コマンド、Codex レビュー必須"

**status**: pending
**max_iterations**: 5

---

### p3: 横断的整合性（3ファイル）

**goal**: 横断的整合性の全ファイルを精査

#### subtasks

- [ ] **p3.1**: check-coherence.sh 精査
  - executor: claudecode
  - test_command: `test -f .claude/hooks/check-coherence.sh && bash -n .claude/hooks/check-coherence.sh && echo PASS || echo FAIL`
  - note: "focus/playbook/branch 整合性、Codex レビュー必須"

- [ ] **p3.2**: depends-check.sh 精査
  - executor: claudecode
  - test_command: `test -f .claude/hooks/depends-check.sh && bash -n .claude/hooks/depends-check.sh && echo PASS || echo FAIL`
  - note: "playbook 間依存関係、Codex レビュー必須"

- [ ] **p3.3**: executor-guard.sh 精査
  - executor: claudecode
  - test_command: `test -f .claude/hooks/executor-guard.sh && bash -n .claude/hooks/executor-guard.sh && echo PASS || echo FAIL`
  - note: "executor 制御、Codex レビュー必須"

**status**: pending
**max_iterations**: 3

---

### p4: Codex 一括レビュー

**goal**: 全16ファイルについて Codex の詳細レビューを実施

**depends_on**: [p1, p2, p3]

#### subtasks

- [ ] **p4.1**: 完了動線 Codex レビュー
  - executor: codex
  - test_command: `grep -q "完了動線.*Codex" docs/deep-audit-completion-common.md && echo PASS || echo FAIL`
  - note: "7ファイルの設計・実装レビュー"

- [ ] **p4.2**: 共通基盤 Codex レビュー
  - executor: codex
  - test_command: `grep -q "共通基盤.*Codex" docs/deep-audit-completion-common.md && echo PASS || echo FAIL`
  - note: "6ファイルの設計・実装レビュー"

- [ ] **p4.3**: 横断的 Codex レビュー
  - executor: codex
  - test_command: `grep -q "横断的.*Codex" docs/deep-audit-completion-common.md && echo PASS || echo FAIL`
  - note: "3ファイルの設計・実装レビュー"

**status**: pending
**max_iterations**: 5

---

### p_final: 完了動線+共通基盤+横断的精査完了

**goal**: 全16ファイルの精査結果を確定

**depends_on**: [p4]

#### subtasks

- [ ] **p_final.1**: docs/deep-audit-completion-common.md に全結果を記録
  - executor: claudecode
  - test_command: `test -f docs/deep-audit-completion-common.md && grep -c "Keep\|Simplify\|Delete" docs/deep-audit-completion-common.md | [ $(cat) -ge 16 ] && echo PASS || echo FAIL`

- [ ] **p_final.2**: 完了動線テスト全 PASS
  - executor: claudecode
  - test_command: `bash scripts/flow-runtime-test.sh 2>&1 | grep "Completion Flow" -A10 | grep -c "PASS" | [ $(cat) -ge 5 ] && echo PASS || echo FAIL`

**status**: pending
**max_iterations**: 3

---

## final_tasks

- [ ] **ft1**: 変更を全てコミットする
  - command: `git add -A && git status`
  - status: pending

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-21 | 初版作成 |
