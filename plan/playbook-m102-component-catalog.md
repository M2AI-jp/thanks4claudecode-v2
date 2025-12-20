# playbook-m102-component-catalog.md

> **リポジトリの全コンポーネントドキュメントを check.md に出力**

---

## meta

```yaml
schema_version: v2
project: thanks4claudecode-v2
branch: feat/m102-component-catalog
created: 2025-12-20
issue: null
derives_from: null  # 臨時タスク（ユーザー直接依頼）
reviewed: false
roles:
  worker: claudecode
```

---

## goal

```yaml
summary: check.md に全コンポーネント（Hooks 22個、SubAgents 3個、Skills 7個、Commands 8個）のドキュメントを出力
done_when:
  - check.md に Hooks 22個の要点とソースが含まれている
  - check.md に SubAgents 3個の要点とソースが含まれている
  - check.md に Skills 7個の要点とソースが含まれている
  - check.md に Commands 8個の要点とソースが含まれている
```

---

## phases

### p1: 全コンポーネントドキュメント出力

**goal**: check.md にリポジトリの全コンポーネント情報を整理して出力

#### subtasks

- [ ] **p1.1**: check.md に Hooks 22個の一覧と各フックの要点・ソースパスが含まれている
  - executor: claudecode
  - test_command: `test -f check.md && grep -c '\.claude/hooks/' check.md | awk '{if($1>=22) print "PASS"; else print "FAIL"}'`
  - validations:
    - technical: "check.md が存在し、hooks パスへの参照が 22 件以上"
    - consistency: "state.md COMPONENT_REGISTRY の hooks: 22 と一致"
    - completeness: "全 22 個のフックが記載されている"

- [ ] **p1.2**: check.md に SubAgents 3個の一覧と各エージェントの要点・ソースパスが含まれている
  - executor: claudecode
  - test_command: `grep -c '\.claude/agents/' check.md | awk '{if($1>=3) print "PASS"; else print "FAIL"}'`
  - validations:
    - technical: "agents パスへの参照が 3 件以上"
    - consistency: "state.md COMPONENT_REGISTRY の agents: 3 と一致"
    - completeness: "全 3 個のエージェントが記載されている"

- [ ] **p1.3**: check.md に Skills 7個の一覧と各スキルの要点・ソースパスが含まれている
  - executor: claudecode
  - test_command: `grep -c '\.claude/skills/' check.md | awk '{if($1>=7) print "PASS"; else print "FAIL"}'`
  - validations:
    - technical: "skills パスへの参照が 7 件以上"
    - consistency: "state.md COMPONENT_REGISTRY の skills: 7 と一致"
    - completeness: "全 7 個のスキルが記載されている"

- [ ] **p1.4**: check.md に Commands 8個の一覧と各コマンドの要点・ソースパスが含まれている
  - executor: claudecode
  - test_command: `grep -c '\.claude/commands/' check.md | awk '{if($1>=8) print "PASS"; else print "FAIL"}'`
  - validations:
    - technical: "commands パスへの参照が 8 件以上"
    - consistency: "state.md COMPONENT_REGISTRY の commands: 8 と一致"
    - completeness: "全 8 個のコマンドが記載されている"

**status**: pending
**max_iterations**: 5

---

### p_final: 完了検証

**goal**: playbook の done_when が全て満たされているか最終検証

#### subtasks

- [ ] **p_final.1**: check.md に Hooks 22個の要点とソースが含まれている
  - executor: claudecode
  - test_command: `grep -c '\.claude/hooks/' check.md | awk '{if($1>=22) print "PASS"; else print "FAIL"}'`
  - validations:
    - technical: "grep コマンドが正常に実行できる"
    - consistency: "カウント結果が実際のファイル数と一致"
    - completeness: "全フックがドキュメント化されている"

- [ ] **p_final.2**: check.md に SubAgents 3個の要点とソースが含まれている
  - executor: claudecode
  - test_command: `grep -c '\.claude/agents/' check.md | awk '{if($1>=3) print "PASS"; else print "FAIL"}'`
  - validations:
    - technical: "grep コマンドが正常に実行できる"
    - consistency: "カウント結果が実際のファイル数と一致"
    - completeness: "全エージェントがドキュメント化されている"

- [ ] **p_final.3**: check.md に Skills 7個の要点とソースが含まれている
  - executor: claudecode
  - test_command: `grep -c '\.claude/skills/' check.md | awk '{if($1>=7) print "PASS"; else print "FAIL"}'`
  - validations:
    - technical: "grep コマンドが正常に実行できる"
    - consistency: "カウント結果が実際のファイル数と一致"
    - completeness: "全スキルがドキュメント化されている"

- [ ] **p_final.4**: check.md に Commands 8個の要点とソースが含まれている
  - executor: claudecode
  - test_command: `grep -c '\.claude/commands/' check.md | awk '{if($1>=8) print "PASS"; else print "FAIL"}'`
  - validations:
    - technical: "grep コマンドが正常に実行できる"
    - consistency: "カウント結果が実際のファイル数と一致"
    - completeness: "全コマンドがドキュメント化されている"

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
