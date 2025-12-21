# playbook-m154-refactoring-spec-sync.md

> **Refactoring + Spec Sync**
>
> M150-M153 の Deep Audit 結論に基づき、不要コードを削除し、仕様と実態を完全同期

---

## meta

```yaml
schema_version: v2
project: deep-audit
branch: feat/m154-refactoring
created: 2025-12-21
issue: null
derives_from: M153
reviewed: false
roles:
  worker: claudecode
  reviewer: codex

user_prompt_original: |
  1行の無駄もない状態でリファクタリングして、凍結する工程も必要
```

---

## goal

```yaml
summary: Deep Audit の結論に基づきリファクタリングを実行し、仕様と実態を完全同期
done_when:
  - "Deep Audit で Delete 判定されたファイルが全て削除されている"
  - "Deep Audit で Simplify 判定されたファイルが全て簡素化されている"
  - "各変更後にテストが PASS している（回帰なし）"
  - "verify-manifest.sh が PASS（仕様=実態）"
  - "core-manifest.yaml が実態と完全一致"
  - "全ドキュメントが正確"
```

---

## phases

### p1: Delete 判定ファイルの削除

**goal**: Deep Audit で Delete 判定されたファイルを安全に削除

#### subtasks

- [ ] **p1.1**: 削除対象リストの確認
  - executor: claudecode
  - test_command: `grep -l "Delete" docs/deep-audit-*.md | wc -l | [ $(cat) -ge 1 ] && echo PASS || echo "SKIP: No files to delete"`
  - validations:
    - technical: "Delete 判定されたファイルをリストアップ"
    - consistency: "core-manifest.yaml の deletion_candidates と照合"
    - completeness: "全 Delete 判定を網羅"

- [ ] **p1.2**: 1ファイルずつ削除 + テスト
  - executor: claudecode
  - test_command: `bash scripts/flow-runtime-test.sh 2>&1 | grep -q "ALL.*PASS" && echo PASS || echo FAIL`
  - validations:
    - technical: "削除後にテストが PASS"
    - consistency: "settings.json から登録も削除"
    - completeness: "参照箇所も更新"
  - note: "各削除後に flow-runtime-test を実行し回帰がないことを確認"

- [ ] **p1.3**: Codex レビュー（削除の妥当性）
  - executor: codex
  - test_command: `grep -q "削除.*承認" docs/deep-audit-completion-common.md && echo PASS || echo "SKIP"`
  - validations:
    - technical: "削除が妥当か Codex が確認"
    - consistency: "依存関係が壊れていないか確認"
    - completeness: "ドキュメント更新も完了"

**status**: pending
**max_iterations**: 10

---

### p2: Simplify 判定ファイルの簡素化

**goal**: Deep Audit で Simplify 判定されたファイルを簡素化

#### subtasks

- [ ] **p2.1**: 簡素化対象リストの確認
  - executor: claudecode
  - test_command: `grep -l "Simplify" docs/deep-audit-*.md | wc -l | [ $(cat) -ge 1 ] && echo PASS || echo "SKIP: No files to simplify"`
  - validations:
    - technical: "Simplify 判定されたファイルをリストアップ"
    - consistency: "改善提案を確認"
    - completeness: "全 Simplify 判定を網羅"

- [ ] **p2.2**: 1ファイルずつ簡素化 + テスト
  - executor: claudecode
  - test_command: `bash scripts/flow-runtime-test.sh 2>&1 | grep -q "ALL.*PASS" && echo PASS || echo FAIL`
  - validations:
    - technical: "簡素化後にテストが PASS"
    - consistency: "機能が維持されている"
    - completeness: "コメント・ドキュメント更新"
  - note: "各簡素化後に flow-runtime-test を実行し回帰がないことを確認"

- [ ] **p2.3**: Codex レビュー（簡素化の妥当性）
  - executor: codex
  - test_command: `grep -q "簡素化.*承認" docs/deep-audit-completion-common.md && echo PASS || echo "SKIP"`
  - validations:
    - technical: "簡素化が妥当か Codex が確認"
    - consistency: "品質が維持されているか確認"
    - completeness: "テストカバレッジが維持されている"

**status**: pending
**max_iterations**: 10

---

### p3: Spec Sync（仕様-実態同期）

**goal**: 仕様と実態を完全同期

#### subtasks

- [ ] **p3.1**: core-manifest.yaml 更新
  - executor: claudecode
  - test_command: `bash scripts/verify-manifest.sh 2>&1 | grep -q "PASS\|OK" && echo PASS || echo FAIL`
  - validations:
    - technical: "実態に合わせて core-manifest.yaml を更新"
    - consistency: "削除したファイルは除去、追加したファイルは追加"
    - completeness: "全コンポーネントが正確に記載"

- [ ] **p3.2**: settings.json 更新
  - executor: claudecode
  - test_command: `jq '.hooks' .claude/settings.json > /dev/null && echo PASS || echo FAIL`
  - validations:
    - technical: "削除した Hook は登録から除去"
    - consistency: "JSON が有効"
    - completeness: "全登録 Hook が存在するファイルを指す"

- [ ] **p3.3**: ドキュメント更新
  - executor: claudecode
  - test_command: `grep -q "削除済み" docs/deep-audit-*.md && echo PASS || echo "SKIP: No documentation needed"`
  - validations:
    - technical: "RUNBOOK.md, README.md を更新"
    - consistency: "削除したコンポーネントへの参照を除去"
    - completeness: "全ドキュメントが正確"

**status**: pending
**max_iterations**: 5

---

### p_final: リファクタリング完了検証

**goal**: 全変更が正しく反映されていることを検証

**depends_on**: [p1, p2, p3]

#### subtasks

- [ ] **p_final.1**: 全テスト PASS
  - executor: claudecode
  - test_command: `bash scripts/flow-runtime-test.sh 2>&1 | grep -q "ALL.*PASS" && echo PASS || echo FAIL`

- [ ] **p_final.2**: verify-manifest.sh PASS
  - executor: claudecode
  - test_command: `bash scripts/verify-manifest.sh && echo PASS || echo FAIL`

- [ ] **p_final.3**: 削除済みファイルが存在しない
  - executor: claudecode
  - test_command: `ls .claude/hooks/*.sh 2>/dev/null | wc -l | [ $(cat) -le 20 ] && echo PASS || echo FAIL`
  - note: "削除後のファイル数が減少していること"

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
  1. git reflog で直前のコミットを確認
     git reflog

  2. リファクタリング前に戻す
     git reset --hard HEAD~N  # N は戻すコミット数

  3. 必要に応じて個別ファイルを復元
     git checkout HEAD~1 -- <file>
```

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-21 | 初版作成 |
