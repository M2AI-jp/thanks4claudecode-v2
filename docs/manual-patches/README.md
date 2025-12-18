# Manual Patches for HARD_BLOCK Files

> **HARD_BLOCK ファイルは Claude Code からは編集できません。**
> このディレクトリには手動で適用すべきパッチが含まれています。

---

## HARD_BLOCK ファイル一覧

| ファイル | 理由 | contract.sh 統合 |
|----------|------|------------------|
| `CLAUDE.md` | 凍結された憲法 | 不要 |
| `.claude/protected-files.txt` | 保護リスト自体の保護 | 不要 |
| `.claude/hooks/playbook-guard.sh` | Playbook Gate の実装 | **必要** (パッチ提供) |
| `.claude/hooks/init-guard.sh` | 初期化ガードの実装 | 不要 (セッション初期化専用) |
| `.claude/hooks/critic-guard.sh` | Critic ガードの実装 | 不要 (自己承認防止専用) |
| `.claude/hooks/scope-guard.sh` | Scope ガードの実装 | 不要 (スコープクリープ検出専用) |
| `.claude/hooks/executor-guard.sh` | Executor ガードの実装 | 不要 (役割強制専用) |

### contract.sh 統合が必要なフック

`playbook-guard.sh` のみが `contract.sh` への委譲が必要です。
他の HARD_BLOCK フックは専門的な目的を持ち、契約チェック（Playbook Gate, Maintenance Allowlist）とは異なるロジックを実装しています。

---

## パッチ適用手順

### 1. パッチファイルの確認

```bash
ls docs/manual-patches/*.patch
```

### 2. パッチの内容を確認

```bash
cat docs/manual-patches/playbook-guard.sh.patch
```

### 3. 手動で適用

```bash
# 方法1: patch コマンドを使用（推奨）
patch -p0 < docs/manual-patches/playbook-guard.sh.patch

# 方法2: 手動編集
# パッチの内容を見ながらエディタで直接編集
```

### 4. 動作確認

```bash
# E2E テストを実行
bash scripts/e2e-contract-test.sh

# Hook 委譲検証を実行
bash scripts/verify-hook-delegation.sh
```

---

## パッチ一覧

| ファイル | 目的 | 優先度 |
|----------|------|--------|
| `playbook-guard.sh.patch` | contract.sh への委譲を追加 | 高 |
| `init-guard.sh.patch` | (予定) contract.sh への委譲 | 中 |

---

## 注意事項

1. **パッチ適用前にバックアップを取る**
   ```bash
   cp .claude/hooks/playbook-guard.sh .claude/hooks/playbook-guard.sh.bak
   ```

2. **パッチ適用後は必ずテストを実行**
   ```bash
   bash scripts/e2e-contract-test.sh
   ```

3. **問題が発生した場合はロールバック**
   ```bash
   cp .claude/hooks/playbook-guard.sh.bak .claude/hooks/playbook-guard.sh
   ```

---

## パッチの設計方針

各パッチは以下の原則に従って設計されています:

1. **最小限の変更**: 必要な変更のみを含む
2. **後方互換性**: contract.sh がない場合は旧ロジックにフォールバック
3. **テスト可能**: E2E テストで動作確認可能
4. **コメント付き**: 変更の理由を明記

---

## パッチ作成方法（メンテナー向け）

新しいパッチを作成する場合:

```bash
# 1. オリジナルをコピー
cp .claude/hooks/target.sh .claude/hooks/target.sh.orig

# 2. 手動で編集
# (エディタで .claude/hooks/target.sh を編集)

# 3. diff を生成
diff -u .claude/hooks/target.sh.orig .claude/hooks/target.sh > docs/manual-patches/target.sh.patch

# 4. オリジナルに戻す（Claude Code で使用するため）
mv .claude/hooks/target.sh.orig .claude/hooks/target.sh
```
