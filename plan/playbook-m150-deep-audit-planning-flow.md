# playbook-m150-deep-audit-planning-flow.md

> **Deep Audit - 計画動線**
>
> 計画動線の全7ファイルを1つずつ精査し、動作確認、必要性議論、Codex レビューを実施

---

## meta

```yaml
schema_version: v2
project: deep-audit
branch: feat/m150-deep-audit-planning
created: 2025-12-21
issue: null
derives_from: M149
reviewed: false
roles:
  worker: claudecode
  reviewer: codex

user_prompt_original: |
  監査結果を踏まえてマイルストーンの再評価をして再開。
  deep以外の議論はあり得ない。手を抜くな。
  理想はコアとして凍結するすべてのファイルごとに、
  今の動線で管理してる粒度で、文字通りコア機能は全部網羅された状態で凍結すること。
```

---

## goal

```yaml
summary: 計画動線の7ファイルを深く精査し、凍結判定を行う
done_when:
  - "全7ファイルが Read され、動作が理解されている"
  - "各ファイルに対して Codex レビューが完了している"
  - "各ファイルの処遇（Keep/Simplify/Delete）が決定している"
  - "動作確認テストが実施されている"
  - "精査結果が docs/deep-audit-planning-flow.md に記録されている"
```

---

## phases

### p1: prompt-guard.sh 精査

**goal**: prompt-guard.sh の完全な理解と動作確認

#### subtasks

- [ ] **p1.1**: ファイルを Read し、全ロジックを理解
  - executor: claudecode
  - test_command: `test -f .claude/hooks/prompt-guard.sh && echo PASS || echo FAIL`
  - validations:
    - technical: "ファイルが存在し構文エラーがない"
    - consistency: "settings.json で UserPromptSubmit に登録されている"
    - completeness: "全ロジック（State Injection, タスク検出, 質問除外）が理解されている"

- [ ] **p1.2**: 動作確認テスト
  - executor: claudecode
  - test_command: `echo '{"prompt":"テスト"}' | bash .claude/hooks/prompt-guard.sh > /dev/null && echo PASS || echo FAIL`
  - validations:
    - technical: "JSON 入力で正常終了する"
    - consistency: "State Injection が出力される"
    - completeness: "エラーなく動作する"

- [ ] **p1.3**: Codex レビュー依頼
  - executor: codex
  - test_command: `grep -q "reviewed: true" plan/playbook-m150-deep-audit-planning-flow.md && echo PASS || echo FAIL`
  - validations:
    - technical: "Codex がコードを読み、フィードバックを返している"
    - consistency: "設計意図と実装が一致している"
    - completeness: "改善提案があれば記録されている"
  - note: "codex exec --full-auto で実行"

- [ ] **p1.4**: 処遇決定
  - executor: claudecode
  - test_command: `grep -q "prompt-guard.sh.*Keep\|prompt-guard.sh.*Simplify\|prompt-guard.sh.*Delete" docs/deep-audit-planning-flow.md && echo PASS || echo FAIL`
  - validations:
    - technical: "Keep/Simplify/Delete のいずれかが決定"
    - consistency: "Codex レビュー結果を反映"
    - completeness: "理由が記録されている"

**status**: pending
**max_iterations**: 5

---

### p2: task-start.md 精査

**goal**: task-start.md の完全な理解と動作確認

#### subtasks

- [ ] **p2.1**: ファイルを Read し、全ロジックを理解
  - executor: claudecode
  - test_command: `test -f .claude/commands/task-start.md && echo PASS || echo FAIL`
  - validations:
    - technical: "ファイルが存在する"
    - consistency: "pm SubAgent を呼び出す設計になっている"
    - completeness: "計画動線の起点として機能する"

- [ ] **p2.2**: Codex レビュー依頼
  - executor: codex
  - test_command: `grep -q "task-start.md" docs/deep-audit-planning-flow.md && echo PASS || echo FAIL`
  - validations:
    - technical: "Codex がドキュメントを読み、フィードバックを返している"
    - consistency: "playbook-init.md との関係が明確"
    - completeness: "重複がないか確認されている"

- [ ] **p2.3**: 処遇決定
  - executor: claudecode
  - test_command: `grep -q "task-start.md.*Keep\|task-start.md.*Simplify\|task-start.md.*Delete" docs/deep-audit-planning-flow.md && echo PASS || echo FAIL`
  - validations:
    - technical: "Keep/Simplify/Delete のいずれかが決定"
    - consistency: "playbook-init.md との統合を検討"
    - completeness: "理由が記録されている"

