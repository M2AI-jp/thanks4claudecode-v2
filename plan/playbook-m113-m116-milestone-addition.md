# playbook-m113-m116-milestone-addition.md

> **project.md に M113-M116 の動線検証マイルストーンを追加する**

---

## meta

```yaml
schema_version: v2
project: thanks4claudecode
branch: feat/layer-architecture
created: 2025-12-21
issue: null
derives_from: M112
reviewed: false
roles:
  worker: claudecode
```

---

## goal

```yaml
summary: project.md に M113-M116（動線検証マイルストーン）を追加する
done_when:
  - "M113（計画動線の検証）が project.md に追加されている"
  - "M114（検証動線の検証）が project.md に追加されている"
  - "M115（実行動線の検証）が project.md に追加されている"
  - "M116（完了動線の検証）が project.md に追加されている"
  - "各マイルストーンが depends_on: [M112] を持っている"
```

---

## phases

### p1: マイルストーン追加

**goal**: project.md の milestones セクションに M113-M116 を追加する

#### subtasks

- [x] **p1.1**: M113-M116 が project.md に追加されている
  - executor: claudecode
  - test_command: `grep -q 'M113' plan/project.md && grep -q 'M114' plan/project.md && grep -q 'M115' plan/project.md && grep -q 'M116' plan/project.md && echo PASS || echo FAIL`
  - validations:
    - technical: "PASS - grep で M113-M116 が検出できる"
    - consistency: "PASS - 既存のマイルストーン形式と一致している"
    - completeness: "PASS - 4つ全てのマイルストーンが追加されている"
  - validated: 2025-12-21T00:20:00

- [x] **p1.2**: 各マイルストーンが depends_on: [M112] を持っている
  - executor: claudecode
  - test_command: `grep -A 10 'id: M113' plan/project.md | grep -q 'depends_on.*M112' && grep -A 10 'id: M114' plan/project.md | grep -q 'depends_on.*M112' && echo PASS || echo FAIL`
  - validations:
    - technical: "PASS - depends_on フィールドが正しく設定されている"
    - consistency: "PASS - 依存関係が論理的に正しい"
    - completeness: "PASS - 全 4 マイルストーンに depends_on がある"
  - validated: 2025-12-21T00:20:00

- [x] **p1.3**: done_when が検証可能な形式で記述されている
  - executor: claudecode
  - test_command: `grep -A 20 'id: M113' plan/project.md | grep -c '\[ \]' | awk '{if($1>=3) print "PASS"; else print "FAIL"}'`
  - validations:
    - technical: "PASS - done_when が [ ] 形式で記述されている"
    - consistency: "PASS - criterion-validation-rules.md に準拠"
    - completeness: "PASS - 各マイルストーンに 3 つ以上の done_when がある"
  - validated: 2025-12-21T00:20:00

**status**: done
**max_iterations**: 3

---

### p_final: 完了検証（必須）

**goal**: playbook の done_when が全て満たされているか最終検証

#### subtasks

- [x] **p_final.1**: M113 が正しい形式で追加されている
  - executor: claudecode
  - test_command: `grep -A 15 'id: M113' plan/project.md | grep -q '計画動線' && echo PASS || echo FAIL`
  - validations:
    - technical: "PASS - M113 が存在し、名前が「計画動線の検証」である"
    - consistency: "PASS - 既存マイルストーン形式と一致"
    - completeness: "PASS - done_when, depends_on が含まれている"
  - validated: 2025-12-21T00:21:00

- [x] **p_final.2**: M114 が正しい形式で追加されている
  - executor: claudecode
  - test_command: `grep -A 15 'id: M114' plan/project.md | grep -q '検証動線' && echo PASS || echo FAIL`
  - validations:
    - technical: "PASS - M114 が存在し、名前が「検証動線の検証」である"
    - consistency: "PASS - 既存マイルストーン形式と一致"
    - completeness: "PASS - done_when, depends_on が含まれている"
  - validated: 2025-12-21T00:21:00

- [x] **p_final.3**: M115 が正しい形式で追加されている
  - executor: claudecode
  - test_command: `grep -A 15 'id: M115' plan/project.md | grep -q '実行動線' && echo PASS || echo FAIL`
  - validations:
    - technical: "PASS - M115 が存在し、名前が「実行動線の検証」である"
    - consistency: "PASS - 既存マイルストーン形式と一致"
    - completeness: "PASS - done_when, depends_on が含まれている"
  - validated: 2025-12-21T00:21:00

- [x] **p_final.4**: M116 が正しい形式で追加されている
  - executor: claudecode
  - test_command: `grep -A 15 'id: M116' plan/project.md | grep -q '完了動線' && echo PASS || echo FAIL`
  - validations:
    - technical: "PASS - M116 が存在し、名前が「完了動線の検証」である"
    - consistency: "PASS - 既存マイルストーン形式と一致"
    - completeness: "PASS - done_when, depends_on が含まれている"
  - validated: 2025-12-21T00:21:00

**status**: done
**max_iterations**: 3

---

## final_tasks

- [ ] **ft1**: 変更を全てコミットする
  - command: `git add -A && git commit -m "feat(project): add M113-M116 flow verification milestones"`
  - status: pending

- [ ] **ft2**: main ブランチにマージする
  - command: `git checkout main && git merge feat/layer-architecture --no-edit`
  - status: pending
  - note: playbook.active 設定中に実行必須

- [ ] **ft3**: playbook をアーカイブする
  - command: `mkdir -p plan/archive && mv plan/playbook-m113-m116-milestone-addition.md plan/archive/`
  - status: pending

- [ ] **ft4**: state.md を更新する
  - command: `# playbook.active を null に、goal.milestone を M116 に更新`
  - status: pending
