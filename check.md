# thanks4claudecode コンポーネントカタログ

> 全 40 コンポーネント（Hooks 22 + SubAgents 3 + Skills 7 + Commands 8）

---

# Hooks (22)

---

## 1. check-coherence.sh

**要点**: 四項整合性（focus/layer/playbook/branch）を検証。PreCommit で発火。

---

## 2. check-main-branch.sh

**要点**: main ブランチでの Edit/Write をブロック。setup/product focus では許可。

---

## 3. check-protected-edit.sh

**要点**: HARD_BLOCK ファイル（CLAUDE.md 等）への編集をブロック。admin でも回避不可。

---

## 4. critic-guard.sh

**要点**: phase を done にする前に critic の PASS を必須にする。報酬詐欺防止。

---

## 5. depends-check.sh

**要点**: playbook 間の依存関係を検証。循環依存を検出。

---

## 6. executor-guard.sh

**要点**: subtask の executor に応じて適切なツール呼び出しを強制。

---

## 7. init-guard.sh

**要点**: セッション開始時に必須ファイルの Read を強制。pending ファイルで状態管理。

---

## 8. lint-check.sh

**要点**: コード変更時に静的解析を自動実行。ESLint/TypeScript エラーを検出。

---

## 9. log-subagent.sh

**要点**: SubAgent 呼び出しを記録。報酬詐欺の証跡として使用。

---

## 10. playbook-guard.sh

**要点**: playbook=null の場合 Edit/Write をブロック。Golden Path の強制。

---

## 11. pre-bash-check.sh

**要点**: 危険な Bash コマンドをブロック。rm -rf / 等の破壊的操作を防止。

---

## 12. pre-compact.sh

**要点**: compact 前に状態スナップショットを保存。復元可能にする。

---

## 13. scope-guard.sh

**要点**: done_criteria/done_when の無断変更を検出。スコープクリープを防止。

---

## 14. session-end.sh

**要点**: セッション終了時の整合性チェックとサマリー生成。

---

## 15. stop-summary.sh

**要点**: エージェント停止時に Phase 状態サマリーを出力。

---

## 16. session-start.sh

**要点**: セッション開始時の自己認識形成。警告・必須 Read 指示・[自認] テンプレートを出力。

---

## 17. archive-playbook.sh

**要点**: playbook 完了時の自動アーカイブ提案。全 Phase done で plan/archive/ への移動を提案。

---

## 18. create-pr-hook.sh

**要点**: playbook 完了時の PR 自動作成フック。

---

## 19. subtask-guard.sh

**要点**: subtask 完了時の 3 検証を強制。technical/consistency/completeness の validations を要求。

---

## 20. cleanup-hook.sh

**要点**: playbook 完了時の tmp/ クリーンアップ。テンポラリファイルを自動削除。

---

## 21. consent-guard.sh

**要点**: 合意プロセス強制フック。consent ファイルが存在する場合 Edit/Write をブロック。

---

## 22. prompt-guard.sh

**要点**: UserPromptSubmit Hook。State Injection、プロンプト保存、合意検出を実行。

---

# SubAgents (3)

---

## 1. pm.md

**要点**: Project Manager Agent。playbook の作成・管理・進捗追跡を担当。全タスク開始の必須経由点。

---

## 2. critic.md

**要点**: Critique Evaluator Agent。done_criteria の達成状況を批判的に評価。報酬詐欺を防止。

---

## 3. reviewer.md

**要点**: Code & Design Reviewer Agent。コードと設計のレビューを担当。playbook レビューも実施。

---

# Skills (7)

---

## 1. context-management

**要点**: /compact 最適化と履歴要約のガイドライン。コンテキスト管理の専門知識を提供。

---

## 2. lint-checker

**要点**: コード品質チェック専門スキル。TypeScript/JavaScript の ESLint、型チェックを検証。

---

## 3. plan-management

**要点**: Multi-layer planning and playbook management。計画階層と Phase 遷移を管理。

---

## 4. post-loop

**要点**: playbook 完了後の自動処理。コミット、マージ、次タスク導出を実行。

---

## 5. state

**要点**: state.md 管理、playbook 運用の専門知識。CRITIQUE の実行方法も定義。

---

## 6. test-runner

**要点**: テスト実行・検証専門スキル。Unit/E2E/型チェック/ビルドを自動実行。

---

## 7. consent-process

**要点**: 合意プロセス（CONSENT）。[理解確認] ブロックを強制し、ユーザー合意を取得。

---

# Commands (8)

---

## 1. /crit

**要点**: done_criteria の達成状況チェック。Phase 完了前の検証に使用。

---

## 2. /focus

**要点**: state.md の focus.current を切り替え。setup/product/plan-template の切り替えに使用。

---

## 3. /lint

**要点**: state.md と playbook の整合性チェック。コミット前の検証に使用。

---

## 4. /playbook-init

**要点**: 新しい playbook を作成するウィザード。ブランチ作成、pm 呼び出しを含む。

---

## 5. /rollback

**要点**: Git ロールバックを実行。soft/mixed/hard/revert/stash から選択可能。

---

## 6. /state-rollback

**要点**: state.md のバックアップと復元を管理。

---

## 7. /task-start

**要点**: project.md から新しいタスクを開始。pm SubAgent を呼び出し playbook を作成。

---

## 8. /test

**要点**: done_criteria のテストを実行。特定テストまたは全テストを実行可能。

---

# 統計サマリー

| カテゴリ | 件数 |
|---------|------|
| Hooks | 22 |
| SubAgents | 3 |
| Skills | 7 |
| Commands | 8 |
| **合計** | **40** |

---

*Generated: 2025-12-20*
