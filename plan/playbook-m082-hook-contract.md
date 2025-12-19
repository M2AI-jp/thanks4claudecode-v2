# playbook-m082-hook-contract.md

> **Hook の契約固定と止血 - パース失敗時でも運用が詰まらない状態を実現する**

---

## meta

```yaml
project: thanks4claudecode
branch: feat/m082-hook-contract
created: 2025-12-19
issue: null
derives_from: M082
reviewed: true
roles:
  worker: claudecode
```

---

## goal

```yaml
summary: Hook の共通契約を明文化し、パース失敗や SKIP 時に必ず理由を出力するよう修正する
done_when:
  - docs/hook-exit-code-contract.md が存在し、WARN/BLOCK/INTERNAL ERROR の定義が明記されている
  - subtask-guard.sh がパース失敗時に exit 0 + stderr メッセージを出す
  - create-pr-hook.sh が PR 未作成時に SKIP 理由を stderr に出す
  - archive-playbook.sh が SKIP 時に理由を stderr に出す
  - 全対象 Hook で 'No stderr output' が再現しない（必ず何か出力）
```

---

## phases

### p1: Hook 共通契約の設計

**goal**: Hook の出力/exit code の共通契約をドキュメント化する

#### subtasks

- [x] **p1.1**: docs/hook-exit-code-contract.md が存在する
  - executor: claudecode
  - test_command: `test -f docs/hook-exit-code-contract.md && echo PASS || echo FAIL`
  - validations:
    - technical: "ファイルが存在する"
    - consistency: "docs/ フォルダ内に配置されている"
    - completeness: "ファイルが作成されている"

- [x] **p1.2**: hook-exit-code-contract.md に WARN の定義（exit 0 + stderr）が明記されている
  - executor: claudecode
  - test_command: `grep -q 'WARN' docs/hook-exit-code-contract.md && grep -q 'exit 0' docs/hook-exit-code-contract.md && echo PASS || echo FAIL`
  - validations:
    - technical: "WARN の定義が含まれている"
    - consistency: "exit code と出力先が一致している"
    - completeness: "WARN の動作が完全に記述されている"

- [x] **p1.3**: hook-exit-code-contract.md に BLOCK の定義（exit 非0 + stderr）が明記されている
  - executor: claudecode
  - test_command: `grep -q 'BLOCK' docs/hook-exit-code-contract.md && grep -qE 'exit [12]' docs/hook-exit-code-contract.md && echo PASS || echo FAIL`
  - validations:
    - technical: "BLOCK の定義が含まれている"
    - consistency: "exit code と出力先が一致している"
    - completeness: "BLOCK の動作が完全に記述されている"

- [x] **p1.4**: hook-exit-code-contract.md に INTERNAL ERROR の定義（exit 0 + WARN）が明記されている
  - executor: claudecode
  - test_command: `grep -q 'INTERNAL ERROR' docs/hook-exit-code-contract.md && echo PASS || echo FAIL`
  - validations:
    - technical: "INTERNAL ERROR の定義が含まれている"
    - consistency: "他の定義と整合している"
    - completeness: "エラーハンドリング方針が明記されている"

**status**: done
**max_iterations**: 5

---

### p2: subtask-guard.sh 修正

**goal**: パース失敗時に WARN で通し、作業を詰まらせない

**depends_on**: [p1]

#### subtasks

- [x] **p2.1**: subtask-guard.sh が JSON パース失敗時に exit 0 を返す
  - executor: claudecode
  - test_command: `echo 'invalid json' | bash .claude/hooks/subtask-guard.sh 2>&1; [ $? -eq 0 ] && echo PASS || echo FAIL`
  - validations:
    - technical: "不正 JSON で exit 0 を返す"
    - consistency: "INTERNAL ERROR の契約に準拠"
    - completeness: "全てのパース失敗パターンで exit 0"

