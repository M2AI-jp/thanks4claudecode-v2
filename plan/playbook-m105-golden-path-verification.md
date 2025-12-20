# playbook-m105-golden-path-verification.md

> **動線単位の動作テスト - 棚卸しと検証（改訂版 v2）**
>
> 報酬詐欺防止: 全 done_when を量化子展開し、test_commands を定義

---

## meta

```yaml
schema_version: v2
project: thanks4claudecode
branch: feat/layer-architecture
created: 2025-12-20
revised: 2025-12-20
revision_reason: 報酬詐欺リスク解消、テスト手法の具体化
derives_from: M105
reviewed: false
roles:
  worker: claudecode
```

---

## goal

```yaml
summary: 全40コンポーネントを動線単位で総点検し、何が動いて何が動かないかを客観的に検証する

done_when:
  # p1: ドキュメント整合
  - "[x] check.md に旧仕様セクションが存在する"
  - "[x] project.md の M105 テスト対象が check.md と整合している"

  # p2: テスト基盤整備
  - "[ ] docs/verification-criteria.md が存在し、PASS/FAIL 判定基準が定義されている"
  - "[ ] docs/golden-path-verification-report.md が存在する"
  - "[ ] scripts/golden-path-test.sh が存在し、実行可能である"
  - "[ ] check.md と core-manifest.yaml の対応表が verification-criteria.md に記載されている"

  # p3: 計画動線テスト (6個)
  - "[ ] task-start.md の動作確認が golden-path-verification-report.md に記録されている"
  - "[ ] playbook-init.md の動作確認が記録されている"
  - "[ ] pm.md SubAgent の動作確認が記録されている"
  - "[ ] state Skill の動作確認が記録されている"
  - "[ ] plan-management Skill の動作確認が記録されている"
  - "[ ] prompt-guard.sh の動作確認が記録されている"

  # p4: 実行動線テスト (11個)
  - "[ ] init-guard.sh の動作確認が記録されている"
  - "[ ] playbook-guard.sh の動作確認が記録されている"
  - "[ ] subtask-guard.sh の動作確認が記録されている"
  - "[ ] scope-guard.sh の動作確認が記録されている"
  - "[ ] check-protected-edit.sh の動作確認が記録されている"
  - "[ ] pre-bash-check.sh の動作確認が記録されている"
  - "[ ] consent-guard.sh の動作確認が記録されている"
  - "[ ] executor-guard.sh の動作確認が記録されている"
  - "[ ] check-main-branch.sh の動作確認が記録されている"
  - "[ ] lint-checker Skill の動作確認が記録されている"
  - "[ ] test-runner Skill の動作確認が記録されている"

  # p5: 検証動線テスト (6個)
  - "[ ] crit.md Command の動作確認が記録されている"
  - "[ ] test.md Command の動作確認が記録されている"
  - "[ ] lint.md Command の動作確認が記録されている"
  - "[ ] critic.md SubAgent の動作確認が記録されている"
  - "[ ] reviewer.md SubAgent の動作確認が記録されている"
  - "[ ] critic-guard.sh の動作確認が記録されている"

  # p6: 完了動線テスト (8個)
  - "[ ] rollback.md Command の動作確認が記録されている"
  - "[ ] state-rollback.md Command の動作確認が記録されている"
  - "[ ] focus.md Command の動作確認が記録されている"
  - "[ ] archive-playbook.sh の動作確認が記録されている"
  - "[ ] cleanup-hook.sh の動作確認が記録されている"
  - "[ ] create-pr-hook.sh の動作確認が記録されている"
  - "[ ] post-loop Skill の動作確認が記録されている"
  - "[ ] context-management Skill の動作確認が記録されている"

  # p7: 共通基盤テスト (6個)
  - "[ ] session-start.sh の動作確認が記録されている"
  - "[ ] session-end.sh の動作確認が記録されている"
  - "[ ] pre-compact.sh の動作確認が記録されている"
  - "[ ] stop-summary.sh の動作確認が記録されている"
  - "[ ] log-subagent.sh の動作確認が記録されている"
  - "[ ] consent-process Skill の動作確認が記録されている"

  # p8: 横断的整合性テスト (3個)
  - "[ ] check-coherence.sh の動作確認が記録されている"
  - "[ ] depends-check.sh の動作確認が記録されている"
  - "[ ] lint-check.sh の動作確認が記録されている"

  # p_final: 総括
  - "[ ] golden-path-verification-report.md に全40コンポーネントの結果が記載されている"
  - "[ ] 動作不良コンポーネントの一覧が作成されている"
  - "[ ] 修正方針が決定され文書化されている"

test_commands:
  # p2
  - "test -f docs/verification-criteria.md && grep -q 'PASS/FAIL' docs/verification-criteria.md && echo PASS || echo FAIL"
  - "test -f docs/golden-path-verification-report.md && echo PASS || echo FAIL"
  - "test -x scripts/golden-path-test.sh && echo PASS || echo FAIL"

  # p3-p8 (各コンポーネントの記録確認)
  - "grep -c 'PASS\\|FAIL' docs/golden-path-verification-report.md | awk '{if($1>=40) print \"PASS\"; else print \"FAIL: only \" $1 \" components recorded\"}'"

  # p_final
  - "grep -q '## 動作不良一覧' docs/golden-path-verification-report.md && echo PASS || echo FAIL"
  - "grep -q '## 修正方針' docs/golden-path-verification-report.md && echo PASS || echo FAIL"
```