**status**: pending
**max_iterations**: 3

---

### p3: pm.md 精査

**goal**: pm.md の完全な理解と動作確認

#### subtasks

- [ ] **p3.1**: ファイルを Read し、全ロジックを理解
  - executor: claudecode
  - test_command: `test -f .claude/agents/pm.md && echo PASS || echo FAIL`
  - validations:
    - technical: "ファイルが存在する"
    - consistency: "playbook 作成の唯一の正規ルート"
    - completeness: "playbook フォーマット、state.md 更新が含まれている"

- [ ] **p3.2**: Codex レビュー依頼
  - executor: codex
  - test_command: `grep -q "pm.md" docs/deep-audit-planning-flow.md && echo PASS || echo FAIL`
  - validations:
    - technical: "Codex が SubAgent 定義を読み、フィードバックを返している"
    - consistency: "playbook-format.md との整合性"
    - completeness: "必要な機能が全て含まれている"

- [ ] **p3.3**: 処遇決定
  - executor: claudecode
  - test_command: `grep -q "pm.md.*Keep\|pm.md.*Simplify\|pm.md.*Delete" docs/deep-audit-planning-flow.md && echo PASS || echo FAIL`
  - validations:
    - technical: "Keep として確定（計画動線の中核）"
    - consistency: "簡素化の余地があれば記録"
    - completeness: "理由が記録されている"

**status**: pending
**max_iterations**: 3

---

### p4: state/SKILL.md 精査

**goal**: state Skill の完全な理解と動作確認

#### subtasks

- [ ] **p4.1**: ファイルを Read し、全ロジックを理解
  - executor: claudecode
  - test_command: `test -f .claude/skills/state/SKILL.md && echo PASS || echo FAIL`
  - validations:
    - technical: "ファイルが存在する"
    - consistency: "state.md 管理の専門知識を提供"
    - completeness: "focus, playbook, verification の更新ロジックが含まれている"

- [ ] **p4.2**: Codex レビュー依頼
  - executor: codex
  - test_command: `grep -q "state/SKILL.md" docs/deep-audit-planning-flow.md && echo PASS || echo FAIL`
  - validations:
    - technical: "Codex が Skill 定義を読み、フィードバックを返している"
    - consistency: "他の Skill との重複がないか確認"
    - completeness: "必要な機能が全て含まれている"

- [ ] **p4.3**: 処遇決定
  - executor: claudecode
  - test_command: `grep -q "state.*Keep\|state.*Simplify\|state.*Delete" docs/deep-audit-planning-flow.md && echo PASS || echo FAIL`
  - validations:
    - technical: "Keep/Simplify/Delete のいずれかが決定"
    - consistency: "context-management との統合を検討"
    - completeness: "理由が記録されている"

**status**: pending
**max_iterations**: 3

---

### p5: plan-management/SKILL.md 精査

**goal**: plan-management Skill の完全な理解と動作確認

#### subtasks

- [ ] **p5.1**: ファイルを Read し、全ロジックを理解
  - executor: claudecode
  - test_command: `test -f .claude/skills/plan-management/SKILL.md && echo PASS || echo FAIL`
  - validations:
    - technical: "ファイルが存在する"
    - consistency: "playbook 運用ガイドを提供"
    - completeness: "phase 管理、subtask 管理が含まれている"

- [ ] **p5.2**: Codex レビュー依頼
  - executor: codex
  - test_command: `grep -q "plan-management" docs/deep-audit-planning-flow.md && echo PASS || echo FAIL`
  - validations:
    - technical: "Codex が Skill 定義を読み、フィードバックを返している"
    - consistency: "pm.md との重複がないか確認"
    - completeness: "必要な機能が全て含まれている"

- [ ] **p5.3**: 処遇決定
  - executor: claudecode
  - test_command: `grep -q "plan-management.*Keep\|plan-management.*Simplify\|plan-management.*Delete" docs/deep-audit-planning-flow.md && echo PASS || echo FAIL`
  - validations:
    - technical: "Keep/Simplify/Delete のいずれかが決定"
    - consistency: "pm.md との統合を検討"
    - completeness: "理由が記録されている"

**status**: pending
**max_iterations**: 3

---

### p6: playbook-init.md 精査

**goal**: playbook-init.md の完全な理解と動作確認

#### subtasks

