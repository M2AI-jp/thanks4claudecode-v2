# playbook-m079-golden-path-fix.md

> **Golden Path（pm 必須）を構造的に強制 + コア契約凍結 + admin権限再定義**

---

## meta

```yaml
project: Golden Path 強制 - コア契約 + admin権限境界
branch: cleanup/architecture-audit
created: 2025-12-18
issue: null
derives_from: M079
reviewed: true
```

---

## goal

```yaml
summary: |
  コア機能（Golden Path, Playbook Gate, Reviewer Gate）を Contract として凍結し、
  admin モードでも絶対に回避できない権限境界を実装する
done_when:
  - CLAUDE.md に Core Contract セクション（## 11）が追加されている
  - CLAUDE.md に Admin Mode Contract セクション（## 12）が追加されている
  - prompt-guard.sh の playbook=null 警告が pm 強制メッセージになっている
  - playbook-guard.sh の admin 全バイパス（29-32行）が削除されている
  - consent-guard.sh の admin 全バイパスが削除されている
  - executor-guard.sh の admin 全バイパスが削除されている
  - pre-bash-check.sh が playbook=null で変更系 Bash をブロックし、HARD_BLOCKは admin でも回避不可
  - check-protected-edit.sh の HARD_BLOCK が admin でも回避不可
  - 検証シナリオ 5 つが全て PASS する
  - check-integrity.sh が PASS する

spec:
  core_contract: |
    ## 11. Core Contract

    以下のルールは admin モードでも回避不可の絶対ルール:

    1. **Golden Path**: タスク依頼を受けたら、返答を始める前に pm を呼ぶ
       - playbook=null の場合: Task(subagent_type='pm') を実行
       - 直接 Edit/Write してはいけない

    2. **Playbook Gate**: playbook 必須
       - state.md の playbook.active が null の場合、Edit/Write をブロック
       - Bash による変更系コマンドも同様にブロック

    3. **Reviewer Gate**: レビュー推奨
       - reviewed: false の playbook には警告を表示
       - playbook 確定前に reviewer による検証を推奨

  admin_contract: |
    ## 12. Admin Mode Contract

    admin モードの権限境界:

    - admin は「バイパス」ではない。コア契約は admin でも回避不可
    - admin でも回避不可:
      - Golden Path（pm 必須）
      - Playbook Gate（playbook=null での Edit/Write/Bash 変更系）
      - HARD_BLOCK ファイル保護
    - admin が緩和できるもの:
      - BLOCK レベルの保護（→ WARN に緩和）
      - 必須ファイル Read チェック（init-guard）
```

---

## phases

### p1: CLAUDE.md に Core Contract + Admin Mode Contract 追加

**goal**: CLAUDE.md に ## 11. Core Contract と ## 12. Admin Mode Contract を追加し、コア機能を凍結

#### subtasks

- [ ] **p1.1**: CLAUDE.md に ## 11. Core Contract セクションが存在する
  - executor: orchestrator
  - test_command: `grep -q '## 11. Core Contract' CLAUDE.md && echo PASS || echo FAIL`

- [ ] **p1.2**: Core Contract に Golden Path ルールが含まれている
  - executor: orchestrator
  - test_command: `grep -qE 'Golden Path|pm.*必須|Task.*pm' CLAUDE.md && echo PASS || echo FAIL`

- [ ] **p1.3**: Core Contract に Playbook Gate ルールが含まれている
  - executor: orchestrator
  - test_command: `grep -qE 'Playbook Gate|playbook.*必須' CLAUDE.md && echo PASS || echo FAIL`

- [ ] **p1.4**: Core Contract に Reviewer Gate ルールが含まれている
  - executor: orchestrator
  - test_command: `grep -qE 'Reviewer Gate|reviewer.*PASS' CLAUDE.md && echo PASS || echo FAIL`

- [ ] **p1.5**: CLAUDE.md に ## 12. Admin Mode Contract セクションが存在する
  - executor: orchestrator
  - test_command: `grep -q '## 12. Admin Mode Contract' CLAUDE.md && echo PASS || echo FAIL`

- [ ] **p1.6**: Admin Mode Contract で「コア契約は回避不可」が明記されている
  - executor: orchestrator
  - test_command: `grep -qE 'admin.*回避.*不可|admin.*bypass.*禁止' CLAUDE.md && echo PASS || echo FAIL`

- [ ] **p1.7**: Version History が 1.1.0 に更新されている
  - executor: orchestrator
  - test_command: `grep -q '1.1.0' CLAUDE.md && echo PASS || echo FAIL`

**status**: pending
**max_iterations**: 5

---

### p2: prompt-guard.sh を pm 強制に強化

**goal**: playbook=null 時に「まず pm を呼べ」という強制メッセージを出す

**depends_on**: [p1]

#### subtasks

