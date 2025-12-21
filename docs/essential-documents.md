# Essential Documents - Claude が把握すべき必須ドキュメント

> **動線単位でドキュメントを整理した Single Source of Truth**
>
> このファイルは `scripts/generate-essential-docs.sh` により自動生成されます

---

## 概要

```yaml
source: governance/core-manifest.yaml
generated_at: 2025-12-21
organization: 動線単位（計画・実行・検証・完了・共通）

layer_summary:
  Core Layer: 11 コンポーネント（計画動線6 + 検証動線5）
  Quality Layer: 10 コンポーネント（実行動線）
  Extension Layer: 15 コンポーネント（完了7 + 共通5 + 横断3）
  Total: 36 コンポーネント
```

---

## 計画動線（Planning Flow）

タスク開始から playbook 作成までの流れで参照するドキュメント。

### 必須ドキュメント

| ファイル | 役割 | 参照タイミング |
|----------|------|---------------|
| `state.md` | 現在の状態（SSOT） | セッション開始時、常に最初 |
| `plan/project.md` | プロジェクト計画、マイルストーン | タスク開始時 |
| `plan/playbook-*.md` | 現在のタスク詳細 | 作業中 |
| `CLAUDE.md` | LLM 行動規範（凍結憲法） | 迷った時 |
| `RUNBOOK.md` | 手順、ツール、例 | 操作手順確認時 |

### Core コンポーネント（計画動線 6）

| コンポーネント | 種別 | 役割 |
|---------------|------|------|
| `prompt-guard.sh` | Hook | タスク検出、pm 必須警告 |
| `task-start.md` | Command | 計画動線の起点コマンド |
| `pm.md` | Subagent | playbook 作成 |
| `state` | Skill | state.md 管理 |
| `plan-management` | Skill | playbook 運用ガイド |
| `playbook-init.md` | Command | playbook 直接作成（旧互換） |

### 参考テンプレート

| ファイル | 役割 |
|----------|------|
| `plan/template/playbook-format.md` | playbook テンプレート（user_prompt_original 含む） |
| `plan/template/project-format.md` | project.md テンプレート |
| `plan/template/planning-rules.md` | pm 責務・計画フロー |
| `plan/design/mission.md` | 存在意義・core_values・anti-patterns |

---

## 実行動線（Execution Flow）

実装作業中に参照するドキュメント。

### 必須ドキュメント

| ファイル | 役割 | 参照タイミング |
|----------|------|---------------|
| `docs/core-contract.md` | Core Contract + Admin Contract | 保護・権限判断時 |
| `docs/folder-management.md` | フォルダ管理 + アーカイブ + 成果物ルール | ファイル配置時 |
| `docs/ai-orchestration.md` | 役割定義 + Orchestration + Toolstack | executor 選択時 |
| `docs/hook-responsibilities.md` | 各 Hook の責任定義 | Guard 発火時 |
| `docs/hook-exit-code-contract.md` | Hook の exit code 契約 | Hook エラー時 |

### Quality コンポーネント（実行動線 10）

| コンポーネント | 種別 | 役割 |
|---------------|------|------|
| `init-guard.sh` | Hook | 必須ファイル Read 強制 |
| `playbook-guard.sh` | Hook | playbook 存在チェック |
| `subtask-guard.sh` | Hook | 3観点検証（technical/consistency/completeness） |
| `scope-guard.sh` | Hook | done_criteria 変更検出 |
| `check-protected-edit.sh` | Hook | HARD_BLOCK ファイル保護 |
| `pre-bash-check.sh` | Hook | 危険コマンドブロック |
| `consent-guard.sh` | Hook | 危険操作同意取得 |
| `check-main-branch.sh` | Hook | main ブランチ保護 |
| `lint-checker` | Skill | 静的解析 |
| `test-runner` | Skill | テスト実行 |
| `archive-playbook.sh` | Hook | playbook アーカイブ |
| `cleanup-hook.sh` | Hook | tmp/ クリーンアップ |
| `create-pr-hook.sh` | Hook | PR 作成 |
| `post-loop` | Skill | 完了後処理 |
| `/post-loop` | Command | post-loop Skill 呼び出し |
| `context-management` | Skill | コンテキスト管理 |
| `/compact` | Command | context-management Skill 呼び出し |
| `rollback.md` | Command | Git ロールバック |
| `state-rollback.md` | Command | state.md ロールバック |
| `session-start.sh` | Hook | セッション初期化 |
| `session-end.sh` | Hook | セッション終了処理 |
| `pre-compact.sh` | Hook | コンパクト前処理 |
| `stop-summary.sh` | Hook | 中断時サマリー |
| `log-subagent.sh` | Hook | SubAgent ログ |
| `check-coherence.sh` | Hook | focus/playbook/branch 整合性 |
| `depends-check.sh` | Hook | playbook 間依存関係 |
| `executor-guard.sh` | Hook | executor 制御 |

