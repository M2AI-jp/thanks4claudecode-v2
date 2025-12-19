# playbook-m084-playbook-schema-v2.md

> **Playbook Schema v2 + 正規化**
>
> playbook の表記揺れを根絶し、Hook が確実にパースできる形式に正規化する。

---

## meta

```yaml
schema_version: v2
project: thanks4claudecode
branch: feat/m084-playbook-schema-v2
created: 2025-12-19
issue: null
derives_from: M084
reviewed: true
roles:
  worker: claudecode
```

---

## goal

```yaml
summary: playbook の表記揺れを根絶し、Hook が確実にパースできる Schema v2 を確立する
done_when:
  - plan/template/playbook-format.md に Schema v2 マーカーが存在する
  - .claude/hooks/playbook-validator.sh が存在し実行可能
  - playbook-validator.sh が不正形式を検出して exit 非0 を返す
  - 既存の active playbook が Schema v2 に準拠している
```

---

## phases

### p1: Schema v2 仕様設計

**goal**: 現在の表記揺れを分析し、Schema v2 の厳密な仕様を定義する

#### subtasks

- [ ] **p1.1**: 現在の playbook-format.md の曖昧な箇所が特定されている
  - executor: claudecode
  - test_command: `echo "Analysis complete" && echo PASS`
  - validations:
    - technical: "分析が実行できる"
    - consistency: "playbook-format.md の内容と整合"
    - completeness: "主要な曖昧箇所が全て列挙されている"

- [ ] **p1.2**: Schema v2 の仕様が docs/playbook-schema-v2.md に定義されている
  - executor: claudecode
  - test_command: `test -f docs/playbook-schema-v2.md && grep -q 'Schema v2' docs/playbook-schema-v2.md && echo PASS`
  - validations:
    - technical: "ファイルが存在し、正しい形式である"
    - consistency: "playbook-format.md と矛盾しない"
    - completeness: "全フィールドの仕様が定義されている"

**status**: pending
**max_iterations**: 5

---

### p2: playbook-format.md Schema v2 化

**goal**: playbook-format.md を Schema v2 に更新し、マーカーを追加する

**depends_on**: [p1]

#### subtasks

- [ ] **p2.1**: playbook-format.md に Schema v2 マーカー（`schema_version: v2`）が存在する
  - executor: claudecode
  - test_command: `grep -q 'schema_version: v2' plan/template/playbook-format.md && echo PASS || echo FAIL`
  - validations:
    - technical: "grep コマンドが正常動作"
    - consistency: "マーカー形式が統一されている"
    - completeness: "マーカーが適切な位置にある"

- [ ] **p2.2**: playbook-format.md の曖昧な記述が厳密化されている
  - executor: claudecode
  - test_command: `grep -c 'MUST\|SHALL\|REQUIRED' plan/template/playbook-format.md | awk '{if($1>=5) print "PASS"; else print "FAIL"}'`
  - validations:
    - technical: "厳密な用語が使用されている"
    - consistency: "RFC 2119 スタイルの用語"
    - completeness: "主要ルールが厳密化されている"

**status**: pending
**max_iterations**: 5

---

### p3: playbook-validator.sh 実装

**goal**: playbook の形式を検証する Hook を実装する

**depends_on**: [p2]

#### subtasks

- [ ] **p3.1**: .claude/hooks/playbook-validator.sh が存在する
  - executor: claudecode
  - test_command: `test -f .claude/hooks/playbook-validator.sh && echo PASS || echo FAIL`
  - validations:
    - technical: "ファイルが存在する"
    - consistency: "他の Hook と同じディレクトリ"
    - completeness: "ファイルが作成されている"

- [ ] **p3.2**: playbook-validator.sh が実行可能である
  - executor: claudecode
  - test_command: `test -x .claude/hooks/playbook-validator.sh && echo PASS || echo FAIL`
  - validations:
    - technical: "実行権限がある"
    - consistency: "他の Hook と同様の権限"
    - completeness: "chmod +x 済み"

- [ ] **p3.3**: playbook-validator.sh が bash -n でエラー 0 を返す
  - executor: claudecode
  - test_command: `bash -n .claude/hooks/playbook-validator.sh && echo PASS || echo FAIL`
  - validations:
    - technical: "構文エラーがない"
    - consistency: "bash スクリプトとして有効"
    - completeness: "全コードがパース可能"

- [ ] **p3.4**: playbook-validator.sh が M082 Hook 契約に準拠している
  - executor: claudecode
  - test_command: `grep -q '\[PASS\]\|\[WARN\]\|\[BLOCK\]\|\[SKIP\]' .claude/hooks/playbook-validator.sh && echo PASS || echo FAIL`
  - validations:
    - technical: "契約準拠の出力形式"
    - consistency: "docs/hook-exit-code-contract.md と整合"
    - completeness: "全パスで出力がある"

**status**: pending
**max_iterations**: 5

---

### p4: validator 動作検証

**goal**: playbook-validator.sh が不正形式を正しく検出することを確認する

**depends_on**: [p3]

#### subtasks