- [ ] **p2.1**: playbook=null 時のメッセージが pm 呼び出し強制になっている
  - executor: orchestrator
  - test_command: `grep -qE 'まず.*pm|pm.*呼.*必須' .claude/hooks/prompt-guard.sh && echo PASS || echo FAIL`

- [ ] **p2.2**: Task(subagent_type='pm') の呼び出し例が含まれている
  - executor: orchestrator
  - test_command: `grep -q "Task.*subagent_type.*pm" .claude/hooks/prompt-guard.sh && echo PASS || echo FAIL`

- [ ] **p2.3**: 返答開始禁止の強い文言が含まれている
  - executor: orchestrator
  - test_command: `grep -qE '返答.*禁止|返答.*始め.*いけない' .claude/hooks/prompt-guard.sh && echo PASS || echo FAIL`

**status**: pending
**max_iterations**: 3

---

### p3: 全ガードの admin 全バイパスを削除

**goal**: playbook-guard, consent-guard, executor-guard の admin 全バイパスを削除

**depends_on**: [p2]

#### subtasks

- [ ] **p3.1**: playbook-guard.sh の admin 全バイパス（29-32行）が削除されている
  - executor: orchestrator
  - test_command: `! grep -B2 'exit 0' .claude/hooks/playbook-guard.sh | head -40 | grep -q 'admin' && echo PASS || echo FAIL`

- [ ] **p3.2**: consent-guard.sh の admin 全バイパス（37-40行）が削除されている
  - executor: orchestrator
  - test_command: `! grep -B2 'exit 0' .claude/hooks/consent-guard.sh | head -50 | grep -q 'admin' && echo PASS || echo FAIL`

- [ ] **p3.3**: executor-guard.sh の admin 全バイパス（26-28行）が削除されている
  - executor: orchestrator
  - test_command: `! grep -B2 'exit 0' .claude/hooks/executor-guard.sh | head -40 | grep -q 'admin' && echo PASS || echo FAIL`

- [ ] **p3.4**: 削除後も全ガードが bash -n で構文エラーなし
  - executor: orchestrator
  - test_command: `bash -n .claude/hooks/playbook-guard.sh && bash -n .claude/hooks/consent-guard.sh && bash -n .claude/hooks/executor-guard.sh && echo PASS || echo FAIL`

**status**: pending
**max_iterations**: 3

---

### p4: pre-bash-check.sh 強化（playbook=null + HARD_BLOCK保護）

**goal**: playbook=null で変更系 Bash をブロック + HARD_BLOCK は admin でも回避不可

**depends_on**: [p3]

#### subtasks

- [ ] **p4.1**: admin 全バイパス（25-28行）を削除し、HARD_BLOCK チェックは維持
  - executor: orchestrator
  - test_command: `! head -35 .claude/hooks/pre-bash-check.sh | grep -qE 'admin.*exit 0' && echo PASS || echo FAIL`

- [ ] **p4.2**: playbook=null チェックロジックが追加されている
  - executor: orchestrator
  - test_command: `grep -qE 'PLAYBOOK.*null|playbook.*null' .claude/hooks/pre-bash-check.sh && echo PASS || echo FAIL`

- [ ] **p4.3**: 変更系 Bash パターンが playbook=null でブロックされる
  - executor: orchestrator
  - test_command: `grep -qE 'cat.*>|tee|sed -i|git.*(add|commit)' .claude/hooks/pre-bash-check.sh && echo PASS || echo FAIL`

- [ ] **p4.4**: bash -n で構文エラーなし
  - executor: orchestrator
  - test_command: `bash -n .claude/hooks/pre-bash-check.sh && echo PASS || echo FAIL`

**status**: pending
**max_iterations**: 5

---

### p5: check-protected-edit.sh 強化（HARD_BLOCK は admin でも回避不可）

**goal**: check-protected-edit.sh の HARD_BLOCK 保護を admin でも回避不可にする

**depends_on**: [p4]

#### subtasks

- [ ] **p5.1**: HARD_BLOCK 処理（82-86行付近）で admin 回避を削除
  - executor: orchestrator
  - test_command: `! grep -B5 'HARD_BLOCK' .claude/hooks/check-protected-edit.sh | grep -qE 'admin.*exit 0' && echo PASS || echo FAIL`

- [ ] **p5.2**: bash -n で構文エラーなし
  - executor: orchestrator
  - test_command: `bash -n .claude/hooks/check-protected-edit.sh && echo PASS || echo FAIL`

**status**: pending
**max_iterations**: 3

---

### p6: 検証シナリオ実行（5つ）

**goal**: 5つの検証シナリオが全て PASS することを確認

**depends_on**: [p5]

#### subtasks

