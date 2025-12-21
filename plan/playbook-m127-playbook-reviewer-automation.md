# playbook-m127-playbook-reviewer-automation.md

> **pm が playbook 作成後、reviewer SubAgent を自動起動し、Codex 経由でレビューする仕組みを構築**

---

## meta

```yaml
schema_version: v2
project: M127 - Playbook Reviewer 動線の自動化
branch: feat/m127-playbook-reviewer-automation
created: 2025-12-21
issue: null
derives_from: M127
reviewed: true
roles:
  worker: claudecode  # .claude/agents/reviewer.md の修正

user_prompt_original: |
  M127 playbook を作成してください。

  ## マイルストーン: M127 Playbook Reviewer 動線の自動化

  ### 背景（M126 Codex 手動レビュー体験から）
  - `codex exec --full-auto` で playbook レビューが可能
  - 5 ラウンドのレビューサイクルで test_command の堅牢化を学習
  - 「レビューなしの実装は何もしないよりタチが悪い」

  ### 目的
  1. pm が playbook 作成後、自動的に reviewer SubAgent を起動
  2. reviewer が config.roles.reviewer に基づいて Codex/ClaudeCode を選択
  3. Codex の場合、`codex exec --full-auto` を実行し RESULT: PASS/FAIL をパース
  4. FAIL なら修正サイクル、PASS なら reviewed: true に更新

  ### 学習した test_command 設計原則
  - exit code で成功/失敗を判定可能にする（`|| { echo FAIL; exit 1; }`）
  - 存在チェックは `test -f` で明示的に行う
  - grep の否定は反転ロジックを使う（`! grep` を避ける）
  - done_when は具体的なファイル名/固定数を明記する

  ### done_criteria（project.md より）
  - reviewer SubAgent が config.roles.reviewer を読んで分岐できる
  - codex の場合、codex exec --full-auto を Bash で実行できる
  - RESULT: PASS/FAIL をパースして reviewed: true/false を更新できる
  - FAIL 時に修正提案を返却できる

  ### roles
  - worker: claudecode（.claude/agents/reviewer.md の修正）
  - reviewer: codex
```

---

## goal

```yaml
summary: pm が playbook 作成後に reviewer を自動起動し、worker に応じて Codex/ClaudeCode で自動レビューする仕組みを構築
done_when:
  - reviewer SubAgent が playbook.meta.roles.worker を読んで分岐できる（worker=codex → Claude レビュー、worker=claudecode → Codex レビュー）
  - codex レビューの場合、codex exec --full-auto を Bash で実行できる
  - RESULT: PASS/FAIL をパースして reviewed: true/false を更新できる
  - FAIL 時に修正提案を返却できる
```

---

## phases

### p1: reviewer SubAgent の roles.worker 分岐機能追加

**goal**: reviewer.md を修正し、playbook.meta.roles.worker を読んで処理を分岐する（worker=codex → Claude レビュー、worker=claudecode → Codex レビュー）

#### subtasks

- [ ] **p1.1**: .claude/agents/reviewer.md に playbook.meta.roles.worker 参照セクションが存在する
  - executor: claudecode
  - test_command: `grep -q 'roles.worker' .claude/agents/reviewer.md && echo PASS || echo FAIL`
  - validations:
    - technical: "grep で該当セクションが存在することを確認"
    - consistency: "playbook の meta.roles 構造と整合"
    - completeness: "worker=codex と worker=claudecode 両方のパスが記述されている"

- [ ] **p1.2**: reviewer.md に「worker=codex → Claude レビュー」「worker=claudecode → Codex レビュー」のロジックが明記されている
  - executor: claudecode
  - test_command: `grep -q 'worker.*codex.*Claude\|codex.*worker.*Claude' .claude/agents/reviewer.md && grep -q 'worker.*claudecode.*Codex\|claudecode.*worker.*Codex' .claude/agents/reviewer.md && echo PASS || echo FAIL`
  - validations:
    - technical: "分岐ロジックが存在することを grep で確認"
    - consistency: "作業者と異なる AI がレビューする原則"
    - completeness: "両方の分岐パスが具体的な手順付きで記述されている"

