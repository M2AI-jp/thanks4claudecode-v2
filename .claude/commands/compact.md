---
description: /compact 最適化と履歴要約のガイドライン。コンテキスト管理の専門知識を提供。
allowed-tools: Read, Edit, Bash
---

# /compact - コンテキスト最適化

コンテキスト使用率が高い場合に実行して、不要な履歴を削除しつつ重要な情報を保持します。

## 実行前チェックリスト

```yaml
pre_compact:
  - [ ] state.md の現在の goal.done_criteria を確認
  - [ ] 作業中の Phase の status を確認
  - [ ] 未コミットの変更がないか確認
  - [ ] 重要な意思決定をメモ
```

## 優先保持情報

```yaml
must_keep:
  - done_criteria: 現在の Phase の完了条件
  - current_phase: 作業中の Phase 情報
  - playbook_path: アクティブな playbook のパス
  - branch: 現在のブランチ名
  - recent_errors: 直近のエラーと対処法
  - user_decisions: ユーザーが明示した意思決定
```

## 削除候補

```yaml
can_remove:
  - completed_phases: 完了済み Phase の詳細（要約可）
  - file_contents: 大きなファイル内容（パスのみ保持）
  - command_outputs: 長いコマンド出力（要点のみ）
  - exploration_results: 探索結果（結論のみ）
```

## 実行後アクション

```yaml
post_compact:
  - [ ] [自認] を再宣言
  - [ ] done_criteria を再確認
  - [ ] 作業を続行
```

## コンテキスト閾値

```yaml
thresholds:
  warning: 70%   # 警告表示
  critical: 80%  # /compact 推奨
  danger: 90%    # /clear 推奨
```

---

**関連 Skill**: context-management
