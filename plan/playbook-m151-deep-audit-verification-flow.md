# playbook-m151-deep-audit-verification-flow.md

> **Deep Audit - 検証動線**
>
> 検証動線の全5ファイルを1つずつ精査し、動作確認、必要性議論、Codex レビューを実施

---

## meta

```yaml
schema_version: v2
project: deep-audit
branch: feat/m151-deep-audit-verification
created: 2025-12-21
issue: null
derives_from: M150
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
summary: 検証動線の5ファイルを深く精査し、凍結判定を行う
done_when:
  - "全5ファイルが Read され、動作が理解されている"
  - "各ファイルに対して Codex レビューが完了している"
  - "各ファイルの処遇（Keep/Simplify/Delete）が決定している"
  - "動作確認テストが実施されている"
  - "精査結果が docs/deep-audit-verification-flow.md に記録されている"
```

---

## phases

### p1: crit.md 精査

**goal**: crit.md（/crit コマンド）の完全な理解と動作確認

#### subtasks

- [ ] **p1.1**: ファイルを Read し、全ロジックを理解
  - executor: claudecode
  - test_command: `test -f .claude/commands/crit.md && echo PASS || echo FAIL`
  - validations:
    - technical: "ファイルが存在する"
    - consistency: "critic SubAgent を呼び出す設計"
    - completeness: "done_criteria 検証の起点として機能"

- [ ] **p1.2**: Codex レビュー依頼
  - executor: codex
  - test_command: `grep -q "crit.md" docs/deep-audit-verification-flow.md && echo PASS || echo FAIL`
  - validations:
    - technical: "Codex がコマンド定義を読み、フィードバックを返している"
    - consistency: "critic.md との連携が正しい"
    - completeness: "検証フローが完結している"

- [ ] **p1.3**: 処遇決定
  - executor: claudecode
  - test_command: `grep -q "crit.md.*Keep" docs/deep-audit-verification-flow.md && echo PASS || echo FAIL`
  - validations:
    - technical: "Keep として確定（検証動線の起点）"
    - consistency: "Core Layer として凍結対象"
    - completeness: "理由が記録されている"

**status**: pending
**max_iterations**: 3

---

### p2: critic.md 精査

**goal**: critic.md（critic SubAgent）の完全な理解と動作確認

#### subtasks

- [ ] **p2.1**: ファイルを Read し、全ロジックを理解
  - executor: claudecode
  - test_command: `test -f .claude/agents/critic.md && echo PASS || echo FAIL`
  - validations:
    - technical: "ファイルが存在する"
    - consistency: "done_criteria を検証する唯一の存在"
    - completeness: "PASS/FAIL 判定、self_complete 更新が含まれている"

- [ ] **p2.2**: Codex レビュー依頼
  - executor: codex
  - test_command: `grep -q "critic.md" docs/deep-audit-verification-flow.md && echo PASS || echo FAIL`
  - validations:
    - technical: "Codex が SubAgent 定義を読み、フィードバックを返している"
    - consistency: "報酬詐欺防止の設計が妥当"
    - completeness: "test_command 実行ロジックが含まれている"

- [ ] **p2.3**: 処遇決定
  - executor: claudecode
  - test_command: `grep -q "critic.md.*Keep" docs/deep-audit-verification-flow.md && echo PASS || echo FAIL`
  - validations:
    - technical: "Keep として確定（検証動線の中核）"
    - consistency: "Core Layer として凍結対象"
    - completeness: "理由が記録されている"

**status**: pending
**max_iterations**: 3

---

### p3: critic-guard.sh 精査

**goal**: critic-guard.sh の完全な理解と動作確認

#### subtasks

- [ ] **p3.1**: ファイルを Read し、全ロジックを理解
  - executor: claudecode
  - test_command: `test -f .claude/hooks/critic-guard.sh && bash -n .claude/hooks/critic-guard.sh && echo PASS || echo FAIL`
  - validations:
    - technical: "ファイルが存在し構文エラーがない"
    - consistency: "phase 完了時に critic PASS を強制"
    - completeness: "self_complete チェック、セッションリセット対応"

- [ ] **p3.2**: 動作確認テスト
  - executor: claudecode
  - test_command: `echo '{"tool_input":{"file_path":"state.md"}}' | bash .claude/hooks/critic-guard.sh > /dev/null 2>&1; [ $? -le 1 ] && echo PASS || echo FAIL`
  - validations:
    - technical: "JSON 入力で動作する"
    - consistency: "state.md 編集時に適切に判定"
    - completeness: "エラーなく動作する"

- [ ] **p3.3**: Codex レビュー依頼
  - executor: codex
  - test_command: `grep -q "critic-guard.sh" docs/deep-audit-verification-flow.md && echo PASS || echo FAIL`
  - validations:
    - technical: "Codex がコードを読み、フィードバックを返している"
    - consistency: "M149 で追加した self_complete リセット対応を評価"
    - completeness: "改善提案があれば記録されている"

