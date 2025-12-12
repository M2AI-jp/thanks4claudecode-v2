# playbook-state-injection.md

> **M005「確実な初期化システム（StateInjection）」を実現する playbook**
>
> UserPromptSubmit Hook を拡張し、state/project/playbook の状態を systemMessage として強制注入する。

---

## meta

```yaml
project: thanks4claudecode
milestone: M005
branch: feat/state-injection
created: 2025-12-13
issue: null
derives_from: M005
reviewed: false
```

---

## goal

```yaml
summary: "state/project/playbook の状態を systemMessage で自動注入し、LLM が Read しなくても必要な情報が届く仕組みを確立する"

done_when:
  - "UserPromptSubmit Hook が state.md の focus/goal を systemMessage に注入する"
  - "playbook の current phase が systemMessage に含まれる"
  - "/clear 後も最初のプロンプトで systemMessage が正しく注入される（動作確認済み）"
  - "LLM が Read ツールを使わずに応答した場合でも state/goal/phase の情報が systemMessage から取得できる"
```

---

## phases

### p0: 現状分析と systemMessage 設計

```yaml
id: p0
name: "現状分析と systemMessage 設計"
goal: "現在の prompt-guard.sh の構造を理解し、注入すべき情報と出力フォーマットを設計"
executor: claudecode
priority: high
max_iterations: 5
time_limit: 30min

done_criteria:
  - "prompt-guard.sh が systemMessage を JSON で返す仕組みを理解している"
  - "state.md, project.md, playbook から注入すべき情報をリスト化している"
  - "systemMessage の構造（focus, goal, phase, remaining）を設計している"
  - "実際に prompt-guard.sh の実行結果を確認した"
  - "実際に動作確認済み（test_method 実行）"

test_method: |
  1. prompt-guard.sh を読み、JSON 出力部分を確認
  2. systemMessage に含める情報を整理（focus, goal, phase, remaining）
  3. 現在の state.md, project.md の内容を手動で確認
  4. 設計ドキュメント（draft-injection-design.md）を作成
  5. grep で systemMessage のパターンを確認
status: done
```

### p1: systemMessage 注入ロジック実装

```yaml
id: p1
name: "systemMessage 注入ロジック実装"
goal: "prompt-guard.sh を拡張し、state/project/playbook から取得した情報を systemMessage に追加"
executor: claudecode
depends_on: [p0]
priority: high
max_iterations: 8
time_limit: 1h

done_criteria:
  - "prompt-guard.sh に state.md 読み込みロジックが追加されている"
  - "project.md と playbook を読み込んで focus/goal/phase を抽出できる"
  - "systemMessage に以下が含まれている: focus.current, goal.milestone, goal.phase, remaining"
  - "JSON の escaping が正しく行われている（バックスラッシュ、改行）"
  - "複数回のプロンプト送信で毎回 systemMessage が注入される"
  - "実際に動作確認済み（test_method 実行）"

test_method: |
  1. prompt-guard.sh のバックアップ作成
  2. 拡張実装を追加（state, project, playbook 読み込み）
  3. echo で JSON を作成し、systemMessage に追加
  4. 動作テスト: test-injection.sh を作成して複数回実行
  5. systemMessage が正しく出力されることを確認
  6. git diff で変更内容を確認
status: done
```

### p2: /clear 後の発火テストと条件分岐

```yaml
id: p2
name: "/clear 後の発火テストと条件分岐"
goal: "/clear で state.md が初期化された後も systemMessage が正しく注入されることを確認"
executor: claudecode
depends_on: [p1]
priority: high
max_iterations: 6
time_limit: 45min

done_criteria:
  - "state.md の playbook=null の場合のログが有る"
  - "/clear 後に test-injection.sh を実行して動作確認した"
  - "systemMessage が state=null, goal=null でも正しく出力される"
  - "playbook がない場合と、ある場合の両方で動作確認済み"
  - "/clear コマンドの前後で state.md の内容が変わることを確認"
  - "実際に動作確認済み（test_method 実行）"

test_method: |
  1. /clear 実行前の state.md をコピー（backup-state-before-clear.md）
  2. ユーザーに /clear の実行を依頼
  3. /clear 実行後、state.md が初期化されたことを grep で確認
  4. test-injection.sh を実行して systemMessage が注入されることを確認
  5. state.md の playbook=null, goal=null の場合の出力を記録
  6. 修正が必要な場合は prompt-guard.sh を調整
status: in_progress
```

