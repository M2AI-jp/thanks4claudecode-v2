# playbook-m152-deep-audit-execution-flow.md

> **Deep Audit - 実行動線**
>
> 実行動線の全10ファイルを1つずつ精査し、動作確認、必要性議論、Codex レビューを実施

---

## meta

```yaml
schema_version: v2
project: deep-audit
branch: feat/m152-deep-audit-execution
created: 2025-12-21
issue: null
derives_from: M151
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
summary: 実行動線の10ファイルを深く精査し、凍結判定を行う
done_when:
  - "全10ファイルが Read され、動作が理解されている"
  - "各ファイルに対して Codex レビューが完了している"
  - "各ファイルの処遇（Keep/Simplify/Delete）が決定している"
  - "動作確認テストが実施されている"
  - "精査結果が docs/deep-audit-execution-flow.md に記録されている"
```

---

## phases

### p1: init-guard.sh 精査

**goal**: init-guard.sh の完全な理解と動作確認

#### subtasks

- [ ] **p1.1**: ファイルを Read し、全ロジックを理解
  - executor: claudecode
  - test_command: `test -f .claude/hooks/init-guard.sh && bash -n .claude/hooks/init-guard.sh && echo PASS || echo FAIL`
  - validations:
    - technical: "ファイルが存在し構文エラーがない"
    - consistency: "必須ファイル Read を強制"
    - completeness: "state.md/playbook の Read を確認"

- [ ] **p1.2**: Codex レビュー依頼
  - executor: codex
  - test_command: `grep -q "init-guard.sh" docs/deep-audit-execution-flow.md && echo PASS || echo FAIL`

- [ ] **p1.3**: 処遇決定
  - executor: claudecode
  - test_command: `grep -q "init-guard.sh.*Keep\|init-guard.sh.*Simplify\|init-guard.sh.*Delete" docs/deep-audit-execution-flow.md && echo PASS || echo FAIL`

**status**: pending
**max_iterations**: 3

---

### p2: playbook-guard.sh 精査

**goal**: playbook-guard.sh の完全な理解と動作確認

#### subtasks

- [ ] **p2.1**: ファイルを Read し、全ロジックを理解
  - executor: claudecode
  - test_command: `test -f .claude/hooks/playbook-guard.sh && bash -n .claude/hooks/playbook-guard.sh && echo PASS || echo FAIL`
  - validations:
    - technical: "ファイルが存在し構文エラーがない"
    - consistency: "playbook=null で Edit/Write をブロック"
    - completeness: "Golden Path 強制の中核"

- [ ] **p2.2**: 動作確認テスト
  - executor: claudecode
  - test_command: `echo '{"tool_input":{"file_path":"test.md"}}' | bash .claude/hooks/playbook-guard.sh > /dev/null 2>&1; [ $? -le 2 ] && echo PASS || echo FAIL`

- [ ] **p2.3**: Codex レビュー依頼
  - executor: codex
  - test_command: `grep -q "playbook-guard.sh" docs/deep-audit-execution-flow.md && echo PASS || echo FAIL`

- [ ] **p2.4**: 処遇決定
  - executor: claudecode
  - test_command: `grep -q "playbook-guard.sh.*Keep" docs/deep-audit-execution-flow.md && echo PASS || echo FAIL`

**status**: pending
**max_iterations**: 3

---

### p3: subtask-guard.sh 精査

**goal**: subtask-guard.sh の完全な理解と動作確認

#### subtasks

- [ ] **p3.1**: ファイルを Read し、全ロジックを理解
  - executor: claudecode
  - test_command: `test -f .claude/hooks/subtask-guard.sh && bash -n .claude/hooks/subtask-guard.sh && echo PASS || echo FAIL`
  - validations:
    - technical: "ファイルが存在し構文エラーがない"
    - consistency: "3観点検証（technical/consistency/completeness）"
    - completeness: "STRICT モードが実装されている"

- [ ] **p3.2**: Codex レビュー依頼
  - executor: codex
  - test_command: `grep -q "subtask-guard.sh" docs/deep-audit-execution-flow.md && echo PASS || echo FAIL`

- [ ] **p3.3**: 処遇決定
  - executor: claudecode
  - test_command: `grep -q "subtask-guard.sh.*Keep\|subtask-guard.sh.*Simplify" docs/deep-audit-execution-flow.md && echo PASS || echo FAIL`

