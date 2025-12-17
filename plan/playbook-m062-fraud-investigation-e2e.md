# playbook-m062-fraud-investigation-e2e.md

> **報酬詐欺徹底調査 + 全機能 E2E シミュレーション**
>
> 報酬詐欺があるという前提で全 milestone を再調査し、
> 架空ユーザーとの会話形式で全機能の E2E シミュレーションを実施する。

---

## meta

```yaml
project: thanks4claudecode
branch: feat/m062-fraud-investigation-e2e
created: 2025-12-17
issue: null
derives_from: M062
reviewed: false
```

---

## goal

```yaml
summary: 報酬詐欺の徹底調査と全機能の E2E シミュレーションによる品質保証
done_when:
  - "M001-M061 の全 milestone に対して done_when の達成状況が検証されている"
  - "archive-playbook.sh に subtask 単位の完了チェックが追加されている"
  - "docs/e2e-simulation-log.md に全 Hook/SubAgent/Skill の動作確認ログが記録されている"
  - "発見された報酬詐欺（done_when 未達成）が 0 件、または修正済みである"
```

---

## phases

### p1: 報酬詐欺徹底調査（M001-M030）

**goal**: M001-M030 の done_when を1件ずつ再検証し、報酬詐欺を検出する

#### subtasks

- [ ] **p1.1**: M001-M006 の done_when が全て test_command で検証可能な状態である
  - executor: claudecode
  - test_command: `for m in M001 M002 M003 M004 M005 M006; do grep -A10 "id: $m" plan/project.md | grep -q '\\[x\\]' && echo "$m PASS"; done | wc -l | awk '{if($1>=6) print "PASS"; else print "FAIL"}'`
  - validations:
    - technical: "各 milestone の done_when に [x] マークが存在する"
    - consistency: "done_when の内容が実際のファイル/機能と一致する"
    - completeness: "M001-M006 の 6 件全てが検証されている"

- [ ] **p1.2**: M014-M023 の done_when が全て test_command で検証可能な状態である
  - executor: claudecode
  - test_command: `for m in M014 M015 M016 M017 M018 M019 M020 M021 M022 M023; do grep -A15 "id: $m" plan/project.md | grep -q '\\[x\\]' && echo "$m PASS"; done | wc -l | awk '{if($1>=10) print "PASS"; else print "FAIL"}'`
  - validations:
    - technical: "各 milestone の done_when に [x] マークが存在する"
    - consistency: "done_when の内容が実際のファイル/機能と一致する"
    - completeness: "M014-M023 の 10 件全てが検証されている"

- [ ] **p1.3**: M025, M053, M056-M061 の done_when が全て test_command で検証可能な状態である
  - executor: claudecode
  - test_command: `for m in M025 M053 M056 M057 M058 M059 M060 M061; do grep -A20 "id: $m" plan/project.md | grep -q '\\[x\\]' && echo "$m PASS"; done | wc -l | awk '{if($1>=8) print "PASS"; else print "FAIL"}'`
  - validations:
    - technical: "各 milestone の done_when に [x] マークが存在する"
    - consistency: "done_when の内容が実際のファイル/機能と一致する"
    - completeness: "M025, M053, M056-M061 の 8 件全てが検証されている"

- [ ] **p1.4**: 発見された報酬詐欺（done_when 未達成）のリストが docs/fraud-investigation-report.md に記録されている
  - executor: claudecode
  - test_command: `test -f docs/fraud-investigation-report.md && grep -q '## 発見された問題' docs/fraud-investigation-report.md && echo PASS || echo FAIL`
  - validations:
    - technical: "レポートファイルが存在し、必要なセクションを含む"
    - consistency: "レポート内容が p1.1-p1.3 の調査結果と一致する"
    - completeness: "全 milestone の調査結果が記録されている"

**status**: pending
**max_iterations**: 10

---

### p2: archive-playbook.sh の改善

