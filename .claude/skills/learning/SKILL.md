---
name: learning
description: 失敗パターンの記録・学習。過去の失敗から学び、同じ問題を繰り返さない。
triggers:
  - エラーが発生したとき
  - critic が FAIL を返したとき
  - 作業が行き詰まったとき
  - 同じ問題が繰り返されているとき
---

# Learning Skill

失敗パターンを記録し、学習するための Skill です。

## 失敗パターンの記録

### 記録先

```yaml
location: .claude/logs/failures.log
format: JSONL（1行1レコード）
retention: 最新 100 件
```

### 記録フォーマット

```json
{
  "timestamp": "2025-12-08T12:00:00+09:00",
  "type": "critic_fail | hook_block | error | timeout",
  "context": {
    "phase": "p2",
    "playbook": "plan/active/playbook-xxx.md",
    "branch": "feat/xxx"
  },
  "failure": {
    "description": "done_criteria の証拠が不十分",
    "details": "ファイル存在確認のみで動作確認なし"
  },
  "resolution": {
    "action": "test_method を実行して動作確認を追加",
    "result": "PASS"
  },
  "lesson": "「設定した」≠「動く」。必ず動作確認が必要"
}
```

## 失敗パターンの分類

```yaml
critic_fail:
  - 証拠不十分
  - done_criteria 未達成
  - 自己報酬詐欺の疑い

hook_block:
  - init-guard: 必須ファイル未読み込み
  - playbook-guard: playbook なしで作業開始
  - protected-edit: 保護ファイル編集試行

error:
  - コマンド実行エラー
  - ファイル操作エラー
  - git 操作エラー

timeout:
  - Phase タイムアウト
  - LOOP 回数超過
```

## 学習の活用

### セッション開始時

```yaml
on_session_start:
  1. failures.log の直近 10 件を確認
  2. 繰り返しパターンがあれば [自認] で警告
  3. 同じ失敗を避けるための対策を意識
```

### 同種のタスク実行時

```yaml
on_similar_task:
  1. failures.log で同種の失敗を検索
  2. 過去の lesson を参照
  3. 対策を適用して実行
```

### 定期的な振り返り

```yaml
periodic_review:
  frequency: 週1回または 10 件蓄積ごと
  action:
    - パターンの分析
    - 根本原因の特定
    - 構造的な改善提案
```

## LLM への指示

```yaml
on_failure:
  1. 失敗を failures.log に記録
  2. 原因を分析
  3. 対策を実行
  4. lesson を記録

on_success_after_failure:
  1. resolution を更新
  2. lesson を明確化
  3. 同種の問題への対策を一般化
```

## 失敗ログの例

```json
{"timestamp":"2025-12-08T10:00:00+09:00","type":"hook_block","context":{"phase":"init","playbook":null,"branch":"main"},"failure":{"description":"init-guard でブロック","details":"state.md を Read していない"},"resolution":{"action":"Read(state.md) を実行","result":"PASS"},"lesson":"INIT フェーズでは必ず state.md を Read する"}
{"timestamp":"2025-12-08T11:00:00+09:00","type":"critic_fail","context":{"phase":"p2","playbook":"plan/active/playbook-xxx.md","branch":"feat/xxx"},"failure":{"description":"証拠不十分","details":"ls 出力なしでファイル存在を主張"},"resolution":{"action":"ls コマンドで存在確認","result":"PASS"},"lesson":"証拠は必ずコマンド出力またはファイル引用で示す"}
```

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-08 | 初版作成。task-13 対応。 |
