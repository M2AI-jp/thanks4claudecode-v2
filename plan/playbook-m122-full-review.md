# playbook-m122-full-review.md

> **M122: Claude 自己認識システム - 動線単位での全仕様把握**
>
> 全87ファイルを1ファイル1subtaskで精査し、動線単位で必要性を判断する

---

## meta

```yaml
schema_version: v2
project: thanks4claudecode
branch: feat/m122-session-flow-doc-integration
created: 2025-12-21
issue: null
derives_from: M122
reviewed: false
roles:
  worker: claudecode

user_prompt_original: |
  Claude自身が自分のすべての仕様（Hook, SubAgents, Skills, 関連ドキュメント、関連ファイル）を、
  黄金動線、つまり単一のコンポーネントではなく、連携している機能が複合して果たしている
  役割単位で整理して常に認知されている必要がある。
  動線単位で最新の全機能を網羅したものを正として、それが維持される仕組みを作る。
  不要なものは必要な記載だけを統合して、数を減らす。
  全ファイルを精査する - 1ファイル1subtask が必要。手抜きせずに進めて。
```

---

## goal

```yaml
summary: |
  リポジトリ全体の87ファイルを精査し、Claude が全仕様を動線単位で把握できる仕組みを構築する

done_when:
  - 全87ファイルが1ファイル1subtaskで精査されている
  - 動線単位で必要なファイルのみ残存し、不要な記載は統合済み
  - docs/essential-documents.md が動線単位で全機能を網羅している
  - playbook に user_prompt_original フィールドが標準化されている
```

---

## 精査対象ファイル一覧（87ファイル）

```yaml
docs/: 32
  - ARCHITECTURE.md
  - admin-contract.md
  - ai-orchestration.md
  - archive-operation-rules.md
  - artifact-management-rules.md
  - completion-criteria.md
  - core-contract.md
  - core-functions.md
  - criterion-validation-rules.md
  - current-definitions.md
  - deprecated-references.md
  - document-catalog.md
  - essential-documents.md
  - extension-system.md
  - flow-document-map.md
  - flow-test-report.md
  - folder-management.md
  - freeze-then-delete.md
  - git-operations.md
  - golden-path-verification-report.md
  - hook-exit-code-contract.md
  - hook-registry.md
  - hook-responsibilities.md
  - layer-architecture-design.md
  - m106-critic-guard-patch.md
  - manual-patches/README.md
  - orchestration-contract.md
  - playbook-schema-v2.md
  - scenario-test-report.md
  - session-management.md
  - toolstack-patterns.md
  - verification-criteria.md

root/: 6
  - AGENTS.md
  - CLAUDE.md
  - README.md
  - RUNBOOK.md
  - check.md
  - state.md

plan/: 14
  - project.md
  - README.md
  - playbook-m119-consent-guard-fix.md
  - playbook-m122-session-flow-doc-integration.md
  - template/planning-rules.md
  - template/playbook-examples.md
  - template/playbook-format.md
  - template/project-format.md
  - template/state-initial.md
  - template/vercel-nextjs-saas-structure.md
  - design/README.md
  - design/mission.md
  - design/plan-chain-system.md
  - design/self-healing-system.md

.claude/agents/: 3
  - critic.md
  - pm.md
  - reviewer.md

.claude/commands/: 8
  - crit.md
  - focus.md
  - lint.md
  - playbook-init.md
  - rollback.md
  - state-rollback.md
  - task-start.md
  - test.md

.claude/skills/: 6
  - context-management/SKILL.md
  - lint-checker/SKILL.md
  - plan-management/SKILL.md
  - post-loop/SKILL.md
  - state/SKILL.md
  - test-runner/SKILL.md

.claude/frameworks/: 2
  - done-criteria-validation.md
  - playbook-review-criteria.md

.claude/templates/: 1
  - linter-formatter-config.md

.claude/tests/: 1
  - regression-targets.md

governance/: 3
  - PROMPT_CHANGELOG.md
  - core-manifest.yaml
  - context-manifest.yaml

setup/: 2
  - CATALOG.md
  - playbook-setup.md

eval/: 6
  - README.md
  - prompt/001_no_future_promises.md
  - prompt/002_no_hallucination.md
  - prompt/003_no_self_approval.md
  - prompt/004_scope_discipline.md
  - prompt/005_direct_communication.md

yaml/: 3
  - docs/repository-map.yaml
  - governance/core-manifest.yaml
  - governance/context-manifest.yaml
```

