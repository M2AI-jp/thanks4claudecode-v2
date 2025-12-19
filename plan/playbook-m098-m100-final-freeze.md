# playbook-m098-m100-final-freeze.md

> **収束→安定稼働→公開 の最終フェーズ**

---

## meta

```yaml
schema_version: v2
project: thanks4claudecode
branch: feat/final-freeze
created: 2025-12-20
issue: null
derives_from: M098-M100
reviewed: false
roles:
  worker: claudecode
```

---

## goal

```yaml
summary: 増殖を止め、削除し、挙動で保証して凍結する
done_when:
  - governance/core-manifest.yaml が存在し policy.no_new_components=true
  - 未登録 hooks が削除されている（34→22 に一致）
  - scripts/behavior-test.sh が PASS
  - README から数字自慢が消えている
```

---

## non_goals

```yaml
forbidden:
  - 新しい Hook/SubAgent/Skill を追加
  - 新しい分類 YAML やドキュメントを増やす
  - "便利そう" で仕組みを足す
  - grep/test -f を PASS 条件にする
  - 「将来やる」計画を書く

max_new_files: 3
allowed_new_files:
  - governance/core-manifest.yaml
  - scripts/find-unused.sh
  - scripts/behavior-test.sh
```

---

## phases

### M098: CORE FREEZE

**goal**: Core を最小で凍結し、増殖を止める

#### subtasks

- [ ] **m098.1**: governance/core-manifest.yaml を作成
  - Core hooks: playbook gate + HARD_BLOCK に必要な最小限
  - Core subagents: pm, critic のみ
  - Core skills: state, plan-management のみ
  - policy.no_new_components=true

- [ ] **m098.2**: completion-criteria.md に grep 禁止を追記
  - 「grep/test -f を PASS 条件にしない」宣言

- [ ] **m098.3**: component-tiers.yaml の扱いを決定
  - 削除するか、manifest 参照のみにする

**status**: pending

---

### M099: UNUSED PURGE

**goal**: 参照されないファイルを機械的に削除

**depends_on**: [M098]

#### subtasks

- [ ] **m099.1**: scripts/find-unused.sh を作成
  - 未登録 hooks を検出
  - manifest 非コアを検出

- [ ] **m099.2**: 未登録 hooks を削除（12個）
  - audit-unused.sh, check-integrity.sh, check-spec-sync.sh
  - create-pr.sh, failure-logger.sh, generate-repository-map.sh
  - merge-pr.sh, playbook-validator.sh, role-resolver.sh
  - system-health-check.sh, test-done-criteria.sh, test-hooks.sh

- [ ] **m099.3**: manifest 非コアで参照されない agents/skills を削除
  - codex-delegate.md, health-checker.md, setup-guide.md
  - deploy-checker, frontend-design

- [ ] **m099.4**: README/docs から削除済み要素への言及を消す

**status**: pending

---

### M100: STABILIZE + RELEASE

**goal**: 挙動テストで保証し、公開用に凍結

**depends_on**: [M099]

#### subtasks

- [ ] **m100.1**: scripts/behavior-test.sh を作成
  - S1: Playbook Gate block (playbook=null で変更系が止まる)
  - S2: Playbook active allow (通常作業ができる)
  - S3: HARD_BLOCK (保護ファイル編集が止まる)
  - S4: Deadlock escape (終了処理のコミットが通る)

- [ ] **m100.2**: M096 型デッドロックを最小例外で修正
  - playbook=null でも state.md/archive への git 操作は許可

- [ ] **m100.3**: README を公開用に整理
  - 数字自慢を削除
  - 「何を保証するか」に書き換え
  - 公開前チェック（3コマンド）を明記

- [ ] **m100.4**: behavior-test.sh が全 PASS

**status**: pending

---

## final_tasks

- [ ] state.md を更新（playbook.active=null, phase=done）
- [ ] 変更をコミット
- [ ] main にマージ

---
