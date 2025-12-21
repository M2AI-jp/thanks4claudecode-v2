---
description: playbook 完了後の自動コミット、マージ、次タスク導出を実行。
allowed-tools: Read, Edit, Bash, Task
---

# /post-loop - Playbook 完了後処理

playbook の全 Phase が done になった後に実行する完了処理です。

## トリガー条件

playbook の全 Phase が `status: done` になった時

## 実行手順

### 0. 自動コミット（最終 Phase 分）

```bash
# 未コミット変更を確認
git status --porcelain

# 変更あり → コミット
git add -A && git commit -m "feat: {playbook 名} 完了"
```

### 1. Playbook アーカイブ

```bash
# アーカイブディレクトリに移動
mkdir -p plan/archive
mv plan/playbook-{name}.md plan/archive/

# state.md の playbook.active を null に更新
# state.md の playbook.last_archived を更新
```

### 2. PR 作成とマージ

```bash
# PR 作成
gh pr create --title "feat({milestone}): {summary}" --body "..."

# PR マージ
gh pr merge --merge --auto --delete-branch
```

### 3. project.md 更新

- `derives_from` から milestone ID を取得
- `status: in_progress` → `status: achieved` に更新
- `achieved_at` に現在日時を追加

### 4. /clear アナウンス

```
[playbook 完了]
playbook-{name} が全 Phase 完了しました。

コンテキスト使用率を確認し、必要に応じて /clear を実行してください。
```

### 5. 次タスク導出

pm SubAgent を呼び出して次の playbook を作成:

```
Task(subagent_type='pm', prompt='次のタスクを開始')
```

## 禁止事項

```yaml
prohibited:
  - 「報告して待つ」パターン（残タスクがあるのに止まる）
  - ユーザーに「次は何をしますか？」と聞く
  - pm を経由せずに次の playbook を作成する
```

---

**関連 Skill**: post-loop
