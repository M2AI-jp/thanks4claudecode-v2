# playbook-m079-golden-path-fix.md

> **Golden Path（pm 必須）を構造的に強制する修正**

---

## meta

```yaml
project: Golden Path 強制 - ボタンのかけ違い修正
branch: cleanup/architecture-audit
created: 2025-12-18
issue: null
derives_from: M079
reviewed: false
```

---

## goal

```yaml
summary: pm 必須の Golden Path を構造的に強制し、バイパス経路を封鎖する
done_when:
  - CLAUDE.md に Golden Path セクション（## 11）が追加されている
  - prompt-guard.sh の playbook=null 警告が pm 必須を明示している
  - playbook-guard.sh の admin バイパス（29-32行）が削除されている
  - pre-bash-check.sh が playbook=null で変更系 Bash をブロックする
  - 検証シナリオ 3 つが全て PASS する
  - check-integrity.sh が PASS する
```

---

## phases

### p1: CLAUDE.md に Golden Path セクション追加

**goal**: CLAUDE.md に ## 11. Golden Path セクションを追加し、pm 必須ルールを明文化

#### subtasks

- [ ] **p1.1**: CLAUDE.md に ## 11. Golden Path セクションが存在する
  - executor: orchestrator
  - test_command: `grep -q '## 11. Golden Path' CLAUDE.md && echo PASS || echo FAIL`
  - validations:
    - technical: "grep で Golden Path セクションが検出される"
    - consistency: "セクション番号が 10 の次（11）である"
    - completeness: "playbook.active=null 時の pm 呼び出しルールが含まれている"

- [ ] **p1.2**: Golden Path セクションに pm 呼び出し必須ルールが含まれている
  - executor: orchestrator
  - test_command: `grep -q "Task.*pm" CLAUDE.md && echo PASS || echo FAIL`
  - validations:
    - technical: "Task(subagent_type='pm') の記述がある"
    - consistency: "pm.md の記述と整合している"
    - completeness: "タスク開始時の必須アクションとして明記されている"

- [ ] **p1.3**: タスク要求インジケータ（やって/作って等）が列挙されている
  - executor: orchestrator
  - test_command: `grep -qE '(やって|作って|修正して)' CLAUDE.md && echo PASS || echo FAIL`
  - validations:
    - technical: "タスク要求パターンが記載されている"
    - consistency: "prompt-guard.sh の WORK_PATTERNS と整合"
    - completeness: "日本語・英語の主要パターンが含まれている"

- [ ] **p1.4**: Version History が更新されている
  - executor: orchestrator
  - test_command: `grep -q '1.1.0.*Golden Path' CLAUDE.md && echo PASS || echo FAIL`
  - validations:
    - technical: "Version History に 1.1.0 エントリがある"
    - consistency: "SemVer 規則に従っている"
    - completeness: "変更内容が記載されている"

**status**: pending
**max_iterations**: 5

---

### p2: prompt-guard.sh の警告強化

**goal**: playbook=null 時の警告メッセージを pm 必須明示に強化

**depends_on**: [p1]

#### subtasks

- [ ] **p2.1**: prompt-guard.sh の playbook=null 警告に pm 必須メッセージが含まれている
  - executor: orchestrator
  - test_command: `grep -qE 'pm.*必須|まず pm' .claude/hooks/prompt-guard.sh && echo PASS || echo FAIL`
  - validations:
    - technical: "grep でメッセージが検出される"
    - consistency: "CLAUDE.md の Golden Path セクションと整合"
    - completeness: "具体的なアクション（Task呼び出し）が案内されている"

- [ ] **p2.2**: 警告メッセージに Task(subagent_type='pm') の呼び出し例が含まれている
  - executor: orchestrator
  - test_command: `grep -q "Task.*pm.*playbook" .claude/hooks/prompt-guard.sh && echo PASS || echo FAIL`
  - validations:
    - technical: "呼び出し例が含まれている"
    - consistency: "pm.md の説明と整合"
    - completeness: "コピペで使用可能な形式である"

