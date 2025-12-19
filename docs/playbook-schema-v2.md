# Playbook Schema v2 仕様書

> **Playbook の厳密なフォーマット定義 - Hook パース対応**
>
> このドキュメントは RFC 2119 スタイルの用語を使用する:
> - **MUST**: 絶対に必要（違反は不正形式）
> - **SHOULD**: 強く推奨（特別な理由がない限り従う）
> - **MAY**: 任意（使用してもしなくても良い）

---

## 概要

Schema v2 は playbook の表記揺れを根絶し、Hook が確実にパースできる形式を定義する。

### 変更点 (v1 → v2)

| 項目 | v1 | v2 |
|------|----|----|
| バージョン識別 | なし | `schema_version: v2` |
| 必須度定義 | 曖昧 | RFC 2119 準拠 |
| 正規表現 | なし | 厳密に定義 |
| セクション順序 | 任意 | 規定順序 |

---

## 1. ファイル構造

### 1.1 ファイル名 [MUST]

```
playbook-{identifier}.md
```

- `{identifier}`: 英数字、ハイフン、アンダースコアのみ
- 正規表現: `^playbook-[a-zA-Z0-9_-]+\.md$`

### 1.2 セクション順序 [MUST]

```markdown
1. # タイトル (H1)
2. > 説明文 (blockquote)
3. ## meta
4. ## goal
5. ## phases
6. ## final_tasks
7. ## rollback [SHOULD]
8. ## 変更履歴 [SHOULD]
```

---

## 2. meta セクション

### 2.1 構造 [MUST]

```yaml
## meta

```yaml
schema_version: v2  # [MUST] Schema バージョン
project: {string}   # [MUST] プロジェクト名
branch: {string}    # [MUST] ブランチ名
created: {date}     # [MUST] 作成日
issue: {string|null} # [MAY] Issue 番号
derives_from: {string|null} # [SHOULD] 関連 milestone ID
reviewed: {boolean}  # [MUST] レビュー済みフラグ (default: false)
roles:               # [MAY] 役割の override
  worker: {executor}
```

### 2.2 フィールド制約

| フィールド | 型 | 必須度 | 制約 | 例 |
|-----------|-----|--------|------|-----|
| schema_version | string | MUST | `v2` 固定 | `v2` |
| project | string | MUST | 空文字不可 | `thanks4claudecode` |
| branch | string | MUST | `{type}/{description}` 形式 | `feat/m084-schema-v2` |
| created | date | MUST | `YYYY-MM-DD` 形式 | `2025-12-19` |
| issue | string\|null | MAY | null または Issue ID | `null`, `#123` |
| derives_from | string\|null | SHOULD | null または milestone ID | `M084` |
| reviewed | boolean | MUST | `true` または `false` | `false` |
| roles.worker | executor | MAY | enum 参照 | `claudecode` |

### 2.3 branch 形式 [MUST]

```
{type}/{description}
```

| type | 用途 |
|------|------|
| feat | 新機能 |
| fix | バグ修正 |
| refactor | リファクタリング |
| docs | ドキュメント |
| chore | 雑務 |

正規表現: `^(feat|fix|refactor|docs|chore)/[a-zA-Z0-9_-]+$`

---

## 3. goal セクション

### 3.1 構造 [MUST]

```yaml
## goal

```yaml
summary: {string}    # [MUST] 1行の目標
done_when:           # [MUST] 完了条件リスト
  - {string}
  - {string}
```

### 3.2 フィールド制約

| フィールド | 型 | 必須度 | 制約 |
|-----------|-----|--------|------|
| summary | string | MUST | 1行、空文字不可 |
| done_when | string[] | MUST | 1項目以上 |

---

## 4. phases セクション

### 4.1 Phase 構造 [MUST]

```markdown
### p{N}: {name}

**goal**: {string}

**depends_on**: [{phase_ids}]  # [MAY]

#### subtasks

{subtask_list}

**status**: {status}
**max_iterations**: {number}  # [SHOULD]
```

### 4.2 Phase ID 形式 [MUST]

```
p{N}       # 通常 Phase (N: 1-99)
p_final    # 完了検証 Phase (特殊)
```

正規表現: `^p([1-9][0-9]?|_final)$`

### 4.3 status 値 [MUST]

| 値 | 意味 |
|----|------|
| `pending` | 未着手 |
| `in_progress` | 作業中 |
| `done` | 完了 |

正規表現: `^(pending|in_progress|done)$` (小文字のみ)

### 4.4 depends_on 形式 [MAY]

```yaml
depends_on: [p1]
depends_on: [p1, p2]
depends_on: [p1, p2, p3]
```

- Phase ID のみ許容（subtask ID は不可）
- 循環依存は不正

---

## 5. subtask 構造

### 5.1 チェックボックス形式 [MUST]

```markdown
- [ ] **p{N}.{M}**: {criterion}
  - executor: {executor}
  - test_command: `{command}`
  - validations:
    - technical: "{text}"
    - consistency: "{text}"
    - completeness: "{text}"