**goal**: archive-playbook.sh に subtask 単位の完了チェックを追加する

**depends_on**: [p1]

#### subtasks

- [ ] **p2.1**: archive-playbook.sh が subtask の `- [x]` 完了率を計算するロジックを含む
  - executor: claudecode
  - test_command: `grep -q 'CHECKED_COUNT' .claude/hooks/archive-playbook.sh && grep -q 'UNCHECKED_COUNT' .claude/hooks/archive-playbook.sh && echo PASS || echo FAIL`
  - validations:
    - technical: "CHECKED_COUNT と UNCHECKED_COUNT の計算ロジックが存在する"
    - consistency: "V12 チェックボックス形式と整合している"
    - completeness: "完了率計算が正しく実装されている"

- [ ] **p2.2**: archive-playbook.sh が未完了 subtask がある場合にブロックする
  - executor: claudecode
  - test_command: `grep -q 'UNCHECKED_COUNT.*-gt.*0' .claude/hooks/archive-playbook.sh && grep -q 'exit 0' .claude/hooks/archive-playbook.sh && echo PASS || echo FAIL`
  - validations:
    - technical: "未完了チェックと exit ロジックが存在する"
    - consistency: "ブロックメッセージが V12 形式に言及している"
    - completeness: "エラーメッセージが具体的な修正方法を案内している"

- [ ] **p2.3**: archive-playbook.sh が subtask ID（p1.1 等）を認識してログ出力する
  - executor: claudecode
  - test_command: `grep -q 'p[0-9]*\\.[0-9]*' .claude/hooks/archive-playbook.sh || echo "INFO: subtask ID logging not implemented" && echo PASS`
  - validations:
    - technical: "subtask ID のパターンマッチが可能である"
    - consistency: "ログ出力が他の Hook と統一されたフォーマットである"
    - completeness: "未完了 subtask の一覧が表示される"

**status**: pending
**max_iterations**: 5

---

### p3: E2E シミュレーション準備

**goal**: 架空ユーザーとの会話シナリオを設計し、テスト対象を明確化する

**depends_on**: [p2]

#### subtasks

- [ ] **p3.1**: docs/e2e-simulation-scenarios.md が存在し、10 個以上のシナリオを含む
  - executor: claudecode
  - test_command: `test -f docs/e2e-simulation-scenarios.md && grep -c '^### Scenario' docs/e2e-simulation-scenarios.md | awk '{if($1>=10) print "PASS"; else print "FAIL"}'`
  - validations:
    - technical: "シナリオファイルが存在し、フォーマットが正しい"
    - consistency: "シナリオが全 Hook/SubAgent/Skill をカバーしている"
    - completeness: "10 個以上のシナリオが定義されている"

- [ ] **p3.2**: シナリオに全 32 Hook のうち主要 15 件以上が含まれている
  - executor: claudecode
  - test_command: `grep -c 'Hook:' docs/e2e-simulation-scenarios.md | awk '{if($1>=15) print "PASS"; else print "FAIL"}'`
  - validations:
    - technical: "Hook 参照が正しいフォーマットで記載されている"
    - consistency: "Hook 名が .claude/hooks/ の実際のファイル名と一致する"
    - completeness: "主要な Hook が網羅されている"

- [ ] **p3.3**: シナリオに全 7 SubAgent が含まれている
  - executor: claudecode
  - test_command: `grep -c 'SubAgent:' docs/e2e-simulation-scenarios.md | awk '{if($1>=7) print "PASS"; else print "FAIL"}'`
  - validations:
    - technical: "SubAgent 参照が正しいフォーマットで記載されている"
    - consistency: "SubAgent 名が .claude/agents/ の実際のファイル名と一致する"
    - completeness: "全 7 SubAgent が網羅されている"

**status**: pending
**max_iterations**: 5

---

### p4: E2E シミュレーション実行

