# playbook-m129-runtime-verification-system.md

> **M129: 動線 100% 担保 - 実行時検証システム**

---

## meta

```yaml
schema_version: v2
project: thanks4claudecode
branch: feat/m129-runtime-verification
created: 2025-12-21
issue: null
derives_from: M129
reviewed: false
roles:
  worker: claudecode
  reviewer: codex

user_prompt_original: |
  M129 の playbook を作成してください。

  ## M129: 動線 100% 担保 - 実行時検証システム

  ### 背景（Codex レビュー FAIL の指摘）

  M128 で Codex が以下を指摘:

  1. **e2e-contract-test.sh のカバレッジ不足**
     - `contract_check_*` を直接テストしているが、実際の Hook（`pre-bash-check.sh` の JSON 解析、`playbook-guard.sh` の配線）はテストしていない
     - 欠落: fail-closed（STATE_FILE 欠損）、HARD_BLOCK_COMMANDS、admin maintenance パターン全種

  2. **flow-integrity-test.sh が純粋に静的**
     - ファイル存在確認のみで、実際の subagent 呼び出しや Hook ランタイム実行なし

  3. **done_when の証拠不足**
     - grep/bash -n チェックに依存し、実際のフロー実行なし

  ### Claude のコンテキスト保持機構

  以下の仕組みが動線保持に関与:
  - `.claude/hooks/session-start.sh` - セッション開始時の動線サマリー出力
  - `.claude/hooks/pre-compact.sh` - コンパクト前のコンテキスト保存
  - `state.md` - playbook/phase 追跡
  - `docs/essential-documents.md` - 動線単位の必須ドキュメント

  ### done_when（評価基準）

  1. 「実際の Hook 発火」を検証するテストが存在し、全 PASS
  2. 「4 動線（計画/実行/検証/完了）の実行時検証」テストが存在し、全 PASS
  3. fail-closed/HARD_BLOCK/admin maintenance パターンのテストが追加され、全 PASS
  4. コンテキスト保持機構（session-start, pre-compact）の動作検証テストが全 PASS
  5. ユーザー承認を得た設計に基づいて実装が完了

  ### Phases（評価 → 設計 → 確認 → 実装）

  **p1: 評価フェーズ**
  - 現在のテストカバレッジを分析
  - 100% 担保に必要な追加テストを特定
  - コンテキスト保持機構の動作を検証

  **p2: 設計フェーズ**
  - 追加テストの設計書作成
  - 実行時検証システムのアーキテクチャ設計
  - テスト実行順序と依存関係の設計

  **p3: ユーザー確認フェーズ**
  - 設計書をユーザーに提示
  - フィードバックを反映
  - 最終設計の承認を取得

  **p4: 実装フェーズ**
  - e2e-contract-test.sh の拡張実装
  - Hook 実行テストの実装
  - 動線実行テストの実装

  **p5: 統合検証フェーズ**
  - 全テスト実行
  - Codex による最終レビュー
  - done_when 達成確認

  ### 制約

  - worker: claudecode（評価・設計・テスト設計）
  - reviewer: codex（設計レビュー、最終検証）
  - p3 で必ずユーザー確認を取ること
```

---

## goal

```yaml
summary: 動線 100% 担保のための実行時検証システムを構築し、全 Hook の実際の発火を E2E でテスト
done_when:
  - 「実際の Hook 発火」を検証するテスト（scripts/hook-runtime-test.sh）が存在し、全 PASS
  - 「4 動線（計画/実行/検証/完了）の実行時検証」テスト（scripts/flow-runtime-test.sh）が存在し、全 PASS
  - fail-closed/HARD_BLOCK/admin maintenance テストが e2e-contract-test.sh に追加され、テスト実行時に全 PASS（exit 0）
  - コンテキスト保持機構（session-start, pre-compact）の動作検証テストが全 PASS
  - ユーザー承認記録（tmp/m129-approval.md）が存在し、設計版識別子を含み、p5.1-5.4 が全 PASS 状態で Codex 最終レビューが PASS
```

---

## phases

### p1: 評価フェーズ（現状分析）

**goal**: 現在のテストカバレッジを分析し、100% 担保に必要な追加テストを特定

**depends_on**: []

#### subtasks

- [ ] **p1.1**: e2e-contract-test.sh の現在のテストケース一覧が分析されている
  - executor: claudecode
  - test_command: `test -f tmp/m129-analysis-contract-test.md`
  - validations:
    - technical: "分析結果ファイルが作成されている"
    - consistency: "テストケースが実際のファイル内容と一致"
    - completeness: "全シナリオ（A/B/C/session_end/boundary/security）が分析されている"

