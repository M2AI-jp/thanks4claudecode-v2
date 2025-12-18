# playbook-contract-consolidation.md

> **契約判定の統合 + Admin Maintenance 権限 + E2E 証明**

---

## meta

```yaml
project: Contract Consolidation - Core/Admin 分離 + E2E 証明
branch: refactor/contract-consolidation
created: 2025-12-18
issue: null
derives_from: M079
reviewed: false
```

---

## goal

```yaml
summary: |
  コア契約を不変に保ちつつ、admin(Maintenance) で運用操作を可能にし、
  E2E テストで挙動を証明する。Hook を増やさず、契約判定を単一中核に統合。

done_when:
  - docs/core-contract.md が作成され、テスト可能な形式で仕様が定義されている
  - docs/admin-contract.md が作成され、Maintenance 権限が明確化されている
  - scripts/contract.sh が作成され、全 Hook がこれを呼ぶ形に統合されている
  - E2E シナリオ A/B/C が全て PASS する
  - RUNBOOK に Golden Path と復旧手順が更新されている
  - セッション終了処理（アーカイブ→state更新→コミット）が手動なしで完遂できる

spec:
  core_contract: |
    ## Core Contract（絶対不変）

    1. Playbook Gate: playbook=null で意味的変更を禁止
       - 対象: コード、Hook、設定、仕様ファイル
       - 例外: state.md, playbook ファイル自体

    2. HARD_BLOCK: 特定ファイルは常に保護
       - CLAUDE.md, protected-files.txt, 重要 Hook

    3. Fail-Closed: 判定不能なら止める
       - git diff 取得失敗等は通過させない

  admin_contract: |
    ## Admin (Maintenance) 権限

    admin は「全てをバイパス」ではなく「運用上必要な最小操作を許可」。

    許可する操作（ホワイトリスト）:
      - state.md の編集（セッション終了等）
      - plan/playbook-*.md → plan/archive/** への移動
      - 上記のみを含むコミット

    必須条件:
      - security: admin が state.md で明示的に ON
      - ホワイトリスト外の変更が含まれていたらブロック
      - 監査ログを残す
```

---

## phases

### p1: 仕様確定 (docs/ 作成)

**goal**: Core Contract と Admin Contract を docs/ に短く定義

#### subtasks

- [ ] **p1.1**: docs/core-contract.md 作成
  - executor: orchestrator
  - test_command: `test -f docs/core-contract.md && echo PASS || echo FAIL`

- [ ] **p1.2**: docs/admin-contract.md 作成
  - executor: orchestrator
  - test_command: `test -f docs/admin-contract.md && echo PASS || echo FAIL`

**status**: pending
**max_iterations**: 3

---

### p2: 契約判定中核スクリプト作成

**goal**: scripts/contract.sh を作成し、全 Hook から呼び出す

**depends_on**: [p1]

#### subtasks

- [ ] **p2.1**: scripts/contract.sh 作成
  - executor: orchestrator
  - test_command: `bash -n scripts/contract.sh && echo PASS || echo FAIL`

- [ ] **p2.2**: playbook-guard.sh が contract.sh を呼ぶ形に変更
  - executor: orchestrator
  - test_command: `grep -q 'contract.sh' .claude/hooks/playbook-guard.sh && echo PASS || echo FAIL`

- [ ] **p2.3**: pre-bash-check.sh が contract.sh を呼ぶ形に変更
  - executor: orchestrator
  - test_command: `grep -q 'contract.sh' .claude/hooks/pre-bash-check.sh && echo PASS || echo FAIL`

**status**: pending
**max_iterations**: 5

---

### p3: E2E テスト実装

**goal**: シナリオ A/B/C を自動テストとして実装

**depends_on**: [p2]

#### subtasks

- [ ] **p3.1**: scripts/e2e-contract-test.sh 作成
  - executor: orchestrator
  - test_command: `test -f scripts/e2e-contract-test.sh && echo PASS || echo FAIL`

- [ ] **p3.2**: シナリオ A (playbook=null & non-admin) PASS
  - executor: orchestrator
  - test_command: `bash scripts/e2e-contract-test.sh scenario_a && echo PASS || echo FAIL`

- [ ] **p3.3**: シナリオ B (playbook=null & admin) PASS
  - executor: orchestrator
  - test_command: `bash scripts/e2e-contract-test.sh scenario_b && echo PASS || echo FAIL`

- [ ] **p3.4**: シナリオ C (playbook=active) PASS
  - executor: orchestrator
  - test_command: `bash scripts/e2e-contract-test.sh scenario_c && echo PASS || echo FAIL`

**status**: pending
**max_iterations**: 5

---

### p4: RUNBOOK 更新

**goal**: Golden Path と復旧手順を更新

**depends_on**: [p3]

#### subtasks

- [ ] **p4.1**: RUNBOOK.md に Admin Maintenance セクション追加
  - executor: orchestrator
  - test_command: `grep -q 'Maintenance' RUNBOOK.md && echo PASS || echo FAIL`

- [ ] **p4.2**: RUNBOOK.md に復旧手順（fail-closed 時）追加
  - executor: orchestrator
  - test_command: `grep -q 'fail-closed' RUNBOOK.md && echo PASS || echo FAIL`

**status**: pending
**max_iterations**: 3

---

### p_final: 完了検証

**goal**: 全ての done_when を満たす

**depends_on**: [p4]

#### subtasks

- [ ] **p_final.1**: 全 E2E テスト PASS
  - executor: orchestrator
  - test_command: `bash scripts/e2e-contract-test.sh all && echo PASS || echo FAIL`

- [ ] **p_final.2**: セッション終了処理がブロックされずに完了できる
  - executor: orchestrator
  - test_command: `bash scripts/e2e-contract-test.sh session_end && echo PASS || echo FAIL`

**status**: pending
**max_iterations**: 3

---

## exclusions

- CLAUDE.md の変更（既に M079 で Core Contract が追加済み）
- 新規 Hook の追加
- SubAgent の変更

---

## risks

| リスク | 影響度 | 対策 |
|--------|--------|------|
| 既存 Hook の動作破壊 | 高 | E2E テストで検証、問題発生時は即ロールバック |
| admin Maintenance が広すぎ | 中 | ホワイトリスト方式で厳密に制限 |
| scripts/ ディレクトリ未存在 | 低 | 作成時に mkdir |

---

## rollback

```bash
# Hook を復元
git checkout HEAD~1 -- .claude/hooks/

# scripts/ を削除
rm -rf scripts/

# state を復元
git checkout HEAD~1 -- state.md
```