**status**: pending
**max_iterations**: 3

---

### p3: playbook-guard.sh の admin バイパス削除

**goal**: playbook-guard.sh から admin モードでの全バイパスを削除

**depends_on**: [p2]

#### subtasks

- [ ] **p3.1**: playbook-guard.sh の 29-32 行（admin バイパス）が削除されている
  - executor: orchestrator
  - test_command: `! grep -qE 'SECURITY.*admin.*exit 0' .claude/hooks/playbook-guard.sh && echo PASS || echo FAIL`
  - validations:
    - technical: "admin バイパスのパターンが存在しない"
    - consistency: "admin でも playbook 必須になる"
    - completeness: "関連コメントも削除されている"

- [ ] **p3.2**: playbook-guard.sh が bash -n で構文エラーなし
  - executor: orchestrator
  - test_command: `bash -n .claude/hooks/playbook-guard.sh && echo PASS || echo FAIL`
  - validations:
    - technical: "構文エラーがない"
    - consistency: "他の Hook と同じコーディング規約"
    - completeness: "全ての分岐が正常に動作する"

**status**: pending
**max_iterations**: 3

---

### p4: pre-bash-check.sh に playbook=null 変更系ブロック追加

**goal**: playbook=null の場合、変更系 Bash コマンドをブロックする

**depends_on**: [p3]

#### subtasks

- [ ] **p4.1**: pre-bash-check.sh に playbook=null チェックロジックが追加されている
  - executor: orchestrator
  - test_command: `grep -q 'playbook.*null' .claude/hooks/pre-bash-check.sh && echo PASS || echo FAIL`
  - validations:
    - technical: "playbook チェックロジックが存在する"
    - consistency: "state.md の構造と整合"
    - completeness: "null と空文字の両方をチェック"

- [ ] **p4.2**: 変更系 Bash パターン（>, >>, tee, cat >, sed -i, mv, cp, rm, mkdir, touch）がブロック対象に含まれている
  - executor: orchestrator
  - test_command: `grep -qE '(tee|cat.*>|sed -i|mv|cp|rm|mkdir|touch)' .claude/hooks/pre-bash-check.sh && echo PASS || echo FAIL`
  - validations:
    - technical: "変更系パターンが検出対象に含まれている"
    - consistency: "既存の WRITE_PATTERNS と整合"
    - completeness: "主要な変更系コマンドが網羅されている"

- [ ] **p4.3**: git add/commit も playbook=null でブロックされる
  - executor: orchestrator
  - test_command: `grep -qE 'git.*(add|commit)' .claude/hooks/pre-bash-check.sh && echo PASS || echo FAIL`
  - validations:
    - technical: "git 操作がチェック対象に含まれている"
    - consistency: "CLAUDE.md の Git Workflow と整合"
    - completeness: "add と commit の両方が対象"

- [ ] **p4.4**: pre-bash-check.sh が bash -n で構文エラーなし
  - executor: orchestrator
  - test_command: `bash -n .claude/hooks/pre-bash-check.sh && echo PASS || echo FAIL`
  - validations:
    - technical: "構文エラーがない"
    - consistency: "他の Hook と同じコーディング規約"
    - completeness: "全ての分岐が正常に動作する"

- [ ] **p4.5**: admin モードでも playbook チェックは維持される（バイパスしない）
  - executor: orchestrator
  - test_command: `! grep -qE 'admin.*exit 0.*# playbook' .claude/hooks/pre-bash-check.sh && echo PASS || echo FAIL`
  - validations:
    - technical: "admin による playbook チェック回避がない"
    - consistency: "playbook-guard.sh と同じ方針"
    - completeness: "admin は HARD_BLOCK のみバイパス可能"

**status**: pending
**max_iterations**: 5

---

### p5: 検証シナリオ実行

**goal**: 3 つの検証シナリオが全て PASS することを確認

**depends_on**: [p4]

#### subtasks