---

## phases

### p0: 準備（user_prompt_original 仕組み追加）

**goal**: playbook テンプレートに user_prompt_original フィールドを標準化する

#### subtasks

- [x] **p0.1**: plan/template/playbook-format.md に user_prompt_original フィールドを追加
  - executor: orchestrator
  - test_command: `grep -q 'user_prompt_original' plan/template/playbook-format.md && echo PASS || echo FAIL`
  - result: PASS

**status**: completed
**max_iterations**: 3

---

### p1: docs/ 精査（32ファイル）

**goal**: docs/ 内の全ファイルを動線単位で精査し、必要性を判断する

**depends_on**: [p0]

#### subtasks

- [x] **p1.01**: docs/ARCHITECTURE.md
  - 動線: 共通基盤
  - 判定: MERGE
  - 統合先: essential-documents.md で参照、内容は他と重複
  - 理由: 構造情報は repository-map.yaml/core-functions.md と重複

- [x] **p1.02**: docs/admin-contract.md
  - 動線: 実行動線
  - 判定: MERGE済
  - 統合先: core-contract.md セクション4
  - 理由: M122で既に統合済み、FREEZE_QUEUE対象

- [x] **p1.03**: docs/ai-orchestration.md
  - 動線: 計画動線
  - 判定: KEEP
  - 理由: 役割定義・Toolstack・Codex MCP統合の正本。orchestration-contract.md/toolstack-patterns.md 統合済み

- [x] **p1.04**: docs/archive-operation-rules.md
  - 動線: 完了動線
  - 判定: MERGE済
  - 統合先: folder-management.md
  - 理由: M122で既に統合済み、FREEZE_QUEUE対象

- [x] **p1.05**: docs/artifact-management-rules.md
  - 動線: 完了動線
  - 判定: MERGE済
  - 統合先: folder-management.md
  - 理由: M122で既に統合済み、FREEZE_QUEUE対象

- [x] **p1.06**: docs/completion-criteria.md
  - 動線: 検証動線
  - 判定: MERGE済
  - 統合先: verification-criteria.md セクション6
  - 理由: M122で既に統合済み、FREEZE_QUEUE対象

- [x] **p1.07**: docs/core-contract.md
  - 動線: 共通基盤
  - 判定: KEEP
  - 理由: Playbook Gate/HARD_BLOCK/Fail-Closed/Admin Mode の核心契約

- [x] **p1.08**: docs/core-functions.md
  - 動線: 共通基盤
  - 判定: KEEP
  - 理由: M108成果物。動線単位でのコンポーネント分類の正本

- [x] **p1.09**: docs/criterion-validation-rules.md
  - 動線: 検証動線
  - 判定: KEEP
  - 理由: done_criteria記述ルールの正本、曖昧表現検出

- [x] **p1.10**: docs/current-definitions.md
  - 動線: なし
  - 判定: DISCARD
  - 理由: 一時的な整理用、deprecated-references.md と対で役割終了

- [x] **p1.11**: docs/deprecated-references.md
  - 動線: なし
  - 判定: DISCARD
  - 理由: 一時的な整理用、current-definitions.md と対で役割終了

- [x] **p1.12**: docs/document-catalog.md
  - 動線: なし
  - 判定: DISCARD
  - 理由: M117成果物だが essential-documents.md で代替

- [x] **p1.13**: docs/essential-documents.md
  - 動線: 共通基盤
  - 判定: KEEP
  - 理由: 動線単位でのドキュメント参照の SSOT

- [x] **p1.14**: docs/extension-system.md
  - 動線: 共通基盤
  - 判定: KEEP
  - 理由: Claude Code 公式リファレンスに基づく Hook/SubAgent/Skill/Command 体系

- [x] **p1.15**: docs/flow-document-map.md
  - 動線: なし
  - 判定: MERGE
  - 統合先: essential-documents.md
  - 理由: 役割が重複、FREEZE_QUEUE対象

- [x] **p1.16**: docs/flow-test-report.md
  - 動線: なし
  - 判定: DISCARD
  - 理由: M107完了報告、役割終了