- [ ] **p1.2**: flow-integrity-test.sh の静的テストと欠落ポイントが特定されている
  - executor: claudecode
  - test_command: `test -f tmp/m129-analysis-flow-test.md`
  - validations:
    - technical: "分析結果ファイルが作成されている"
    - consistency: "テスト内容が実際のファイルと一致"
    - completeness: "静的チェックと動的チェックの区別が明確"

- [ ] **p1.3**: contract.sh の全パターン（HARD_BLOCK_COMMANDS, ADMIN_MAINTENANCE_PATTERNS）のカバレッジが分析されている
  - executor: claudecode
  - test_command: `test -f tmp/m129-analysis-contract-patterns.md`
  - validations:
    - technical: "全パターンがリストアップされている"
    - consistency: "contract.sh の定義と一致"
    - completeness: "テスト有無の判定が全パターンに対して完了"

- [ ] **p1.4**: コンテキスト保持機構（session-start, pre-compact）の動作状態が分析されている
  - executor: claudecode
  - test_command: `test -f tmp/m129-analysis-context-mechanism.md`
  - validations:
    - technical: "各機構の動作フローが記録されている"
    - consistency: "実際のスクリプト内容と分析が一致"
    - completeness: "session-start, pre-compact, state.md の全てが分析されている"

- [ ] **p1.5**: Hook 発火テストの欠落（pre-bash-check.sh の JSON 解析、playbook-guard.sh の配線）が特定されている
  - executor: claudecode
  - test_command: `test -f tmp/m129-analysis-hook-gaps.md`
  - validations:
    - technical: "欠落ポイントが具体的にリストアップされている"
    - consistency: "Codex レビュー指摘と一致"
    - completeness: "全 Hook の発火テスト状況が分析されている"

**status**: done
**max_iterations**: 5

---

### p2: 設計フェーズ (done)

**goal**: 実行時検証システムのアーキテクチャと追加テストを設計

**depends_on**: [p1]

#### subtasks

- [ ] **p2.1**: Hook 実行時テスト（hook-runtime-test.sh）の設計書が作成されている
  - executor: claudecode
  - test_command: `test -f tmp/m129-design-hook-runtime-test.md && grep -q 'テストケース' tmp/m129-design-hook-runtime-test.md`
  - validations:
    - technical: "テストケースが具体的に定義されている"
    - consistency: "p1 の分析結果と整合"
    - completeness: "pre-bash-check, playbook-guard の JSON 入力テストが含まれている"

- [ ] **p2.2**: 動線実行時テスト（flow-runtime-test.sh）の設計書が作成されている
  - executor: claudecode
  - test_command: `test -f tmp/m129-design-flow-runtime-test.md && grep -q '計画動線' tmp/m129-design-flow-runtime-test.md`
  - validations:
    - technical: "4 動線それぞれのテストケースが定義されている"
    - consistency: "essential-documents.md の動線定義と整合"
    - completeness: "計画/実行/検証/完了の全動線がカバーされている"

- [ ] **p2.3**: fail-closed/HARD_BLOCK/admin maintenance テストの設計書が作成されている
  - executor: claudecode
  - test_command: `test -f tmp/m129-design-edge-cases.md && grep -q 'HARD_BLOCK' tmp/m129-design-edge-cases.md`
  - validations:
    - technical: "contract.sh の全パターンがテストケース化されている"
    - consistency: "p1.3 の分析結果と整合"
    - completeness: "fail-closed, HARD_BLOCK_COMMANDS, ADMIN_MAINTENANCE_PATTERNS が全て含まれている"

- [ ] **p2.4**: コンテキスト保持テストの設計書が作成されている
  - executor: claudecode
  - test_command: `test -f tmp/m129-design-context-test.md && grep -q 'pre-compact' tmp/m129-design-context-test.md`
  - validations:
    - technical: "session-start, pre-compact のテストケースが定義されている"
    - consistency: "p1.4 の分析結果と整合"
    - completeness: "snapshot.json の保存/復元テストが含まれている"

- [ ] **p2.5**: 統合設計書（tmp/m129-unified-design.md）が作成されている
  - executor: claudecode
  - test_command: `test -f tmp/m129-unified-design.md && awk 'END{exit !(NR>=100)}' tmp/m129-unified-design.md`
  - validations:
    - technical: "全設計書が統合されている"
    - consistency: "p2.1-p2.4 の内容と一貫性がある"
    - completeness: "実装順序、依存関係、期待結果が明記されている"

**status**: pending
**max_iterations**: 5

---

### p3: ユーザー確認フェーズ

**goal**: 設計書をユーザーに提示し、承認を取得

**depends_on**: [p2]

#### subtasks

- [ ] **p3.1**: 統合設計書（tmp/m129-unified-design.md）がユーザーに提示されている
  - executor: claudecode
  - test_command: `test -f tmp/m129-design-presented.flag`
  - validations:
    - technical: "設計書の内容が正確に説明されている"
    - consistency: "p2.5 の設計書と提示内容が一致"
    - completeness: "全テストカテゴリが説明されている"

