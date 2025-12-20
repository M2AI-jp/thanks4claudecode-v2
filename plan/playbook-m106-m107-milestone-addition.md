# playbook-m106-m107-milestone-addition.md

> **M105 完了後のマイルストーン追加作業**

---

## meta

```yaml
schema_version: v2
project: thanks4claudecode
branch: feat/layer-architecture
created: 2025-12-20
issue: null
derives_from: M105 完了後の計画更新
reviewed: false
roles:
  worker: claudecode
```

---

## goal

```yaml
summary: M106/M107 を project.md に追加し、M105 完了後の次ステップを明確化
done_when:
  - "project.md に M106（動作不良コンポーネント修正）が追加されている"
  - "project.md に M107（動線単位テスト再実施）が追加されている"
  - "M106 の done_when に consent-guard, critic-guard, subtask-guard の修正条件が含まれている"
  - "M107 の done_when に動線単位テストの設計・実行条件が含まれている"
```

---

## phases

### p1: project.md 更新

**goal**: M106/M107 を project.md に追加

#### subtasks

- [ ] **p1.1**: project.md に M106 が追加されている
  - executor: claudecode
  - test_command: `grep -q 'id: M106' plan/project.md && echo PASS || echo FAIL`
  - validations:
    - technical: "YAML 構文が正しく、M105 の後に配置されている"
    - consistency: "done_when 形式が他のマイルストーンと統一されている"
    - completeness: "consent-guard, critic-guard, subtask-guard の3件が明記されている"

- [ ] **p1.2**: project.md に M107 が追加されている
  - executor: claudecode
  - test_command: `grep -q 'id: M107' plan/project.md && echo PASS || echo FAIL`
  - validations:
    - technical: "YAML 構文が正しい"
    - consistency: "done_when 形式が他のマイルストーンと統一されている"
    - completeness: "動線単位テストの設計・実行条件が含まれている"

- [ ] **p1.3**: M106 の done_when が検証可能な形式である
  - executor: claudecode
  - test_command: `grep -A20 'id: M106' plan/project.md | grep -q 'done_when' && echo PASS || echo FAIL`
  - validations:
    - technical: "done_when が状態形式で記述されている"
    - consistency: "criterion-validation-rules.md の禁止パターンに該当しない"
    - completeness: "3件の動作不良コンポーネント全てに対応"

- [ ] **p1.4**: M107 の done_when が検証可能な形式である
  - executor: claudecode
  - test_command: `grep -A20 'id: M107' plan/project.md | grep -q 'done_when' && echo PASS || echo FAIL`
  - validations:
    - technical: "done_when が状態形式で記述されている"
    - consistency: "criterion-validation-rules.md の禁止パターンに該当しない"
    - completeness: "動線単位テストの再設計条件が含まれている"

**status**: pending
**max_iterations**: 3

---

### p_final: 完了検証

**goal**: playbook の done_when が全て満たされているか最終検証

#### subtasks

- [ ] **p_final.1**: M106 が project.md に存在し、3件の動作不良コンポーネントが明記されている
  - executor: claudecode
  - test_command: `grep -A30 'id: M106' plan/project.md | grep -E 'consent-guard|critic-guard|subtask-guard' | wc -l | awk '{if($1>=3) print "PASS"; else print "FAIL"}'`
  - validations:
    - technical: "grep コマンドが正常に実行できる"
    - consistency: "check.md の動作不良リストと一致している"
    - completeness: "3件全てが含まれている"

- [ ] **p_final.2**: M107 が project.md に存在し、動線単位テストの再実施条件が含まれている
  - executor: claudecode
  - test_command: `grep -A30 'id: M107' plan/project.md | grep -qE '動線.*テスト|テスト.*設計' && echo PASS || echo FAIL`
  - validations:
    - technical: "grep コマンドが正常に実行できる"
    - consistency: "M105 の問題点（bash -n のみ）が解決される設計になっている"
    - completeness: "テスト設計と実行の両方が含まれている"

**status**: pending
**max_iterations**: 3

---

## final_tasks

- [ ] **ft1**: 変更を全てコミットする
  - command: `git add -A && git status`
  - status: pending

---

## M106/M107 追加内容（参考）

### M106: 動作不良コンポーネント修正

```yaml
- id: M106
  name: "動作不良コンポーネント修正"
  description: |
    M105 で特定された3件の動作不良コンポーネントを修正する。
    - consent-guard: 特定単語トリガー、デッドロック発生
    - subtask-guard: STRICT=0 でデフォルト WARN、検証が緩い
    - critic-guard: playbook の phase 完了をチェックしない
  status: pending
  depends_on: [M105]
  done_when:
    - "[ ] consent-guard.sh がデッドロックを起こさない（無限ループ防止ロジックが実装されている）"
    - "[ ] subtask-guard.sh が STRICT=1 でデフォルト BLOCK に変更されている"
    - "[ ] critic-guard.sh が playbook の phase 完了をチェックする"
    - "[ ] 3件全てが bash -n で構文エラーなし"
  test_commands:
    - "timeout 5 bash .claude/hooks/consent-guard.sh && echo PASS || echo FAIL"
    - "grep -q 'STRICT=1' .claude/hooks/subtask-guard.sh && echo PASS || echo FAIL"
    - "grep -q 'phase' .claude/hooks/critic-guard.sh && echo PASS || echo FAIL"
```

### M107: 動線単位テスト再実施

```yaml
- id: M107
  name: "動線単位テスト再実施（M105 報酬詐欺是正）"
  description: |
    M105 のテストは「bash -n 構文チェック」のみで「動線単位テスト」を実施していなかった。
    これは報酬詐欺（テスト名と実際のテスト内容の乖離）である。
    正しいテスト手法を設計し、全40コンポーネントの動作を実際に検証する。
  status: pending
  depends_on: [M106]
  done_when:
    - "[ ] 動線単位テストの設計が docs/golden-path-test-design.md に文書化されている"
    - "[ ] scripts/golden-path-test.sh が動線単位テスト（入力→出力）を実行する"
    - "[ ] 全40コンポーネントが動線単位テストで PASS（40/40）"
    - "[ ] テスト結果が再現可能である（同じ環境で同じ結果が得られる）"
  test_commands:
    - "test -f docs/golden-path-test-design.md && echo PASS || echo FAIL"
    - "bash scripts/golden-path-test.sh 2>&1 | grep -q 'ALL TESTS PASSED' && echo PASS || echo FAIL"
```
