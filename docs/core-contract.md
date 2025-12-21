# Core Contract

> **この契約は admin モードでも回避不可。Hooks により構造的に強制される。**
>
> **注**: 本ドキュメントには Admin Mode Contract が統合されています（M122）

---

## 1. Playbook Gate

### ルール

`state.md` の `playbook.active` が `null` の場合、**意味的変更を禁止**する。

### 意味的変更の定義

| 対象 | 例 |
|------|-----|
| コード | `*.ts`, `*.js`, `*.py`, `*.go` 等 |
| Hook | `.claude/hooks/*.sh` |
| 設定 | `.claude/settings.json`, `*.config.*` |
| 仕様 | `docs/*.md`（core-contract.md, admin-contract.md を含む） |

### 例外（常に許可）

| 対象 | 理由 |
|------|------|
| `state.md` | 状態管理の SSOT。セッション終了等で更新が必要 |
| `plan/playbook-*.md` | Bootstrap 例外。playbook 自体の作成が必要 |
| `plan/archive/**` | アーカイブ先。Admin Maintenance で許可 |

### 判定

```
IF playbook.active == null:
    IF target IN 例外リスト:
        ALLOW
    ELSE IF security == admin AND target IN maintenance_whitelist:
        ALLOW (Maintenance 権限)
    ELSE:
        BLOCK
```

---

## 2. HARD_BLOCK

### ルール

以下のファイルは **security モードに関係なく常に保護**される。

### 対象ファイル

```
CLAUDE.md
.claude/protected-files.txt
.claude/hooks/init-guard.sh
.claude/hooks/critic-guard.sh
.claude/hooks/scope-guard.sh
.claude/hooks/executor-guard.sh
.claude/hooks/playbook-guard.sh
```

> **注**: consent 関連ファイルは M122 で削除されました（playbook 方式と重複）

### 判定

```
IF target IN HARD_BLOCK_LIST:
    BLOCK (admin でも回避不可)
```

---

## 3. Fail-Closed

### ルール

判定に必要な情報が取得できない場合、**通過させずにブロック**する。

### 例

| 状況 | 挙動 |
|------|------|
| `state.md` が存在しない | BLOCK |
| `jq` コマンドが無い | BLOCK |
| `git diff` が失敗 | BLOCK |
| `playbook.active` が読み取れない | BLOCK |

### 判定

```
IF 判定に必要な情報が取得不可:
    BLOCK (fail-closed)
```

---

## E2E テスト要件

以下のシナリオで Core Contract の動作を検証する。

### シナリオ A: playbook=null & non-admin

```yaml
given:
  - state.md: playbook.active = null
  - state.md: security = strict
expect:
  - Edit .claude/hooks/*.sh → BLOCK
  - Bash "echo 'x' > src/index.ts" → BLOCK
  - git add → BLOCK
```

### シナリオ D: HARD_BLOCK 検証

```yaml
given:
  - state.md: security = admin
expect:
  - Edit CLAUDE.md → BLOCK (admin でも)
  - Edit .claude/protected-files.txt → BLOCK
```

---

## 4. Admin Mode Contract（M122 統合）

> **admin は「全てをバイパス」ではなく「運用上必要な最小操作を許可」する限定権限**

### 4.1 権限の原則

```yaml
admin_is_not_bypass:
  rule: admin は Core Contract を回避できない
  principle: Playbook Gate, HARD_BLOCK, Fail-Closed は admin でも有効

admin_is_maintenance:
  rule: admin は「運用を前に進める」ための限定権限
  scope: セッション終了処理、状態更新、アーカイブのみ
```

### 4.2 許可される操作（ホワイトリスト）

#### ファイル操作

| 操作 | 対象 | 条件 |
|------|------|------|
| Edit/Write | `state.md` | 常に許可（Core Contract の例外） |
| Edit/Write | `plan/playbook-*.md` | 常に許可（Bootstrap 例外） |
| Bash mv | `plan/playbook-*.md` → `plan/archive/**` | admin のみ |
| Bash mkdir | `plan/archive/` | admin のみ |

#### Git 操作

| 操作 | 条件 |
|------|------|
| `git add state.md` | admin のみ |
| `git add plan/archive/**` | admin のみ |
| `git commit` | staged diff がホワイトリスト内のみ |
| `git push` | コミット内容がホワイトリスト内のみ |

#### 判定ロジック

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

### 4.3 禁止される操作

admin モードでも以下は禁止（Core Contract により）:

| 操作 | 理由 |
|------|------|
| HARD_BLOCK ファイルの編集 | 絶対守護 |
| コード（`*.ts`, `*.js` 等）の編集 | playbook 必須 |
| Hook の編集 | 構造的強制の保護 |
| 設定ファイルの編集 | 意図しない挙動変更の防止 |

### 4.4 有効化方法

```yaml
## config

security: admin  # ← これを設定
```

#### 注意事項

```yaml
session_scope:
  - admin モードはセッション終了時に strict に戻すことを推奨
  - 長時間の admin モード維持は非推奨

audit_requirement:
  - admin 操作は監査ログ（.claude/logs/）に記録
  - 理由、実行者、日時、対象を記録
```

### 4.5 E2E テスト要件（Admin）

#### シナリオ B: playbook=null & admin (Maintenance)

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

#### シナリオ B-fail: ホワイトリスト外の混入

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

### 4.6 Golden Path (セッション終了)

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
