# playbook-m157-post-m156-completion.md

> **M156 完了処理 + 次ステップ決定**
>
> M156 の後処理（push/merge/project.md 更新）を完了し、次のマイルストーンを検討する。

---

## meta

```yaml
schema_version: v2
project: M157 Post-M156 Completion
branch: feat/m156-pipeline-completeness-audit  # M156 ブランチで継続作業
created: 2025-12-22
issue: null
derives_from: M156
reviewed: true  # reviewer シミュレーション完了
roles:
  worker: claudecode

user_prompt_original: |
  M156 が critic PASS で完了しました。次タスクの playbook を作成してください。

  現在の状態:
  - M156 完了（ローカルコミット済み、push/merge 未完了）
  - project.md の M156 achieved 更新も未完了

  pm への依頼:
  1. project.md を読んで次の milestone を特定
  2. 新しい playbook を作成
  3. p0 に「M156 完了処理（push/merge/project.md更新）」を含める
  4. state.md を更新
```

---

## goal

```yaml
summary: M156 の後処理を完了し、プロジェクトを完了状態にする
done_when:
  - feat/m156-pipeline-completeness-audit ブランチが main にマージされている
  - project.md の M156 status が achieved に更新されている
  - project.md の M156 done_when が全て [x] に更新されている
  - state.md の playbook.active が null に更新されている
  - リポジトリが安定状態（git status clean）である
```

---

## phases

### p0: M156 完了処理

**goal**: M156 ブランチを main にマージし、project.md を更新する

#### subtasks

- [ ] **p0.1**: feat/m156-pipeline-completeness-audit ブランチが origin に push されている
  - executor: claudecode
  - test_command: `git ls-remote origin feat/m156-pipeline-completeness-audit 2>/dev/null | grep -q 'feat/m156' && echo PASS || echo FAIL`
  - validations:
    - technical: "git push が成功している"
    - consistency: "ローカルとリモートが同期"
    - completeness: "全コミットが push 済み"

- [ ] **p0.2**: feat/m156-pipeline-completeness-audit ブランチが main にマージされている
  - executor: claudecode
  - test_command: `git branch --merged main 2>/dev/null | grep -q 'm156' && echo PASS || echo FAIL`
  - validations:
    - technical: "マージが成功している"
    - consistency: "コンフリクトなし"
    - completeness: "全変更が main に反映"

- [ ] **p0.3**: project.md の M156 status が achieved に更新されている
  - executor: claudecode
  - test_command: `grep -A2 'id: M156' plan/project.md | grep -q 'status: achieved' && echo PASS || echo FAIL`
  - validations:
    - technical: "YAML 構文が正しい"
    - consistency: "実際の完了状態と一致"
    - completeness: "status フィールドが更新済み"

- [ ] **p0.4**: project.md の M156 done_when が全て [x] に更新されている
  - executor: claudecode
  - test_command: `grep -A10 'id: M156' plan/project.md | grep -c '\[x\]' | awk '{if($1>=4) print "PASS"; else print "FAIL"}'`
  - validations:
    - technical: "マークダウン形式が正しい"
    - consistency: "done_when の数と一致"
    - completeness: "4項目全てが [x]"

- [ ] **p0.5**: project.md の M156 achieved_at が設定されている
  - executor: claudecode
  - test_command: `grep -A5 'id: M156' plan/project.md | grep -q 'achieved_at: 2025-12-22' && echo PASS || echo FAIL`
  - validations:
    - technical: "日付形式が正しい"
    - consistency: "本日の日付"
    - completeness: "achieved_at フィールドが存在"

**status**: pending
**max_iterations**: 5

---

### p1: state.md クリーンアップ

**goal**: state.md を安定状態に更新する
**depends_on**: [p0]

#### subtasks

- [ ] **p1.1**: state.md の playbook.active が null に設定されている
  - executor: claudecode
  - test_command: `grep -A2 'playbook:' state.md | grep -q 'active: null' && echo PASS || echo FAIL`
  - validations:
    - technical: "YAML 構文が正しい"
    - consistency: "playbook 完了と一致"
    - completeness: "active フィールドが null"

- [ ] **p1.2**: state.md の goal.milestone が M156 完了を反映している
  - executor: claudecode
  - test_command: `grep -A2 'goal:' state.md | grep -q 'milestone:' && echo PASS || echo FAIL`
  - validations:
    - technical: "YAML 構文が正しい"
    - consistency: "project.md と一致"
    - completeness: "milestone が適切に設定"