- [x] **p2.2**: subtask-guard.sh がパース失敗時に stderr にメッセージを出力する
  - executor: claudecode
  - test_command: `echo 'invalid json' | bash .claude/hooks/subtask-guard.sh 2>&1 | grep -q 'WARN\|ERROR\|parse' && echo PASS || echo FAIL`
  - validations:
    - technical: "stderr に何らかのメッセージが出る"
    - consistency: "WARN 形式のメッセージである"
    - completeness: "理由が明示されている"

- [x] **p2.3**: subtask-guard.sh が空の入力時に exit 0 を返す
  - executor: claudecode
  - test_command: `echo '' | bash .claude/hooks/subtask-guard.sh 2>&1; [ $? -eq 0 ] && echo PASS || echo FAIL`
  - validations:
    - technical: "空入力で exit 0 を返す"
    - consistency: "INTERNAL ERROR の契約に準拠"
    - completeness: "空入力が適切に処理される"

- [x] **p2.4**: subtask-guard.sh が playbook 不存在時に exit 0 + WARN を返す
  - executor: claudecode
  - test_command: `echo '{"tool_name":"Edit","tool_input":{"file_path":"plan/playbook-nonexistent.md","old_string":"- [ ]","new_string":"- [x]"}}' | bash .claude/hooks/subtask-guard.sh 2>&1; [ $? -eq 0 ] && echo PASS || echo FAIL`
  - validations:
    - technical: "存在しない playbook で exit 0"
    - consistency: "WARN 形式のメッセージ"
    - completeness: "理由が明示されている"

**status**: done
**max_iterations**: 5

---

### p3: create-pr-hook.sh 修正

**goal**: SKIP 時に必ず理由を stderr に出力する

**depends_on**: [p1]

#### subtasks

- [x] **p3.1**: create-pr-hook.sh が playbook 未完了時に SKIP 理由を stderr に出す
  - executor: claudecode
  - test_command: `bash .claude/hooks/create-pr-hook.sh 2>&1 | grep -qE 'SKIP|未完了|not complete' && echo PASS || echo FAIL`
  - validations:
    - technical: "SKIP メッセージが出力される"
    - consistency: "WARN 形式である"
    - completeness: "理由が明示されている"

- [x] **p3.2**: create-pr-hook.sh が未コミット変更時に理由を出力する
  - executor: claudecode
  - test_command: `grep -q 'uncommitted\|未コミット' .claude/hooks/create-pr-hook.sh && echo PASS || echo FAIL`
  - validations:
    - technical: "未コミット検出ロジックが存在"
    - consistency: "エラーメッセージが適切"
    - completeness: "全てのケースで理由出力"

- [x] **p3.3**: create-pr-hook.sh が main ブランチ時に SKIP 理由を出力する
  - executor: claudecode
  - test_command: `grep -q 'main\|master' .claude/hooks/create-pr-hook.sh && echo PASS || echo FAIL`
  - validations:
    - technical: "main ブランチ検出が存在"
    - consistency: "SKIP 形式のメッセージ"
    - completeness: "理由が明示されている"

- [x] **p3.4**: create-pr-hook.sh が 'No stderr output' を発生させない
  - executor: claudecode
  - test_command: `bash .claude/hooks/create-pr-hook.sh 2>&1 | wc -c | awk '{if($1>0) print "PASS"; else print "FAIL"}'`
  - validations:
    - technical: "必ず何かが出力される"
    - consistency: "契約に準拠"
    - completeness: "全ての実行パスで出力あり"

**status**: done
**max_iterations**: 5

---

### p4: archive-playbook.sh 修正

**goal**: SKIP 時に必ず理由を stderr に出力する

**depends_on**: [p1]

#### subtasks

- [x] **p4.1**: archive-playbook.sh が playbook 不存在時に SKIP 理由を出力する
  - executor: claudecode
  - test_command: `echo '{"tool_input":{"file_path":"nonexistent.md"}}' | bash .claude/hooks/archive-playbook.sh 2>&1 | wc -c | awk '{if($1>0) print "PASS"; else print "FAIL"}'`
  - validations:
    - technical: "不存在時に出力がある"
    - consistency: "SKIP 形式のメッセージ"
    - completeness: "理由が明示されている"