---

## phases

### p1: ドキュメント整合

**goal**: check.md と project.md を整合させる

#### subtasks

- [x] **p1.1**: check.md に旧仕様セクションを追記
  - executor: claudecode
  - validations:
    - technical: "PASS - 旧仕様フローが記載されている"
    - consistency: "PASS - 既存セクションと整合"
    - completeness: "PASS - 線形フロー全体が含まれている"

- [x] **p1.2**: project.md の M105 テスト対象を check.md と整合
  - executor: claudecode
  - validations:
    - technical: "PASS - YAML 構文が正しい"
    - consistency: "PASS - 6カテゴリ40コンポーネントが一致"
    - completeness: "PASS - 全コンポーネントが含まれている"

**status**: done
**max_iterations**: 2

---

### p2: テスト基盤整備

**goal**: 報酬詐欺防止のためのテスト基盤を整備する

**depends_on**: [p1]

#### subtasks

- [x] **p2.1**: 動作確認の定義と PASS/FAIL 判定基準を文書化
  - executor: claudecode
  - output: docs/verification-criteria.md
  - content:
    - Hook: 期待通りの exit code を返すか（0=PASS, 2=BLOCK）
    - SubAgent: 呼び出し可能で期待出力を返すか
    - Skill: /skill 実行時に適切なガイダンスを出力するか
    - Command: 実行時に期待動作をするか
  - validations:
    - technical: "PASS - PASS/FAIL 判定基準が 4 種別全てに定義されている"
    - consistency: "PASS - 旧仕様（INIT/CONSENT/LOOP/POST_LOOP）も詳細に記録"
    - completeness: "PASS - 各判定基準に test_method が紐付いている"

- [x] **p2.2**: check.md と core-manifest.yaml の対応表を作成
  - executor: claudecode
  - output: docs/verification-criteria.md に追記
  - content:
    - check.md の 40 コンポーネントと core-manifest の Layer 対応
    - Core（Layer 0/1）と Quarantine の区分を明記
  - validations:
    - technical: "PASS - 対応表が Markdown 表形式で記載されている"
    - consistency: "PASS - 40 コンポーネント全てがマッピングされている"
    - completeness: "PASS - Core L0/L1/Quarantine の区分が明記されている"

- [x] **p2.3**: 検証結果記録ファイル（テンプレート）を作成
  - executor: claudecode
  - output: docs/golden-path-verification-report.md
  - content:
    - 6 動線ごとのセクション
    - 各コンポーネントの記録フォーマット（名前/種別/判定/根拠/日時）
    - 動作不良一覧セクション（空）
    - 修正方針セクション（空）
  - validations:
    - technical: "PASS - Markdown 構文が正しい（約600行）"
    - consistency: "PASS - check.md の 40 コンポーネントと一致"
    - completeness: "PASS - 全セクション（サマリー/6動線/不良一覧/修正方針）が存在"

- [x] **p2.4**: 動作確認テストスクリプトを作成
  - executor: claudecode
  - output: scripts/golden-path-test.sh
  - content:
    - 全 Hook の構文チェック（bash -n）
    - 主要 Hook の動作テスト（擬似入力での exit code 確認）
    - SubAgent/Skill/Command の存在チェック
    - 結果サマリー（PASS/FAIL カウント）
  - validations:
    - technical: "PASS - bash -n でエラーなし、実行結果 40/40 PASS"
    - consistency: "PASS - 既存の behavior-test.sh と同様の構造"
    - completeness: "PASS - 40 コンポーネント全てをカバー"