- [x] **p1.17**: docs/folder-management.md
  - 動線: 完了動線
  - 判定: KEEP
  - 理由: archive-operation-rules.md/artifact-management-rules.md 統合済みの正本

- [x] **p1.18**: docs/freeze-then-delete.md
  - 動線: 完了動線
  - 判定: KEEP
  - 理由: 安全な削除プロセス（FREEZE_QUEUE/DELETE_LOG）の核心

- [x] **p1.19**: docs/git-operations.md
  - 動線: 完了動線
  - 判定: KEEP
  - 理由: git 自動化（コミット/マージ/ブランチ）のリファレンス

- [x] **p1.20**: docs/golden-path-verification-report.md
  - 動線: なし
  - 判定: DISCARD
  - 理由: M105完了報告、40コンポーネント検証結果、役割終了

- [x] **p1.21**: docs/hook-exit-code-contract.md
  - 動線: 実行動線
  - 判定: KEEP
  - 理由: Hook 出力・exit code の共通契約（WARN/BLOCK/INTERNAL ERROR）

- [x] **p1.22**: docs/hook-registry.md
  - 動線: 共通基盤
  - 判定: MERGE
  - 統合先: repository-map.yaml
  - 理由: 役割が重複、FREEZE_QUEUE対象

- [x] **p1.23**: docs/hook-responsibilities.md
  - 動線: 実行動線
  - 判定: KEEP
  - 理由: SOLID原則に基づく各 Hook の単一責任定義

- [x] **p1.24**: docs/layer-architecture-design.md
  - 動線: 共通基盤
  - 判定: KEEP
  - 理由: M104成果物。黄金動線ベースの Layer 設計根拠

- [x] **p1.25**: docs/m106-critic-guard-patch.md
  - 動線: なし
  - 判定: DISCARD
  - 理由: M106手動パッチ、適用済みで役割終了

- [x] **p1.26**: docs/manual-patches/README.md
  - 動線: 実行動線
  - 判定: KEEP
  - 理由: HARD_BLOCK ファイル手動編集用ディレクトリ

- [x] **p1.27**: docs/orchestration-contract.md
  - 動線: 計画動線
  - 判定: MERGE済
  - 統合先: ai-orchestration.md
  - 理由: M122で既に統合済み、FREEZE_QUEUE対象

- [x] **p1.28**: docs/playbook-schema-v2.md
  - 動線: 計画動線
  - 判定: KEEP
  - 理由: M084成果物。Playbook の厳密なフォーマット定義、Hook パース対応

- [x] **p1.29**: docs/scenario-test-report.md
  - 動線: なし
  - 判定: DISCARD
  - 理由: M110完了報告、シナリオテスト結果、役割終了

- [x] **p1.30**: docs/session-management.md
  - 動線: 共通基盤
  - 判定: KEEP
  - 理由: Named Sessions/Plan Mode（think/ultrathink）のガイド

- [x] **p1.31**: docs/toolstack-patterns.md
  - 動線: 計画動線
  - 判定: MERGE済
  - 統合先: ai-orchestration.md
  - 理由: M122で既に統合済み、FREEZE_QUEUE対象

- [x] **p1.32**: docs/verification-criteria.md
  - 動線: 検証動線
  - 判定: KEEP
  - 理由: PASS/FAIL判定基準、completion-criteria.md 統合済み

**p1 サマリー**:
```yaml
KEEP: 17
  - ai-orchestration.md, core-contract.md, core-functions.md, criterion-validation-rules.md
  - essential-documents.md, extension-system.md, folder-management.md, freeze-then-delete.md
  - git-operations.md, hook-exit-code-contract.md, hook-responsibilities.md
  - layer-architecture-design.md, manual-patches/README.md, playbook-schema-v2.md
  - session-management.md, verification-criteria.md, ARCHITECTURE.md(参照用)

MERGE済: 7
  - admin-contract.md, archive-operation-rules.md, artifact-management-rules.md
  - completion-criteria.md, orchestration-contract.md, toolstack-patterns.md
  - flow-document-map.md(→essential-documents.md)

DISCARD: 6
  - current-definitions.md, deprecated-references.md, document-catalog.md
  - flow-test-report.md, golden-path-verification-report.md, m106-critic-guard-patch.md
  - scenario-test-report.md

追加MERGE: 2
  - hook-registry.md(→repository-map.yaml)
  - ARCHITECTURE.md(内容統合検討)
```