---

## 検証動線（Verification Flow）

done_criteria 検証で参照するドキュメント。

### 必須ドキュメント

| ファイル | 役割 | 参照タイミング |
|----------|------|---------------|
| `docs/verification-criteria.md` | 検証基準 + Completion Criteria | critic 実行時 |
| `docs/criterion-validation-rules.md` | done_criteria 記述ルール | playbook 作成時 |

### Core コンポーネント（検証動線 5）

| コンポーネント | 種別 | 役割 |
|---------------|------|------|
| `crit.md` | Command | 検証起点コマンド |
| `critic.md` | Subagent | done_criteria 検証 |
| `critic-guard.sh` | Hook | critic PASS 必須 |
| `test` | Skill | test_command 実行 |
| `lint` | Skill | state/playbook 整合性チェック |
| `init-guard.sh` | Hook | 必須ファイル Read 強制 |
| `playbook-guard.sh` | Hook | playbook 存在チェック |
| `subtask-guard.sh` | Hook | 3観点検証（technical/consistency/completeness） |
| `scope-guard.sh` | Hook | done_criteria 変更検出 |
| `check-protected-edit.sh` | Hook | HARD_BLOCK ファイル保護 |
| `pre-bash-check.sh` | Hook | 危険コマンドブロック |
| `consent-guard.sh` | Hook | 危険操作同意取得 |
| `check-main-branch.sh` | Hook | main ブランチ保護 |
| `lint-checker` | Skill | 静的解析 |
| `test-runner` | Skill | テスト実行 |
| `archive-playbook.sh` | Hook | playbook アーカイブ |
| `cleanup-hook.sh` | Hook | tmp/ クリーンアップ |
| `create-pr-hook.sh` | Hook | PR 作成 |
| `post-loop` | Skill | 完了後処理 |
| `/post-loop` | Command | post-loop Skill 呼び出し |
| `context-management` | Skill | コンテキスト管理 |
| `/compact` | Command | context-management Skill 呼び出し |
| `rollback.md` | Command | Git ロールバック |
| `state-rollback.md` | Command | state.md ロールバック |
| `session-start.sh` | Hook | セッション初期化 |
| `session-end.sh` | Hook | セッション終了処理 |
| `pre-compact.sh` | Hook | コンパクト前処理 |
| `stop-summary.sh` | Hook | 中断時サマリー |
| `log-subagent.sh` | Hook | SubAgent ログ |
| `check-coherence.sh` | Hook | focus/playbook/branch 整合性 |
| `depends-check.sh` | Hook | playbook 間依存関係 |
| `executor-guard.sh` | Hook | executor 制御 |

### 評価フレームワーク

| ファイル | 役割 |
|----------|------|
| `.claude/frameworks/done-criteria-validation.md` | critic の固定評価フレームワーク（5項目） |
| `.claude/frameworks/playbook-review-criteria.md` | reviewer の評価基準（3段階検証） |

---

## 完了動線（Completion Flow）

Phase/playbook 完了時に参照するドキュメント。

### 必須ドキュメント