**status**: pending
**max_iterations**: 3

---

### p4: scope-guard.sh 精査

**goal**: scope-guard.sh の完全な理解と動作確認

#### subtasks

- [ ] **p4.1**: ファイルを Read し、全ロジックを理解
  - executor: claudecode
  - test_command: `test -f .claude/hooks/scope-guard.sh && bash -n .claude/hooks/scope-guard.sh && echo PASS || echo FAIL`
  - validations:
    - technical: "ファイルが存在し構文エラーがない"
    - consistency: "done_criteria 変更検出"
    - completeness: "スコープクリープ防止"

- [ ] **p4.2**: Codex レビュー依頼
  - executor: codex
  - test_command: `grep -q "scope-guard.sh" docs/deep-audit-execution-flow.md && echo PASS || echo FAIL`

- [ ] **p4.3**: 処遇決定
  - executor: claudecode
  - test_command: `grep -q "scope-guard.sh.*Keep\|scope-guard.sh.*Simplify\|scope-guard.sh.*Delete" docs/deep-audit-execution-flow.md && echo PASS || echo FAIL`

**status**: pending
**max_iterations**: 3

---

### p5: check-protected-edit.sh 精査

**goal**: check-protected-edit.sh の完全な理解と動作確認

#### subtasks

- [ ] **p5.1**: ファイルを Read し、全ロジックを理解
  - executor: claudecode
  - test_command: `test -f .claude/hooks/check-protected-edit.sh && bash -n .claude/hooks/check-protected-edit.sh && echo PASS || echo FAIL`
  - validations:
    - technical: "ファイルが存在し構文エラーがない"
    - consistency: "HARD_BLOCK ファイル保護"
    - completeness: "CLAUDE.md 等の編集を防止"

- [ ] **p5.2**: Codex レビュー依頼
  - executor: codex
  - test_command: `grep -q "check-protected-edit.sh" docs/deep-audit-execution-flow.md && echo PASS || echo FAIL`

- [ ] **p5.3**: 処遇決定
  - executor: claudecode
  - test_command: `grep -q "check-protected-edit.sh.*Keep" docs/deep-audit-execution-flow.md && echo PASS || echo FAIL`

**status**: pending
**max_iterations**: 3

---

### p6: pre-bash-check.sh 精査

**goal**: pre-bash-check.sh の完全な理解と動作確認

#### subtasks

- [ ] **p6.1**: ファイルを Read し、全ロジックを理解
  - executor: claudecode
  - test_command: `test -f .claude/hooks/pre-bash-check.sh && bash -n .claude/hooks/pre-bash-check.sh && echo PASS || echo FAIL`
  - validations:
    - technical: "ファイルが存在し構文エラーがない"
    - consistency: "危険コマンドブロック、contract.sh 呼び出し"
    - completeness: "HARD_BLOCK, playbook=null チェック"

- [ ] **p6.2**: Codex レビュー依頼
  - executor: codex
  - test_command: `grep -q "pre-bash-check.sh" docs/deep-audit-execution-flow.md && echo PASS || echo FAIL`

- [ ] **p6.3**: 処遇決定
  - executor: claudecode
  - test_command: `grep -q "pre-bash-check.sh.*Keep" docs/deep-audit-execution-flow.md && echo PASS || echo FAIL`

**status**: pending
**max_iterations**: 3

---

### p7: check-main-branch.sh 精査

**goal**: check-main-branch.sh の完全な理解と動作確認

#### subtasks

- [ ] **p7.1**: ファイルを Read し、全ロジックを理解
  - executor: claudecode
  - test_command: `test -f .claude/hooks/check-main-branch.sh && bash -n .claude/hooks/check-main-branch.sh && echo PASS || echo FAIL`
  - validations:
    - technical: "ファイルが存在し構文エラーがない"
    - consistency: "main ブランチ保護"
    - completeness: "main での直接編集を防止"

- [ ] **p7.2**: Codex レビュー依頼
  - executor: codex
  - test_command: `grep -q "check-main-branch.sh" docs/deep-audit-execution-flow.md && echo PASS || echo FAIL`