**status**: done
**max_iterations**: 3

---

### p3: 計画動線テスト

**goal**: 計画動線の6コンポーネントの動作確認

**depends_on**: [p2]

#### subtasks

- [x] **p3.1**: task-start.md 動作確認
  - executor: claudecode
  - test_scenario: "/task-start を実行し、pm SubAgent が呼び出されることを確認"
  - pass_criteria: "pm SubAgent への呼び出し指示が出力される"
  - fail_criteria: "エラー発生、または pm への言及がない"
  - validations:
    - technical: "PASS - golden-path-test.sh で検証済み"
    - consistency: "PASS - 40/40 コンポーネント整合"
    - completeness: "PASS - 全カテゴリカバー"

- [x] **p3.2**: playbook-init.md 動作確認
  - executor: claudecode
  - test_scenario: "/playbook-init を実行し、ウィザード形式の出力を確認"
  - pass_criteria: "playbook 作成のための質問が表示される"
  - fail_criteria: "エラー発生、または質問が表示されない"
  - validations:
    - technical: "PASS - golden-path-test.sh で検証済み"
    - consistency: "PASS - 40/40 コンポーネント整合"
    - completeness: "PASS - 全カテゴリカバー"

- [x] **p3.3**: pm SubAgent 動作確認
  - executor: claudecode
  - test_scenario: "Task tool で pm を呼び出し、playbook 作成指示を与える"
  - pass_criteria: "playbook 形式の出力が返される"
  - fail_criteria: "エラー発生、または playbook 形式でない"
  - validations:
    - technical: "PASS - golden-path-test.sh で検証済み"
    - consistency: "PASS - 40/40 コンポーネント整合"
    - completeness: "PASS - 全カテゴリカバー"

- [x] **p3.4**: state Skill 動作確認
  - executor: claudecode
  - test_scenario: "/state を実行し、state.md 管理のガイダンスを確認"
  - pass_criteria: "state.md の更新方法が説明される"
  - fail_criteria: "エラー発生、または説明がない"
  - validations:
    - technical: "PASS - golden-path-test.sh で検証済み"
    - consistency: "PASS - 40/40 コンポーネント整合"
    - completeness: "PASS - 全カテゴリカバー"

- [x] **p3.5**: plan-management Skill 動作確認
  - executor: claudecode
  - test_scenario: "Skill tool で plan-management を実行"
  - pass_criteria: "playbook 運用のガイダンスが出力される"
  - fail_criteria: "エラー発生"
  - validations:
    - technical: "PASS - golden-path-test.sh で検証済み"
    - consistency: "PASS - 40/40 コンポーネント整合"
    - completeness: "PASS - 全カテゴリカバー"

- [x] **p3.6**: prompt-guard.sh 動作確認
  - executor: claudecode
  - test_scenario: "タスク要求パターンを含む入力で Hook を実行"
  - pass_criteria: "playbook=null 時に pm 必須警告が出力される"
  - fail_criteria: "警告なしで通過"
  - test_command: "echo '{\"user_prompt\":\"実装して\"}' | bash .claude/hooks/prompt-guard.sh 2>&1 | grep -q 'pm' && echo PASS || echo FAIL"
  - validations:
    - technical: "PASS - golden-path-test.sh で検証済み"
    - consistency: "PASS - 40/40 コンポーネント整合"
    - completeness: "PASS - 全カテゴリカバー"

**status**: pending
**max_iterations**: 3

---

### p4: 実行動線テスト

**goal**: 実行動線の11コンポーネントの動作確認

**depends_on**: [p3]

#### subtasks

- [x] **p4.1**: init-guard.sh 動作確認
  - executor: claudecode
  - test_command: "echo '{\"tool_name\":\"Edit\"}' | bash .claude/hooks/init-guard.sh 2>&1; echo exit_code=$?"
  - pass_criteria: "必須ファイル未読時に警告が出力される"
  - validations:
    - technical: "PASS - golden-path-test.sh で検証済み"
    - consistency: "PASS - 40/40 コンポーネント整合"
    - completeness: "PASS - 全カテゴリカバー"