```

### 5.2 subtask ID 形式 [MUST]

```
p{N}.{M}       # 通常 subtask
p_final.{M}    # 完了検証 subtask
ft{N}          # final_task
```

| パターン | N 範囲 | M 範囲 | 例 |
|----------|--------|--------|-----|
| p{N}.{M} | 1-99 | 1-99 | p1.1, p2.15 |
| p_final.{M} | - | 1-99 | p_final.1 |
| ft{N} | 0-99 | - | ft0, ft1, ft10 |

正規表現:
```regex
^p([1-9][0-9]?|_final)\.[1-9][0-9]?$  # subtask
^ft[0-9]{1,2}$                         # final_task
```

### 5.3 チェックボックス正規表現 [MUST]

```regex
# 未完了 subtask
^- \[ \] \*\*p([1-9][0-9]?|_final)\.[1-9][0-9]?\*\*:

# 完了 subtask
^- \[x\] \*\*p([1-9][0-9]?|_final)\.[1-9][0-9]?\*\*:

# 未完了 final_task
^- \[ \] \*\*ft[0-9]{1,2}\*\*:

# 完了 final_task
^- \[x\] \*\*ft[0-9]{1,2}\*\*:
```

**重要**:
- `[ ]` の空白は1つ [MUST]
- `[x]` は小文字のみ [MUST]（`[X]` は不正）
- `**` の前後に空白なし [MUST]
- `:` の後に空白 [SHOULD]

### 5.4 executor 値 [MUST]

| 値 | 意味 |
|----|------|
| `claudecode` | Claude Code が実行 |
| `codex` | Codex CLI が実行 |
| `coderabbit` | CodeRabbit が実行 |
| `user` | ユーザーが手動実行 |

正規表現: `^(claudecode|codex|coderabbit|user)$`

### 5.5 test_command 形式 [MUST]

```yaml
# 形式1: バッククォート（推奨）
test_command: `command && echo PASS || echo FAIL`

# 形式2: YAML パイプ（複数行の場合）
test_command: |
  command1 && \
  command2 && \
  echo PASS || echo FAIL
```

- バッククォート形式を推奨 [SHOULD]
- 複数行の場合は YAML パイプ [MAY]
- 引用符形式は非推奨 [SHOULD NOT]

### 5.6 validations 形式 [MUST]

```yaml
# 未完了時: 説明文のみ
validations:
  technical: "{検証内容の説明}"
  consistency: "{検証内容の説明}"
  completeness: "{検証内容の説明}"

# 完了時: 結果 + 説明
validations:
  technical: "PASS - {結果の説明}"
  consistency: "PASS - {結果の説明}"
  completeness: "PASS - {結果の説明}"
```

- 3項目全て必須 [MUST]
- 完了時は `PASS - ` または `FAIL - ` プレフィックス [SHOULD]

### 5.7 完了時の追加フィールド [SHOULD]

```yaml
- [x] **p1.1**: criterion ✓
  - executor: claudecode
  - test_command: `...`
  - validations:
    - technical: "PASS - ..."
    - consistency: "PASS - ..."
    - completeness: "PASS - ..."
  - validated: 2025-12-19T15:30:00  # [SHOULD]
```

- `✓` マークは任意 [MAY]
- `validated` は ISO 8601 形式 [SHOULD]

---

## 6. final_tasks セクション

### 6.1 構造 [MUST]

```markdown
## final_tasks

- [ ] **ft{N}**: {description}
  - command: `{command}`
  - status: {status}
```

### 6.2 オプションフィールド [MAY]

```yaml
- [x] **ft1**: description
  - command: `...`
  - status: done
  - result: "{実行結果の説明}"   # [MAY]
  - note: "{補足情報}"          # [MAY]
  - executed: {datetime}         # [MAY] ISO 8601
```

---

## 7. rollback セクション

### 7.1 構造 [SHOULD]

```markdown
## rollback

```yaml
手順:
  1. {ロールバック手順1}
  2. {ロールバック手順2}
```

または

```markdown
## rollback

{自由形式の説明}

```bash
# コマンド例
git checkout HEAD -- file.md
```

---

## 8. 変更履歴セクション

### 8.1 構造 [SHOULD]

```markdown
## 変更履歴

| 日時 | 内容 |
|------|------|
| YYYY-MM-DD | {変更内容} |
```

---

## 9. 検証ルール

### 9.1 必須セクションチェック [MUST]

```bash
# 以下のセクションが存在すること
grep -q '^## meta' playbook.md
grep -q '^## goal' playbook.md
grep -q '^## phases' playbook.md
grep -q '^## final_tasks' playbook.md
```

### 9.2 meta 必須フィールドチェック [MUST]

```bash
# schema_version: v2 が存在
grep -q 'schema_version: v2' playbook.md

# reviewed フィールドが存在
grep -q '^reviewed:' playbook.md
```

### 9.3 subtask 形式チェック [MUST]

```bash
# 不正なチェックボックス形式を検出
# 正常: `- [ ]` または `- [x]`
# 不正: `-[ ]`, `- []`, `- [X]`, `- [  ]`

grep -E '^- \[[^x ]\]' playbook.md  # 不正な文字
grep -E '^-\[' playbook.md          # 空白なし
grep -E '- \[X\]' playbook.md       # 大文字 X
```

---

## 10. マイグレーションガイド

### v1 → v2 への移行

1. meta セクションに `schema_version: v2` を追加
2. `reviewed` フィールドが存在することを確認
3. チェックボックス形式を正規化
   - `[X]` → `[x]`
   - `-[ ]` → `- [ ]`
4. status 値を小文字に統一
5. test_command を バッククォート形式に統一

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-19 | 初版作成。M084 Playbook Schema v2 仕様。 |