- [ ] **p1.3**: state.md の verification.self_complete が true に設定されている
  - executor: claudecode
  - test_command: `grep -A2 'verification:' state.md | grep -q 'self_complete: true' && echo PASS || echo FAIL`
  - validations:
    - technical: "YAML 構文が正しい"
    - consistency: "critic PASS と一致"
    - completeness: "self_complete が true"

**status**: pending
**max_iterations**: 3

---

### p2: 最終確認

**goal**: リポジトリが安定状態であることを確認する
**depends_on**: [p1]

#### subtasks

- [ ] **p2.1**: git status が clean である
  - executor: claudecode
  - test_command: `git status --porcelain | wc -l | awk '{if($1==0) print "PASS"; else print "FAIL"}'`
  - validations:
    - technical: "git コマンドが正常動作"
    - consistency: "全変更がコミット済み"
    - completeness: "未追跡ファイルがない"

- [ ] **p2.2**: main ブランチに切り替わっている
  - executor: claudecode
  - test_command: `git branch --show-current | grep -q 'main' && echo PASS || echo FAIL`
  - validations:
    - technical: "ブランチ切り替えが成功"
    - consistency: "playbook 完了後の標準状態"
    - completeness: "作業ブランチではない"

- [ ] **p2.3**: flow-runtime-test.sh が引き続き PASS している
  - executor: claudecode
  - test_command: `bash scripts/flow-runtime-test.sh 2>&1 | grep -E '^Tests:' | grep -q '25/25' && echo PASS || echo FAIL`
  - validations:
    - technical: "テストが実行可能"
    - consistency: "M156 完了時と同じ結果"
    - completeness: "リグレッションなし"

**status**: pending
**max_iterations**: 3

---

### p_final: 完了検証（必須）

**goal**: playbook の done_when が全て満たされているか最終検証

#### subtasks

- [ ] **p_final.1**: feat/m156-pipeline-completeness-audit ブランチが main にマージされている
  - executor: claudecode
  - test_command: `git log main --oneline | head -5 | grep -q 'm156\|M156' && echo PASS || echo FAIL`
  - validations:
    - technical: "git log が正常動作"
    - consistency: "p0.2 の結果と一致"
    - completeness: "マージコミットが確認可能"

- [ ] **p_final.2**: project.md の M156 が完了状態である
  - executor: claudecode
  - test_command: `grep -A5 'id: M156' plan/project.md | grep -q 'status: achieved' && echo PASS || echo FAIL`
  - validations:
    - technical: "project.md が読み取り可能"
    - consistency: "p0.3-p0.5 の結果と一致"
    - completeness: "status/done_when/achieved_at が全て更新済み"

- [ ] **p_final.3**: state.md が安定状態である
  - executor: claudecode
  - test_command: `grep -q 'active: null' state.md && grep -q 'self_complete: true' state.md && echo PASS || echo FAIL`
  - validations:
    - technical: "state.md が読み取り可能"
    - consistency: "p1 の結果と一致"
    - completeness: "playbook/verification が適切"

- [ ] **p_final.4**: リポジトリが安定状態である
  - executor: claudecode
  - test_command: `git status --porcelain | wc -l | awk '{if($1==0) print "PASS"; else print "FAIL"}'`
  - validations:
    - technical: "git が正常動作"
    - consistency: "p2.1 の結果と一致"
    - completeness: "未コミット変更がない"

**status**: pending
**max_iterations**: 3

---

## final_tasks

- [ ] **ft1**: 変更を全てコミットする
  - command: `git add -A && git status`
  - status: pending

- [ ] **ft2**: main にマージ済みの作業ブランチを削除する
  - command: `git branch -d feat/m156-pipeline-completeness-audit 2>/dev/null || echo "already deleted or not merged"`
  - status: pending

- [ ] **ft3**: 完了メッセージを表示する
  - command: `echo "M156 完了処理が完了しました。プロジェクトは安定状態です。"`
  - status: pending

---

## notes

### 実行順序

```yaml
1. M156 ブランチを push
2. M156 ブランチを main にマージ
3. project.md を更新（M156 achieved）
4. state.md を更新（playbook.active = null）
5. git status clean を確認
6. main ブランチに切り替え
```

### 次ステップ

M156 完了後、project.md に次の milestone がありません。
ユーザーと相談して次のタスクを決定する必要があります。

候補:
- 新機能の追加（ユーザー要望ベース）
- ドキュメント整備
- パフォーマンス改善
- バグ修正（発見されたもの）