### p3: LLM Read 省略時の情報到達確認

```yaml
id: p3
name: "LLM Read 省略時の情報到達確認"
goal: "LLM が Read を実行せずに応答した場合、systemMessage から必要な情報が取得できることを確認"
executor: claudecode
depends_on: [p2]
priority: medium
max_iterations: 5
time_limit: 30min

done_criteria:
  - "systemMessage に含まれる情報がフォーマットされている（readable）"
  - "複数プロンプト送信時に毎回同じ形式で systemMessage が出力される"
  - "systemMessage の構造が CLAUDE.md の INIT と一致している"
  - "test-no-read.sh で LLM が Read せずに応答できることをシミュレート"
  - "実際に動作確認済み（test_method 実行）"

test_method: |
  1. systemMessage のフォーマットを確認（見やすいレイアウト）
  2. test-no-read.sh を作成し、systemMessage を抽出・解析
  3. systemMessage から以下を自動抽出:
     - focus.current
     - goal.milestone
     - goal.phase
     - remaining
  4. 抽出結果が正しいことを確認
  5. 複数のシナリオ（phase pending, in_progress, done）で動作確認
status: pending
```

### p4: ドキュメント更新とクリーンアップ

```yaml
id: p4
name: "ドキュメント更新とクリーンアップ"
goal: "state-injection の仕組みを docs に記録し、draft ファイルを削除"
executor: claudecode
depends_on: [p3]
priority: medium
max_iterations: 4
time_limit: 30min

done_criteria:
  - "docs/state-injection-guide.md が作成されている"
  - "systemMessage の注入フロー、注入する情報、フォーマットが記載されている"
  - "draft-injection-design.md が削除されている"
  - "test-injection.sh, test-no-read.sh が削除されている"
  - "state.md の playbook と goal が正しく設定されている"
  - "実際に動作確認済み（test_method 実行）"

test_method: |
  1. docs/state-injection-guide.md を作成
  2. draft-*.md, test-*.sh を削除
  3. git status で不要なファイルが残っていないことを確認
  4. state.md が正しく更新されていることを確認
  5. check-coherence.sh で整合性をチェック
status: pending
```

---

## 補足

### systemMessage に注入する情報

```yaml
目的:
  - LLM が Read を実行しなくても必要な情報が届く
  - [自認] の内容を systemMessage で強制提示
  - /clear 後の初期化状態でも動作する

注入する情報:
  - focus.current（現在のプロジェクト）
  - goal.milestone（現在の milestone）
  - goal.phase（現在の phase）
  - goal.done_criteria（phase の完了条件）
  - project_summary（project.md の vision）
  - remaining（残り milestone/phase 数）
  - playbook.active（活動中の playbook）
  - git_status（git の状態）

フォーマット:
  ┌──────────────────────────────────────┐
  │ [State Injection]                    │
  │                                      │
  │ focus: {project}                     │
  │ milestone: {M00X}                    │
  │ phase: {p0}                          │
  │ playbook: {path}                     │
  │ remaining: {X}/{Y}                   │
  │                                      │
  │ current_criteria: {criteria_list}    │
  └──────────────────────────────────────┘
```

### why systemMessage?

1. SessionStart Hook（現在）は出力するだけで強制力がない
2. systemMessage は Claude のシステムプロンプトレベルで注入される
3. LLM が Read を実行せずに応答した場合も systemMessage は Always delivered
4. プロンプトのたびに更新される（最新の state 情報が常に available）

### Hook 統合

```bash
# .claude/settings.json に以下を追加
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "UserPromptSubmit",
        "command": ".claude/hooks/prompt-guard.sh"
      }
    ]
  }
}

# prompt-guard.sh が systemMessage を返す形式：
{
  "systemMessage": "[State Injection]\n\nfocus: {focus}\nmilestone: {milestone}\n..."
}
```

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-13 | 初版作成。4 フェーズで systemMessage 注入機構を実装。 |
