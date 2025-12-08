---
name: context-management
description: /compact 最適化と履歴要約のガイドライン。コンテキスト管理の専門知識を提供。
triggers:
  - /compact を実行する前
  - コンテキストが 80% を超えたとき
  - セッション終了時（履歴要約）
---

# Context Management Skill

コンテキスト管理の専門知識を提供する Skill です。

## /compact 最適化ガイドライン（task-09）

### 優先保持情報（高優先度）

```yaml
must_keep:
  - done_criteria: 現在の Phase の完了条件
  - current_phase: 作業中の Phase 情報
  - playbook_path: アクティブな playbook のパス
  - branch: 現在のブランチ名
  - recent_errors: 直近のエラーと対処法
  - user_decisions: ユーザーが明示した意思決定
```

### 削除候補（低優先度）

```yaml
can_remove:
  - completed_phases: 完了済み Phase の詳細（要約可）
  - file_contents: 大きなファイル内容（パスのみ保持）
  - command_outputs: 長いコマンド出力（要点のみ）
  - exploration_results: 探索結果（結論のみ）
```

### /compact 実行前のチェックリスト

```yaml
pre_compact:
  - [ ] state.md の現在の goal.done_criteria を確認
  - [ ] 作業中の Phase の status を確認
  - [ ] 未コミットの変更がないか確認
  - [ ] 重要な意思決定をメモ

post_compact:
  - [ ] [自認] を再宣言
  - [ ] done_criteria を再確認
  - [ ] 作業を続行
```

## 履歴要約ガイドライン（task-10）

### セッション終了時の要約フォーマット

```yaml
session_summary:
  date: {ISO8601}
  duration: {開始-終了}
  branch: {ブランチ名}

  completed:
    - {完了した Phase/タスク}

  in_progress:
    - {進行中の作業}
    - next_step: {次にやるべきこと}

  decisions:
    - {ユーザーが決定した重要事項}

  issues:
    - {発生した問題と対処法}

  commits:
    - {コミットハッシュ}: {メッセージ}
```

### 要約の保存先

```yaml
storage:
  location: .claude/session-history/
  format: session-{YYYYMMDD-HHMMSS}.md
  retention: 最新 30 件
```

### LLM への指示

```yaml
on_session_end:
  1. 上記フォーマットで要約を作成
  2. .claude/session-history/ に保存
  3. state.md の session_tracking を更新

on_session_start:
  1. 最新の session-history を確認
  2. 前回の in_progress を把握
  3. [自認] に反映
```

## コンテキスト監視

```yaml
thresholds:
  warning: 70%   # 警告表示
  critical: 80%  # /compact 推奨
  danger: 90%    # /clear 推奨

monitoring:
  - /context でコンテキスト使用率を確認
  - 80% 超過で「コンテキスト使用率が高いです。/compact を検討してください」
  - 90% 超過で「/clear を推奨します。state.md が真実源です」
```

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-08 | 初版作成。task-09, task-10 対応。 |