- [ ] **p3.2**: ユーザーからのフィードバックが記録されている
  - executor: user
  - test_command: `test -f tmp/m129-user-feedback.md`
  - validations:
    - technical: "フィードバックが明確に記録されている"
    - consistency: "ユーザーの意図が正確に反映されている"
    - completeness: "全ての懸念事項がリストアップされている"

- [ ] **p3.3**: フィードバックが設計書に反映されている（修正がある場合）
  - executor: claudecode
  - test_command: `test -f tmp/m129-feedback-applied.flag || test -f tmp/m129-no-changes-needed.flag`
  - validations:
    - technical: "修正内容が設計書に反映されている"
    - consistency: "フィードバックと修正内容が一致"
    - completeness: "全ての指摘事項が対応されている"

- [ ] **p3.4**: ユーザーの最終承認が得られている
  - executor: user
  - test_command: `test -f tmp/m129-approval.md && grep -qE '承認|LGTM|Approved' tmp/m129-approval.md`
  - validations:
    - technical: "承認が明確に記録されている"
    - consistency: "設計書の最終版と承認が整合"
    - completeness: "実装開始の許可が得られている"

**status**: pending
**max_iterations**: 3

---

### p4: 実装フェーズ

**goal**: 設計に基づいて実行時検証テストを実装

**depends_on**: [p3]

#### subtasks

- [ ] **p4.1**: scripts/hook-runtime-test.sh が作成され、実行可能
  - executor: claudecode
  - test_command: `test -f scripts/hook-runtime-test.sh && bash -n scripts/hook-runtime-test.sh`
  - validations:
    - technical: "スクリプトが構文エラーなしで解析可能"
    - consistency: "p2.1 の設計書と実装が一致"
    - completeness: "全テストケースが実装されている"

- [ ] **p4.2**: scripts/flow-runtime-test.sh が作成され、実行可能
  - executor: claudecode
  - test_command: `test -f scripts/flow-runtime-test.sh && bash -n scripts/flow-runtime-test.sh`
  - validations:
    - technical: "スクリプトが構文エラーなしで解析可能"
    - consistency: "p2.2 の設計書と実装が一致"
    - completeness: "4 動線のテストが全て実装されている"

- [ ] **p4.3**: e2e-contract-test.sh に fail-closed/HARD_BLOCK/admin maintenance テストが追加されている
  - executor: claudecode
  - test_command: `grep -qE 'fail.closed|HARD_BLOCK_COMMANDS|admin.*maintenance' scripts/e2e-contract-test.sh`
  - validations:
    - technical: "テストケースがファイルに追加されている"
    - consistency: "p2.3 の設計書と実装が一致"
    - completeness: "全パターンがテスト化されている"

- [ ] **p4.4**: scripts/context-test.sh が作成され、session-start/pre-compact の動作を検証
  - executor: claudecode
  - test_command: `test -f scripts/context-test.sh && bash -n scripts/context-test.sh`
  - validations:
    - technical: "スクリプトが構文エラーなしで解析可能"
    - consistency: "p2.4 の設計書と実装が一致"
    - completeness: "snapshot.json 保存/復元テストが含まれている"

- [ ] **p4.5**: 中間成果物（tmp/m129-*.md）が不要な場合は削除またはアーカイブ
  - executor: claudecode
  - test_command: `test $(find tmp -name 'm129-*.md' -type f 2>/dev/null | wc -l) -le 1`
  - validations:
    - technical: "中間成果物が整理されている"
    - consistency: "folder-management.md のルールに準拠"
    - completeness: "必要なもののみ残存"

**status**: pending
**max_iterations**: 5

---

### p5: 統合検証フェーズ

**goal**: 全テスト実行と Codex 最終レビューで done_when 達成を確認

**depends_on**: [p4]

#### subtasks

- [ ] **p5.1**: hook-runtime-test.sh が全 PASS で完了
  - executor: claudecode
  - test_command: `bash scripts/hook-runtime-test.sh`
  - validations:
    - technical: "テストが正常に実行され、全 PASS（exit 0）"
    - consistency: "p4.1 で実装したテストが動作"
    - completeness: "全 Hook 発火テストが含まれている"

- [ ] **p5.2**: flow-runtime-test.sh が全 PASS で完了
  - executor: claudecode
  - test_command: `bash scripts/flow-runtime-test.sh`
  - validations:
    - technical: "テストが正常に実行され、全 PASS（exit 0）"
    - consistency: "p4.2 で実装したテストが動作"
    - completeness: "4 動線テストが全て PASS"

