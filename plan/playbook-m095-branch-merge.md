# playbook-m095-branch-merge.md

## meta

```yaml
schema_version: v2
project: M093/M094 ブランチマージ
branch: feat/m094-consent-auto-delete
created: 2025-12-19
issue: null
derives_from: null
reviewed: true
```

---

## goal

```yaml
summary: M093 と M094 のブランチを main にマージし、ブランチを削除する
done_when:
  - M093 と M094 のコミットが main に統合されている
  - feat/m093-ssc-phase3 と feat/m094-consent-auto-delete が削除されている
```

---

## phases

### p1: ブランチマージと削除

**goal**: M094 をコミットし、M093/M094 を main にマージ、ブランチ削除

#### subtasks

- [ ] **p1.1**: M094 の変更がコミットされている
  - executor: claudecode
  - test_command: `git log -1 --oneline | grep -q 'M094' && echo PASS || echo FAIL`
  - validations:
    - technical: "コミットが作成されている"
    - consistency: "M094 の変更が全て含まれている"
    - completeness: "state.md と削除された playbook が含まれる"

- [ ] **p1.2**: M093 が main にマージされている
  - executor: claudecode
  - test_command: `git log main --oneline | head -3 | grep -q 'M093' && echo PASS || echo FAIL`
  - validations:
    - technical: "マージが成功している"
    - consistency: "M093 のコミットが main に存在する"
    - completeness: "SSC Phase 3 の全変更が含まれている"

- [ ] **p1.3**: M094 が main にマージされている
  - executor: claudecode
  - test_command: `git log main --oneline | head -3 | grep -q 'M094' && echo PASS || echo FAIL`
  - validations:
    - technical: "マージが成功している"
    - consistency: "M094 のコミットが main に存在する"
    - completeness: "consent-auto-delete の全変更が含まれている"

- [ ] **p1.4**: feat/m093-ssc-phase3 ブランチが削除されている
  - executor: claudecode
  - test_command: `git branch | grep -q 'feat/m093-ssc-phase3' && echo FAIL || echo PASS`
  - validations:
    - technical: "ブランチが存在しない"
    - consistency: "main にマージ済み"
    - completeness: "ローカルブランチが削除されている"

- [ ] **p1.5**: feat/m094-consent-auto-delete ブランチが削除されている
  - executor: claudecode
  - test_command: `git branch | grep -q 'feat/m094-consent-auto-delete' && echo FAIL || echo PASS`
  - validations:
    - technical: "ブランチが存在しない"
    - consistency: "main にマージ済み"
    - completeness: "ローカルブランチが削除されている"

**status**: pending
**max_iterations**: 3

---

## final_tasks

- [ ] **ft1**: 現在のブランチが main である
  - command: `git branch --show-current`
  - status: pending