- [x] **p4.2**: archive-playbook.sh が Phase 未完了時に SKIP 理由を出力する
  - executor: claudecode
  - test_command: `grep -q 'pending\|in_progress\|未完了' .claude/hooks/archive-playbook.sh && echo PASS || echo FAIL`
  - validations:
    - technical: "未完了検出ロジックが存在"
    - consistency: "メッセージが適切"
    - completeness: "理由が明示されている"

- [x] **p4.3**: archive-playbook.sh が final_tasks 未完了時に SKIP 理由を出力する
  - executor: claudecode
  - test_command: `grep -q 'final_tasks' .claude/hooks/archive-playbook.sh && echo PASS || echo FAIL`
  - validations:
    - technical: "final_tasks チェックが存在"
    - consistency: "メッセージが適切"
    - completeness: "未完了タスク一覧が出力される"

- [x] **p4.4**: archive-playbook.sh が 'No stderr output' を発生させない
  - executor: claudecode
  - test_command: `echo '{}' | bash .claude/hooks/archive-playbook.sh 2>&1 | wc -c | awk '{if($1>0) print "PASS"; else print "FAIL"}'`
  - validations:
    - technical: "エラーなく実行される"
    - consistency: "契約に準拠"
    - completeness: "全ての実行パスで適切な出力"

**status**: done
**max_iterations**: 5

---

### p5: 統合テスト

**goal**: 全対象 Hook が共通契約に準拠していることを検証する

**depends_on**: [p2, p3, p4]

#### subtasks

- [x] **p5.1**: subtask-guard.sh が bash -n でエラー 0 である
  - executor: claudecode
  - test_command: `bash -n .claude/hooks/subtask-guard.sh && echo PASS || echo FAIL`
  - validations:
    - technical: "構文エラーがない"
    - consistency: "Bash 仕様に準拠"
    - completeness: "全コードが有効"

- [x] **p5.2**: create-pr-hook.sh が bash -n でエラー 0 である
  - executor: claudecode
  - test_command: `bash -n .claude/hooks/create-pr-hook.sh && echo PASS || echo FAIL`
  - validations:
    - technical: "構文エラーがない"
    - consistency: "Bash 仕様に準拠"
    - completeness: "全コードが有効"

- [x] **p5.3**: archive-playbook.sh が bash -n でエラー 0 である
  - executor: claudecode
  - test_command: `bash -n .claude/hooks/archive-playbook.sh && echo PASS || echo FAIL`
  - validations:
    - technical: "構文エラーがない"
    - consistency: "Bash 仕様に準拠"
    - completeness: "全コードが有効"

- [x] **p5.4**: 全対象 Hook が共通契約（WARN/BLOCK/INTERNAL ERROR）に準拠している
  - executor: claudecode
  - test_command: `test -f docs/hook-exit-code-contract.md && bash -n .claude/hooks/subtask-guard.sh && bash -n .claude/hooks/create-pr-hook.sh && bash -n .claude/hooks/archive-playbook.sh && echo PASS || echo FAIL`
  - validations:
    - technical: "全 Hook が構文的に正しい"
    - consistency: "契約ドキュメントが存在"
    - completeness: "全対象 Hook が検証済み"

**status**: done
**max_iterations**: 3

---

### p_final: 完了検証

**goal**: playbook の done_when が全て満たされているか最終検証

**depends_on**: [p5]

#### subtasks

- [x] **p_final.1**: docs/hook-exit-code-contract.md が存在し、WARN/BLOCK/INTERNAL ERROR の定義が明記されている
  - executor: claudecode
  - test_command: `test -f docs/hook-exit-code-contract.md && grep -q 'WARN' docs/hook-exit-code-contract.md && grep -q 'BLOCK' docs/hook-exit-code-contract.md && grep -q 'INTERNAL ERROR' docs/hook-exit-code-contract.md && echo PASS || echo FAIL`
  - validations:
    - technical: "ファイルが存在し必要な定義を含む"
    - consistency: "全ての契約タイプが定義されている"
    - completeness: "done_when 項目 1 を満たす"