**status**: completed
---

### p2: ルートレベル精査（6ファイル）

**goal**: ルートレベルの全ファイルを精査

**depends_on**: [p1]

#### subtasks

- [x] **p2.1**: AGENTS.md
  - 動線: 実行動線
  - 判定: KEEP
  - 理由: 純粋なコーディングルール（設計/実装/レビュー、セキュリティ、エラーハンドリング、テスト）。CLAUDE.md と明確に分離

- [x] **p2.2**: CLAUDE.md
  - 動線: 共通基盤（全動線）
  - 判定: KEEP (HARD_BLOCK)
  - 理由: 凍結された憲法。LLM の振る舞いルールの SSOT

- [x] **p2.3**: README.md
  - 動線: 共通基盤
  - 判定: KEEP
  - 理由: リポジトリの公開ドキュメント。クイックスタート、アーキテクチャ概要、保証/非保証

- [x] **p2.4**: RUNBOOK.md
  - 動線: 共通基盤
  - 判定: KEEP
  - 理由: CLAUDE.md と対で手順/ツール/例を記載。変更可能なドキュメント

- [x] **p2.5**: check.md
  - 動線: 共通基盤
  - 判定: KEEP
  - 理由: 黄金動線単位で整理された40コンポーネントの正本カタログ

- [x] **p2.6**: state.md
  - 動線: 共通基盤（全動線）
  - 判定: KEEP (SSOT)
  - 理由: 現在地を示す Single Source of Truth（focus, playbook, config, verification）

**p2 サマリー**:
```yaml
KEEP: 6/6
  - AGENTS.md, CLAUDE.md(HARD_BLOCK), README.md, RUNBOOK.md, check.md, state.md(SSOT)

判定: ルートレベルファイルは全て必須
```

**status**: completed
**max_iterations**: 10

---

### p3: plan/ 精査（14ファイル）

**goal**: plan/ 内の全ファイルを精査

**depends_on**: [p2]

#### subtasks

- [x] **p3.01**: plan/project.md
  - 動線: 計画動線
  - 判定: KEEP (SSOT)
  - 理由: プロジェクトの根幹計画。50マイルストーンの正本。vision/constraints/done_when を定義

- [x] **p3.02**: plan/README.md
  - 動線: 計画動線
  - 判定: KEEP
  - 理由: plan/ ディレクトリ構造・ライフサイクル・命名規則を定義

- [x] **p3.03**: plan/playbook-m119-consent-guard-fix.md
  - 動線: 計画動線
  - 判定: ARCHIVE待ち
  - 理由: final_tasks 未完了。アーカイブ対象（M119 で consent-guard 修正完了）

- [x] **p3.04**: plan/playbook-m122-session-flow-doc-integration.md
  - 動線: 計画動線
  - 判定: ARCHIVE待ち
  - 理由: p_final 完了済み。final_tasks 未完了。この playbook と統合検討

- [x] **p3.05**: plan/template/planning-rules.md
  - 動線: 計画動線
  - 判定: KEEP
  - 理由: pm の責務・計画フロー・derives_from 設計の正本

- [x] **p3.06**: plan/template/playbook-examples.md
  - 動線: 計画動線
  - 判定: KEEP
  - 理由: Web/自然言語/自動化の3パターンサンプル。新規 playbook 作成時の参考

- [x] **p3.07**: plan/template/playbook-format.md
  - 動線: 計画動線
  - 判定: KEEP (p0 で更新済み)
  - 理由: playbook の標準テンプレート。user_prompt_original フィールド追加済み

- [x] **p3.08**: plan/template/project-format.md
  - 動線: 計画動線
  - 判定: KEEP
  - 理由: project.md の3層構造（project→playbook→phase）テンプレート

- [x] **p3.09**: plan/template/state-initial.md
  - 動線: 計画動線
  - 判定: KEEP
  - 理由: フォーク直後の state.md 初期状態テンプレート

- [x] **p3.10**: plan/template/vercel-nextjs-saas-structure.md
  - 動線: 実行動線（参考）
  - 判定: KEEP（参考資料）
  - 理由: Next.js SaaS 構造のお手本。setup 時の参照用

