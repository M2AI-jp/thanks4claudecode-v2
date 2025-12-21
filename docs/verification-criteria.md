# Verification Criteria - 動作確認の判定基準

> **M105 Golden Path Verification のためのテスト基準定義**
>
> 報酬詐欺防止: 全コンポーネントに客観的な PASS/FAIL 判定基準を定義
>
> **注**: 本ドキュメントには Completion Criteria（5つの動作シナリオ）が統合されています（M122）

---

## 1. コンポーネント種別ごとの判定基準

### 1.1 Hook (22個)

```yaml
test_method: シェルスクリプトとして実行し exit code を確認
pass_criteria:
  - bash -n でエラーなし（構文チェック）
  - 期待される exit code を返す
    - 0: PASS（処理続行）
    - 1: WARN（警告のみ、続行）
    - 2: BLOCK（処理中断）
  - stderr に適切なメッセージを出力
fail_criteria:
  - bash -n でエラー
  - 期待と異なる exit code
  - サイレント失敗（出力なしで異常終了）
```

### 1.2 SubAgent (6個)

```yaml
test_method: Task tool で呼び出し、出力を確認
pass_criteria:
  - .claude/agents/{name}.md が存在
  - YAML frontmatter に name/description/tools が存在
  - Task tool での呼び出しが成功
  - 期待される形式の出力が返る
fail_criteria:
  - ファイル不存在
  - 必須フィールド欠落
  - 呼び出しエラー
  - 出力が期待形式でない
```

### 1.3 Skill (9個)

```yaml
test_method: Skill tool で実行、または /skill-name で呼び出し
pass_criteria:
  - .claude/skills/{name}/SKILL.md が存在
  - YAML に name/description が存在
  - 実行時にガイダンスが出力される
fail_criteria:
  - ディレクトリまたは SKILL.md 不存在
  - 必須フィールド欠落
  - 実行時エラー
```

### 1.4 Command (8個)

```yaml
test_method: /{command-name} で実行
pass_criteria:
  - .claude/commands/{name}.md が存在
  - 実行時に期待動作（出力または指示）がある
fail_criteria:
  - ファイル不存在
  - 実行時エラー
  - 無出力
```

---

## 2. 旧仕様（参考資料）

> **M104 以前のステート名主導アーキテクチャ**
>
> 現在の「黄金動線」より優れている可能性があるため、詳細を保存する。

### 2.1 旧仕様の全体フロー

```
セッション開始
    ↓
[Hooks] session-start.sh → pending/consent 生成
    ↓
[Hooks] init-guard.sh → 必須 Read 強制
    ↓
[CLAUDE.md] INIT → [自認] → ルート分岐
    ↓
[Hooks] playbook-guard.sh → [SubAgents] pm → [Skills] plan-management
    ↓
[CLAUDE.md] CONSENT → [理解確認] → ユーザー承認
    ↓
[CLAUDE.md] LOOP → done_criteria → [SubAgents] critic → [Skills] lint-checker/test-runner
    ↓
[Hooks] create-pr-hook.sh → PR → merge-pr.sh
    ↓
[CLAUDE.md] POST_LOOP → 次タスク導出
    ↓
```

### 2.2 旧仕様のステート定義

```yaml
INIT:
  description: セッション初期化フェーズ
  trigger: セッション開始
  actions:
    - state.md を読み込む
    - [自認] を宣言する
    - ルート分岐（setup/product/plan-template）
  next: CONSENT

CONSENT:
  description: ユーザー合意取得フェーズ
  trigger: タスク要求受信
  actions:
    - [理解確認] を表示
    - done_when を提示
    - ユーザー承認を待機
  next: LOOP

LOOP:
  description: 作業実行フェーズ
  trigger: ユーザー承認完了
  actions:
    - subtask を順次実行
    - 各 subtask で 3 観点検証（technical/consistency/completeness）
    - done_criteria を満たすまで繰り返す
    - critic を呼び出して検証
  next: POST_LOOP

POST_LOOP:
  description: 完了処理フェーズ
  trigger: 全 phase 完了
  actions:
    - playbook をアーカイブ
    - project.md を更新
    - 次タスクを導出
    - /clear を推奨
  next: INIT（次セッション）
```

### 2.3 旧仕様の利点（現仕様との比較）

