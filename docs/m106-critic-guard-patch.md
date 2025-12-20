# M106: critic-guard.sh 手動修正パッチ

> **HARD_BLOCK 保護のため、以下の変更は手動で適用してください**

---

## 変更箇所

ファイル: `.claude/hooks/critic-guard.sh`

### 変更 1: ヘッダーコメントの更新（行 1-17）

**旧:**
```bash
#!/bin/bash
# ==============================================================================
# critic-guard.sh - state: done への変更を構造的にブロック
# ==============================================================================
# トリガー: PreToolUse(Edit)
# 目的: critic PASS なしで state: done に変更することを防止
#
# 動作:
#   1. 編集対象が state.md かチェック
#   2. new_string に "state: done" が含まれるかチェック
#   3. self_complete: true がファイルに存在しなければブロック
#
# 根拠: CONTEXT.md「自己報酬詐欺」対策
# ==============================================================================
```

**新:**
```bash
#!/bin/bash
# ==============================================================================
# critic-guard.sh - phase/state 完了時に critic 呼び出しを強制
# ==============================================================================
# トリガー: PreToolUse(Edit)
# 目的: critic PASS なしで phase/state を完了にすることを防止
#
# M106: phase.status 変更検出を追加
#   - state.md の "state: done" だけでなく
#   - playbook の "status: done" も検出
#
# 動作:
#   1. 編集対象が state.md または playbook かチェック
#   2. new_string に完了パターンが含まれるかチェック
#   3. self_complete: true がファイルに存在しなければブロック
#
# 根拠: CONTEXT.md「自己報酬詐欺」対策
# ==============================================================================
```

### 変更 2: 対象ファイル判定の拡張（行 34-37 を置き換え）

**旧:**
```bash
# state.md 以外は対象外
if [[ "$FILE_PATH" != *"state.md" ]]; then
    exit 0
fi
```

**新:**
```bash
# ==============================================================================
# M106: 対象ファイル判定（state.md + playbook-*.md）
# ==============================================================================
IS_STATE_MD=false
IS_PLAYBOOK=false

if [[ "$FILE_PATH" == *"state.md" ]]; then
    IS_STATE_MD=true
elif [[ "$FILE_PATH" == *"playbook-"*".md" ]]; then
    IS_PLAYBOOK=true
fi

# 対象外ファイルはスキップ
if [[ "$IS_STATE_MD" == false && "$IS_PLAYBOOK" == false ]]; then
    exit 0
fi
```

### 変更 3: 完了パターン検出の拡張（行 39-43 を置き換え）

**旧:**
```bash
# "state: done" を含まない編集は対象外
# YAML 形式を考慮: "state: done" または "state:done"
if ! echo "$NEW_STRING" | grep -qE "state:[[:space:]]*done"; then
    exit 0
fi
```

**新:**
```bash
# ==============================================================================
# M106: 完了パターン検出（state: done + status: done）
# ==============================================================================
COMPLETION_DETECTED=false

# state.md の "state: done" パターン
if echo "$NEW_STRING" | grep -qE "state:[[:space:]]*done"; then
    COMPLETION_DETECTED=true
fi

# playbook の "status: done" パターン
if [[ "$IS_PLAYBOOK" == true ]]; then
    if echo "$NEW_STRING" | grep -qE "status:[[:space:]]*(done|completed)"; then
        COMPLETION_DETECTED=true
    fi
fi

# 完了パターンが検出されなければスキップ
if [[ "$COMPLETION_DETECTED" == false ]]; then
    exit 0
fi
```

---

## 適用方法

```bash
# エディタで直接編集
code .claude/hooks/critic-guard.sh
# または
vim .claude/hooks/critic-guard.sh
```

---

## 検証

修正後、以下を実行して構文チェック:
```bash
bash -n .claude/hooks/critic-guard.sh && echo "OK"
```

---

*Created: 2025-12-20 (M106)*
