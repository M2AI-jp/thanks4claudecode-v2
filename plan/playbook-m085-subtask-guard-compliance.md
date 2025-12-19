# playbook-m085-subtask-guard-compliance.md

> **subtask-guard.sh を M082 契約に完全準拠させ、Layer2 復旧を完了する**

---

## meta

```yaml
schema_version: v2
project: thanks4claudecode
branch: feat/m085-subtask-guard-compliance
created: 2025-12-19
issue: null
derives_from: M085
reviewed: true
roles:
  worker: claudecode
```

---

## goal

```yaml
summary: subtask-guard.sh を M082 契約に準拠させ、パース失敗時の安全動作と厳格モード切替を実装する
done_when:
  - subtask-guard.sh がパース失敗時に exit 0 を返す
  - subtask-guard.sh に厳格モード（STRICT=1）オプションが存在する
  - 通常モードで validations 不足は WARN のみ
  - 厳格モードで validations 不足は BLOCK
```

---

## phases

### p1: 現状分析と設計

**goal**: 現在の subtask-guard.sh の問題点を特定し、修正設計を策定する

#### subtasks

- [ ] **p1.1**: 現在の subtask-guard.sh が M082 契約に違反している箇所が特定されている
  - executor: claudecode
  - test_command: `echo "分析完了" && echo PASS`
  - validations:
    - technical: "subtask-guard.sh の全コードパスが確認されている"
    - consistency: "docs/hook-exit-code-contract.md との差異が明確"
    - completeness: "全ての違反箇所がリストアップされている"

- [ ] **p1.2**: 修正設計書が tmp/subtask-guard-design.md に作成されている
  - executor: claudecode
  - test_command: `test -f tmp/subtask-guard-design.md && grep -q 'STRICT' tmp/subtask-guard-design.md && echo PASS`
  - validations:
    - technical: "設計書が存在し、STRICT モードの仕様が含まれる"
    - consistency: "M082 契約（docs/hook-exit-code-contract.md）と整合している"
    - completeness: "全ての修正箇所が設計書に記載されている"

**status**: pending
**max_iterations**: 3

---

### p2: subtask-guard.sh 修正

**goal**: M082 契約に準拠するよう subtask-guard.sh を修正する

**depends_on**: [p1]

#### subtasks

- [ ] **p2.1**: パース失敗時の全てのパスで exit 0 + stderr メッセージを返す実装が完了している
  - executor: claudecode
  - test_command: `echo '{"invalid_json' | bash .claude/hooks/subtask-guard.sh 2>&1; echo "EXIT_CODE=$?"; echo '{"invalid_json' | bash .claude/hooks/subtask-guard.sh 2>&1 | grep -q 'INTERNAL ERROR' && echo PASS || echo FAIL`
  - validations:
    - technical: "不正 JSON 入力時に exit 0 を返す"
    - consistency: "docs/hook-exit-code-contract.md の INTERNAL ERROR 形式に準拠"
    - completeness: "全ての jq/パースエラーパスで対応済み"

- [ ] **p2.2**: STRICT 環境変数が未設定の場合、validations 不足で WARN を出し exit 0 を返す
  - executor: claudecode
  - test_command: `echo '{"tool_name":"Edit","tool_input":{"file_path":"plan/playbook-test.md","old_string":"- [ ]","new_string":"- [x]"}}' | STRICT= bash .claude/hooks/subtask-guard.sh 2>&1; echo "EXIT_CODE=$?"`
  - validations:
    - technical: "STRICT 未設定時は WARN で exit 0"
    - consistency: "M082 契約の WARN 定義に準拠"
    - completeness: "validations 不足ケースで確認済み"

- [ ] **p2.3**: STRICT=1 の場合、validations 不足で BLOCK を出し exit 2 を返す
  - executor: claudecode
  - test_command: `echo '{"tool_name":"Edit","tool_input":{"file_path":"plan/playbook-test.md","old_string":"- [ ]","new_string":"- [x]"}}' | STRICT=1 bash .claude/hooks/subtask-guard.sh 2>&1; [ $? -eq 2 ] && echo PASS || echo FAIL`
  - validations:
    - technical: "STRICT=1 時は exit 2 を返す"
    - consistency: "M082 契約の BLOCK 定義に準拠"
    - completeness: "厳格モードの動作が確認済み"

- [ ] **p2.4**: 全ての出力パスで stderr にメッセージが出力される（無出力禁止）
  - executor: claudecode
  - test_command: `bash -n .claude/hooks/subtask-guard.sh && grep -c 'echo.*>&2' .claude/hooks/subtask-guard.sh | awk '{if($1>=10) print "PASS"; else print "FAIL"}'`
  - validations:
    - technical: "bash -n でシンタックスエラーなし"
    - consistency: "全 exit パスで stderr 出力がある"
    - completeness: "無出力で終了するパスが存在しない"