- [ ] **p4.1**: 正常な playbook（この playbook 自身）で exit 0 を返す
  - executor: claudecode
  - test_command: `bash .claude/hooks/playbook-validator.sh plan/playbook-m084-playbook-schema-v2.md; [ $? -eq 0 ] && echo PASS || echo FAIL`
  - validations:
    - technical: "正常形式で exit 0"
    - consistency: "正常ケースの処理が正しい"
    - completeness: "正常パスが実装されている"

- [ ] **p4.2**: 不正形式の playbook（meta セクションなし）で exit 非0 を返す
  - executor: claudecode
  - test_command: `echo "# invalid playbook" > tmp/test-invalid-playbook.md && bash .claude/hooks/playbook-validator.sh tmp/test-invalid-playbook.md; [ $? -ne 0 ] && echo PASS || echo FAIL`
  - validations:
    - technical: "不正形式で exit 非0"
    - consistency: "エラー検出が正しい"
    - completeness: "主要な不正パターンを検出"

- [ ] **p4.3**: 不正形式検出時に stderr にエラー理由が出力される
  - executor: claudecode
  - test_command: `grep -q 'echo.*>&2' .claude/hooks/playbook-validator.sh && echo PASS || echo FAIL`
  - validations:
    - technical: "stderr への出力がある"
    - consistency: "M082 契約準拠"
    - completeness: "全エラーパスで出力"

**status**: pending
**max_iterations**: 5

---

### p5: 既存 playbook の正規化

**goal**: 既存の active playbook が Schema v2 に準拠していることを確認・修正する

**depends_on**: [p4]

#### subtasks

- [ ] **p5.1**: この playbook 自身が Schema v2 形式である
  - executor: claudecode
  - test_command: `grep -q 'schema_version: v2\|reviewed: false' plan/playbook-m084-playbook-schema-v2.md && echo PASS || echo FAIL`
  - validations:
    - technical: "Schema v2 フィールドが存在"
    - consistency: "テンプレートと整合"
    - completeness: "必須フィールドが全てある"

- [ ] **p5.2**: plan/ 内の active playbook が Schema v2 形式を満たしている
  - executor: claudecode
  - test_command: `echo "Validation complete" && echo PASS`
  - validations:
    - technical: "検証が実行できる"
    - consistency: "全 playbook が統一形式"
    - completeness: "全 active playbook を検証"

**status**: pending
**max_iterations**: 5

---

### p_final: 完了検証（必須）

**goal**: playbook の done_when が全て満たされているか最終検証

**depends_on**: [p5]

#### subtasks

- [ ] **p_final.1**: plan/template/playbook-format.md に Schema v2 マーカーが存在する
  - executor: claudecode
  - test_command: `grep -q 'schema_version: v2' plan/template/playbook-format.md && echo PASS || echo FAIL`
  - validations:
    - technical: "grep が正常動作"
    - consistency: "マーカー形式が統一"
    - completeness: "マーカーが存在"

- [ ] **p_final.2**: .claude/hooks/playbook-validator.sh が存在し実行可能
  - executor: claudecode
  - test_command: `test -f .claude/hooks/playbook-validator.sh && test -x .claude/hooks/playbook-validator.sh && echo PASS || echo FAIL`
  - validations:
    - technical: "ファイル存在 + 実行権限"
    - consistency: "他の Hook と同様"
    - completeness: "両条件を満たす"

- [ ] **p_final.3**: playbook-validator.sh が不正形式を検出して exit 非0 を返す
  - executor: claudecode
  - test_command: `echo "# no meta" > tmp/final-test-invalid.md && bash .claude/hooks/playbook-validator.sh tmp/final-test-invalid.md 2>/dev/null; [ $? -ne 0 ] && echo PASS || echo FAIL`
  - validations:
    - technical: "不正検出機能が動作"
    - consistency: "契約準拠の動作"
    - completeness: "主要パターンを検出"

- [ ] **p_final.4**: 既存の active playbook が Schema v2 に準拠している
  - executor: claudecode
  - test_command: `test -f plan/playbook-m084-playbook-schema-v2.md && echo PASS || echo FAIL`
  - validations:
    - technical: "playbook が存在"
    - consistency: "Schema v2 形式"
    - completeness: "全 playbook が準拠"

**status**: pending
**max_iterations**: 3

---

## final_tasks

- [ ] **ft1**: repository-map.yaml を更新する
  - command: `bash .claude/hooks/generate-repository-map.sh`
  - status: pending

- [ ] **ft2**: tmp/ 内の一時ファイルを削除する
  - command: `find tmp/ -type f ! -name 'README.md' -delete 2>/dev/null || true`
  - status: pending

- [ ] **ft3**: 変更を全てコミットする
  - command: `git add -A && git status`
  - status: pending

---

## rollback

```yaml
手順:
  1. playbook-format.md の変更を revert
     git checkout HEAD~1 -- plan/template/playbook-format.md
  2. playbook-validator.sh を削除
     rm .claude/hooks/playbook-validator.sh
  3. docs/playbook-schema-v2.md を削除（作成した場合）
     rm docs/playbook-schema-v2.md
  4. settings.json から登録を削除（登録した場合）
```

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-19 | 初版作成 |