- [ ] **p6.1**: ファイルを Read し、全ロジックを理解
  - executor: claudecode
  - test_command: `test -f .claude/commands/playbook-init.md && echo PASS || echo FAIL`
  - validations:
    - technical: "ファイルが存在する"
    - consistency: "task-start.md との関係が明確"
    - completeness: "pm 呼び出しのエイリアスとして機能"

- [ ] **p6.2**: Codex レビュー依頼 + task-start.md との統合検討
  - executor: codex
  - test_command: `grep -q "playbook-init.md" docs/deep-audit-planning-flow.md && echo PASS || echo FAIL`
  - validations:
    - technical: "Codex がドキュメントを読み、フィードバックを返している"
    - consistency: "task-start.md との重複を評価"
    - completeness: "統合すべきか別々に維持すべきか結論を出す"

- [ ] **p6.3**: 処遇決定
  - executor: claudecode
  - test_command: `grep -q "playbook-init.md.*Keep\|playbook-init.md.*Simplify\|playbook-init.md.*Delete" docs/deep-audit-planning-flow.md && echo PASS || echo FAIL`
  - validations:
    - technical: "Keep/Simplify/Delete のいずれかが決定"
    - consistency: "task-start.md との関係が整理されている"
    - completeness: "理由が記録されている"

**status**: pending
**max_iterations**: 3

---

### p7: reviewer.md 精査

**goal**: reviewer.md の完全な理解と動作確認

#### subtasks

- [ ] **p7.1**: ファイルを Read し、全ロジックを理解
  - executor: claudecode
  - test_command: `test -f .claude/agents/reviewer.md && echo PASS || echo FAIL`
  - validations:
    - technical: "ファイルが存在する"
    - consistency: "playbook レビューの役割を担う"
    - completeness: "Codex 連携、PASS/FAIL 判定が含まれている"

- [ ] **p7.2**: Codex レビュー依頼
  - executor: codex
  - test_command: `grep -q "reviewer.md" docs/deep-audit-planning-flow.md && echo PASS || echo FAIL`
  - validations:
    - technical: "Codex が SubAgent 定義を読み、フィードバックを返している"
    - consistency: "critic.md との役割分担が明確"
    - completeness: "自動化の方針が含まれている"

- [ ] **p7.3**: 処遇決定
  - executor: claudecode
  - test_command: `grep -q "reviewer.md.*Keep\|reviewer.md.*Simplify\|reviewer.md.*Delete" docs/deep-audit-planning-flow.md && echo PASS || echo FAIL`
  - validations:
    - technical: "Keep/Simplify/Delete のいずれかが決定"
    - consistency: "計画動線での位置づけが明確"
    - completeness: "理由が記録されている"

**status**: pending
**max_iterations**: 3

---

### p_final: 計画動線精査完了

**goal**: 全7ファイルの精査結果を確定

**depends_on**: [p1, p2, p3, p4, p5, p6, p7]

#### subtasks

- [ ] **p_final.1**: docs/deep-audit-planning-flow.md に全結果を記録
  - executor: claudecode
  - test_command: `test -f docs/deep-audit-planning-flow.md && grep -c "Keep\|Simplify\|Delete" docs/deep-audit-planning-flow.md | [ $(cat) -ge 7 ] && echo PASS || echo FAIL`
  - validations:
    - technical: "7ファイル全ての処遇が記録されている"
    - consistency: "Codex レビュー結果が反映されている"
    - completeness: "理由と改善提案が含まれている"

- [ ] **p_final.2**: 計画動線テスト全 PASS
  - executor: claudecode
  - test_command: `bash scripts/flow-runtime-test.sh 2>&1 | grep "Planning Flow" -A10 | grep -c "PASS" | [ $(cat) -ge 7 ] && echo PASS || echo FAIL`
  - validations:
    - technical: "計画動線のテストが全て PASS"
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
     rm docs/deep-audit-planning-flow.md

  2. 変更した場合は復元
     git checkout HEAD -- .claude/hooks/prompt-guard.sh
     git checkout HEAD -- .claude/commands/task-start.md
     # etc.
```

---

## notes

### 精査の観点

```yaml
各ファイルについて:
  1. 読んで理解:
     - 何をしているか
     - なぜ必要か
     - どの動線で使われるか

  2. 動作確認:
     - 構文エラーなし（bash -n）
     - 実際の入力で動作する
     - 期待する出力が得られる

  3. 必要性議論:
     - 本当に必要か
     - 簡素化できないか
     - 他と統合できないか

  4. Codex レビュー:
     - 設計の妥当性
     - 実装の品質
     - 改善提案
```

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-21 | 初版作成 |
