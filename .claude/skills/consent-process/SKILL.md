# consent-process

> **合意プロセス（CONSENT）- ユーザープロンプトの誤解釈防止**

---

## frontmatter

```yaml
name: consent-process
description: ユーザープロンプトの誤解釈防止。[理解確認] ブロックを強制。
triggers:
  - playbook=null で新規タスク開始時
  - Edit/Write 前の合意取得が必要な時
auto_invoke: false  # INIT フェーズ 4.5 で手動参照
```

---

## 目的

```yaml
problem: |
  Claude がユーザープロンプトを「良かれと思って省略」し、
  意図しない大規模変更や方向性のずれが発生する。

solution: |
  Edit/Write 前に処理結果を構造化出力し、ユーザー合意を取得。
  Hook（consent-guard.sh）で合意ファイルの有無をチェック。
```

---

## [理解確認] フォーマット

```
[理解確認]
what: 「〇〇をすること」と理解しました
why: 目的は「△△」と推測します
how: 以下の手順で進めます
  1. ...
  2. ...
  3. ...
scope: 変更対象ファイル
  - file1.ts
  - file2.ts
exclusions: 以下は変更しません
  - config.json
  - CLAUDE.md
risks: |
  リスク1_{カテゴリ}:
    問題: {何が失敗する可能性があるか}
    影響: {失敗した場合の影響}
    対策: {どう防ぐか}
  リスク2_{カテゴリ}:
    問題: ...
    影響: ...
    対策: ...
```

---

## [失敗リスク分析] ガイドライン

```yaml
目的: |
  作業開始前に失敗パターンを構造的に検討し、
  タスク完遂の確実性を高める。

必須項目:
  - 問題: 何が失敗する可能性があるか（具体的に）
  - 影響: 失敗した場合の影響（深刻度）
  - 対策: どう防ぐか（具体的なアクション）

リスクカテゴリ例:
  - 不完全な網羅性: 必要なファイル/機能の見落とし
  - 整合性の欠如: ファイル間の矛盾
  - 技術的障害: 依存関係、権限、環境の問題
  - 仕様の誤解: ユーザー意図との乖離
  - 回帰: 既存機能の破壊

ルール:
  - 主要リスク 3-5 個に絞る（網羅性より深さ）
  - 形骸化防止: コピペではなくタスク固有のリスクを記載
  - 対策は実行可能なアクションであること
```

---

## ユーザー応答フロー

```yaml
OK: |
  「OK」「了解」「はい」「進めて」等 → prompt-guard.sh が自動検出 → consent ファイル自動削除 → 処理開始

  自動検出される合意パターン:
    - OK, ok, Ok
    - 了解
    - はい
    - 進めて, 進めます
    - yes, Yes, YES
    - お願い, おねがい
    - おｋ, オッケー, オーケー

  条件:
    - プロンプトが20文字以内
    - 合意パターンのみで構成されている（前後の空白は許容）

  注意:
    - 「OKだけど待って」等は検出されない（意図的）
    - Claude は consent を直接削除できない（HARD_BLOCK）

修正: |
  「〇〇ではなく△△です」→ Claude が [理解確認] を再出力 → 再合意
却下: |
  「やめて」または「キャンセル」→ 処理中止
```

---

## Hook 統合

```yaml
hook_name: consent-guard.sh
trigger: PreToolUse:Edit/Write
location: .claude/hooks/consent-guard.sh

workflow: |
  1. session-start.sh:
     → .claude/.session-init/pending 作成
     → .claude/.session-init/consent 作成

  2. init-guard.sh:
     → pending 存在 → Read 強制
     → Read 完了 → pending 削除

  3. [理解確認]:
     → Claude が処理結果を構造化出力
     → ユーザー応答待機

  4. consent-guard.sh:
     → consent ファイル存在?
     → YES（ユーザー OK) → ファイル削除 → 通過 → Edit/Write 実行
     → NO（未承認） → exit 2 ブロック → [理解確認] 再表示

  5. playbook-guard.sh:
     → playbook チェック → 通過

  6. LOOP:
     → done_criteria 検証 → 実行

file_locations:
  pending: .claude/.session-init/pending
  consent: .claude/.session-init/consent
```

---

## 実装状態

```yaml
status: implemented

components:
  consent_guard_sh:
    file: .claude/hooks/consent-guard.sh
    status: created
    functionality: consent ファイルの有無を確認、exit 2 でブロック

  settings_json:
    file: .claude/settings.json
    status: REGISTERED
    hook: PreToolUse:Edit/Write
    script: consent-guard.sh

  session_start_sh:
    file: .claude/hooks/session-start.sh
    status: INTEGRATED
    new_functionality: consent ファイル作成機能追加
```

---

## 禁止パターン

```yaml
forbidden:
  - [理解確認] なしで Edit/Write 実行
  - ユーザー応答なしで consent ファイル削除
  - consent ファイル作成後、[理解確認] を出力しない
```