**status**: pending
**max_iterations**: 5

---

### p2: Codex exec コマンド実行機能の実装

**goal**: codex の場合に codex exec --full-auto を Bash で実行する手順を reviewer.md に追加

**depends_on**: [p1]

#### subtasks

- [ ] **p2.1**: reviewer.md に codex exec --full-auto の実行手順が記載されている
  - executor: claudecode
  - test_command: `grep -q 'codex exec --full-auto' .claude/agents/reviewer.md && echo PASS || echo FAIL`
  - validations:
    - technical: "codex exec コマンドの記述が存在する"
    - consistency: "Codex CLI の実際のオプションと整合"
    - completeness: "タイムアウト設定やエラーハンドリングも記載"

- [ ] **p2.2**: reviewer.md に playbook レビュー用のプロンプトテンプレートが存在する
  - executor: claudecode
  - test_command: `grep -q 'playbook-review-criteria.md' .claude/agents/reviewer.md && echo PASS || echo FAIL`
  - validations:
    - technical: "プロンプトテンプレートが存在する"
    - consistency: ".claude/frameworks/playbook-review-criteria.md を参照している"
    - completeness: "Codex に渡す具体的なプロンプト形式が定義されている"

**status**: pending
**max_iterations**: 5

---

### p3: RESULT パース機能の実装

**goal**: Codex 出力から RESULT: PASS/FAIL をパースし、playbook の reviewed フィールドを更新する

**depends_on**: [p2]

#### subtasks

- [ ] **p3.1**: reviewer.md に RESULT: PASS/FAIL のパース手順が記載されている
  - executor: claudecode
  - test_command: `grep -qE 'RESULT.*PASS|PASS.*FAIL' .claude/agents/reviewer.md && echo PASS || echo FAIL`
  - validations:
    - technical: "パースロジックの記述が存在する"
    - consistency: "playbook-review-criteria.md の出力フォーマットと整合"
    - completeness: "PASS/FAIL 両方のケースが記述されている"

- [ ] **p3.2**: reviewer.md に reviewed: true/false の更新手順が記載されている
  - executor: claudecode
  - test_command: `grep -q 'reviewed:.*true' .claude/agents/reviewer.md && echo PASS || echo FAIL`
  - validations:
    - technical: "reviewed フィールド更新の記述が存在する"
    - consistency: "playbook-format.md の meta.reviewed フィールドと整合"
    - completeness: "Edit ツールでの更新手順が具体的に記載されている"

**status**: pending
**max_iterations**: 5

---

### p4: FAIL 時の修正サイクル機能の実装

**goal**: FAIL 時に修正提案を返却し、pm が修正できるようにする

**depends_on**: [p3]

#### subtasks

- [ ] **p4.1**: reviewer.md に FAIL 時の修正提案フォーマットが定義されている
  - executor: claudecode
  - test_command: `grep -qE 'FAIL.*修正|issues.*suggestion' .claude/agents/reviewer.md && echo PASS || echo FAIL`
  - validations:
    - technical: "FAIL 時の出力フォーマットが定義されている"
    - consistency: "playbook-review-criteria.md の issues フォーマットと整合"
    - completeness: "severity, description, suggestion が含まれている"

- [ ] **p4.2**: reviewer.md に最大リトライ回数（3回）と人間エスカレーションの記述がある
  - executor: claudecode
  - test_command: `grep -qE '3回|最大.*リトライ|人間.*エスカレーション' .claude/agents/reviewer.md && echo PASS || echo FAIL`
  - validations:
    - technical: "リトライ制限の記述が存在する"
    - consistency: "pm.md の reviewer 連携セクションと整合"
    - completeness: "エスカレーション時の具体的なアクションが記載されている"