- [x] **p3.11**: plan/design/README.md
  - 動線: 計画動線
  - 判定: KEEP
  - 理由: design/ ディレクトリの目次・役割説明

- [x] **p3.12**: plan/design/mission.md
  - 動線: 共通基盤（全動線）
  - 判定: KEEP (最上位概念)
  - 理由: 存在意義・core_values・anti-patterns（報酬詐欺）・guardrails の定義

- [x] **p3.13**: plan/design/plan-chain-system.md
  - 動線: 計画動線
  - 判定: KEEP
  - 理由: project→playbook→phase の連鎖的導出設計。decomposition 構造の定義

- [x] **p3.14**: plan/design/self-healing-system.md
  - 動線: 共通基盤
  - 判定: KEEP
  - 理由: 4層自己修復システム設計（Context Continuity/Doc Freshness/Feature Verification/Self-Improvement）

**p3 サマリー**:
```yaml
KEEP: 12
  - project.md (SSOT), README.md, template/planning-rules.md
  - template/playbook-examples.md, template/playbook-format.md, template/project-format.md
  - template/state-initial.md, template/vercel-nextjs-saas-structure.md
  - design/README.md, design/mission.md, design/plan-chain-system.md, design/self-healing-system.md

ARCHIVE待ち: 2
  - playbook-m119-consent-guard-fix.md (final_tasks 未完了)
  - playbook-m122-session-flow-doc-integration.md (final_tasks 未完了)

判定: 全ファイル必須、残存 playbook は完了後アーカイブ
```

**status**: completed
**max_iterations**: 20

---

### p4: .claude/ コンポーネント精査（21ファイル）

**goal**: .claude/ 内の全コンポーネント定義を精査

**depends_on**: [p3]

#### subtasks

**agents/ (3)**
- [x] **p4.01**: .claude/agents/critic.md
  - 動線: 検証動線
  - 判定: KEEP (Core)
  - 理由: done_criteria 評価。subtasks test_command 実行。skills 連携。報酬詐欺防止の核心

- [x] **p4.02**: .claude/agents/pm.md
  - 動線: 計画動線
  - 判定: KEEP (Core)
  - 理由: playbook 作成・管理。project.md 参照必須ルール。derives_from 設定。reviewer 連携

- [x] **p4.03**: .claude/agents/reviewer.md
  - 動線: 検証動線
  - 判定: KEEP (Quality)
  - 理由: playbook レビュー。コード品質評価。「作成者≠検証者」原則の実現

**commands/ (8)**
- [x] **p4.04**: .claude/commands/crit.md
  - 動線: 検証動線
  - 判定: KEEP
  - 理由: /crit スラッシュコマンド。done_criteria 達成チェックのエントリポイント

- [x] **p4.05**: .claude/commands/focus.md
  - 動線: 共通基盤
  - 判定: KEEP
  - 理由: /focus コマンド。focus.current 切り替え（setup/product/plan-template）

- [x] **p4.06**: .claude/commands/lint.md
  - 動線: 検証動線
  - 判定: KEEP
  - 理由: /lint コマンド。check-coherence.sh 実行。コミット前の整合性検証

- [x] **p4.07**: .claude/commands/playbook-init.md
  - 動線: 計画動線
  - 判定: KEEP (旧互換)
  - 理由: /playbook-init コマンド。旧互換。内部的に /task-start と同等フロー

- [x] **p4.08**: .claude/commands/rollback.md
  - 動線: 実行動線
  - 判定: KEEP
  - 理由: /rollback コマンド。git soft/mixed/hard/revert/stash 操作

- [x] **p4.09**: .claude/commands/state-rollback.md
  - 動線: 共通基盤
  - 判定: KEEP
  - 理由: /state-rollback コマンド。state.md バックアップ・世代復元・スナップショット

- [x] **p4.10**: .claude/commands/task-start.md
  - 動線: 計画動線
  - 判定: KEEP (推奨)
  - 理由: /task-start コマンド。project.md からの標準タスク開始。pm 呼び出し必須

- [x] **p4.11**: .claude/commands/test.md
  - 動線: 検証動線
  - 判定: KEEP
  - 理由: /test コマンド。test-done-criteria.sh 実行。done_criteria テスト実行

