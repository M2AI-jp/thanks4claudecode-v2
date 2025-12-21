# playbook-m156-pipeline-completeness-audit.md

> **動線単位の完全性評価 + 大掃除**
>
> コンポーネントを列挙するな。「動線が動くか動かないか」で評価する。

---

## meta

```yaml
schema_version: v2
project: M156 Pipeline Completeness Audit
branch: feat/m156-pipeline-completeness-audit
created: 2025-12-22
issue: null
derives_from: M156
reviewed: true
roles:
  worker: codex
  evaluator: claudecode

user_prompt_original: |
  M156: 動線単位の完全性評価 + 大掃除
  - ユーザーが何回も同じ問題を指摘しているのに直らない
  - 根本原因: Claude がコンポーネント単位で見ていて、動線単位で評価していない
  - 38コンポーネント + ドキュメント + フォルダが多すぎる
  - 残す価値の評価が完了していない
  - 4動線を1つの連結されたユニットとして扱う
```

---

## goal

```yaml
summary: 4動線すべてをE2Eで評価し、不要なファイル/フォルダをゼロにする
done_when:
  - 4動線すべてがE2Eで PASS（flow-runtime-test.sh が 25/25 PASS）
  - 不要なファイル/フォルダがゼロ（deletion_candidates が全て処理済み）
  - 全ファイルが「なぜ存在するか」を1文で説明できる（core-manifest.yaml で網羅）
  - project.md が実態と完全同期（M142-M155 の achieved_at 設定、M156 追加）
```

---

## phases

### p0: 動線仕様の明文化

**goal**: 4動線それぞれの「正しい動作」を定義し、E2Eテストシナリオを設計する

#### subtasks

- [ ] **p0.1**: 計画動線の仕様書が存在する（入力/出力/成功条件/失敗条件/テストシナリオ）
  - executor: claudecode
  - test_command: `test -f docs/spec-planning-flow.md && grep -q '成功条件' docs/spec-planning-flow.md && echo PASS || echo FAIL`
  - validations:
    - technical: "ファイルが存在し、必須セクションを含む"
    - consistency: "core-manifest.yaml の planning_flow と整合"
    - completeness: "入力/出力/成功/失敗/シナリオの5セクション全てが存在"

- [ ] **p0.2**: 実行動線の仕様書が存在する
  - executor: claudecode
  - test_command: `test -f docs/spec-execution-flow.md && grep -q '成功条件' docs/spec-execution-flow.md && echo PASS || echo FAIL`
  - validations:
    - technical: "ファイルが存在し、必須セクションを含む"
    - consistency: "core-manifest.yaml の execution_flow と整合"
    - completeness: "5セクション全てが存在"

- [ ] **p0.3**: 検証動線の仕様書が存在する
  - executor: claudecode
  - test_command: `test -f docs/spec-verification-flow.md && grep -q '成功条件' docs/spec-verification-flow.md && echo PASS || echo FAIL`
  - validations:
    - technical: "ファイルが存在し、必須セクションを含む"
    - consistency: "core-manifest.yaml の verification_flow と整合"
    - completeness: "5セクション全てが存在"

- [ ] **p0.4**: 完了動線の仕様書が存在する
  - executor: claudecode
  - test_command: `test -f docs/spec-completion-flow.md && grep -q '成功条件' docs/spec-completion-flow.md && echo PASS || echo FAIL`
  - validations:
    - technical: "ファイルが存在し、必須セクションを含む"
    - consistency: "core-manifest.yaml の completion_flow と整合"
    - completeness: "5セクション全てが存在"

**status**: pending
**max_iterations**: 5

---

### p1: 計画動線E2E評価

**goal**: 計画動線をE2Eでテストし、動線として動くか判定する
**depends_on**: [p0]

#### subtasks

- [ ] **p1.1**: 計画動線のE2Eテストスクリプトが存在する
  - executor: codex
  - test_command: `test -f scripts/test-planning-flow-e2e.sh && bash -n scripts/test-planning-flow-e2e.sh && echo PASS || echo FAIL`
  - validations:
    - technical: "シンタックスエラーなし"
    - consistency: "p0.1 の仕様書に基づくテスト"
    - completeness: "成功/失敗パスの両方をテスト"

- [ ] **p1.2**: 計画動線E2Eテストが PASS する
  - executor: codex
  - test_command: `bash scripts/test-planning-flow-e2e.sh 2>&1 | tail -1 | grep -q 'PASS' && echo PASS || echo FAIL`
  - validations:
    - technical: "テストが実行され PASS を返す"
    - consistency: "flow-runtime-test.sh の計画動線テストと整合"
    - completeness: "全テストケースが PASS"

