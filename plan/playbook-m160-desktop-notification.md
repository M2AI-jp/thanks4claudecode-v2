# playbook-m160-desktop-notification.md

> **Claude Code が停止してユーザー入力を待つ際にデスクトップ通知を送る**

---

## meta

```yaml
schema_version: v2
project: thanks4claudecode-v2
branch: feat/m160-desktop-notification
created: 2026-01-12
issue: null
derives_from: null  # project.md に該当なし（新規機能）
reviewed: true  # pm 自己レビュー完了

user_prompt_original: |
  毎回停止して私に指示を仰ぐ際にデスクトップ通知を送る
  これは AskUserQuestion ツールが呼ばれた際に macOS のデスクトップ通知を送る機能の実装です。
```

---

## goal

```yaml
summary: Claude Code が Stop イベントで停止する際に macOS デスクトップ通知を送信する
done_when:
  - "~/.claude/notify.sh が存在し、実行可能である"
  - "notify.sh を実行すると macOS デスクトップ通知が表示される"
  - "settings.json の Stop フックで notify.sh が呼び出される設定になっている"
```

---

## phases

### p1: notify.sh の作成

**goal**: macOS デスクトップ通知を送信するスクリプトを作成する

#### subtasks

- [ ] **p1.1**: ~/.claude/notify.sh が存在する
  - executor: claudecode
  - test_command: `test -f ~/.claude/notify.sh && echo PASS || echo FAIL`
  - validations:
    - technical: "ファイルが指定パスに存在する"
    - consistency: "settings.json で参照されているパスと一致"
    - completeness: "スクリプトの中身が空でない"

- [ ] **p1.2**: notify.sh が実行可能権限を持つ
  - executor: claudecode
  - test_command: `test -x ~/.claude/notify.sh && echo PASS || echo FAIL`
  - validations:
    - technical: "chmod +x が適用されている"
    - consistency: "Bash から直接実行可能"
    - completeness: "権限設定が完了している"

- [ ] **p1.3**: notify.sh を実行すると macOS 通知が表示される
  - executor: user
  - test_command: `手動確認: ~/.claude/notify.sh を実行してデスクトップ通知が表示されることを確認`
  - validations:
    - technical: "osascript コマンドが正常に動作する"
    - consistency: "通知のタイトルと本文が適切"
    - completeness: "エラーなく通知が表示される"

**status**: pending
**max_iterations**: 5

---

### p2: settings.json の修正

**goal**: Stop フックで notify.sh が正しく呼び出される設定に修正する

**depends_on**: [p1]

**risk_mitigation**: settings.json 編集前にバックアップを取る。問題があれば `git checkout .claude/settings.json` でロールバック可能。

#### subtasks

- [ ] **p2.1**: PreToolUse 内の不正な Stop/Notification ネストが削除されている
  - executor: claudecode
  - test_command: `jq '.hooks.PreToolUse[0] | has("Stop")' .claude/settings.json | grep -q 'false' && echo PASS || echo FAIL`
  - validations:
    - technical: "JSON 構文が正しい"
    - consistency: "PreToolUse は matcher と hooks のみを持つ"
    - completeness: "不正なネストが全て削除されている"

- [ ] **p2.2**: hooks.Stop に notify.sh の呼び出しが追加されている
  - executor: claudecode
  - test_command: `jq '.hooks.Stop[].hooks[].command' .claude/settings.json | grep -q 'notify.sh' && echo PASS || echo FAIL`
  - validations:
    - technical: "jq でパース可能な正しい JSON 構造"
    - consistency: "既存の stop-summary.sh と共存している"
    - completeness: "notify.sh が Stop イベントで発火する設定になっている"

**status**: pending
**max_iterations**: 5

---

### p3: 動作確認

**goal**: 実際に Claude Code が停止する際に通知が送信されることを確認する

**depends_on**: [p1, p2]

#### subtasks

- [ ] **p3.1**: Claude Code セッションで Stop イベント発生時に通知が表示される
  - executor: user
  - test_command: `手動確認: Claude Code で質問に回答し、停止時にデスクトップ通知が表示されることを確認`
  - validations:
    - technical: "Stop Hook が正常に発火する"
    - consistency: "通知内容がコンテキストを反映している"
    - completeness: "ユーザーが離席中でも気づける"

**status**: pending
**max_iterations**: 3

---

### p_final: 完了検証

**goal**: done_when の全項目が満たされていることを検証する

**depends_on**: [p1, p2, p3]

#### subtasks

- [ ] **p_final.1**: ~/.claude/notify.sh が存在し、実行可能である
  - executor: claudecode
  - test_command: `test -f ~/.claude/notify.sh && test -x ~/.claude/notify.sh && echo PASS || echo FAIL`
  - validations:
    - technical: "ファイル存在と実行権限の両方を確認"
    - consistency: "p1 の結果と一致"
    - completeness: "done_when の項目1を完全にカバー"

- [ ] **p_final.2**: notify.sh を実行すると macOS デスクトップ通知が表示される
  - executor: user
  - test_command: `手動確認: ~/.claude/notify.sh を実行して通知が表示されることを確認`
  - validations:
    - technical: "osascript が正常動作"
    - consistency: "p1.3 の結果と一致"
    - completeness: "done_when の項目2を完全にカバー"

- [ ] **p_final.3**: settings.json の Stop フックで notify.sh が呼び出される設定になっている
  - executor: claudecode
  - test_command: `jq '.hooks.Stop[].hooks[].command' .claude/settings.json | grep -q 'notify.sh' && echo PASS || echo FAIL`
  - validations:
    - technical: "jq クエリが成功する"
    - consistency: "p2 の結果と一致"
    - completeness: "done_when の項目3を完全にカバー"

**status**: pending
**max_iterations**: 3

---

## final_tasks

- [ ] **ft1**: 変更を全てコミットする
  - command: `git add -A && git status`
  - status: pending

- [ ] **ft2**: state.md を更新する
  - command: `手動確認: playbook.active を null に設定`
  - status: pending

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2026-01-12 | 初版作成 |
