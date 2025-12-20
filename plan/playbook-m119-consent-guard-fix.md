# playbook-m119-consent-guard-fix.md

> **consent-guard のデッドロック修正**

---

## meta

```yaml
schema_version: v2
project: M119
branch: feat/layer-architecture
created: 2025-12-21
issue: null
derives_from: M119
reviewed: false
```

---

## goal

```yaml
summary: consent-guard.sh に playbook 作成例外を追加し、pm のデッドロックを解消
done_when:
  - consent-guard.sh が plan/playbook-*.md への Edit/Write を許可する
  - playbook-guard.sh と同じ例外パターンが使用されている
```

---

## phases

### p1: consent-guard.sh 修正

**goal**: playbook-guard.sh と同じ例外パターンを consent-guard.sh に追加

#### subtasks

- [x] **p1.1**: consent-guard.sh に playbook 作成例外が追加されている
  - executor: claudecode
  - test_command: `grep -q 'plan/playbook-' /Users/amano/Desktop/thanks4claudecode-v2/.claude/hooks/consent-guard.sh && echo PASS || echo FAIL`
  - validations:
    - technical: "PASS - bash -n でシンタックスエラーなし"
    - consistency: "PASS - playbook-guard.sh と同じパターン使用"
    - completeness: "PASS - plan/playbook-*.md と plan/active/playbook-*.md 両方を許可"
  - validated: 2025-12-21T02:00:00

**status**: done
**max_iterations**: 3

---

### p_final: 完了検証

**goal**: done_when が全て満たされているか最終検証

#### subtasks

- [x] **p_final.1**: consent-guard.sh が plan/playbook-*.md への Edit/Write を許可する
  - executor: claudecode
  - test_command: `grep -A5 'plan/playbook-' consent-guard.sh | grep -q 'exit 0'`
  - validations:
    - technical: "PASS - exit 0 で許可されている（行85）"
    - consistency: "PASS - playbook-guard.sh の 57-60 行目と同じパターン"
    - completeness: "PASS - plan/active/playbook-*.md も許可されている"
  - validated: 2025-12-21T02:00:00

- [x] **p_final.2**: playbook-guard.sh と同じ例外パターンが使用されている
  - executor: claudecode
  - test_command: `grep 'plan/playbook-' playbook-guard.sh` vs `grep 'plan/playbook-' consent-guard.sh`
  - validations:
    - technical: "PASS - 両方とも同じパターン使用"
    - consistency: "PASS - if [[ \"$FILE_PATH\" == *\"plan/playbook-\"*.md ]] || \\"
    - completeness: "PASS - 全てのパスパターンが含まれている"
  - validated: 2025-12-21T02:00:00

**status**: done

---

## final_tasks

- [ ] **ft1**: 変更を全てコミットする
  - command: `git add -A && git commit -m "fix(M119): add playbook creation exception to consent-guard"`
  - status: pending

- [ ] **ft2**: main ブランチにマージする
  - command: `git checkout main && git merge feat/layer-architecture --no-edit`
  - status: pending

- [ ] **ft3**: playbook をアーカイブする
  - command: `mkdir -p plan/archive && mv plan/playbook-m119-consent-guard-fix.md plan/archive/`
  - status: pending

- [ ] **ft4**: state.md を更新する
  - command: `# playbook.active を null に、last_archived を更新`
  - status: pending