| 観点 | 旧仕様（ステート主導） | 現仕様（動線主導） |
|------|----------------------|------------------|
| **明確性** | ステート名が状態を明示 | 動線名は流れを示すが状態不明 |
| **遷移ルール** | INIT→CONSENT→LOOP→POST_LOOP が固定 | 動線間の遷移が暗黙的 |
| **CONSENT** | [理解確認] が明示的なゲート | 暗黙的（Hook 任せ） |
| **pending/consent** | session-start.sh が生成 | 現在は未使用？ |
| **デバッグ** | 現在のステートが分かりやすい | どの動線にいるか不明確 |

### 2.4 旧仕様の問題点（当時の議論）

```yaml
problems:
  - ステート名が CLAUDE.md に依存（凍結困難）
  - コンポーネント増加でステート遷移が複雑化
  - CONSENT の [理解確認] がフォーマット依存
  - pending/consent ファイルの管理が煩雑
```

### 2.5 検討事項

```yaml
consider_revival:
  - INIT/CONSENT/LOOP/POST_LOOP のステート概念を復活させるか
  - [理解確認] の明示的なゲートを復活させるか
  - pending/consent メカニズムを再評価するか
  - ステート主導と動線主導のハイブリッドが可能か
```

---

## 3. check.md と core-manifest.yaml の対応表

### 3.1 計画動線（6個）

| check.md | core-manifest | Layer | 備考 |
|----------|---------------|-------|------|
| task-start.md | core.commands | Core | 黄金動線の起点 |
| playbook-init.md | quarantine.commands | Quarantine | 便利機能 |
| pm.md | core.subagents | Core | playbook 作成 |
| state Skill | core.skills | Core | state.md 管理 |
| plan-management Skill | core.skills | Core | playbook 運用 |
| prompt-guard.sh | core.runtime.hooks | Core (L0) | pm 必須警告 |

### 3.2 実行動線（11個）

| check.md | core-manifest | Layer | 備考 |
|----------|---------------|-------|------|
| init-guard.sh | core.runtime.hooks | Core (L0) | 必須 Read 強制 |
| playbook-guard.sh | core.runtime.hooks | Core (L0) | Playbook Gate |
| subtask-guard.sh | core.orchestration.hooks | Core (L1) | 3 観点検証 |
| scope-guard.sh | core.orchestration.hooks | Core (L1) | スコープクリープ防止 |
| check-protected-edit.sh | core.runtime.hooks | Core (L0) | HARD_BLOCK |
| pre-bash-check.sh | core.runtime.hooks | Core (L0) | Bash Gate |
| consent-guard.sh | core.orchestration.hooks | Core (L1) | ユーザー同意 |
| executor-guard.sh | quarantine.hooks | Quarantine | 便利機能 |
| check-main-branch.sh | quarantine.hooks | Quarantine | 便利機能 |
| lint-checker Skill | quarantine.skills | Quarantine | 便利機能 |
| test-runner Skill | quarantine.skills | Quarantine | 便利機能 |

### 3.3 検証動線（6個）

| check.md | core-manifest | Layer | 備考 |
|----------|---------------|-------|------|
| crit.md | core.commands | Core | critic 呼び出し |
| test.md | quarantine.commands | Quarantine | 便利機能 |
| lint.md | quarantine.commands | Quarantine | 便利機能 |
| critic.md | core.subagents | Core | 報酬詐欺防止 |
| reviewer.md | quarantine.subagents | Quarantine | オンデマンド |
| critic-guard.sh | core.orchestration.hooks | Core (L1) | critic 強制 |

### 3.4 完了動線（8個）

| check.md | core-manifest | Layer | 備考 |
|----------|---------------|-------|------|
| rollback.md | quarantine.commands | Quarantine | 便利機能 |
| state-rollback.md | quarantine.commands | Quarantine | 便利機能 |
| focus.md | quarantine.commands | Quarantine | 便利機能 |
| archive-playbook.sh | quarantine.hooks | Quarantine | 便利機能 |
| cleanup-hook.sh | quarantine.hooks | Quarantine | 便利機能 |
| create-pr-hook.sh | quarantine.hooks | Quarantine | 便利機能 |
| post-loop Skill | quarantine.skills | Quarantine | 便利機能 |
| context-management Skill | quarantine.skills | Quarantine | 便利機能 |

### 3.5 共通基盤（6個）

| check.md | core-manifest | Layer | 備考 |
|----------|---------------|-------|------|
| session-start.sh | core.runtime.hooks | Core (L0) | 初期化 |
| session-end.sh | quarantine.hooks | Quarantine | 便利機能 |
| pre-compact.sh | quarantine.hooks | Quarantine | 便利機能 |
| stop-summary.sh | quarantine.hooks | Quarantine | 便利機能 |
| log-subagent.sh | quarantine.hooks | Quarantine | 便利機能 |
| consent-process Skill | quarantine.skills | Quarantine | 便利機能 |

