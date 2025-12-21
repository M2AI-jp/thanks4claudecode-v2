# Playbook M159: gh コマンドを ADMIN_MAINTENANCE_PATTERNS に追加

```yaml
meta:
  project: m159-gh-pr-patterns
  branch: feat/m158-completion-flow-push-fix
  created: 2025-12-22

goal:
  summary: gh pr create/merge を ADMIN_MAINTENANCE_PATTERNS に追加し、完了動線での PR 操作を playbook=null で許可する
  done_when:
    - scripts/contract.sh に gh pr create/merge パターンが追加されている
    - 変更がコミット・プッシュされている
    - PR が作成・マージされている
    - main ブランチが最新状態

phases:
  - id: p0
    name: パターン追加
    goal: ADMIN_MAINTENANCE_PATTERNS に gh pr create/merge を追加
    executor: claudecode
    done_criteria:
      - scripts/contract.sh の ADMIN_MAINTENANCE_PATTERNS 配列に以下が追加されている
        - '^gh[[:space:]]+pr[[:space:]]+create'
        - '^gh[[:space:]]+pr[[:space:]]+merge'
      - 変更がコミットされている
    status: pending

  - id: p1
    name: PR 作成とマージ
    goal: 変更を main にマージして完了動線を完成させる
    executor: claudecode
    done_criteria:
      - feat/m158-completion-flow-push-fix ブランチがプッシュされている
      - PR が作成されている
      - PR がマージされている
      - main ブランチに切り替えて pull されている
    status: pending
```

## 背景

M158 で `git push` パターンを追加したが、`gh pr create` と `gh pr merge` が playbook=null でブロックされる問題が残っている。完了動線で PR 作成/マージは必須操作のため、これらを ADMIN_MAINTENANCE_PATTERNS に追加する必要がある。

## 実装詳細

### Phase 0: パターン追加

scripts/contract.sh の ADMIN_MAINTENANCE_PATTERNS 配列（line 275-310 付近）に以下を追加:

```bash
# gh pr create（PR 作成）
'^gh[[:space:]]+pr[[:space:]]+create'
# gh pr merge（PR マージ）
'^gh[[:space:]]+pr[[:space:]]+merge'
```

追加位置: `git push origin` の後（line 309 の後）

### Phase 1: PR 作成とマージ

1. 変更をコミット: `fix(M159): add gh pr create/merge to admin maintenance patterns`
2. ブランチをプッシュ
3. PR を作成
4. PR をマージ
5. main に切り替えて pull

## リスク

なし（allowlist への追加のみ、既存機能への影響なし）

## 検証

```bash
# パターンが追加されたことを確認
grep -A35 "ADMIN_MAINTENANCE_PATTERNS" scripts/contract.sh | grep "gh pr"
```