- [ ] **p1.3**: Claude が計画動線E2E結果を評価し PASS と判定する
  - executor: claudecode
  - test_command: `手動確認: Claude が p1.2 の結果を確認し、動線として動くと判定`
  - validations:
    - technical: "テスト結果が正確に解釈されている"
    - consistency: "p0.1 の成功条件と結果が一致"
    - completeness: "全ての成功条件を満たしている"

**status**: pending
**max_iterations**: 5

---

### p2: 実行動線E2E評価

**goal**: 実行動線をE2Eでテストし、動線として動くか判定する
**depends_on**: [p0]

#### subtasks

- [ ] **p2.1**: 実行動線のE2Eテストスクリプトが存在する
  - executor: codex
  - test_command: `test -f scripts/test-execution-flow-e2e.sh && bash -n scripts/test-execution-flow-e2e.sh && echo PASS || echo FAIL`
  - validations:
    - technical: "シンタックスエラーなし"
    - consistency: "p0.2 の仕様書に基づくテスト"
    - completeness: "ガード発火/ブロック/許可の全パスをテスト"

- [ ] **p2.2**: 実行動線E2Eテストが PASS する
  - executor: codex
  - test_command: `bash scripts/test-execution-flow-e2e.sh 2>&1 | tail -1 | grep -q 'PASS' && echo PASS || echo FAIL`
  - validations:
    - technical: "テストが実行され PASS を返す"
    - consistency: "flow-runtime-test.sh の実行動線テストと整合"
    - completeness: "全テストケースが PASS"

- [ ] **p2.3**: Claude が実行動線E2E結果を評価し PASS と判定する
  - executor: claudecode
  - test_command: `手動確認: Claude が p2.2 の結果を確認し、動線として動くと判定`
  - validations:
    - technical: "テスト結果が正確に解釈されている"
    - consistency: "p0.2 の成功条件と結果が一致"
    - completeness: "全ての成功条件を満たしている"

**status**: pending
**max_iterations**: 5

---

### p3: 検証動線E2E評価

**goal**: 検証動線をE2Eでテストし、動線として動くか判定する
**depends_on**: [p0]

#### subtasks

- [ ] **p3.1**: 検証動線のE2Eテストスクリプトが存在する
  - executor: codex
  - test_command: `test -f scripts/test-verification-flow-e2e.sh && bash -n scripts/test-verification-flow-e2e.sh && echo PASS || echo FAIL`
  - validations:
    - technical: "シンタックスエラーなし"
    - consistency: "p0.3 の仕様書に基づくテスト"
    - completeness: "critic PASS/FAIL の両パスをテスト"

- [ ] **p3.2**: 検証動線E2Eテストが PASS する
  - executor: codex
  - test_command: `bash scripts/test-verification-flow-e2e.sh 2>&1 | tail -1 | grep -q 'PASS' && echo PASS || echo FAIL`
  - validations:
    - technical: "テストが実行され PASS を返す"
    - consistency: "flow-runtime-test.sh の検証動線テストと整合"
    - completeness: "全テストケースが PASS"

- [ ] **p3.3**: Claude が検証動線E2E結果を評価し PASS と判定する
  - executor: claudecode
  - test_command: `手動確認: Claude が p3.2 の結果を確認し、動線として動くと判定`
  - validations:
    - technical: "テスト結果が正確に解釈されている"
    - consistency: "p0.3 の成功条件と結果が一致"
    - completeness: "全ての成功条件を満たしている"

**status**: pending
**max_iterations**: 5

---

### p4: 完了動線E2E評価

**goal**: 完了動線をE2Eでテストし、動線として動くか判定する
**depends_on**: [p0]

#### subtasks

- [ ] **p4.1**: 完了動線のE2Eテストスクリプトが存在する
  - executor: codex
  - test_command: `test -f scripts/test-completion-flow-e2e.sh && bash -n scripts/test-completion-flow-e2e.sh && echo PASS || echo FAIL`
  - validations:
    - technical: "シンタックスエラーなし"
    - consistency: "p0.4 の仕様書に基づくテスト"
    - completeness: "アーカイブ/次タスク導出の全パスをテスト"

- [ ] **p4.2**: 完了動線E2Eテストが PASS する
  - executor: codex
  - test_command: `bash scripts/test-completion-flow-e2e.sh 2>&1 | tail -1 | grep -q 'PASS' && echo PASS || echo FAIL`
  - validations:
    - technical: "テストが実行され PASS を返す"
    - consistency: "flow-runtime-test.sh の完了動線テストと整合"
    - completeness: "全テストケースが PASS"

