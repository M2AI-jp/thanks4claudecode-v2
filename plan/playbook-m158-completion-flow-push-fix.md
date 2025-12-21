# Playbook M158: 完了動線 git push 許可パターン追加

```yaml
id: M158
title: "完了動線での git push をadmin maintenance allowlist に追加"
created: 2025-12-22
status: active
phase: p0
reviewed: true
```

## 目的

post-loop skill での main マージ後の `git push origin main` が playbook=null で ブロックされる問題を解決する。

## 背景

- M157 完了後、post-loop で `git push origin main` を実行
- playbook=null 状態での実行のため、contract.sh がブロック
- admin maintenance allowlist に git push パターンが未登録

## 実装計画

### Phase 0: パターン追加

**タスク:**
1. scripts/contract.sh の ADMIN_MAINTENANCE_PATTERNS に以下を追加:
   - `git push` (引数なし)
   - `git push origin <branch>`
   - `git push -u origin <branch>` (トラッキング付き)
   - `git push origin` (デフォルトブランチ)

2. コミット

**完了条件 (done_criteria):**
- [ ] scripts/contract.sh に 4 つの git push パターンが追加されている
- [ ] 変更がコミットされている

## リスク

なし（allowlist への追加のみ、既存機能への影響なし）

## 検証

```bash
# パターンが追加されたことを確認
grep -A30 "ADMIN_MAINTENANCE_PATTERNS" scripts/contract.sh | grep "git push"
```

## 備考

- M156 の完了動線で同様のブロックが発生
- この修正で完了動線がスムーズになる