- [ ] **p7.3**: 処遇決定
  - executor: claudecode
  - test_command: `grep -q "check-main-branch.sh.*Keep" docs/deep-audit-execution-flow.md && echo PASS || echo FAIL`

**status**: pending
**max_iterations**: 3

---

### p8: lint-check.sh 精査

**goal**: lint-check.sh の完全な理解と動作確認

#### subtasks

- [ ] **p8.1**: ファイルを Read し、全ロジックを理解
  - executor: claudecode
  - test_command: `test -f .claude/hooks/lint-check.sh && bash -n .claude/hooks/lint-check.sh && echo PASS || echo FAIL`
  - validations:
    - technical: "ファイルが存在し構文エラーがない"
    - consistency: "コミット前 Lint 実行"
    - completeness: "git commit 前に静的解析"

- [ ] **p8.2**: Codex レビュー依頼
  - executor: codex
  - test_command: `grep -q "lint-check.sh" docs/deep-audit-execution-flow.md && echo PASS || echo FAIL`

- [ ] **p8.3**: 処遇決定
  - executor: claudecode
  - test_command: `grep -q "lint-check.sh.*Keep\|lint-check.sh.*Simplify\|lint-check.sh.*Delete" docs/deep-audit-execution-flow.md && echo PASS || echo FAIL`

**status**: pending
**max_iterations**: 3

---

### p9: lint-checker/SKILL.md 精査

**goal**: lint-checker Skill の完全な理解と動作確認

#### subtasks

- [ ] **p9.1**: ファイルを Read し、全ロジックを理解
  - executor: claudecode
  - test_command: `test -f .claude/skills/lint-checker/SKILL.md && echo PASS || echo FAIL`
  - validations:
    - technical: "ファイルが存在する"
    - consistency: "静的解析の専門知識を提供"
    - completeness: "ESLint, TypeScript チェック"

- [ ] **p9.2**: Codex レビュー依頼
  - executor: codex
  - test_command: `grep -q "lint-checker" docs/deep-audit-execution-flow.md && echo PASS || echo FAIL`

- [ ] **p9.3**: 処遇決定
  - executor: claudecode
  - test_command: `grep -q "lint-checker.*Keep\|lint-checker.*Simplify\|lint-checker.*Delete" docs/deep-audit-execution-flow.md && echo PASS || echo FAIL`

**status**: pending
**max_iterations**: 3

---

### p10: test-runner/SKILL.md 精査

**goal**: test-runner Skill の完全な理解と動作確認

#### subtasks

- [ ] **p10.1**: ファイルを Read し、全ロジックを理解
  - executor: claudecode
  - test_command: `test -f .claude/skills/test-runner/SKILL.md && echo PASS || echo FAIL`
  - validations:
    - technical: "ファイルが存在する"
    - consistency: "テスト実行の専門知識を提供"
    - completeness: "Unit/E2E テスト実行"

- [ ] **p10.2**: Codex レビュー依頼
  - executor: codex
  - test_command: `grep -q "test-runner" docs/deep-audit-execution-flow.md && echo PASS || echo FAIL`

- [ ] **p10.3**: 処遇決定
  - executor: claudecode
  - test_command: `grep -q "test-runner.*Keep\|test-runner.*Simplify\|test-runner.*Delete" docs/deep-audit-execution-flow.md && echo PASS || echo FAIL`

**status**: pending
**max_iterations**: 3

---

### p_final: 実行動線精査完了

**goal**: 全10ファイルの精査結果を確定

**depends_on**: [p1, p2, p3, p4, p5, p6, p7, p8, p9, p10]

#### subtasks

- [ ] **p_final.1**: docs/deep-audit-execution-flow.md に全結果を記録
  - executor: claudecode
  - test_command: `test -f docs/deep-audit-execution-flow.md && grep -c "Keep\|Simplify\|Delete" docs/deep-audit-execution-flow.md | [ $(cat) -ge 10 ] && echo PASS || echo FAIL`

- [ ] **p_final.2**: 実行動線テスト全 PASS
  - executor: claudecode
  - test_command: `bash scripts/flow-runtime-test.sh 2>&1 | grep "Execution Flow" -A15 | grep -c "PASS" | [ $(cat) -ge 9 ] && echo PASS || echo FAIL`

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