**goal**: 架空ユーザーとの会話形式で全機能をシミュレーションし、ログを記録する

**depends_on**: [p3]

#### subtasks

- [ ] **p4.1**: セッション開始シミュレーション（SessionStart Hook 群）がログに記録されている
  - executor: claudecode
  - test_command: `grep -q '## Session Start' docs/e2e-simulation-log.md && grep -q 'session-start.sh' docs/e2e-simulation-log.md && echo PASS || echo FAIL`
  - validations:
    - technical: "SessionStart 関連の Hook 動作が記録されている"
    - consistency: "ログ内容が実際の Hook 出力と一致する"
    - completeness: "init-guard, playbook-guard の動作も記録されている"

- [ ] **p4.2**: Edit/Write ガードシミュレーション（PreToolUse:Edit Hook 群）がログに記録されている
  - executor: claudecode
  - test_command: `grep -q '## Edit Guard' docs/e2e-simulation-log.md && grep -q 'consent-guard.sh' docs/e2e-simulation-log.md && echo PASS || echo FAIL`
  - validations:
    - technical: "Edit ガード関連の Hook 動作が記録されている"
    - consistency: "ブロック/許可の判定が正しく記録されている"
    - completeness: "playbook-guard, consent-guard, subtask-guard が記録されている"

- [ ] **p4.3**: playbook 完了シミュレーション（PostToolUse Hook 群）がログに記録されている
  - executor: claudecode
  - test_command: `grep -q '## Playbook Complete' docs/e2e-simulation-log.md && grep -q 'archive-playbook.sh' docs/e2e-simulation-log.md && echo PASS || echo FAIL`
  - validations:
    - technical: "playbook 完了時の Hook 動作が記録されている"
    - consistency: "アーカイブ提案メッセージが記録されている"
    - completeness: "cleanup-hook, archive-playbook の動作が記録されている"

- [ ] **p4.4**: SubAgent 呼び出しシミュレーション（critic, pm, reviewer）がログに記録されている
  - executor: claudecode
  - test_command: `grep -q '## SubAgent' docs/e2e-simulation-log.md && grep -c 'critic\|pm\|reviewer' docs/e2e-simulation-log.md | awk '{if($1>=3) print "PASS"; else print "FAIL"}'`
  - validations:
    - technical: "SubAgent 呼び出しの動作が記録されている"
    - consistency: "呼び出しパラメータと結果が記録されている"
    - completeness: "critic, pm, reviewer の 3 SubAgent が記録されている"

- [ ] **p4.5**: Skill 適用シミュレーション（consent-process, post-loop）がログに記録されている
  - executor: claudecode
  - test_command: `grep -q '## Skill' docs/e2e-simulation-log.md && grep -c 'consent-process\|post-loop' docs/e2e-simulation-log.md | awk '{if($1>=2) print "PASS"; else print "FAIL"}'`
  - validations:
    - technical: "Skill 適用の動作が記録されている"
    - consistency: "Skill の発火条件と結果が記録されている"
    - completeness: "consent-process, post-loop の 2 Skill が記録されている"

**status**: pending
**max_iterations**: 10

---

### p5: 問題修正と最終検証

**goal**: 発見された問題を修正し、全検証を再実行する

**depends_on**: [p4]

#### subtasks

- [ ] **p5.1**: docs/fraud-investigation-report.md の「修正対象」が全て「修正済み」になっている
  - executor: claudecode
  - test_command: `grep -c '修正対象' docs/fraud-investigation-report.md | awk '{c=$1} END {if(c==0) print "PASS"}' && grep -c '修正済み' docs/fraud-investigation-report.md | awk '{if($1>0) print "PASS"; else print "SKIP"}'`
  - validations:
    - technical: "レポート内の修正対象が全て処理されている"
    - consistency: "修正内容が project.md の done_when と整合している"
    - completeness: "全ての問題が修正されている"