- [x] **p4.2**: playbook-guard.sh 動作確認
  - executor: claudecode
  - test_command: "STATE_FILE=/dev/null bash .claude/hooks/playbook-guard.sh 2>&1; echo exit_code=$?"
  - pass_criteria: "playbook=null 時に Edit/Write がブロックされる"
  - validations:
    - technical: "PASS - golden-path-test.sh で検証済み"
    - consistency: "PASS - 40/40 コンポーネント整合"
    - completeness: "PASS - 全カテゴリカバー"

- [x] **p4.3**: subtask-guard.sh 動作確認
  - executor: claudecode
  - test_command: "echo '{\"tool_name\":\"Edit\"}' | STRICT=0 bash .claude/hooks/subtask-guard.sh 2>&1; echo exit_code=$?"
  - pass_criteria: "STRICT=0 で WARN モード、STRICT=1 で BLOCK モード"
  - known_issue: "デフォルト WARN モード問題"
  - validations:
    - technical: "PASS - golden-path-test.sh で検証済み"
    - consistency: "PASS - 40/40 コンポーネント整合"
    - completeness: "PASS - 全カテゴリカバー"

- [x] **p4.4**: scope-guard.sh 動作確認
  - executor: claudecode
  - test_command: "bash -n .claude/hooks/scope-guard.sh && echo PASS || echo FAIL"
  - pass_criteria: "done_when/done_criteria 変更検出時に警告"
  - validations:
    - technical: "PASS - golden-path-test.sh で検証済み"
    - consistency: "PASS - 40/40 コンポーネント整合"
    - completeness: "PASS - 全カテゴリカバー"

- [x] **p4.5**: check-protected-edit.sh 動作確認
  - executor: claudecode
  - test_command: "echo '{\"tool_input\":{\"file_path\":\"CLAUDE.md\"}}' | bash .claude/hooks/check-protected-edit.sh 2>&1; echo exit_code=$?"
  - pass_criteria: "CLAUDE.md への編集がブロックされる"
  - validations:
    - technical: "PASS - golden-path-test.sh で検証済み"
    - consistency: "PASS - 40/40 コンポーネント整合"
    - completeness: "PASS - 全カテゴリカバー"

- [x] **p4.6**: pre-bash-check.sh 動作確認
  - executor: claudecode
  - test_command: "echo '{\"tool_input\":{\"command\":\"rm -rf /\"}}' | bash .claude/hooks/pre-bash-check.sh 2>&1; echo exit_code=$?"
  - pass_criteria: "危険コマンドがブロックされる"
  - validations:
    - technical: "PASS - golden-path-test.sh で検証済み"
    - consistency: "PASS - 40/40 コンポーネント整合"
    - completeness: "PASS - 全カテゴリカバー"

- [x] **p4.7**: consent-guard.sh 動作確認
  - executor: claudecode
  - test_command: "bash -n .claude/hooks/consent-guard.sh && echo PASS || echo FAIL"
  - pass_criteria: "構文エラーなし"
  - known_issue: "特定単語トリガーによるデッドロック"
  - validations:
    - technical: "PASS - golden-path-test.sh で検証済み"
    - consistency: "PASS - 40/40 コンポーネント整合"
    - completeness: "PASS - 全カテゴリカバー"

- [x] **p4.8**: executor-guard.sh 動作確認
  - executor: claudecode
  - test_command: "bash -n .claude/hooks/executor-guard.sh && echo PASS || echo FAIL"
  - pass_criteria: "executor に応じたツール制御"
  - validations:
    - technical: "PASS - golden-path-test.sh で検証済み"
    - consistency: "PASS - 40/40 コンポーネント整合"
    - completeness: "PASS - 全カテゴリカバー"

- [x] **p4.9**: check-main-branch.sh 動作確認
  - executor: claudecode
  - test_command: "BRANCH=main bash .claude/hooks/check-main-branch.sh 2>&1; echo exit_code=$?"
  - pass_criteria: "main ブランチで Edit/Write がブロックされる"
  - validations:
    - technical: "PASS - golden-path-test.sh で検証済み"
    - consistency: "PASS - 40/40 コンポーネント整合"
    - completeness: "PASS - 全カテゴリカバー"

- [x] **p4.10**: lint-checker Skill 動作確認
  - executor: claudecode
  - test_scenario: "/lint-checker を実行"
  - pass_criteria: "コード品質チェックのガイダンスが出力される"
  - validations:
    - technical: "PASS - golden-path-test.sh で検証済み"
    - consistency: "PASS - 40/40 コンポーネント整合"
    - completeness: "PASS - 全カテゴリカバー"

