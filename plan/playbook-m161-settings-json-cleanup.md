# playbook-m161-settings-json-cleanup.md

> **settings.json の構造修正と Stop フックへの notify.sh 追加**

---

## meta

```yaml
schema_version: v2
project: thanks4claudecode-v2
branch: feat/m161-settings-json-cleanup
created: 2026-01-12
issue: null
derives_from: null
reviewed: true
roles:
  worker: claudecode

user_prompt_original: |
  ユーザー要求: settings.json の Stop フックに notify.sh を追加し、完了時にデスクトップ通知を送信する

  現状の問題:
  1. PreToolUse[0] 内に誤ってネストされた Stop/Notification 設定がある（無効な構造）
  2. hooks.Stop には stop-summary.sh のみで notify.sh がない

  修正内容:
  1. PreToolUse[0] 内の誤った Stop/Notification ブロック（行 38-59）を削除
  2. hooks.Stop に notify.sh 呼び出しを追加
```

---

## goal

```yaml
summary: settings.json の構造を修正し、Stop フックで notify.sh が正しく呼び出されるようにする
done_when:
  - settings.json が有効な JSON として解析できる
  - PreToolUse[0] 内の誤った Stop/Notification ブロックが削除されている
  - hooks.Stop に notify.sh 呼び出しが追加されている
```

---

## phases

### p1: settings.json の構造修正

**goal**: 誤ってネストされた設定を削除し、Stop フックに notify.sh を追加する

#### subtasks

- [ ] **p1.1**: PreToolUse[0] 内の誤った Stop/Notification ブロック（行 38-59）が削除されている
  - executor: claudecode
  - test_command: `grep -c '"Stop":' .claude/settings.json | awk '{if($1==1) print "PASS"; else print "FAIL"}'`
  - validations:
    - technical: "Stop ブロックが hooks 直下に1つのみ存在する"
    - consistency: "PreToolUse 内に不正なネストがない"
    - completeness: "削除対象のブロックが全て除去されている"

- [ ] **p1.2**: hooks.Stop に notify.sh 呼び出しが追加されている
  - executor: claudecode
  - test_command: `grep -q 'notify.sh' .claude/settings.json && echo PASS || echo FAIL`
  - validations:
    - technical: "notify.sh コマンドが設定に含まれている"
    - consistency: "stop-summary.sh と並行して呼び出される構造になっている"
    - completeness: "notify.sh のパスとコマンド形式が正しい"

- [ ] **p1.3**: settings.json が有効な JSON として解析できる
  - executor: claudecode
  - test_command: `python3 -c "import json; json.load(open('.claude/settings.json'))" && echo PASS || echo FAIL`
  - validations:
    - technical: "JSON パーサーがエラーなく解析できる"
    - consistency: "全てのブラケットとブレースが正しく閉じている"
    - completeness: "必要なフィールドが全て存在する"

**status**: done
**max_iterations**: 5

---

### p_final: 完了検証

**goal**: playbook の done_when が全て満たされているか最終検証

#### subtasks

- [ ] **p_final.1**: settings.json が有効な JSON として解析できる
  - executor: claudecode
  - test_command: `python3 -c "import json; json.load(open('.claude/settings.json'))" && echo PASS || echo FAIL`
  - validations:
    - technical: "JSON が正常にパースできる"
    - consistency: "Claude Code が正常に設定を読み込める"
    - completeness: "全ての必須フィールドが存在する"

- [ ] **p_final.2**: PreToolUse[0] 内の誤った Stop/Notification ブロックが削除されている
  - executor: claudecode
  - test_command: `python3 -c "import json; d=json.load(open('.claude/settings.json')); print('PASS' if 'Stop' not in d['hooks']['PreToolUse'][0] else 'FAIL')"`
  - validations:
    - technical: "PreToolUse[0] に Stop キーが存在しない"
    - consistency: "他の PreToolUse エントリに影響がない"
    - completeness: "不正なネストが全て除去されている"

- [ ] **p_final.3**: hooks.Stop に notify.sh 呼び出しが追加されている
  - executor: claudecode
  - test_command: `python3 -c "import json; d=json.load(open('.claude/settings.json')); hooks=[h['command'] for h in d['hooks']['Stop'][0]['hooks']]; print('PASS' if any('notify.sh' in h for h in hooks) else 'FAIL')"`
  - validations:
    - technical: "notify.sh が Stop フック内のコマンドとして登録されている"
    - consistency: "stop-summary.sh と共存している"
    - completeness: "正しいパスと引数で設定されている"

**status**: done
**max_iterations**: 3

---

## final_tasks

- [x] **ft1**: 変更を全てコミットする
  - command: `git add -A && git status`
  - status: done