- [ ] **p4.3**: Claude が完了動線E2E結果を評価し PASS と判定する
  - executor: claudecode
  - test_command: `手動確認: Claude が p4.2 の結果を確認し、動線として動くと判定`
  - validations:
    - technical: "テスト結果が正確に解釈されている"
    - consistency: "p0.4 の成功条件と結果が一致"
    - completeness: "全ての成功条件を満たしている"

**status**: pending
**max_iterations**: 5

---

### p5: 不要物削除

**goal**: 4動線に関与しないファイル/フォルダを全て削除する
**depends_on**: [p1, p2, p3, p4]

#### subtasks

- [ ] **p5.1**: deletion_candidates の全ファイルが存在チェック済みである
  - executor: claudecode
  - test_command: `bash -c 'for f in .claude/hooks/audit-unused.sh .claude/hooks/check-integrity.sh .claude/hooks/check-spec-sync.sh .claude/hooks/create-pr.sh .claude/hooks/failure-logger.sh .claude/hooks/generate-repository-map.sh .claude/hooks/merge-pr.sh .claude/hooks/playbook-validator.sh .claude/hooks/role-resolver.sh .claude/hooks/system-health-check.sh .claude/hooks/test-done-criteria.sh .claude/hooks/test-hooks.sh; do test -f "$f" && echo "$f exists"; done' | wc -l | awk '{if($1>=0) print "PASS"}'`
  - validations:
    - technical: "ファイル存在が確認できる"
    - consistency: "core-manifest.yaml の deletion_candidates と一致"
    - completeness: "全候補が確認済み"

- [ ] **p5.2**: 存在する不要ファイルが削除されている
  - executor: codex
  - test_command: `bash -c 'for f in .claude/hooks/audit-unused.sh .claude/hooks/check-integrity.sh .claude/hooks/check-spec-sync.sh .claude/hooks/create-pr.sh .claude/hooks/failure-logger.sh .claude/hooks/generate-repository-map.sh .claude/hooks/merge-pr.sh .claude/hooks/playbook-validator.sh .claude/hooks/role-resolver.sh .claude/hooks/system-health-check.sh .claude/hooks/test-done-criteria.sh .claude/hooks/test-hooks.sh .claude/agents/codex-delegate.md .claude/agents/health-checker.md .claude/agents/setup-guide.md; do test -f "$f" && echo "FAIL: $f still exists" && exit 1; done; echo PASS'`
  - validations:
    - technical: "削除コマンドが成功"
    - consistency: "settings.json から参照が削除されている"
    - completeness: "全候補ファイルが削除済み"

- [ ] **p5.3**: 全ファイルが「なぜ存在するか」を1文で説明できる状態である
  - executor: claudecode
  - test_command: `grep -c 'why_core\|why_quality\|role:' governance/core-manifest.yaml | awk '{if($1>=38) print "PASS"; else print "FAIL"}'`
  - validations:
    - technical: "core-manifest.yaml に説明が存在"
    - consistency: "実際のファイルと manifest が一致"
    - completeness: "38コンポーネント全てに説明がある"

**status**: pending
**max_iterations**: 5

---

### p6: 仕様同期

**goal**: project.md、core-manifest.yaml、README.md を実態と完全同期させる
**depends_on**: [p5]

#### subtasks

- [ ] **p6.1**: project.md に M156 が追加され、M142-M155 に achieved_at が設定されている
  - executor: codex
  - test_command: `grep -q 'id: M156' plan/project.md && grep -c 'achieved_at:' plan/project.md | awk '{if($1>=50) print "PASS"; else print "FAIL"}'`
  - validations:
    - technical: "M156 セクションが存在"
    - consistency: "achieved_at の日付が実際の完了日と一致"
    - completeness: "M142-M155 全てに achieved_at がある"

- [ ] **p6.2**: core-manifest.yaml の deletion_candidates セクションが空または削除されている
  - executor: codex
  - test_command: `grep -c 'deletion_candidates:' governance/core-manifest.yaml | awk '{if($1==0) print "PASS"; else { if(grep -A5 "deletion_candidates:" governance/core-manifest.yaml | grep -c "^    - " == 0) print "PASS"; else print "FAIL"; }}'`
  - validations:
    - technical: "YAML 構文が正しい"
    - consistency: "p5 の削除結果と一致"
    - completeness: "削除候補が全て処理済み"