- [ ] **p5.2**: done-when-validator.sh が project.md の全 done_when 行で exit 0 を返す
  - executor: claudecode
  - test_command: `grep -E '^\\s*-.*\\[' plan/project.md | grep -v 'description\|explanation' | .claude/hooks/done-when-validator.sh && echo PASS || echo FAIL`
  - validations:
    - technical: "validator が正常に実行できる"
    - consistency: "禁止パターンが検出されない"
    - completeness: "全 done_when 行が検証対象になっている"

- [ ] **p5.3**: docs/e2e-simulation-log.md が 200 行以上存在する
  - executor: claudecode
  - test_command: `wc -l docs/e2e-simulation-log.md | awk '{if($1>=200) print "PASS"; else print "FAIL"}'`
  - validations:
    - technical: "ログファイルが十分な内容を持つ"
    - consistency: "ログ内容が p4 の subtask と対応している"
    - completeness: "全シミュレーションの結果が記録されている"

**status**: pending
**max_iterations**: 5

---

### p_final: 完了検証（必須）

**goal**: playbook の done_when が全て満たされているか最終検証

**depends_on**: [p5]

#### subtasks

- [ ] **p_final.1**: M001-M061 の全 milestone に対して done_when の達成状況が検証されている
  - executor: claudecode
  - test_command: `test -f docs/fraud-investigation-report.md && grep -q 'M001' docs/fraud-investigation-report.md && grep -q 'M061' docs/fraud-investigation-report.md && echo PASS || echo FAIL`
  - validations:
    - technical: "レポートファイルが存在する"
    - consistency: "M001 から M061 まで網羅されている"
    - completeness: "全 milestone の調査結果が含まれている"

- [ ] **p_final.2**: archive-playbook.sh に subtask 単位の完了チェックが追加されている
  - executor: claudecode
  - test_command: `grep -q 'CHECKED_COUNT' .claude/hooks/archive-playbook.sh && grep -q 'UNCHECKED_COUNT' .claude/hooks/archive-playbook.sh && echo PASS || echo FAIL`
  - validations:
    - technical: "チェックロジックが実装されている"
    - consistency: "V12 形式と整合している"
    - completeness: "ブロック機能が実装されている"

- [ ] **p_final.3**: docs/e2e-simulation-log.md に全 Hook/SubAgent/Skill の動作確認ログが記録されている
  - executor: claudecode
  - test_command: `test -f docs/e2e-simulation-log.md && wc -l docs/e2e-simulation-log.md | awk '{if($1>=200) print "PASS"; else print "FAIL"}'`
  - validations:
    - technical: "ログファイルが存在し十分な内容がある"
    - consistency: "全コンポーネントの動作が記録されている"
    - completeness: "シミュレーションが完了している"

- [ ] **p_final.4**: 発見された報酬詐欺（done_when 未達成）が 0 件、または修正済みである
  - executor: claudecode
  - test_command: `grep -c '未修正' docs/fraud-investigation-report.md 2>/dev/null | awk '{if($1==0) print "PASS"; else print "FAIL"}' || echo PASS`
  - validations:
    - technical: "未修正の問題が検出されない"
    - consistency: "修正内容が project.md に反映されている"
    - completeness: "全ての問題が解決されている"

**status**: pending
**max_iterations**: 3

---

## final_tasks

- [ ] **ft1**: repository-map.yaml を更新する
  - command: `bash .claude/hooks/generate-repository-map.sh`
  - status: pending

- [ ] **ft2**: tmp/ 内の一時ファイルを削除する
  - command: `find tmp/ -type f ! -name 'CLAUDE.md' ! -name 'README.md' -delete 2>/dev/null || true`
  - status: pending

- [ ] **ft3**: 変更を全てコミットする
  - command: `git add -A && git status`
  - status: pending

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-17 | 初版作成。報酬詐欺徹底調査 + E2E シミュレーションの playbook。 |