**status**: pending
**max_iterations**: 5

---

### p5: pm SubAgent との連携確認

**goal**: pm.md に reviewer 自動呼び出しの記述があることを確認し、必要なら追加

**depends_on**: [p4]

#### subtasks

- [ ] **p5.1**: pm.md に playbook 作成後の reviewer 呼び出しが必須として記載されている
  - executor: claudecode
  - test_command: `grep -q 'reviewer.*必須\|必須.*reviewer' .claude/agents/pm.md && echo PASS || echo FAIL`
  - validations:
    - technical: "reviewer 必須の記述が存在する"
    - consistency: "CLAUDE.md の Core Contract と整合"
    - completeness: "スキップ禁止が明示されている"

- [ ] **p5.2**: pm.md に reviewer の PASS/FAIL に応じたフロー分岐が記載されている
  - executor: claudecode
  - test_command: `grep -q 'PASS.*確定\|FAIL.*修正' .claude/agents/pm.md && echo PASS || echo FAIL`
  - validations:
    - technical: "PASS/FAIL フロー分岐の記述が存在する"
    - consistency: "reviewer.md の出力フォーマットと整合"
    - completeness: "最大リトライ超過時の挙動も記載されている"

**status**: pending
**max_iterations**: 5

---

### p_final: 完了検証（必須）

**goal**: playbook の done_when が全て満たされているか最終検証

**depends_on**: [p5]

#### subtasks

- [ ] **p_final.1**: reviewer SubAgent が playbook.meta.roles.worker を読んで分岐できる（worker=codex → Claude、worker=claudecode → Codex）
  - executor: claudecode
  - test_command: `grep -q 'roles.worker' .claude/agents/reviewer.md && grep -q 'worker.*codex.*Claude\|codex.*worker' .claude/agents/reviewer.md && echo PASS || echo FAIL`
  - validations:
    - technical: "roles.worker 参照と分岐ロジックが実装されている"
    - consistency: "playbook.meta.roles 構造と整合"
    - completeness: "worker=codex と worker=claudecode 両方の分岐がある"

- [ ] **p_final.2**: codex の場合、codex exec --full-auto を Bash で実行できる
  - executor: claudecode
  - test_command: `grep -q 'codex exec --full-auto' .claude/agents/reviewer.md && echo PASS || echo FAIL`
  - validations:
    - technical: "codex exec コマンドが記載されている"
    - consistency: "Codex CLI の実際の使用法と整合"
    - completeness: "プロンプトテンプレートとタイムアウトが定義されている"

- [ ] **p_final.3**: RESULT: PASS/FAIL をパースして reviewed: true/false を更新できる
  - executor: claudecode
  - test_command: `grep -qE 'RESULT|PASS|FAIL' .claude/agents/reviewer.md && grep -q 'reviewed:' .claude/agents/reviewer.md && echo PASS || echo FAIL`
  - validations:
    - technical: "パースと更新の両方が記載されている"
    - consistency: "playbook-format.md の reviewed フィールドと整合"
    - completeness: "PASS/FAIL 両方のケースが処理される"

- [ ] **p_final.4**: FAIL 時に修正提案を返却できる
  - executor: claudecode
  - test_command: `grep -qE 'FAIL.*修正|issues|suggestion' .claude/agents/reviewer.md && echo PASS || echo FAIL`
  - validations:
    - technical: "FAIL 時の修正提案フォーマットが存在する"
    - consistency: "playbook-review-criteria.md の issues フォーマットと整合"
    - completeness: "pm が修正可能な形式で提案が返される"

**status**: pending
**max_iterations**: 3

---

## final_tasks

- [ ] **ft1**: tmp/ 内の一時ファイルを削除する
  - command: `find tmp/ -type f ! -name 'README.md' -delete 2>/dev/null || true`
  - status: pending

- [ ] **ft2**: 変更を全てコミットする
  - command: `git add -A && git status`
  - status: pending

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-21 | 初版作成 |
