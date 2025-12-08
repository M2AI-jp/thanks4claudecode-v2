# project.md

> **Macro 計画: リポジトリ全体の最終目標**

---

## vision

```yaml
summary: 仕組みのための仕組みづくり - LLM 主導の開発環境テンプレート
goal: LLM が完全自律で PDCA を回せる開発環境を提供する
```

---

## done_when

```yaml
core:
  - LLM がセッション開始から終了まで自律で動作する
  - playbook 完了後、自動で次のタスクに進む
  - 自己報酬詐欺を構造的に防止する

quality:
  - 全ての機能が検証済み
  - 新規ユーザーがフォークして即使用可能
  - setup レイヤーが完全に動作する
```

---

## current_phase

```yaml
phase: implementation
focus: 欠落機能の実装
completed:
  - Issue #8: 自律性強化（PDCA自動回転・妥当性評価フレームワーク）
  - Issue #9: 回帰テスト機能（task-06）
  - Issue #10: 自動 /clear 判断（task-08）
  - Issue #11: ロールバック機能（task-11）
  - task-07: レビュー機能（reviewer SubAgent）
  - task-01: タイムボックス機能（playbook スキーマ拡張: time_limit）
  - task-02: 優先順位管理（playbook スキーマ拡張: priority）
  - task-03: 依存関係管理（playbook スキーマ拡張: depends_on 強化）
  - task-09: /compact 最適化（context-management Skill）
  - task-10: 履歴の要約（context-management Skill + session-history/）
  - task-12: ヘルスチェック（health-checker SubAgent）
  - task-04: 並列実行制御（execution-management Skill）
  - task-05: リソース配分（execution-management Skill）
  - task-13: 学習・改善機構（learning Skill + logs/）

remaining_tasks: []  # 全タスク完了
```

---

## priority_order

```yaml
# 全タスク完了
all_completed: true
completed_count: 13

completion_summary:
  high: Issue #8, #9, #10, #11
  medium: task-01, task-02, task-03, task-07, task-09, task-10, task-12
  low: task-04, task-05, task-13
```

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-08 | 全タスク完了。13件の機能実装を終了。 |
| 2025-12-08 | 初版作成。MECE 分析の残タスク 13件を登録。 |