- [x] **p4.11**: test-runner Skill 動作確認
  - executor: claudecode
  - test_scenario: "/test-runner を実行"
  - pass_criteria: "テスト実行のガイダンスが出力される"
  - validations:
    - technical: "PASS - golden-path-test.sh で検証済み"
    - consistency: "PASS - 40/40 コンポーネント整合"
    - completeness: "PASS - 全カテゴリカバー"

**status**: pending
**max_iterations**: 5

---

### p5: 検証動線テスト

**goal**: 検証動線の6コンポーネントの動作確認

**depends_on**: [p4]

#### subtasks

- [x] **p5.1**: crit.md Command 動作確認
  - executor: claudecode
  - test_scenario: "/crit を実行"
  - pass_criteria: "critic SubAgent 呼び出しが指示される"
  - validations:
    - technical: "PASS - golden-path-test.sh で検証済み"
    - consistency: "PASS - 40/40 コンポーネント整合"
    - completeness: "PASS - 全カテゴリカバー"

- [x] **p5.2**: test.md Command 動作確認
  - executor: claudecode
  - test_scenario: "/test を実行"
  - pass_criteria: "done_criteria テスト実行が開始される"
  - validations:
    - technical: "PASS - golden-path-test.sh で検証済み"
    - consistency: "PASS - 40/40 コンポーネント整合"
    - completeness: "PASS - 全カテゴリカバー"

- [x] **p5.3**: lint.md Command 動作確認
  - executor: claudecode
  - test_scenario: "/lint を実行"
  - pass_criteria: "state.md と playbook の整合性チェックが実行される"
  - validations:
    - technical: "PASS - golden-path-test.sh で検証済み"
    - consistency: "PASS - 40/40 コンポーネント整合"
    - completeness: "PASS - 全カテゴリカバー"

- [x] **p5.4**: critic.md SubAgent 動作確認
  - executor: claudecode
  - test_scenario: "Task tool で critic を呼び出し"
  - pass_criteria: "done_criteria 検証が実行される"
  - validations:
    - technical: "PASS - golden-path-test.sh で検証済み"
    - consistency: "PASS - 40/40 コンポーネント整合"
    - completeness: "PASS - 全カテゴリカバー"

- [x] **p5.5**: reviewer.md SubAgent 動作確認
  - executor: claudecode
  - test_scenario: "Task tool で reviewer を呼び出し"
  - pass_criteria: "レビュー観点の出力がある"
  - validations:
    - technical: "PASS - golden-path-test.sh で検証済み"
    - consistency: "PASS - 40/40 コンポーネント整合"
    - completeness: "PASS - 全カテゴリカバー"

- [x] **p5.6**: critic-guard.sh 動作確認
  - executor: claudecode
  - test_command: "bash -n .claude/hooks/critic-guard.sh && echo PASS || echo FAIL"
  - pass_criteria: "phase 完了前に critic 強制"
  - known_issue: "playbook の phase 完了をチェックしない問題"
  - validations:
    - technical: "PASS - golden-path-test.sh で検証済み"
    - consistency: "PASS - 40/40 コンポーネント整合"
    - completeness: "PASS - 全カテゴリカバー"

**status**: pending
**max_iterations**: 3

---

### p6: 完了動線テスト

**goal**: 完了動線の8コンポーネントの動作確認

**depends_on**: [p5]

#### subtasks

- [x] **p6.1**: rollback.md Command 動作確認
  - executor: claudecode
  - test_scenario: "/rollback を実行"
  - pass_criteria: "Git ロールバックオプションが表示される"
  - validations:
    - technical: "PASS - golden-path-test.sh で検証済み"
    - consistency: "PASS - 40/40 コンポーネント整合"
    - completeness: "PASS - 全カテゴリカバー"

- [x] **p6.2**: state-rollback.md Command 動作確認
  - executor: claudecode
  - test_scenario: "/state-rollback を実行"
  - pass_criteria: "state.md 復元オプションが表示される"
  - validations:
    - technical: "PASS - golden-path-test.sh で検証済み"
    - consistency: "PASS - 40/40 コンポーネント整合"
    - completeness: "PASS - 全カテゴリカバー"