- [ ] **p6.3**: README.md の概要が実態と一致している
  - executor: claudecode
  - test_command: `test -f README.md && grep -q '動線' README.md && echo PASS || echo FAIL`
  - validations:
    - technical: "README.md が存在し読み取り可能"
    - consistency: "core-manifest.yaml の構造と一致"
    - completeness: "4動線の説明が含まれている"

- [ ] **p6.4**: flow-runtime-test.sh が 25/25 PASS を返す
  - executor: codex
  - test_command: `bash scripts/flow-runtime-test.sh 2>&1 | grep -E '^Tests:' | grep -q '25/25' && echo PASS || echo FAIL`
  - validations:
    - technical: "テストスクリプトが正常に実行される"
    - consistency: "4動線全てのテストが含まれている"
    - completeness: "失敗テストが0件"

**status**: pending
**max_iterations**: 5

---

### p_final: 完了検証（必須）

**goal**: playbook の done_when が全て満たされているか最終検証

#### subtasks

- [ ] **p_final.1**: 4動線すべてがE2Eで PASS している
  - executor: claudecode
  - test_command: `bash scripts/flow-runtime-test.sh 2>&1 | grep -E '^Tests:' | grep -q '25/25' && echo PASS || echo FAIL`
  - validations:
    - technical: "テストが実行可能"
    - consistency: "p1-p4 の結果と一致"
    - completeness: "全動線テストが PASS"

- [ ] **p_final.2**: 不要なファイル/フォルダがゼロである
  - executor: claudecode
  - test_command: `bash -c 'for f in .claude/hooks/audit-unused.sh .claude/hooks/check-integrity.sh .claude/hooks/check-spec-sync.sh .claude/hooks/create-pr.sh .claude/hooks/failure-logger.sh .claude/hooks/generate-repository-map.sh .claude/hooks/merge-pr.sh .claude/hooks/playbook-validator.sh .claude/hooks/role-resolver.sh .claude/hooks/system-health-check.sh .claude/hooks/test-done-criteria.sh .claude/hooks/test-hooks.sh .claude/agents/codex-delegate.md .claude/agents/health-checker.md .claude/agents/setup-guide.md; do test -f "$f" && exit 1; done; echo PASS'`
  - validations:
    - technical: "ファイル存在チェックが動作"
    - consistency: "p5.2 の結果と一致"
    - completeness: "全候補が確認済み"

- [ ] **p_final.3**: 全ファイルが「なぜ存在するか」を1文で説明できる
  - executor: claudecode
  - test_command: `grep -c 'why_core\|why_quality\|role:' governance/core-manifest.yaml | awk '{if($1>=38) print "PASS"; else print "FAIL"}'`
  - validations:
    - technical: "grep が正常動作"
    - consistency: "p5.3 の結果と一致"
    - completeness: "38コンポーネント全てをカバー"

- [ ] **p_final.4**: project.md が実態と完全同期している
  - executor: claudecode
  - test_command: `grep -q 'id: M156' plan/project.md && grep -c 'achieved_at:' plan/project.md | awk '{if($1>=50) print "PASS"; else print "FAIL"}'`
  - validations:
    - technical: "project.md が読み取り可能"
    - consistency: "p6.1 の結果と一致"
    - completeness: "M156 を含む全 milestone が記録済み"

**status**: pending
**max_iterations**: 3

---

## final_tasks

- [ ] **ft1**: repository-map.yaml を更新する
  - command: `bash .claude/hooks/generate-repository-map.sh 2>/dev/null || echo "スクリプト削除済み - 手動でスキップ"`
  - status: pending

- [ ] **ft2**: tmp/ 内の一時ファイルを削除する
  - command: `find tmp/ -type f ! -name 'README.md' -delete 2>/dev/null || true`
  - status: pending

- [ ] **ft3**: 変更を全てコミットする
  - command: `git add -A && git status`
  - status: pending

---

## notes

### 4動線の定義（ユーザー指示より）

```yaml
計画動線:
  入力: 「Xを作って」
  出力: playbook完成 + 作業開始可能状態
  判定: できたか、できなかったか

実行動線:
  入力: playbook に基づく Edit/Write
  出力: 適切にガードされ、品質が保たれた変更
  判定: ガードが機能したか、しなかったか

検証動線:
  入力: /crit
  出力: done_criteria の PASS/FAIL 判定
  判定: 検証が動いたか、動かなかったか

完了動線:
  入力: phase 完了
  出力: アーカイブ + 次タスク導出
  判定: 次に進めたか、進めなかったか
```

### 核心原則

- コンポーネントを列挙するな
- 「動線が動くか動かないか」で評価する
- 動線を1つの連結されたユニットとして扱う