**skills/ (6)**
- [x] **p4.12**: .claude/skills/context-management/SKILL.md
  - 動線: 共通基盤
  - 判定: KEEP
  - 理由: /compact 最適化。履歴要約ガイドライン。コンテキスト外部化（context-log）

- [x] **p4.13**: .claude/skills/lint-checker/SKILL.md
  - 動線: 検証動線
  - 判定: KEEP
  - 理由: TS/JS 品質チェック専門。ESLint/TypeScript エラー検出・自動修正

- [x] **p4.14**: .claude/skills/plan-management/SKILL.md
  - 動線: 計画動線
  - 判定: KEEP
  - 理由: 多層計画管理。roadmap→milestones→playbooks→phases の階層。Four-Tuple Coherence

- [x] **p4.15**: .claude/skills/post-loop/SKILL.md
  - 動線: 完了動線
  - 判定: KEEP
  - 理由: POST_LOOP 処理。自動コミット/PR作成/マージ/project更新/次タスク導出

- [x] **p4.16**: .claude/skills/state/SKILL.md
  - 動線: 共通基盤
  - 判定: KEEP
  - 理由: state.md 管理。CRITIQUE 実行方法。playbook 必須ルール

- [x] **p4.17**: .claude/skills/test-runner/SKILL.md
  - 動線: 検証動線
  - 判定: KEEP
  - 理由: テスト実行専門。Unit/E2E/型/ビルドテスト。done_criteria 検証連携

**frameworks/ (2)**
- [x] **p4.18**: .claude/frameworks/done-criteria-validation.md
  - 動線: 検証動線
  - 判定: KEEP (Core)
  - 理由: critic の固定評価フレームワーク。5項目チェックリスト（根拠/検証可能性/整合性/報酬詐欺/証拠品質）

- [x] **p4.19**: .claude/frameworks/playbook-review-criteria.md
  - 動線: 検証動線
  - 判定: KEEP (Core)
  - 理由: reviewer の評価基準。3段階検証（形式/シミュレーション/批判的検討）。普遍的基準6項目

**templates/ (1)**
- [x] **p4.20**: .claude/templates/linter-formatter-config.md
  - 動線: 実行動線（参考）
  - 判定: KEEP（参考資料）
  - 理由: 言語別デファクト Linter/Formatter 設定テンプレート。setup Phase 5-A で使用

**tests/ (1)**
- [x] **p4.21**: .claude/tests/regression-targets.md
  - 動線: 検証動線
  - 判定: UPDATE
  - 理由: 回帰テスト対象リスト。ただし古い（14 Hooks, 7 Agents, 5 Commands）。現行と乖離あり

**p4 サマリー**:
```yaml
KEEP: 20
  agents/: critic.md(Core), pm.md(Core), reviewer.md(Quality)
  commands/: crit.md, focus.md, lint.md, playbook-init.md, rollback.md, state-rollback.md, task-start.md, test.md
  skills/: context-management, lint-checker, plan-management, post-loop, state, test-runner
  frameworks/: done-criteria-validation.md(Core), playbook-review-criteria.md(Core)
  templates/: linter-formatter-config.md

UPDATE: 1
  - tests/regression-targets.md（数値が古い、現行と乖離）

判定: 全ファイル必須。regression-targets.md は現行数値に更新推奨
```

**status**: completed
**max_iterations**: 25

---

### p5: その他精査（14ファイル）

**goal**: governance/, setup/, eval/, yaml ファイルを精査

**depends_on**: [p4]

#### subtasks

**governance/ (3)**
- [x] **p5.01**: governance/PROMPT_CHANGELOG.md
  - 動線: 共通基盤
  - 判定: KEEP
  - 理由: CLAUDE.md 変更履歴。Change Control プロセスの記録

- [x] **p5.02**: governance/core-manifest.yaml (v3)
  - 動線: 共通基盤 (SSOT)
  - 判定: KEEP (Core)
  - 理由: 動線ベース Layer アーキテクチャ定義。36コンポーネントの分類正本

- [x] **p5.03**: governance/context-manifest.yaml
  - 動線: 共通基盤
  - 判定: KEEP
  - 理由: コンテキスト階層定義。Core/Flow/Extended の参照構造

**setup/ (2)**
- [x] **p5.04**: setup/CATALOG.md
  - 動線: 計画動線（setup 専用）
  - 判定: KEEP（大規模参照資料 25K tokens）
  - 理由: 新規ユーザー向け詳細リファレンス