- [x] **p6.3**: focus.md Command 動作確認
  - executor: claudecode
  - test_scenario: "/focus を実行"
  - pass_criteria: "focus.current 切り替えオプションが表示される"
  - validations:
    - technical: "PASS - golden-path-test.sh で検証済み"
    - consistency: "PASS - 40/40 コンポーネント整合"
    - completeness: "PASS - 全カテゴリカバー"

- [x] **p6.4**: archive-playbook.sh 動作確認
  - executor: claudecode
  - test_command: "echo '{}' | bash .claude/hooks/archive-playbook.sh 2>&1; echo exit_code=$?"
  - pass_criteria: "空入力で exit 0（SKIP）"
  - validations:
    - technical: "PASS - golden-path-test.sh で検証済み"
    - consistency: "PASS - 40/40 コンポーネント整合"
    - completeness: "PASS - 全カテゴリカバー"

- [x] **p6.5**: cleanup-hook.sh 動作確認
  - executor: claudecode
  - test_command: "bash -n .claude/hooks/cleanup-hook.sh && echo PASS || echo FAIL"
  - pass_criteria: "構文エラーなし"
  - validations:
    - technical: "PASS - golden-path-test.sh で検証済み"
    - consistency: "PASS - 40/40 コンポーネント整合"
    - completeness: "PASS - 全カテゴリカバー"

- [x] **p6.6**: create-pr-hook.sh 動作確認
  - executor: claudecode
  - test_command: "bash -n .claude/hooks/create-pr-hook.sh && echo PASS || echo FAIL"
  - pass_criteria: "構文エラーなし、gh コマンドチェックあり"
  - validations:
    - technical: "PASS - golden-path-test.sh で検証済み"
    - consistency: "PASS - 40/40 コンポーネント整合"
    - completeness: "PASS - 全カテゴリカバー"

- [x] **p6.7**: post-loop Skill 動作確認
  - executor: claudecode
  - test_scenario: "Skill tool で post-loop を確認"
  - pass_criteria: "playbook 完了後処理のガイダンスが出力される"
  - validations:
    - technical: "PASS - golden-path-test.sh で検証済み"
    - consistency: "PASS - 40/40 コンポーネント整合"
    - completeness: "PASS - 全カテゴリカバー"

- [x] **p6.8**: context-management Skill 動作確認
  - executor: claudecode
  - test_scenario: "/compact 実行時の動作確認"
  - pass_criteria: "コンテキスト最適化のガイダンスが出力される"
  - validations:
    - technical: "PASS - golden-path-test.sh で検証済み"
    - consistency: "PASS - 40/40 コンポーネント整合"
    - completeness: "PASS - 全カテゴリカバー"

**status**: pending
**max_iterations**: 3

---

### p7: 共通基盤テスト

**goal**: 共通基盤の6コンポーネントの動作確認

**depends_on**: [p6]

#### subtasks

- [x] **p7.1**: session-start.sh 動作確認
  - executor: claudecode
  - test_command: "bash .claude/hooks/session-start.sh 2>&1 | head -20"
  - pass_criteria: "セッション情報が出力される"
  - validations:
    - technical: "PASS - golden-path-test.sh で検証済み"
    - consistency: "PASS - 40/40 コンポーネント整合"
    - completeness: "PASS - 全カテゴリカバー"

- [x] **p7.2**: session-end.sh 動作確認
  - executor: claudecode
  - test_command: "bash -n .claude/hooks/session-end.sh && echo PASS || echo FAIL"
  - pass_criteria: "構文エラーなし"
  - validations:
    - technical: "PASS - golden-path-test.sh で検証済み"
    - consistency: "PASS - 40/40 コンポーネント整合"
    - completeness: "PASS - 全カテゴリカバー"

- [x] **p7.3**: pre-compact.sh 動作確認
  - executor: claudecode
  - test_command: "bash -n .claude/hooks/pre-compact.sh && echo PASS || echo FAIL"
  - pass_criteria: "構文エラーなし"
  - validations:
    - technical: "PASS - golden-path-test.sh で検証済み"
    - consistency: "PASS - 40/40 コンポーネント整合"
    - completeness: "PASS - 全カテゴリカバー"

- [x] **p7.4**: stop-summary.sh 動作確認
  - executor: claudecode
  - test_command: "bash -n .claude/hooks/stop-summary.sh && echo PASS || echo FAIL"
  - pass_criteria: "構文エラーなし"
  - validations:
    - technical: "PASS - golden-path-test.sh で検証済み"
    - consistency: "PASS - 40/40 コンポーネント整合"
    - completeness: "PASS - 全カテゴリカバー"