- [ ] **p6.1**: シナリオA - Core Contract が CLAUDE.md に存在する
  - executor: orchestrator
  - test_command: `grep -q '## 11. Core Contract' CLAUDE.md && grep -q '## 12. Admin Mode Contract' CLAUDE.md && echo PASS || echo FAIL`

- [ ] **p6.2**: シナリオB - 全ガードで admin 全バイパスが削除されている
  - executor: orchestrator
  - test_command: `for f in playbook-guard consent-guard executor-guard; do head -50 .claude/hooks/$f.sh | grep -B2 'exit 0' | grep -q 'admin' && exit 1; done && echo PASS || echo FAIL`

- [ ] **p6.3**: シナリオC - pre-bash-check で playbook=null チェックが存在する
  - executor: orchestrator
  - test_command: `grep -qE 'PLAYBOOK.*null|playbook.*null' .claude/hooks/pre-bash-check.sh && echo PASS || echo FAIL`

- [ ] **p6.4**: シナリオD - HARD_BLOCK は admin でも回避不可
  - executor: orchestrator
  - test_command: `! grep -B10 'IS_HARD_BLOCK=true' .claude/hooks/check-protected-edit.sh | grep -qE 'admin.*exit 0' && echo PASS || echo FAIL`

- [ ] **p6.5**: シナリオE - check-integrity.sh が PASS
  - executor: orchestrator
  - test_command: `bash .claude/hooks/check-integrity.sh && echo PASS || echo FAIL`

**status**: pending
**max_iterations**: 3

---

### p_final: 完了検証（必須）

**goal**: playbook の done_when が全て満たされているか最終検証

**depends_on**: [p6]

#### subtasks

- [ ] **p_final.1**: CLAUDE.md に Core Contract + Admin Mode Contract が追加されている
  - executor: orchestrator
  - test_command: `grep -q '## 11. Core Contract' CLAUDE.md && grep -q '## 12. Admin Mode Contract' CLAUDE.md && echo PASS || echo FAIL`

- [ ] **p_final.2**: prompt-guard.sh が pm 強制メッセージを出す
  - executor: orchestrator
  - test_command: `grep -qE 'まず.*pm|pm.*必須' .claude/hooks/prompt-guard.sh && echo PASS || echo FAIL`

- [ ] **p_final.3**: 全ガードで admin 全バイパスが削除されている
  - executor: orchestrator
  - test_command: `for f in playbook-guard consent-guard executor-guard pre-bash-check; do head -50 .claude/hooks/$f.sh | grep -B2 'exit 0' | grep -q 'admin' && exit 1; done && echo PASS || echo FAIL`

- [ ] **p_final.4**: HARD_BLOCK は admin でも回避不可
  - executor: orchestrator
  - test_command: `! grep -B10 'IS_HARD_BLOCK=true' .claude/hooks/check-protected-edit.sh | grep -qE 'admin.*exit 0' && echo PASS || echo FAIL`

- [ ] **p_final.5**: 全スクリプトが bash -n で構文エラーなし
  - executor: orchestrator
  - test_command: `for f in .claude/hooks/playbook-guard.sh .claude/hooks/consent-guard.sh .claude/hooks/executor-guard.sh .claude/hooks/pre-bash-check.sh .claude/hooks/check-protected-edit.sh .claude/hooks/prompt-guard.sh; do bash -n "$f" || exit 1; done && echo PASS || echo FAIL`

- [ ] **p_final.6**: check-integrity.sh が PASS
  - executor: orchestrator
  - test_command: `bash .claude/hooks/check-integrity.sh && echo PASS || echo FAIL`

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

---

## exclusions

以下は変更対象外:
- .claude/hooks/session-start.sh
- .claude/hooks/role-resolver.sh
- .claude/hooks/failure-logger.sh
- .claude/hooks/check-coherence.sh
- .claude/hooks/check-state-update.sh
- .claude/hooks/check-integrity.sh
- .claude/settings.json
- init-guard.sh（admin の必須 Read バイパスは維持）

---

## risks

| リスク | 影響度 | 対策 |
|--------|--------|------|
| admin バイパス削除による開発影響 | 高 | CLAUDE.md 編集が必要な場合は手動編集または protected-files.txt から一時削除 |
| テスト不足による本番障害 | 中 | p6 の検証シナリオで網羅テスト |
| Hook 変更による予期せぬブロック | 中 | 段階的にテスト、問題発生時は即ロールバック |

---

## rollback

問題発生時の手順:
1. `git stash` で現在の変更を退避
2. `git checkout .claude/hooks/` で hooks を復元
3. `git checkout CLAUDE.md` で CLAUDE.md を復元
4. `git stash pop` で退避した変更を戻す（必要に応じて）

緊急時:
```bash
git checkout HEAD~1 -- .claude/hooks/
```

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-18 | 初版作成 |
| 2025-12-18 | reviewer フィードバック反映: spec追加、test_command修正、risks/rollback追加 |
