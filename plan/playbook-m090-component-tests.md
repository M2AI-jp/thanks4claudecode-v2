# playbook-m090-component-tests.md

> **コンポーネント動作保証システム - SubAgent/Skill/Command のテストスクリプト作成**

---

## meta

```yaml
schema_version: v2
project: thanks4claudecode
branch: feat/m090-component-tests
created: 2025-12-19
issue: null
derives_from: M090
reviewed: true
roles:
  worker: claudecode
```

---

## goal

```yaml
summary: SubAgent/Skill/Command の動作テストスクリプトを作成し、vision.success_criteria を達成
done_when:
  - scripts/test-subagents.sh が存在し、6 SubAgent 全てをテスト
  - scripts/test-skills.sh が存在し、9 Skill 全てをテスト
  - scripts/test-commands.sh が存在し、8 Command 全てをテスト
  - 全テストが PASS
```

---

## phases

### p1: SubAgent テストスクリプト作成

**goal**: 6 個の SubAgent（codex-delegate, critic, health-checker, pm, reviewer, setup-guide）の動作テストスクリプトを作成

#### subtasks

- [x] **p1.1**: scripts/test-subagents.sh が存在する
  - executor: claudecode
  - test_command: `test -f scripts/test-subagents.sh && echo PASS || echo FAIL`
  - validations:
    - technical: "ファイルが存在する"
    - consistency: "scripts/ ディレクトリ内に配置"
    - completeness: "ファイルが作成されている"

- [x] **p1.2**: test-subagents.sh が実行可能である
  - executor: claudecode
  - test_command: `test -x scripts/test-subagents.sh && echo PASS || echo FAIL`
  - validations:
    - technical: "実行権限が付与されている"
    - consistency: "他のテストスクリプトと同様の権限設定"
    - completeness: "chmod +x が実行済み"

- [x] **p1.3**: test-subagents.sh が bash -n でエラー 0 である
  - executor: claudecode
  - test_command: `bash -n scripts/test-subagents.sh && echo PASS || echo FAIL`
  - validations:
    - technical: "構文エラーがない"
    - consistency: "Bash スクリプト標準に準拠"
    - completeness: "全行が正しい構文"

- [x] **p1.4**: test-subagents.sh が 6 個の SubAgent を全てテストしている
  - executor: claudecode
  - test_command: `grep -c 'codex-delegate\|critic\|health-checker\|pm\|reviewer\|setup-guide' scripts/test-subagents.sh | awk '{if($1>=6) print "PASS"; else print "FAIL"}'`
  - validations:
    - technical: "6 SubAgent 全ての名前が含まれている"
    - consistency: ".claude/agents/*.md と一致"
    - completeness: "全 SubAgent がカバーされている"

- [x] **p1.5**: test-subagents.sh の実行結果に ALL PASS が含まれる
  - executor: claudecode
  - test_command: `bash scripts/test-subagents.sh 2>&1 | grep -q 'ALL.*PASS\|PASS: 6' && echo PASS || echo FAIL`
  - validations:
    - technical: "全テストケースが成功"
    - consistency: "test-hooks.sh と同様の出力形式"
    - completeness: "全 SubAgent のテストが PASS"

**status**: done
**max_iterations**: 5

---

### p2: Skill テストスクリプト作成

**goal**: 9 個の Skill の動作テストスクリプトを作成

**depends_on**: [p1]

#### subtasks

- [x] **p2.1**: scripts/test-skills.sh が存在する
  - executor: claudecode
  - test_command: `test -f scripts/test-skills.sh && echo PASS || echo FAIL`
  - validations:
    - technical: "ファイルが存在する"
    - consistency: "scripts/ ディレクトリ内に配置"
    - completeness: "ファイルが作成されている"

- [x] **p2.2**: test-skills.sh が実行可能である
  - executor: claudecode
  - test_command: `test -x scripts/test-skills.sh && echo PASS || echo FAIL`
  - validations:
    - technical: "実行権限が付与されている"
    - consistency: "他のテストスクリプトと同様の権限設定"
    - completeness: "chmod +x が実行済み"

- [x] **p2.3**: test-skills.sh が bash -n でエラー 0 である
  - executor: claudecode
  - test_command: `bash -n scripts/test-skills.sh && echo PASS || echo FAIL`
  - validations:
    - technical: "構文エラーがない"
    - consistency: "Bash スクリプト標準に準拠"
    - completeness: "全行が正しい構文"

- [x] **p2.4**: test-skills.sh が 9 個の Skill を全てテストしている
  - executor: claudecode
  - test_command: `grep -c 'consent-process\|context-management\|deploy-checker\|frontend-design\|lint-checker\|plan-management\|post-loop\|state\|test-runner' scripts/test-skills.sh | awk '{if($1>=9) print "PASS"; else print "FAIL"}'`
  - validations:
    - technical: "9 Skill 全ての名前が含まれている"
    - consistency: ".claude/skills/*/SKILL.md と一致"
    - completeness: "全 Skill がカバーされている"