- [ ] **p3.4**: 処遇決定
  - executor: claudecode
  - test_command: `grep -q "critic-guard.sh.*Keep" docs/deep-audit-verification-flow.md && echo PASS || echo FAIL`
  - validations:
    - technical: "Keep として確定（報酬詐欺防止の要）"
    - consistency: "Core Layer として凍結対象"
    - completeness: "理由が記録されている"

**status**: pending
**max_iterations**: 3

---

### p4: test.md 精査

**goal**: test.md（/test コマンド）の完全な理解と動作確認

#### subtasks

- [ ] **p4.1**: ファイルを Read し、全ロジックを理解
  - executor: claudecode
  - test_command: `test -f .claude/commands/test.md && echo PASS || echo FAIL`
  - validations:
    - technical: "ファイルが存在する"
    - consistency: "test_command を実行するコマンド"
    - completeness: "done_criteria の検証に使用"

- [ ] **p4.2**: Codex レビュー依頼
  - executor: codex
  - test_command: `grep -q "test.md" docs/deep-audit-verification-flow.md && echo PASS || echo FAIL`
  - validations:
    - technical: "Codex がコマンド定義を読み、フィードバックを返している"
    - consistency: "test-runner Skill との関係"
    - completeness: "機能が重複していないか確認"

- [ ] **p4.3**: 処遇決定
  - executor: claudecode
  - test_command: `grep -q "test.md.*Keep\|test.md.*Simplify" docs/deep-audit-verification-flow.md && echo PASS || echo FAIL`
  - validations:
    - technical: "Keep/Simplify のいずれかが決定"
    - consistency: "Core Layer として凍結対象"
    - completeness: "理由が記録されている"

**status**: pending
**max_iterations**: 3

---

### p5: lint.md 精査

**goal**: lint.md（/lint コマンド）の完全な理解と動作確認

#### subtasks

- [ ] **p5.1**: ファイルを Read し、全ロジックを理解
  - executor: claudecode
  - test_command: `test -f .claude/commands/lint.md && echo PASS || echo FAIL`
  - validations:
    - technical: "ファイルが存在する"
    - consistency: "state/playbook 整合性チェック"
    - completeness: "構造的整合性を検証"

- [ ] **p5.2**: Codex レビュー依頼
  - executor: codex
  - test_command: `grep -q "lint.md" docs/deep-audit-verification-flow.md && echo PASS || echo FAIL`
  - validations:
    - technical: "Codex がコマンド定義を読み、フィードバックを返している"
    - consistency: "lint-checker Skill との関係"
    - completeness: "機能が重複していないか確認"

- [ ] **p5.3**: 処遇決定
  - executor: claudecode
  - test_command: `grep -q "lint.md.*Keep\|lint.md.*Simplify" docs/deep-audit-verification-flow.md && echo PASS || echo FAIL`
  - validations:
    - technical: "Keep/Simplify のいずれかが決定"
    - consistency: "Core Layer として凍結対象"
    - completeness: "理由が記録されている"

**status**: pending
**max_iterations**: 3

---

### p_final: 検証動線精査完了

**goal**: 全5ファイルの精査結果を確定

**depends_on**: [p1, p2, p3, p4, p5]

#### subtasks

- [ ] **p_final.1**: docs/deep-audit-verification-flow.md に全結果を記録
  - executor: claudecode
  - test_command: `test -f docs/deep-audit-verification-flow.md && grep -c "Keep\|Simplify\|Delete" docs/deep-audit-verification-flow.md | [ $(cat) -ge 5 ] && echo PASS || echo FAIL`
  - validations:
    - technical: "5ファイル全ての処遇が記録されている"
    - consistency: "Codex レビュー結果が反映されている"
    - completeness: "理由と改善提案が含まれている"

- [ ] **p_final.2**: 検証動線テスト全 PASS
  - executor: claudecode
  - test_command: `bash scripts/flow-runtime-test.sh 2>&1 | grep "Verification Flow" -A10 | grep -c "PASS" | [ $(cat) -ge 5 ] && echo PASS || echo FAIL`
  - validations:
    - technical: "検証動線のテストが全て PASS"
    - consistency: "精査後も動作が維持されている"
    - completeness: "破壊的変更がない"

**status**: pending
**max_iterations**: 3

---

## final_tasks

- [ ] **ft1**: 変更を全てコミットする
  - command: `git add -A && git status`
  - status: pending

---

## rollback

```yaml
手順:
  1. 精査結果ドキュメントを削除
     rm docs/deep-audit-verification-flow.md

  2. 変更した場合は復元
     git checkout HEAD -- .claude/hooks/critic-guard.sh
     # etc.
```

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-21 | 初版作成 |
