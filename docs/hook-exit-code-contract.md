# Hook Exit Code Contract

> **Hook の出力と exit code の共通契約**
>
> 全ての Hook はこの契約に準拠すること。

---

## 概要

Hook が意図せず運用をブロックすることを防ぐため、出力と exit code の共通ルールを定める。

原則: **Hook が壊れても作業が詰まらない。少なくとも理由が出力される。**

---

## 契約定義

### WARN

**用途**: 警告を出すが、処理は続行する

```yaml
exit_code: 0
output_target: stderr
message_format: "[WARN] {hook_name}: {reason}"
```

**例**:
```bash
echo "[WARN] subtask-guard: playbook not found, skipping validation" >&2
exit 0
```

**使用場面**:
- 前提条件が満たされていないが、ブロックするほどではない
- 推奨されない操作だが、禁止はしない
- パース失敗したが、安全に処理をスキップできる

---

### BLOCK

**用途**: 処理を中断し、Claude に操作をやり直させる

```yaml
exit_code: 2  # 非0（慣例として 2 を使用）
output_target: stderr
message_format: "[BLOCK] {hook_name}: {reason}"
```

**例**:
```bash
echo "[BLOCK] playbook-guard: playbook.active is null, Edit/Write blocked" >&2
exit 2
```

**使用場面**:
- 重大な制約違反（playbook なしでの編集など）
- セキュリティ上の懸念
- 必須条件が満たされていない

---

### INTERNAL ERROR

**用途**: Hook 自体にエラーが発生したが、運用を止めない

```yaml
exit_code: 0  # 運用を止めないため exit 0
output_target: stderr
message_format: "[INTERNAL ERROR] {hook_name}: {error_description}"
```

**例**:
```bash
echo "[INTERNAL ERROR] subtask-guard: JSON parse failed, allowing operation" >&2
exit 0
```

**使用場面**:
- JSON パースに失敗した
- 依存ファイルが見つからない
- 予期しない入力形式

**原則**:
- Hook のエラーで運用が詰まるのは最悪のケース
- エラーが発生しても、安全側に倒して処理を通す
- ただし、必ず stderr にエラー内容を出力する

---

## 必須ルール

### 1. 無出力禁止

全ての Hook は、どのパスを通っても **必ず何かを stderr に出力する**。

```bash
# BAD: 無出力で終了
if [ condition ]; then
    exit 0
fi

# GOOD: 理由を出力して終了
if [ condition ]; then
    echo "[SKIP] hook-name: condition not met" >&2
    exit 0
fi
```

### 2. exit code の一貫性

| 状態 | exit code |
|------|-----------|
| 正常終了（PASS/WARN/SKIP/INTERNAL ERROR） | 0 |
| ブロック（BLOCK） | 2 |
| その他のエラー | 1 |

### 3. メッセージ形式

```
[{TYPE}] {hook_name}: {reason}
```

- TYPE: PASS, WARN, SKIP, BLOCK, INTERNAL ERROR のいずれか
- hook_name: スクリプト名（拡張子なし）
- reason: 1行で理由を説明

---

## 実装パターン

### 基本テンプレート

```bash
#!/bin/bash
set -uo pipefail  # -e は使わない（エラーでも処理を続けたいため）

HOOK_NAME="hook-name"

# JSON パース（失敗しても止めない）
INPUT=$(cat) || {
    echo "[INTERNAL ERROR] $HOOK_NAME: failed to read input" >&2
    exit 0
}

# jq パース（失敗しても止めない）
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null) || {
    echo "[INTERNAL ERROR] $HOOK_NAME: JSON parse failed, allowing operation" >&2
    exit 0
}

# 本処理
if [ -z "$TOOL_NAME" ]; then
    echo "[SKIP] $HOOK_NAME: no tool_name in input" >&2
    exit 0
fi

# ブロック条件
if [ "$SHOULD_BLOCK" = "true" ]; then
    echo "[BLOCK] $HOOK_NAME: reason for blocking" >&2
    exit 2
fi

echo "[PASS] $HOOK_NAME: all checks passed" >&2
exit 0
```

---

## 対象 Hook

以下の Hook はこの契約に準拠する:

| Hook | 主な役割 | 契約準拠 |
|------|----------|----------|
| subtask-guard.sh | subtask 完了検証 | 必須 |
| create-pr-hook.sh | PR 自動作成 | 必須 |
| archive-playbook.sh | playbook アーカイブ | 必須 |
| playbook-guard.sh | playbook 存在チェック | 必須 |
| init-guard.sh | 必須ファイル Read 強制 | 必須 |

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-19 | 初版作成（M082 Hook 契約固定） |