- [ ] **p5.1**: シナリオ1 - 自然文でのタスク要求時に pm 呼び出しルールが CLAUDE.md に存在する
  - executor: orchestrator
  - test_command: `grep -qE 'playbook.*null.*pm' CLAUDE.md && echo PASS || echo FAIL`
  - validations:
    - technical: "ルールが記載されている"
    - consistency: "pm.md の記述と整合"
    - completeness: "具体的なアクションが明示されている"

- [ ] **p5.2**: シナリオ2 - playbook=null で `cat > docs/x.md` 相当のコマンドがブロックされるロジックが存在する
  - executor: orchestrator
  - test_command: `grep -qE 'PLAYBOOK.*null.*cat.*>' .claude/hooks/pre-bash-check.sh && echo PASS || echo FAIL`
  - validations:
    - technical: "ブロックロジックが存在する"
    - consistency: "playbook-guard.sh と同じブロック基準"
    - completeness: "エラーメッセージが含まれている"

- [ ] **p5.3**: シナリオ3 - admin モードでも playbook-guard の playbook 必須チェックが維持される
  - executor: orchestrator
  - test_command: `! grep -qE 'admin.*exit 0' .claude/hooks/playbook-guard.sh && echo PASS || echo FAIL`
  - validations:
    - technical: "admin バイパスが削除されている"
    - consistency: "Golden Path ルールと整合"
    - completeness: "pm 経由が必須になっている"

**status**: pending
**max_iterations**: 3

---

### p_final: 完了検証（必須）

**goal**: playbook の done_when が全て満たされているか最終検証

**depends_on**: [p5]

#### subtasks

- [ ] **p_final.1**: CLAUDE.md に Golden Path セクション（## 11）が追加されている
  - executor: orchestrator
  - test_command: `grep -q '## 11. Golden Path' CLAUDE.md && grep -q 'pm' CLAUDE.md && echo PASS || echo FAIL`
  - validations:
    - technical: "セクションが存在し、pm への言及がある"
    - consistency: "CLAUDE.md の構造と整合"
    - completeness: "必要な内容が全て含まれている"

- [ ] **p_final.2**: prompt-guard.sh の playbook=null 警告が pm 必須を明示している
  - executor: orchestrator
  - test_command: `grep -qE 'pm.*必須|まず pm' .claude/hooks/prompt-guard.sh && echo PASS || echo FAIL`
  - validations:
    - technical: "メッセージが存在する"
    - consistency: "CLAUDE.md と整合"
    - completeness: "具体的な対処法が案内されている"

- [ ] **p_final.3**: playbook-guard.sh の admin バイパス（29-32行）が削除されている
  - executor: orchestrator
  - test_command: `! grep -qE 'SECURITY.*admin.*exit 0' .claude/hooks/playbook-guard.sh && echo PASS || echo FAIL`
  - validations:
    - technical: "パターンが存在しない"
    - consistency: "Golden Path ルールと整合"
    - completeness: "関連コードも削除されている"

- [ ] **p_final.4**: pre-bash-check.sh が playbook=null で変更系 Bash をブロックする
  - executor: orchestrator
  - test_command: `grep -qE 'PLAYBOOK.*null' .claude/hooks/pre-bash-check.sh && grep -qE 'exit 2' .claude/hooks/pre-bash-check.sh && echo PASS || echo FAIL`
  - validations:
    - technical: "チェックロジックとブロック処理が存在する"
    - consistency: "playbook-guard.sh と同じ方針"
    - completeness: "変更系パターンが網羅されている"

- [ ] **p_final.5**: 全スクリプトが bash -n で構文エラーなし
  - executor: orchestrator
  - test_command: `bash -n .claude/hooks/playbook-guard.sh && bash -n .claude/hooks/pre-bash-check.sh && echo PASS || echo FAIL`
  - validations:
    - technical: "構文エラーがない"
    - consistency: "既存の Hook と同じ品質"
    - completeness: "全ての変更対象スクリプトが検証済み"

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

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-18 | 初版作成 |
