# playbook-m083-state-sync-fix.md

> **緊急: 状態同期とガード機能の修正**
>
> M082 完了後に発見された 3 つの問題を修正する。

---

## meta

```yaml
project: thanks4claudecode
branch: feat/m083-state-sync-fix
created: 2025-12-19
issue: null
derives_from: M083
reviewed: true
roles:
  worker: claudecode
```

---

## goal

```yaml
summary: project.md 自動更新、用語統一、consent-guard の 3 つの問題を修正する
done_when:
  - playbook 完了時に project.md の対応 milestone が status: achieved に自動更新される仕組みが存在する
  - done_when と done_criteria の用語が統一されている（done_when に統一）
  - consent-guard.sh が consent ファイル存在時に [理解確認] ブロックを表示してブロックする
```

---

## phases

### p1: 問題1 - project.md 自動更新の実装

**goal**: playbook 完了時に project.md の対応 milestone を自動更新する仕組みを追加

#### subtasks

- [ ] **p1.1**: archive-playbook.sh に project.md 更新ロジックが追加されている
  - executor: claudecode
  - test_command: `grep -q 'project.md' .claude/hooks/archive-playbook.sh && echo PASS || echo FAIL`
  - validations:
    - technical: "project.md 更新コードが存在する"
    - consistency: "アーカイブ処理と連動している"
    - completeness: "derives_from を参照して milestone を特定する"

- [ ] **p1.2**: archive-playbook.sh が playbook の derives_from を読み取り、対応する milestone を特定できる
  - executor: claudecode
  - test_command: `grep -q 'derives_from' .claude/hooks/archive-playbook.sh && echo PASS || echo FAIL`
  - validations:
    - technical: "derives_from の読み取りロジックが存在"
    - consistency: "playbook meta セクションを正しくパースする"
    - completeness: "milestone ID を正確に取得できる"

- [ ] **p1.3**: archive-playbook.sh が project.md の該当 milestone の status を achieved に更新できる
  - executor: claudecode
  - test_command: `grep -qE 'status.*achieved|achieved.*status' .claude/hooks/archive-playbook.sh && echo PASS || echo FAIL`
  - validations:
    - technical: "status 更新ロジックが存在"
    - consistency: "sed/awk で正しく置換される"
    - completeness: "achieved_at も同時に更新される"

- [ ] **p1.4**: M082 の status が achieved に更新されている
  - executor: claudecode
  - test_command: `grep -A5 'id: M082' plan/project.md | grep -q 'status: achieved' && echo PASS || echo FAIL`
  - validations:
    - technical: "M082 が achieved になっている"
    - consistency: "project.md が正しく更新されている"
    - completeness: "achieved_at も設定されている"

**status**: pending
**max_iterations**: 5

---

### p2: 問題2 - 用語統一（done_when/done_criteria）

**goal**: done_when と done_criteria の用語を統一する

**depends_on**: [p1]

#### subtasks

- [ ] **p2.1**: 影響範囲を調査し、tmp/term-unification-report.md に記録されている
  - executor: claudecode
  - test_command: `test -f tmp/term-unification-report.md && echo PASS || echo FAIL`
  - validations:
    - technical: "レポートファイルが存在する"
    - consistency: "全ての影響ファイルがリストされている"
    - completeness: "done_when/done_criteria の使用箇所が網羅されている"