- [ ] **p5.3**: e2e-contract-test.sh の拡張テストが全 PASS
  - executor: claudecode
  - test_command: `bash scripts/e2e-contract-test.sh all`
  - validations:
    - technical: "テストが正常に実行され、全 PASS（exit 0）"
    - consistency: "p4.3 で追加したテストが含まれている"
    - completeness: "fail-closed/HARD_BLOCK/admin maintenance が全て PASS"

- [ ] **p5.4**: context-test.sh が全 PASS で完了
  - executor: claudecode
  - test_command: `bash scripts/context-test.sh`
  - validations:
    - technical: "テストが正常に実行され、全 PASS（exit 0）"
    - consistency: "p4.4 で実装したテストが動作"
    - completeness: "session-start/pre-compact テストが全て PASS"

- [ ] **p5.5**: Codex による最終レビューが PASS
  - executor: codex
  - test_command: `test -f tmp/m129-codex-final-review.md && grep -qE 'RESULT:.*PASS' tmp/m129-codex-final-review.md`
  - validations:
    - technical: "Codex がレビューを完了"
    - consistency: "done_when の全項目が達成されている"
    - completeness: "レビュー指摘事項がない、または全て対応済み"

**status**: pending
**max_iterations**: 5

---

### p_final: 完了検証（必須）

**goal**: playbook の done_when が全て満たされているか最終検証

**depends_on**: [p5]

#### subtasks

- [ ] **p_final.1**: hook-runtime-test.sh が存在し全 PASS
  - executor: claudecode
  - test_command: `test -f scripts/hook-runtime-test.sh && bash scripts/hook-runtime-test.sh`
  - validations:
    - technical: "テストスクリプトが存在し実行可能"
    - consistency: "done_when 1 と整合"
    - completeness: "全 Hook 発火テストがカバーされている"

- [ ] **p_final.2**: flow-runtime-test.sh が存在し全 PASS
  - executor: claudecode
  - test_command: `test -f scripts/flow-runtime-test.sh && bash scripts/flow-runtime-test.sh`
  - validations:
    - technical: "テストスクリプトが存在し実行可能"
    - consistency: "done_when 2 と整合"
    - completeness: "4 動線テストが全て含まれている"

- [ ] **p_final.3**: fail-closed/HARD_BLOCK/admin maintenance テストが全 PASS
  - executor: claudecode
  - test_command: `bash scripts/e2e-contract-test.sh all`
  - validations:
    - technical: "テストが正常に実行される"
    - consistency: "done_when 3 と整合"
    - completeness: "契約の全パターンがテストされている"

- [ ] **p_final.4**: context-test.sh が存在し全 PASS
  - executor: claudecode
  - test_command: `test -f scripts/context-test.sh && bash scripts/context-test.sh`
  - validations:
    - technical: "テストスクリプトが存在し実行可能"
    - consistency: "done_when 4 と整合"
    - completeness: "session-start/pre-compact がテストされている"

- [ ] **p_final.5**: ユーザー承認記録が存在し、設計版識別子を含み、p5.1-5.4 再実行 PASS、Codex レビュー PASS
  - executor: claudecode
  - test_command: `bash scripts/hook-runtime-test.sh && bash scripts/flow-runtime-test.sh && bash scripts/e2e-contract-test.sh all && bash scripts/context-test.sh && test -f tmp/m129-approval.md && grep -qE '承認|LGTM|Approved' tmp/m129-approval.md && grep -qE 'design_version:|m129-unified-design' tmp/m129-approval.md && test -f tmp/m129-codex-final-review.md && grep -qE 'RESULT:.*PASS' tmp/m129-codex-final-review.md`
  - validations:
    - technical: "p5.1-5.4 テストを再実行して全 PASS、承認記録と Codex レビュー PASS"
    - consistency: "done_when 5 と整合"
    - completeness: "全テスト再実行 + 承認 + Codex レビューの 3 条件を同時検証"

**status**: pending
**max_iterations**: 3

---

## final_tasks

- [ ] **ft1**: tmp/ 内の中間成果物を整理する
  - command: `find tmp/ -type f -name 'm129-*.md' -delete 2>/dev/null || true`
  - status: pending

- [ ] **ft2**: 変更を全てコミットする
  - command: `git add -A && git status`
  - status: pending

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-21 | Codex 3回目レビュー指摘を反映: done_when 3 を具体化。p_final.5 で p5.1-5.4 テストを再実行して連動を保証。 |
| 2025-12-21 | Codex 2回目レビュー指摘を反映: done_when 5 を客観検証可能に修正。p_final.5 の test_command を設計版識別子+Codex PASS で検証。 |
| 2025-12-21 | Codex レビュー指摘を反映: test_command を exit code ベースに修正。手動確認を成果物ファイル検証に変換。 |
| 2025-12-21 | 初版作成。M129 playbook。 |