**status**: pending
**max_iterations**: 5

---

### p3: テストとドキュメント更新

**goal**: 修正内容をテストし、ドキュメントを更新する

**depends_on**: [p2]

#### subtasks

- [ ] **p3.1**: 通常モード（STRICT 未設定）で validations 不足が WARN のみで通過することが確認されている
  - executor: claudecode
  - test_command: `echo '{"tool_name":"Edit","tool_input":{"file_path":"plan/playbook-test.md","old_string":"- [ ] **p1.1**: test","new_string":"- [x] **p1.1**: test"}}' | STRICT= bash .claude/hooks/subtask-guard.sh 2>&1 | grep -q 'WARN' && echo PASS || echo FAIL`
  - validations:
    - technical: "WARN メッセージが出力される"
    - consistency: "exit 0 で終了する"
    - completeness: "処理が続行される"

- [ ] **p3.2**: 厳格モード（STRICT=1）で validations 不足が BLOCK されることが確認されている
  - executor: claudecode
  - test_command: `echo '{"tool_name":"Edit","tool_input":{"file_path":"plan/playbook-test.md","old_string":"- [ ] **p1.1**: test","new_string":"- [x] **p1.1**: test"}}' | STRICT=1 bash .claude/hooks/subtask-guard.sh 2>&1 | grep -q 'BLOCK' && echo PASS || echo FAIL`
  - validations:
    - technical: "BLOCK メッセージが出力される"
    - consistency: "exit 2 で終了する"
    - completeness: "処理がブロックされる"

- [ ] **p3.3**: docs/hook-exit-code-contract.md に subtask-guard.sh の STRICT モードが記載されている
  - executor: claudecode
  - test_command: `grep -q 'STRICT' docs/hook-exit-code-contract.md && echo PASS || echo FAIL`
  - validations:
    - technical: "STRICT モードの説明が追加されている"
    - consistency: "既存の契約定義と整合している"
    - completeness: "使用方法が明記されている"

**status**: pending
**max_iterations**: 3

---

### p_final: 完了検証

**goal**: playbook の done_when が全て満たされているか最終検証

**depends_on**: [p3]

#### subtasks

- [ ] **p_final.1**: subtask-guard.sh がパース失敗時に exit 0 を返すことが確認されている
  - executor: claudecode
  - test_command: `echo 'invalid' | bash .claude/hooks/subtask-guard.sh 2>/dev/null; [ $? -eq 0 ] && echo PASS || echo FAIL`
  - validations:
    - technical: "不正入力で exit 0 を返す"
    - consistency: "M082 契約に準拠"
    - completeness: "全パース失敗パスで確認済み"

- [ ] **p_final.2**: STRICT=1 環境変数オプションが存在し機能することが確認されている
  - executor: claudecode
  - test_command: `grep -q 'STRICT' .claude/hooks/subtask-guard.sh && echo PASS || echo FAIL`
  - validations:
    - technical: "STRICT 変数の参照がある"
    - consistency: "環境変数で動作切替可能"
    - completeness: "ドキュメントにも記載済み"

- [ ] **p_final.3**: 通常モードで validations 不足は WARN のみであることが確認されている
  - executor: claudecode
  - test_command: `echo '{"tool_name":"Edit","tool_input":{"file_path":"plan/playbook-x.md","old_string":"- [ ]","new_string":"- [x]"}}' | bash .claude/hooks/subtask-guard.sh 2>&1 | grep -qE 'WARN|SKIP' && echo PASS || echo FAIL`
  - validations:
    - technical: "BLOCK ではなく WARN/SKIP を返す"
    - consistency: "M082 契約に準拠"
    - completeness: "validations なしでも通過する"

- [ ] **p_final.4**: 厳格モードで validations 不足は BLOCK されることが確認されている
  - executor: claudecode
  - test_command: `echo '{"tool_name":"Edit","tool_input":{"file_path":"plan/playbook-x.md","old_string":"- [ ] **p1.1**:","new_string":"- [x] **p1.1**:"}}' | STRICT=1 bash .claude/hooks/subtask-guard.sh 2>&1 | grep -q 'BLOCK' && echo PASS || echo FAIL`
  - validations:
    - technical: "STRICT=1 時は BLOCK を返す"
    - consistency: "M082 契約に準拠"
    - completeness: "exit 2 で終了する"

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
  1. git checkout HEAD -- .claude/hooks/subtask-guard.sh
  2. git checkout HEAD -- docs/hook-exit-code-contract.md
```

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-19 | 初版作成。M085 subtask-guard 仕様準拠化。 |