- [ ] **p2.2**: 統一方針が決定されている（done_when に統一推奨）
  - executor: claudecode
  - test_command: `grep -q '統一方針' tmp/term-unification-report.md && echo PASS || echo FAIL`
  - scope: |
      変更対象: state.md, .claude/hooks/*.sh（アクティブファイルのみ）
      変更対象外: plan/archive/*, .claude/frameworks/*（履歴・メタドキュメントは保持）
  - validations:
    - technical: "方針が明記されている"
    - consistency: "既存の仕様との整合性が考慮されている"
    - completeness: "影響範囲と移行手順が記載されている、変更対象ファイルが明示されている"

- [ ] **p2.3**: state.md の done_criteria が done_when に変更されている
  - executor: claudecode
  - test_command: `grep -q 'done_when:' state.md && ! grep -q 'done_criteria:' state.md && echo PASS || echo FAIL`
  - validations:
    - technical: "state.md が更新されている"
    - consistency: "playbook と同じ用語を使用"
    - completeness: "セクション名と値が正しい"

- [ ] **p2.4**: archive-playbook.sh が done_when を正しく参照している
  - executor: claudecode
  - test_command: `grep -q 'done_when' .claude/hooks/archive-playbook.sh && echo PASS || echo FAIL`
  - validations:
    - technical: "done_when を参照している"
    - consistency: "playbook との整合性がある"
    - completeness: "パース処理が正しい"

- [ ] **p2.5**: 関連する全ての Hook/SubAgent/Skill が統一された用語を使用している
  - executor: claudecode
  - test_command: `! grep -r 'done_criteria' .claude/hooks/*.sh 2>/dev/null && echo PASS || echo FAIL`
  - validations:
    - technical: "Hook に done_criteria が残っていない"
    - consistency: "全コンポーネントで統一"
    - completeness: "検索で見つからない"

**status**: pending
**max_iterations**: 5

---

### p3: 問題3 - consent-guard.sh の動作修正

**goal**: consent-guard.sh が consent ファイル存在時に正しくブロックする

**depends_on**: [p1]

#### subtasks

- [ ] **p3.1**: consent-guard.sh の問題点を調査し特定されている
  - executor: claudecode
  - test_command: `test -f tmp/consent-guard-analysis.md && echo PASS || echo FAIL`
  - validations:
    - technical: "分析レポートが存在する"
    - consistency: "session-start.sh との連携が確認されている"
    - completeness: "問題の根本原因が特定されている"

- [ ] **p3.2**: consent ファイル存在時に consent-guard.sh が exit 2 を返す
  - executor: claudecode
  - test_command: `mkdir -p .claude/.session-init && touch .claude/.session-init/consent && (bash .claude/hooks/consent-guard.sh < /dev/null 2>&1; exit_code=$?; rm -f .claude/.session-init/consent; [ $exit_code -eq 2 ]) && echo PASS || echo FAIL`
  - validations:
    - technical: "exit 2 でブロックする"
    - consistency: "BLOCK 契約に準拠"
    - completeness: "[理解確認] メッセージが表示される"

- [ ] **p3.3**: consent ファイル不存在時に consent-guard.sh が exit 0 を返す
  - executor: claudecode
  - test_command: `rm -f .claude/.session-init/consent && (bash .claude/hooks/consent-guard.sh < /dev/null 2>&1; [ $? -eq 0 ]) && echo PASS || echo FAIL`
  - validations:
    - technical: "exit 0 で通過する"
    - consistency: "通常フローが妨げられない"
    - completeness: "問題なく動作する"

- [ ] **p3.4**: session-start.sh が適切なタイミングで consent ファイルを作成している
  - executor: claudecode
  - test_command: `grep -q 'consent' .claude/hooks/session-start.sh && echo PASS || echo FAIL`
  - validations:
    - technical: "consent 作成ロジックが存在"
    - consistency: "条件が適切（playbook=null 時のみ）"
    - completeness: "フローが完全"

**status**: pending
**max_iterations**: 5

---

### p_final: 完了検証

**goal**: playbook の done_when が全て満たされているか最終検証

**depends_on**: [p1, p2, p3]

#### subtasks

- [ ] **p_final.1**: playbook 完了時に project.md の対応 milestone が自動更新される仕組みが存在する
  - executor: claudecode
  - test_command: `grep -q 'project.md' .claude/hooks/archive-playbook.sh && grep -q 'derives_from' .claude/hooks/archive-playbook.sh && grep -qE 'status.*achieved' .claude/hooks/archive-playbook.sh && echo PASS || echo FAIL`
  - validations:
    - technical: "archive-playbook.sh に更新ロジックが存在"
    - consistency: "derives_from を参照して milestone を特定"
    - completeness: "status と achieved_at が更新される"

- [ ] **p_final.2**: done_when と done_criteria の用語が統一されている
  - executor: claudecode
  - test_command: `grep -q 'done_when:' state.md && ! grep -q 'done_criteria:' state.md && echo PASS || echo FAIL`
  - validations:
    - technical: "state.md が done_when を使用"
    - consistency: "playbook と同じ用語"
    - completeness: "全ファイルで統一"

- [ ] **p_final.3**: consent-guard.sh が consent ファイル存在時に正しくブロックする
  - executor: claudecode
  - test_command: `mkdir -p .claude/.session-init && touch .claude/.session-init/consent && (echo '{"tool_name":"Edit"}' | bash .claude/hooks/consent-guard.sh 2>&1; exit_code=$?; rm -f .claude/.session-init/consent; [ $exit_code -eq 2 ]) && echo PASS || echo FAIL`
  - validations:
    - technical: "Edit ツールで exit 2 を返す"
    - consistency: "BLOCK 契約に準拠"
    - completeness: "[理解確認] メッセージが表示される"

**status**: pending
**max_iterations**: 3

---

## final_tasks

- [ ] **ft1**: M082 の status を achieved に手動更新する（自動更新機能実装前のため）
  - command: `sed -i '' '/id: M082/,/^- id:/ s/status: .*/status: achieved/' plan/project.md`
  - note: M082 ブロック内の status のみを変更（他の milestone に影響しない）
  - status: pending

- [ ] **ft2**: repository-map.yaml を更新する
  - command: `bash .claude/hooks/generate-repository-map.sh`
  - status: pending

- [ ] **ft3**: tmp/ 内の一時ファイルを削除する
  - command: `find tmp/ -type f ! -name 'README.md' -delete 2>/dev/null || true`
  - status: pending

- [ ] **ft4**: 変更を全てコミットする
  - command: `git add -A && git status`
  - status: pending

---

## rollback

問題発生時の復元手順:

```bash
# 1. archive-playbook.sh を復元
git checkout HEAD -- .claude/hooks/archive-playbook.sh

# 2. consent-guard.sh を復元
git checkout HEAD -- .claude/hooks/consent-guard.sh

# 3. state.md を復元
git checkout HEAD -- state.md

# 4. session-start.sh を復元（変更した場合）
git checkout HEAD -- .claude/hooks/session-start.sh
```

バックアップ戦略:
- 変更前に `git stash` でバックアップ
- テスト失敗時は即座に `git checkout HEAD --` で revert
- 各 Phase 完了後にコミットを作成し、ロールバックポイントを確保

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-19 | Reviewer 指摘対応: rollback セクション追加、p2.5 test_command 修正、スコープ明確化 |
| 2025-12-19 | 初版作成。M082 完了後に発見された 3 つの問題を修正。 |
