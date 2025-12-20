# playbook-m120-role-resolver.md

> **役割名を具体的な executor に解決するスクリプトの作成**

---

## meta

```yaml
schema_version: v2
project: thanks4claudecode
branch: feat/layer-architecture
created: 2025-12-21
issue: null
derives_from: M120
reviewed: true  # 事前承認済み
```

---

## goal

```yaml
summary: role-resolver.sh を作成し、executor-guard.sh から呼び出せるようにする
done_when:
  - .claude/hooks/role-resolver.sh が存在し、実行可能である
  - 役割名（worker, orchestrator, reviewer, human）を具体的な executor に解決できる
  - toolstack（A/B/C）に応じた正しい解決が行われる
```

---

## phases

### p1: role-resolver.sh の作成

**goal**: 役割名を executor に解決するスクリプトを作成

#### subtasks

- [x] **p1.1**: .claude/hooks/role-resolver.sh が存在する
  - executor: claudecode
  - test_command: `test -f .claude/hooks/role-resolver.sh && echo PASS || echo FAIL`
  - validations:
    - technical: "PASS - ファイルが存在する"
    - consistency: "PASS - executor-guard.sh から参照される位置にある"
    - completeness: "PASS - スクリプト内容が完全"
  - validated: 2025-12-21T03:00:00

- [x] **p1.2**: role-resolver.sh が実行可能である
  - executor: claudecode
  - test_command: `test -x .claude/hooks/role-resolver.sh && echo PASS || echo FAIL`
  - validations:
    - technical: "PASS - 実行権限がある"
    - consistency: "PASS - 他の hook スクリプトと同じ権限設定"
    - completeness: "PASS - chmod +x が適用されている"
  - validated: 2025-12-21T03:00:00

**status**: done
**max_iterations**: 5

---

### p2: 動作確認

**goal**: 各 toolstack での解決が正しく行われることを確認

**depends_on**: [p1]

#### subtasks

- [x] **p2.1**: Toolstack A で worker が claudecode に解決される
  - executor: claudecode
  - test_command: `STATE_FILE=/dev/null TOOLSTACK=A bash .claude/hooks/role-resolver.sh worker | grep -q claudecode && echo PASS || echo FAIL`
  - validations:
    - technical: "PASS - コマンドが正常に実行された"
    - consistency: "PASS - docs/ai-orchestration.md の定義と一致"
    - completeness: "PASS - worker が claudecode に解決された"
  - validated: 2025-12-21T03:00:00

- [x] **p2.2**: Toolstack B で worker が codex に解決される
  - executor: claudecode
  - test_command: `STATE_FILE=/dev/null TOOLSTACK=B bash .claude/hooks/role-resolver.sh worker | grep -q codex && echo PASS || echo FAIL`
  - validations:
    - technical: "PASS - コマンドが正常に実行された"
    - consistency: "PASS - docs/ai-orchestration.md の定義と一致"
    - completeness: "PASS - worker が codex に解決された"
  - validated: 2025-12-21T03:00:00

- [x] **p2.3**: Toolstack C で reviewer が coderabbit に解決される
  - executor: claudecode
  - test_command: `STATE_FILE=/dev/null TOOLSTACK=C bash .claude/hooks/role-resolver.sh reviewer | grep -q coderabbit && echo PASS || echo FAIL`
  - validations:
    - technical: "PASS - コマンドが正常に実行された"
    - consistency: "PASS - docs/ai-orchestration.md の定義と一致"
    - completeness: "PASS - reviewer が coderabbit に解決された"
  - validated: 2025-12-21T03:00:00

- [x] **p2.4**: 具体的な executor 名はそのまま返される
  - executor: claudecode
  - test_command: `bash .claude/hooks/role-resolver.sh claudecode | grep -q claudecode && echo PASS || echo FAIL`
  - validations:
    - technical: "PASS - パススルーが正常に動作した"
    - consistency: "PASS - 既存の playbook との互換性が保たれている"
    - completeness: "PASS - 全ての具体的 executor 名がパススルーされる"
  - validated: 2025-12-21T03:00:00

**status**: done
**max_iterations**: 5

---

### p_final: 完了検証

**goal**: done_when の全項目が満たされていることを確認

**depends_on**: [p1, p2]

#### subtasks

- [x] **p_final.1**: role-resolver.sh が存在し実行可能である
  - executor: claudecode
  - test_command: `test -x .claude/hooks/role-resolver.sh && echo PASS || echo FAIL`
  - validations:
    - technical: "PASS - ファイルが存在し実行可能"
    - consistency: "PASS - hooks ディレクトリ内にある"
    - completeness: "PASS - 必要な権限が設定されている"
  - validated: 2025-12-21T03:00:00

- [x] **p_final.2**: 役割名が正しく解決される
  - executor: claudecode
  - test_command: `STATE_FILE=/dev/null TOOLSTACK=B bash .claude/hooks/role-resolver.sh worker | grep -q codex && STATE_FILE=/dev/null TOOLSTACK=A bash .claude/hooks/role-resolver.sh worker | grep -q claudecode && echo PASS || echo FAIL`
  - validations:
    - technical: "PASS - 解決ロジックが正常に動作"
    - consistency: "PASS - docs/ai-orchestration.md の仕様と一致"
    - completeness: "PASS - 全ての役割名（orchestrator, worker, reviewer, human）が解決可能"
  - validated: 2025-12-21T03:00:00

**status**: done
**max_iterations**: 3

---

## final_tasks

- [x] **ft1**: 変更を全てコミットする
  - command: `git add -A && git commit -m "feat(M120): create role-resolver.sh"`
  - status: done
  - executed: 2025-12-21T03:05:00

- [ ] **ft2**: main ブランチにマージする
  - command: `git checkout main && git merge feat/m120-role-resolver --no-edit`
  - status: pending

- [ ] **ft3**: state.md の playbook.active を null に更新する
  - command: `# playbook.active を null に更新`
  - status: pending