### 3.6 横断的整合性（3個）

| check.md | core-manifest | Layer | 備考 |
|----------|---------------|-------|------|
| check-coherence.sh | quarantine.hooks | Quarantine | 便利機能 |
| depends-check.sh | quarantine.hooks | Quarantine | 便利機能 |
| lint-check.sh | quarantine.hooks | Quarantine | 便利機能 |

---

## 4. Core vs Quarantine サマリー

```yaml
core_layer_0:
  hooks: 6
    - session-start.sh
    - init-guard.sh
    - prompt-guard.sh
    - playbook-guard.sh
    - pre-bash-check.sh
    - check-protected-edit.sh

core_layer_1:
  hooks: 4
    - consent-guard.sh
    - critic-guard.sh
    - subtask-guard.sh
    - scope-guard.sh

core_subagents: 2
  - pm.md
  - critic.md

core_skills: 2
  - state
  - plan-management

core_commands: 2
  - task-start.md
  - crit.md

quarantine:
  hooks: 12
  skills: 7
  commands: 6
  subagents: 1 (reviewer)
```

---

## 5. テスト優先度

```yaml
priority_1_core_runtime:
  reason: 常時発火、DX 直撃
  components:
    - session-start.sh
    - init-guard.sh
    - playbook-guard.sh
    - pre-bash-check.sh
    - check-protected-edit.sh
    - prompt-guard.sh

priority_2_core_orchestration:
  reason: 報酬詐欺防止の中核
  components:
    - critic-guard.sh
    - subtask-guard.sh
    - scope-guard.sh
    - consent-guard.sh
    - pm.md
    - critic.md

priority_3_quarantine:
  reason: 便利機能、Core 昇格候補
  components:
    - その他全て
```

---

## 6. Completion Criteria - 5つの動作シナリオ（M122 統合）

> **旧: docs/completion-criteria.md の内容を統合**
>
> 数字での成果報告（Hook X個、Milestone Y件）は自己欺瞞を生む。
> 「動くシナリオ」で完成を定義する。

### 6.1 シナリオ 1: 黄金動線

**目的**: タスク依頼から完了までの基本フローが動作すること

```
1. ユーザーが「〇〇を作って」とタスク依頼
2. pm SubAgent が自動起動
3. playbook が作成される
4. state.md が更新される
5. 作業が playbook に従って進行
6. critic SubAgent が done_criteria を検証
7. 検証 PASS で phase 完了
8. 全 phase 完了で playbook アーカイブ
9. 次タスクが自動提案される
```

### 6.2 シナリオ 2: メンテ作業デッドロック防止

**目的**: playbook=null でもメンテナンス作業が可能なこと

| コマンド | 期待 |
|---------|------|
| `git add -A` | PASS |
| `git commit` | PASS |
| `git merge` | PASS |
| `cat > test.txt` | BLOCK |

### 6.3 シナリオ 3: HARD_BLOCK 保護

**目的**: 重要ファイルが誤って編集・削除されないこと

- CLAUDE.md, protected-files.txt への Edit/Write → exit 2 でブロック
- admin モードでも回避不可

### 6.4 シナリオ 4: 報酬詐欺防止

**目的**: LLM が自己承認で完了を偽装できないこと

| 抜け道 | 対策 |
|--------|------|
| done_criteria を曖昧に書く | pm が具体的な test_command を強制 |
| critic を呼ばずに完了宣言 | critic-guard.sh でブロック |
| test_command を通るよう調整 | reviewer が事後チェック |

### 6.5 シナリオ 5: README/実装/テスト一致

**目的**: ドキュメントと実態が乖離しないこと

- README の数値は自動生成
- governance/core-manifest.yaml で Core/Non-Core を定義
- 未登録 Hook、未使用 SubAgent を可視化

### 6.6 テスト方針（M098 凍結）

```yaml
grep_prohibition: true
reason: |
  grep/test -f による「存在確認」は PASS 条件にしない。
  「ファイルがある」≠「動く」だから。

allowed_tests:
  - 挙動テスト（実行して exit code で判定）
  - scripts/behavior-test.sh による統合テスト

forbidden_tests:
  - grep -q "keyword" file && echo PASS
  - test -f path/to/file && echo PASS
  - ファイル数のカウント
```

---

*Created: 2025-12-20 (M105 p2.1)*
*Updated: 2025-12-21 (M122 - completion-criteria.md 統合)*
