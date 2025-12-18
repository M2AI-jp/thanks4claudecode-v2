# Admin Contract (Maintenance 権限)

> **admin は「全てをバイパス」ではなく「運用上必要な最小操作を許可」する限定権限**

---

## 1. 権限の原則

```yaml
admin_is_not_bypass:
  rule: admin は Core Contract を回避できない
  principle: Playbook Gate, HARD_BLOCK, Fail-Closed は admin でも有効

admin_is_maintenance:
  rule: admin は「運用を前に進める」ための限定権限
  scope: セッション終了処理、状態更新、アーカイブのみ
```

---

## 2. 許可される操作（ホワイトリスト）

### 2.1 ファイル操作

| 操作 | 対象 | 条件 |
|------|------|------|
| Edit/Write | `state.md` | 常に許可（Core Contract の例外） |
| Edit/Write | `plan/playbook-*.md` | 常に許可（Bootstrap 例外） |
| Bash mv | `plan/playbook-*.md` → `plan/archive/**` | admin のみ |
| Bash mkdir | `plan/archive/` | admin のみ |

### 2.2 Git 操作

| 操作 | 条件 |
|------|------|
| `git add state.md` | admin のみ |
| `git add plan/archive/**` | admin のみ |
| `git commit` | staged diff がホワイトリスト内のみ |
| `git push` | コミット内容がホワイトリスト内のみ |

### 2.3 判定ロジック

```bash
maintenance_whitelist=(
    "state.md"
    "plan/playbook-*.md"
    "plan/archive/**"
)

is_maintenance_allowed() {
    local target="$1"
    local security="$2"

    # admin でない場合は不許可
    [[ "$security" != "admin" ]] && return 1

    # ホワイトリストチェック
    for pattern in "${maintenance_whitelist[@]}"; do
        # shellcheck disable=SC2053
        [[ "$target" == $pattern ]] && return 0
    done

    return 1
}
```

---

## 3. 禁止される操作

admin モードでも以下は禁止（Core Contract により）:

| 操作 | 理由 |
|------|------|
| HARD_BLOCK ファイルの編集 | 絶対守護 |
| コード（`*.ts`, `*.js` 等）の編集 | playbook 必須 |
| Hook の編集 | 構造的強制の保護 |
| 設定ファイルの編集 | 意図しない挙動変更の防止 |

---

## 4. 有効化方法

### state.md で設定

```yaml
## config

```yaml
security: admin  # ← これを設定
```
```

### 注意事項

```yaml
session_scope:
  - admin モードはセッション終了時に strict に戻すことを推奨
  - 長時間の admin モード維持は非推奨

audit_requirement:
  - admin 操作は監査ログ（.claude/logs/）に記録
  - 理由、実行者、日時、対象を記録
```

---

## 5. E2E テスト要件

### シナリオ B: playbook=null & admin (Maintenance)

```yaml
given:
  - state.md: playbook.active = null
  - state.md: security = admin
expect:
  - Edit state.md → ALLOW
  - Bash "mv plan/playbook-x.md plan/archive/" → ALLOW
  - Bash "mkdir -p plan/archive" → ALLOW
  - git add state.md → ALLOW
  - git add plan/archive/** → ALLOW
  - git commit (上記のみ) → ALLOW
```

### シナリオ B-fail: ホワイトリスト外の混入

```yaml
given:
  - state.md: playbook.active = null
  - state.md: security = admin
actions:
  - Bash "touch src/hack.ts"  # ホワイトリスト外
  - git add -A  # 全てをステージ
expect:
  - git commit → BLOCK (ホワイトリスト外のファイルが含まれる)
```

---

## 6. Golden Path (セッション終了)

playbook 完了後のセッション終了処理:

```
1. [playbook=active] 作業完了、レビュー PASS
2. [playbook=active] git commit -m "feat: ..."
3. [playbook=active] git push → PR 作成 → マージ
4. [security=admin] playbook アーカイブ: mv plan/playbook-*.md plan/archive/
5. [security=admin] state 更新: playbook.active = null
6. [security=admin] git add state.md plan/archive/**
7. [security=admin] git commit -m "chore: session end"
8. [security=strict] 通常モードに復帰
```

**重要**: ステップ 4-7 は admin Maintenance 権限が必要。