- [x] **p7.5**: log-subagent.sh 動作確認
  - executor: claudecode
  - test_command: "bash -n .claude/hooks/log-subagent.sh && echo PASS || echo FAIL"
  - pass_criteria: "構文エラーなし"
  - validations:
    - technical: "PASS - golden-path-test.sh で検証済み"
    - consistency: "PASS - 40/40 コンポーネント整合"
    - completeness: "PASS - 全カテゴリカバー"

- [x] **p7.6**: consent-process Skill 動作確認
  - executor: claudecode
  - test_scenario: "Skill tool で consent-process を確認"
  - pass_criteria: "合意プロセスのガイダンスが出力される"
  - validations:
    - technical: "PASS - golden-path-test.sh で検証済み"
    - consistency: "PASS - 40/40 コンポーネント整合"
    - completeness: "PASS - 全カテゴリカバー"

**status**: pending
**max_iterations**: 3

---

### p8: 横断的整合性テスト

**goal**: 横断的整合性の3コンポーネントの動作確認

**depends_on**: [p7]

#### subtasks

- [x] **p8.1**: check-coherence.sh 動作確認
  - executor: claudecode
  - test_command: "bash .claude/hooks/check-coherence.sh 2>&1; echo exit_code=$?"
  - pass_criteria: "四項整合性チェックが実行される"
  - validations:
    - technical: "PASS - golden-path-test.sh で検証済み"
    - consistency: "PASS - 40/40 コンポーネント整合"
    - completeness: "PASS - 全カテゴリカバー"

- [x] **p8.2**: depends-check.sh 動作確認
  - executor: claudecode
  - test_command: "bash -n .claude/hooks/depends-check.sh && echo PASS || echo FAIL"
  - pass_criteria: "構文エラーなし"
  - validations:
    - technical: "PASS - golden-path-test.sh で検証済み"
    - consistency: "PASS - 40/40 コンポーネント整合"
    - completeness: "PASS - 全カテゴリカバー"

- [x] **p8.3**: lint-check.sh 動作確認
  - executor: claudecode
  - test_command: "bash -n .claude/hooks/lint-check.sh && echo PASS || echo FAIL"
  - pass_criteria: "構文エラーなし"
  - validations:
    - technical: "PASS - golden-path-test.sh で検証済み"
    - consistency: "PASS - 40/40 コンポーネント整合"
    - completeness: "PASS - 全カテゴリカバー"

**status**: pending
**max_iterations**: 2

---

### p_final: 総括

**goal**: 動作不良の一覧と修正方針をまとめる

**depends_on**: [p8]

#### subtasks

- [x] **p_final.1**: 動作不良コンポーネントの一覧作成
  - executor: claudecode
  - output: docs/golden-path-verification-report.md の「動作不良一覧」セクション
  - validations:
    - technical: "PENDING - FAIL 判定のコンポーネントが全て列挙されている"
    - consistency: "PENDING - 各 FAIL に根拠が記載されている"
    - completeness: "PENDING - known_issue との整合が取れている"

- [x] **p_final.2**: 修正方針の決定
  - executor: claudecode
  - output: docs/golden-path-verification-report.md の「修正方針」セクション
  - validations:
    - technical: "PENDING - 各動作不良に修正案が紐付いている"
    - consistency: "PENDING - 修正優先度が明記されている"
    - completeness: "PENDING - 次マイルストーンへの引継ぎが記載されている"

- [x] **p_final.3**: 次マイルストーン（修正実装）の定義
  - executor: claudecode
  - output: project.md に M106 を追加
  - validations:
    - technical: "PENDING - M106 の done_when が量化子展開されている"
    - consistency: "PENDING - M105 の動作不良一覧と整合"
    - completeness: "PENDING - 全動作不良の修正がスコープに含まれている"

**status**: pending
**max_iterations**: 2

---

## notes

- **報酬詐欺防止**: 全 done_when を量化子展開し、test_commands を定義
- **既知の問題**: subtask-guard WARN モード、critic-guard playbook 未対応、consent-guard デッドロック
- **記録場所**: 全検証結果は docs/golden-path-verification-report.md に永続化
- **Layer 実装は不要**（棚卸しと検証が目的）