| ファイル | 役割 | 参照タイミング |
|----------|------|---------------|
| `docs/folder-management.md` | アーカイブ操作ルール（統合済み） | playbook 完了時 |
| `docs/freeze-then-delete.md` | 安全な削除プロセス（FREEZE_QUEUE） | ファイル削除時 |
| `docs/git-operations.md` | Git 操作リファレンス | マージ・ブランチ削除時 |

### Extension コンポーネント（完了動線 7）

| コンポーネント | 種別 | 役割 |
|---------------|------|------|
| `archive-playbook.sh` | Hook | playbook アーカイブ |
| `cleanup-hook.sh` | Hook | tmp/ クリーンアップ |
| `create-pr-hook.sh` | Hook | PR 作成 |
| `post-loop` | Skill | 完了後処理 |
| `/post-loop` | Command | post-loop Skill 呼び出し |
| `context-management` | Skill | コンテキスト管理 |
| `/compact` | Command | context-management Skill 呼び出し |
| `rollback.md` | Command | Git ロールバック |
| `state-rollback.md` | Command | state.md ロールバック |

---

## 共通基盤（Common Infrastructure）

全動線で参照される基盤ドキュメント。

### 必須ドキュメント

| ファイル | 役割 | 参照タイミング |
|----------|------|---------------|
| `docs/repository-map.yaml` | 全ファイルマッピング（自動生成） | コンポーネント確認時 |
| `docs/extension-system.md` | Claude Code 公式リファレンス | Hook/Skill 実装時 |
| `docs/layer-architecture-design.md` | Layer アーキテクチャ設計 | システム理解時 |
| `docs/session-management.md` | セッション管理 | セッション問題時 |

### 正本マニフェスト

| ファイル | 役割 |
|----------|------|
| `governance/core-manifest.yaml` | 動線ベース Layer アーキテクチャ定義（36コンポーネント正本） |
| `governance/context-manifest.yaml` | コンテキスト階層定義（Core/Flow/Extended） |
| `governance/PROMPT_CHANGELOG.md` | CLAUDE.md 変更履歴 |

### Extension コンポーネント（共通 5 + 横断 3）

| コンポーネント | 種別 | 役割 |
|---------------|------|------|
| `session-start.sh` | Hook | セッション初期化 |
| `session-end.sh` | Hook | セッション終了処理 |
| `pre-compact.sh` | Hook | コンパクト前処理 |
| `stop-summary.sh` | Hook | 中断時サマリー |
| `log-subagent.sh` | Hook | SubAgent ログ |
| `check-coherence.sh` | Hook | focus/playbook/branch 整合性 |
| `depends-check.sh` | Hook | playbook 間依存関係 |
| `executor-guard.sh` | Hook | executor 制御 |

---

## 参照優先順位

```yaml
セッション開始時:
  1. state.md（必須）
  2. plan/project.md（推奨）
  3. 現在の playbook（active の場合）

作業中:
  1. 現在の playbook
  2. 関連する実行動線ドキュメント

迷った時:
  1. CLAUDE.md（原則確認）
  2. RUNBOOK.md（手順確認）
  3. docs/*.md（詳細確認）
```

---

## 非推奨ドキュメント（FREEZE_QUEUE）

以下のファイルは統合または廃止され、FREEZE_QUEUE に入っています:

```yaml
queue:
  - docs/current-definitions.md
  - docs/deprecated-references.md
  - docs/document-catalog.md
  - docs/flow-test-report.md
  - docs/golden-path-verification-report.md
  - docs/m106-critic-guard-patch.md
  - docs/scenario-test-report.md
  - docs/admin-contract.md
  - docs/archive-operation-rules.md
  - docs/artifact-management-rules.md
  - docs/completion-criteria.md
  - docs/orchestration-contract.md
  - docs/toolstack-patterns.md
  - docs/ARCHITECTURE.md
  - docs/flow-document-map.md
  - docs/hook-registry.md
```

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-21 | 自動生成（generate-essential-docs.sh） |
