# playbook-m087-local-hook-tests.md

> **ローカル Hook テストスイートの整備**
>
> Hook の動作を保証するローカルテストスイートを整備。
> ローカル完結の設計原則を維持し、CI 依存を回避。

---

## meta

```yaml
schema_version: v2
project: thanks4claudecode
branch: feat/m087-local-hook-tests
created: 2025-12-19
issue: null
derives_from: M087
reviewed: true
roles:
  worker: claudecode
```

---

## goal

```yaml
summary: ローカル完結の Hook テストスイートを整備し、回帰テストを可能にする
done_when:
  - .claude/tests/hook-tests.sh が存在し実行可能
  - 全 Hook が bash -n で構文エラーなし
  - 主要 Hook の基本動作テストが PASS
  - テスト結果が stdout に出力される
```

---

## phases

### p1: テストスクリプトの実装

**goal**: .claude/tests/hook-tests.sh を作成し、全 Hook のテストを実装する

#### subtasks

- [ ] **p1.1**: .claude/tests/ ディレクトリが存在する
  - executor: claudecode
  - test_command: `test -d .claude/tests && echo PASS || echo FAIL`
  - validations:
    - technical: "ディレクトリが存在する"
    - consistency: ".claude/ 配下に配置されている"
    - completeness: "テスト用ディレクトリとして適切"

- [ ] **p1.2**: hook-tests.sh が存在し実行権限がある
  - executor: claudecode
  - test_command: `test -x .claude/tests/hook-tests.sh && echo PASS || echo FAIL`
  - validations:
    - technical: "ファイルが存在し実行可能"
    - consistency: "他の Hook と同様の権限設定"
    - completeness: "実行に必要な権限がある"

- [ ] **p1.3**: 全 Hook の構文チェック（bash -n）が実装されている
  - executor: claudecode
  - test_command: `grep -q 'bash -n' .claude/tests/hook-tests.sh && echo PASS || echo FAIL`
  - validations:
    - technical: "bash -n によるチェックがある"
    - consistency: "全 Hook を対象としている"
    - completeness: "構文チェック機能が完全"

- [ ] **p1.4**: 主要 Hook の基本動作テストが実装されている
  - executor: claudecode
  - test_command: `grep -cE 'test_.*\(\)|subtask-guard|consent-guard|archive-playbook' .claude/tests/hook-tests.sh | awk '{if($1>=3) print "PASS"; else print "FAIL"}'`
  - validations:
    - technical: "テスト関数が定義されている"
    - consistency: "M082 契約準拠を検証している"
    - completeness: "主要 Hook がカバーされている"

**status**: pending
**max_iterations**: 5

---

### p2: テスト実行と検証

**goal**: テストスクリプトを実行し、全テストが PASS することを確認する

**depends_on**: [p1]

#### subtasks

- [ ] **p2.1**: 全 Hook が bash -n で構文エラーなし
  - executor: claudecode
  - test_command: `bash .claude/tests/hook-tests.sh 2>&1 | grep -q 'Syntax.*PASS\|All.*PASS' && echo PASS || echo FAIL`
  - validations:
    - technical: "全 Hook の構文が正しい"
    - consistency: "新規追加された Hook も含む"
    - completeness: "例外なく全 Hook をチェック"

- [ ] **p2.2**: 主要 Hook の基本動作テストが PASS
  - executor: claudecode
  - test_command: `bash .claude/tests/hook-tests.sh 2>&1 | grep -cE '\[PASS\]' | awk '{if($1>=5) print "PASS"; else print "FAIL"}'`
  - validations:
    - technical: "基本動作テストが成功"
    - consistency: "M082 契約に準拠した出力"
    - completeness: "主要 Hook 全てテスト済み"

- [ ] **p2.3**: テスト結果が stdout に出力される
  - executor: claudecode
  - test_command: `bash .claude/tests/hook-tests.sh 2>&1 | wc -l | awk '{if($1>=10) print "PASS"; else print "FAIL"}'`
  - validations:
    - technical: "出力が生成される"
    - consistency: "人間が読める形式"
    - completeness: "全テスト結果が含まれる"

**status**: pending
**max_iterations**: 5

---

### p_final: 完了検証（必須）

**goal**: playbook の done_when が全て満たされているか最終検証

**depends_on**: [p2]

#### subtasks

- [ ] **p_final.1**: .claude/tests/hook-tests.sh が存在し実行可能
  - executor: claudecode
  - test_command: `test -f .claude/tests/hook-tests.sh && test -x .claude/tests/hook-tests.sh && echo PASS || echo FAIL`
  - validations:
    - technical: "ファイル存在 + 実行権限"
    - consistency: "done_when 項目 1"
    - completeness: "条件を満たす"

- [ ] **p_final.2**: 全 Hook が bash -n で構文エラーなし
  - executor: claudecode
  - test_command: `for f in .claude/hooks/*.sh; do bash -n "$f" || exit 1; done && echo PASS`
  - validations:
    - technical: "全 Hook の構文が正しい"
    - consistency: "done_when 項目 2"
    - completeness: "例外なし"

- [ ] **p_final.3**: 主要 Hook の基本動作テストが PASS
  - executor: claudecode
  - test_command: `bash .claude/tests/hook-tests.sh 2>&1 | grep -q 'All tests passed\|PASS' && echo PASS || echo FAIL`
  - validations:
    - technical: "テストが成功"
    - consistency: "done_when 項目 3"
    - completeness: "主要 Hook カバー"

- [ ] **p_final.4**: テスト結果が stdout に出力される
  - executor: claudecode
  - test_command: `bash .claude/tests/hook-tests.sh | head -1 | grep -qE '^\[|^=|^Hook' && echo PASS || echo FAIL`
  - validations:
    - technical: "stdout に出力がある"
    - consistency: "done_when 項目 4"
    - completeness: "結果が確認可能"

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
  1. hook-tests.sh を削除
     rm .claude/tests/hook-tests.sh
  2. tests ディレクトリが空なら削除
     rmdir .claude/tests 2>/dev/null || true
  3. project.md の変更を revert（必要に応じて）
     git checkout HEAD -- plan/project.md
```

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-19 | 初版作成。M087 再設計（CI 化 → ローカルテスト）。 |