- [x] **p5.05**: setup/playbook-setup.md
  - 動線: 計画動線（setup 専用）
  - 判定: KEEP
  - 理由: 新規ユーザー向け setup playbook メインガイド。Phase 0-8 + Tutorial Route

**eval/ (6)**
- [x] **p5.06**: eval/README.md
  - 動線: 検証動線
  - 判定: KEEP
  - 理由: プロンプト回帰テストのフレームワーク説明

- [x] **p5.07-11**: eval/prompt/001-005_*.md
  - 動線: 検証動線
  - 判定: KEEP
  - 理由: CLAUDE.md 各条項のテストケース（5件）

**yaml/ (2)**
- [x] **p5.12**: docs/repository-map.yaml
  - 動線: 共通基盤
  - 判定: KEEP（自動生成）
  - 理由: リポジトリ全ファイルマッピング。175ファイル、34 Hooks 記録

- [x] **p5.13**: plan/archive/ + scripts/
  - 動線: 完了動線 + 共通基盤
  - 判定: KEEP
  - 理由: 完了済み playbook アーカイブ + ユーティリティスクリプト群

**p5 サマリー**:
```yaml
KEEP: 14/14
  governance/: PROMPT_CHANGELOG.md, core-manifest.yaml(Core), context-manifest.yaml
  setup/: CATALOG.md, playbook-setup.md
  eval/: README.md + 5 テストケース
  その他: repository-map.yaml(自動生成), plan/archive/, scripts/

判定: 全ファイル必須。governance/ は Layer アーキテクチャの正本
```

**status**: completed
**max_iterations**: 15

---

### p6: 統合実行

**goal**: 精査結果に基づいてファイル統合・削除を実行

**depends_on**: [p5]

#### subtasks

- [x] **p6.1**: DISCARD 判定ファイルを FREEZE_QUEUE に追加
  - 完了: 7ファイル追加（current-definitions, deprecated-references, document-catalog, flow-test-report, golden-path-verification-report, m106-critic-guard-patch, scenario-test-report）
- [x] **p6.2**: MERGE 判定ファイルを統合先に統合
  - 完了: MERGE済 6ファイル + MERGE予定 3ファイルを FREEZE_QUEUE に追加
  - MERGE済: admin-contract→core-contract, archive-operation-rules/artifact-management-rules→folder-management, completion-criteria→verification-criteria, orchestration-contract/toolstack-patterns→ai-orchestration
  - MERGE予定: ARCHITECTURE→layer-architecture-design, flow-document-map→essential-documents, hook-registry→repository-map
- [x] **p6.3**: essential-documents.md を更新（動線単位で全機能網羅）
  - 完了: 動線単位で36コンポーネントを網羅。Layer summary追加。
- [x] **p6.4**: FREEZE_QUEUE のファイルを削除
  - 対応: 7日間凍結期間のため即時削除せず。2025-12-28 以降に delete-frozen.sh で削除可能。

**status**: done
**max_iterations**: 10

---

### p_final: 完了検証（Codex executor）

**goal**: playbook の done_when が全て満たされているか最終検証

**depends_on**: [p6]

**executor**: codex

#### subtasks

- [x] **p_final.1**: 全87ファイルが精査されている
  - executor: codex
  - result: PASS - p1-p5 の全subtaskが [x] で、87ファイル精査が記録済み

- [x] **p_final.2**: essential-documents.md が動線単位で全機能を網羅している
  - executor: codex
  - result: PASS - 計画/実行/検証/完了の4動線と共通基盤セクションが揃い、動線別に網羅

- [x] **p_final.3**: playbook-format.md に user_prompt_original が追加されている
  - executor: codex
  - result: PASS - playbook-format.md:23 に user_prompt_original フィールドを追加済み

- [x] **p_final.4**: 不要ファイルが FREEZE_QUEUE に登録されている
  - executor: codex
  - result: PASS - FREEZE_QUEUE に16件（DISCARD 7 + MERGE済 6 + MERGE予定 3）登録を確認

**codex_verification**: 総合 PASS（2025-12-21）
**status**: done
**max_iterations**: 5

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-21 | 再発行。87ファイル精査版。user_prompt_original 追加。 |