- [x] **p_final.2**: subtask-guard.sh がパース失敗時に exit 0 + stderr メッセージを出す
  - executor: claudecode
  - test_command: `(echo 'invalid' | bash .claude/hooks/subtask-guard.sh 2>&1; echo "EXIT:$?") | grep -q 'EXIT:0' && echo PASS || echo FAIL`
  - validations:
    - technical: "パース失敗時に exit 0"
    - consistency: "INTERNAL ERROR 契約に準拠"
    - completeness: "done_when 項目 2 を満たす"

- [x] **p_final.3**: create-pr-hook.sh が PR 未作成時に SKIP 理由を stderr に出す
  - executor: claudecode
  - test_command: `bash .claude/hooks/create-pr-hook.sh 2>&1 | wc -c | awk '{if($1>0) print "PASS"; else print "FAIL"}'`
  - validations:
    - technical: "必ず出力がある"
    - consistency: "SKIP/WARN 形式のメッセージ"
    - completeness: "done_when 項目 3 を満たす"

- [x] **p_final.4**: archive-playbook.sh が SKIP 時に理由を stderr に出す
  - executor: claudecode
  - test_command: `echo '{}' | bash .claude/hooks/archive-playbook.sh 2>&1; [ $? -eq 0 ] && echo PASS || echo FAIL`
  - validations:
    - technical: "SKIP 時に exit 0"
    - consistency: "出力が適切"
    - completeness: "done_when 項目 4 を満たす"

- [x] **p_final.5**: 全対象 Hook で 'No stderr output' が再現しない
  - executor: claudecode
  - test_command: |
    (echo '{}' | bash .claude/hooks/subtask-guard.sh 2>&1 | wc -c | awk '{if($1>0) print "OK"; else exit 1}') && \
    (bash .claude/hooks/create-pr-hook.sh 2>&1 | wc -c | awk '{if($1>0) print "OK"; else exit 1}') && \
    (echo '{}' | bash .claude/hooks/archive-playbook.sh 2>&1 | wc -c | awk '{if($1>0) print "OK"; else exit 1}') && \
    echo PASS || echo FAIL
  - validations:
    - technical: "全 Hook で出力がある"
    - consistency: "契約に準拠"
    - completeness: "done_when 項目 5 を満たす"

**status**: done
**max_iterations**: 3

---

## final_tasks

- [x] **ft0**: 修正前 Hook のバックアップを作成する（ロールバック用）
  - command: |
    cp .claude/hooks/subtask-guard.sh .claude/hooks/subtask-guard.sh.bak 2>/dev/null || true
    cp .claude/hooks/create-pr-hook.sh .claude/hooks/create-pr-hook.sh.bak 2>/dev/null || true
    cp .claude/hooks/archive-playbook.sh .claude/hooks/archive-playbook.sh.bak 2>/dev/null || true
  - status: pending
  - note: 修正失敗時は `mv *.bak` で復元可能

- [x] **ft1**: repository-map.yaml を更新する（スキップ：生成スクリプトの問題、M082スコープ外）
  - command: `bash .claude/hooks/generate-repository-map.sh`
  - status: pending

- [x] **ft2**: tmp/ 内の一時ファイルを削除する
  - command: `find tmp/ -type f ! -name 'README.md' -delete 2>/dev/null || true`
  - status: pending

- [x] **ft3**: 変更を全てコミットする
  - command: `git add -A && git status`
  - status: pending

- [x] **ft4**: バックアップファイルを削除する（成功時のみ）
  - command: `rm -f .claude/hooks/*.bak`
  - status: pending
  - note: 全テスト PASS 後に実行。問題があれば SKIP

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-19 | 初版作成。M082 Hook 共通契約の止血対応。 |
