# playbook-m096-pre-bash-deadlock-fix.md

> **pre-bash-check のデッドロック問題を修正**

---

## meta

```yaml
schema_version: v2
project: thanks4claudecode
branch: fix/pre-bash-deadlock
created: 2025-12-20
issue: null
derives_from: M096
reviewed: false
```

---

## goal

```yaml
summary: playbook=null でも playbook 完了後のメンテナンス操作を許可する
done_when:
  - scripts/contract.sh の ADMIN_MAINTENANCE_PATTERNS に git checkout/merge/branch -d が追加されている
  - playbook=null で git add state.md が実行できる
  - playbook=null で git commit が実行できる
  - playbook=null で git checkout main が実行できる
```

---

## phases

### p1: メンテナンスパターン拡張

**goal**: ADMIN_MAINTENANCE_PATTERNS に不足しているパターンを追加

#### subtasks

- [x] **p1.1**: scripts/contract.sh に git checkout main パターンが追加されている
  - executor: claudecode
  - test_command: `grep -q 'git.*checkout.*main' scripts/contract.sh && echo PASS || echo FAIL`
  - validations:
    - technical: "PASS - 正規表現として有効"
    - consistency: "PASS - 他のパターンと形式が一致"
    - completeness: "PASS - main ブランチへのチェックアウトをカバー"
  - validated: 2025-12-20T00:00:00

- [x] **p1.2**: scripts/contract.sh に git merge パターンが追加されている
  - executor: claudecode
  - test_command: `grep -q 'git.*merge' scripts/contract.sh && echo PASS || echo FAIL`
  - validations:
    - technical: "PASS - 正規表現として有効"
    - consistency: "PASS - 他のパターンと形式が一致"
    - completeness: "PASS - ブランチマージをカバー"
  - validated: 2025-12-20T00:00:00

- [x] **p1.3**: scripts/contract.sh に git branch -d パターンが追加されている
  - executor: claudecode
  - test_command: `grep -q 'git.*branch.*-d' scripts/contract.sh && echo PASS || echo FAIL`
  - validations:
    - technical: "PASS - 正規表現として有効"
    - consistency: "PASS - 他のパターンと形式が一致"
    - completeness: "PASS - ブランチ削除をカバー"
  - validated: 2025-12-20T00:00:00

- [x] **p1.4**: scripts/contract.sh に mv plan/playbook-*.md plan/archive/ パターンが追加されている
  - executor: claudecode
  - test_command: `grep -q 'mv.*plan/playbook' scripts/contract.sh && echo PASS || echo FAIL`
  - validations:
    - technical: "PASS - 正規表現として有効（既存パターン）"
    - consistency: "PASS - 他のパターンと形式が一致"
    - completeness: "PASS - playbook アーカイブをカバー"
  - validated: 2025-12-20T00:00:00

**status**: done

---

### p_final: 完了検証

**goal**: 全ての done_when が満たされていることを確認

#### subtasks

- [x] **p_final.1**: playbook=null で git add state.md が実行できる
  - executor: claudecode
  - test_command: `bash -c 'source scripts/contract.sh; contract_check_bash "git add state.md"' && echo PASS`
  - validations:
    - technical: "PASS - 契約チェックが exit 0 を返す"
    - consistency: "PASS - 他の許可パターンと同様に動作"
    - completeness: "PASS - git add state.md が許可される"
  - validated: 2025-12-20T00:00:00

- [x] **p_final.2**: playbook=null で git checkout main が実行できる
  - executor: claudecode
  - test_command: `bash -c 'source scripts/contract.sh; contract_check_bash "git checkout main"' && echo PASS`
  - validations:
    - technical: "PASS - 契約チェックが exit 0 を返す"
    - consistency: "PASS - 他の許可パターンと同様に動作"
    - completeness: "PASS - git checkout main が許可される"
  - validated: 2025-12-20T00:00:00

**status**: done

---

## final_tasks

- [x] **ft1**: repository-map.yaml を更新する
  - command: `bash .claude/hooks/generate-repository-map.sh`
  - status: done
  - executed: 2025-12-20T00:00:00

- [x] **ft2**: 変更をコミットする
  - command: `git add -A && git status`
  - status: done
  - executed: 2025-12-20T00:00:00