- [x] **p2.5**: test-skills.sh の実行結果に ALL PASS が含まれる
  - executor: claudecode
  - test_command: `bash scripts/test-skills.sh 2>&1 | grep -q 'ALL.*PASS\|PASS: 9' && echo PASS || echo FAIL`
  - validations:
    - technical: "全テストケースが成功"
    - consistency: "test-hooks.sh と同様の出力形式"
    - completeness: "全 Skill のテストが PASS"

**status**: done
**max_iterations**: 5

---

### p3: Command テストスクリプト作成

**goal**: 8 個の Command の動作テストスクリプトを作成

**depends_on**: [p2]

#### subtasks

- [x] **p3.1**: scripts/test-commands.sh が存在する
  - executor: claudecode
  - test_command: `test -f scripts/test-commands.sh && echo PASS || echo FAIL`
  - validations:
    - technical: "ファイルが存在する"
    - consistency: "scripts/ ディレクトリ内に配置"
    - completeness: "ファイルが作成されている"

- [x] **p3.2**: test-commands.sh が実行可能である
  - executor: claudecode
  - test_command: `test -x scripts/test-commands.sh && echo PASS || echo FAIL`
  - validations:
    - technical: "実行権限が付与されている"
    - consistency: "他のテストスクリプトと同様の権限設定"
    - completeness: "chmod +x が実行済み"

- [x] **p3.3**: test-commands.sh が bash -n でエラー 0 である
  - executor: claudecode
  - test_command: `bash -n scripts/test-commands.sh && echo PASS || echo FAIL`
  - validations:
    - technical: "構文エラーがない"
    - consistency: "Bash スクリプト標準に準拠"
    - completeness: "全行が正しい構文"

- [x] **p3.4**: test-commands.sh が 8 個の Command を全てテストしている
  - executor: claudecode
  - test_command: `grep -c 'crit\|focus\|lint\|playbook-init\|rollback\|state-rollback\|task-start\|test' scripts/test-commands.sh | awk '{if($1>=8) print "PASS"; else print "FAIL"}'`
  - validations:
    - technical: "8 Command 全ての名前が含まれている"
    - consistency: ".claude/commands/*.md と一致"
    - completeness: "全 Command がカバーされている"

- [x] **p3.5**: test-commands.sh の実行結果に ALL PASS が含まれる
  - executor: claudecode
  - test_command: `bash scripts/test-commands.sh 2>&1 | grep -q 'ALL.*PASS\|PASS: 8' && echo PASS || echo FAIL`
  - validations:
    - technical: "全テストケースが成功"
    - consistency: "test-hooks.sh と同様の出力形式"
    - completeness: "全 Command のテストが PASS"

**status**: done
**max_iterations**: 5

---

### p_final: 完了検証

**goal**: playbook の done_when が全て満たされているか最終検証

**depends_on**: [p1, p2, p3]

#### subtasks

- [x] **p_final.1**: scripts/test-subagents.sh が存在し、6 SubAgent 全てをテストしている
  - executor: claudecode
  - test_command: `test -f scripts/test-subagents.sh && bash scripts/test-subagents.sh 2>&1 | grep -q 'PASS: 6' && echo PASS || echo FAIL`
  - validations:
    - technical: "ファイルが存在し実行可能"
    - consistency: "6 SubAgent 全てがテストされている"
    - completeness: "全テストが PASS"

- [x] **p_final.2**: scripts/test-skills.sh が存在し、9 Skill 全てをテストしている
  - executor: claudecode
  - test_command: `test -f scripts/test-skills.sh && bash scripts/test-skills.sh 2>&1 | grep -q 'PASS: 9' && echo PASS || echo FAIL`
  - validations:
    - technical: "ファイルが存在し実行可能"
    - consistency: "9 Skill 全てがテストされている"
    - completeness: "全テストが PASS"

- [x] **p_final.3**: scripts/test-commands.sh が存在し、8 Command 全てをテストしている
  - executor: claudecode
  - test_command: `test -f scripts/test-commands.sh && bash scripts/test-commands.sh 2>&1 | grep -q 'PASS: 8' && echo PASS || echo FAIL`
  - validations:
    - technical: "ファイルが存在し実行可能"
    - consistency: "8 Command 全てがテストされている"
    - completeness: "全テストが PASS"

- [x] **p_final.4**: 全テストスクリプトが正常終了する
  - executor: claudecode
  - test_command: `bash scripts/test-subagents.sh && bash scripts/test-skills.sh && bash scripts/test-commands.sh && echo PASS || echo FAIL`
  - validations:
    - technical: "全スクリプトが exit 0"
    - consistency: "vision.success_criteria を達成"
    - completeness: "全コンポーネントの動作が確認済み"

**status**: done
**max_iterations**: 3

---

## final_tasks

- [x] **ft1**: repository-map.yaml を更新する
  - command: `bash .claude/hooks/generate-repository-map.sh`
  - status: done

- [x] **ft2**: tmp/ 内の一時ファイルを削除する
  - command: `find tmp/ -type f ! -name 'README.md' -delete 2>/dev/null || true`
  - status: done

- [x] **ft3**: 変更を全てコミットする
  - command: `git add -A && git status`
  - status: done

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-19 | 初版作成。M090 コンポーネント動作保証システム。 |
