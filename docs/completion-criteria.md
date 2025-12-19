# completion-criteria.md

> **「完成」の定義 - 5つの動作シナリオ**

---

## 目的

```yaml
problem: |
  数字での成果報告（Hook X個、Milestone Y件）は自己欺瞞を生む。
  「45 Milestone 達成」と言っても、実際に動くかは別問題。

solution: |
  数字ではなく「動くシナリオ」で完成を定義する。
  各シナリオは実際に検証可能なテストを持つ。
```

---

## シナリオ 1: 黄金動線

**目的**: タスク依頼から完了までの基本フローが動作すること

### 期待動作

```
1. ユーザーが「〇〇を作って」とタスク依頼
2. pm SubAgent が自動起動
3. playbook が作成される
4. state.md が更新される（playbook.active, goal）
5. 作業が playbook に従って進行
6. critic SubAgent が done_criteria を検証
7. 検証 PASS で phase 完了
8. 全 phase 完了で playbook アーカイブ
9. 次タスクが自動提案される
```

### テスト方法

```bash
# 準備: playbook=null, main ブランチの状態から開始
# 入力: 「state.md にテストコメントを追加して」

# 検証項目:
# 1. pm が呼ばれた（log-subagent.sh のログ確認）
grep "pm" .claude/logs/subagent.log

# 2. playbook が作成された
test -f plan/playbook-*.md

# 3. state.md が更新された
grep "playbook.active:" state.md | grep -v "null"

# 4. 作業後に critic が呼ばれた
grep "critic" .claude/logs/subagent.log
```

### 失敗パターン

- pm が呼ばれずに直接 Edit/Write → playbook-guard でブロック
- playbook なしで作業開始 → init-guard でブロック
- critic なしで完了宣言 → critic-guard で警告

---

## シナリオ 2: メンテ作業デッドロック防止

**目的**: playbook=null でもメンテナンス作業が可能なこと

### 期待動作

```
1. playbook 完了後、state.md の playbook.active=null
2. この状態でも以下が可能:
   - git add -A
   - git commit
   - git merge
   - git branch -d
   - git checkout main
3. 新規の Edit/Write は引き続きブロック
```

### テスト方法

```bash
# 準備: playbook=null の状態を作成
# state.md の playbook.active を null に設定

# 検証: メンテナンスコマンドが通過
scripts/contract.sh check_bash "git add -A"     # → PASS
scripts/contract.sh check_bash "git commit -m 'test'"  # → PASS
scripts/contract.sh check_bash "git merge feat/xxx"    # → PASS

# 検証: 変更系コマンドはブロック
scripts/contract.sh check_bash "cat > test.txt"  # → BLOCK
```

### 失敗パターン

- git add が playbook=null でブロック → デッドロック発生
- git commit 後に playbook が必要 → 永遠にコミットできない

### 関連修正

- M096: pre-bash-check.sh にメンテナンスパターン追加
- scripts/contract.sh に ADMIN_MAINTENANCE_PATTERNS 追加

---

## シナリオ 3: HARD_BLOCK 保護

**目的**: 重要ファイルが誤って編集・削除されないこと

### 対象ファイル

```
.claude/protected-files.txt に記載:
- CLAUDE.md
- .claude/protected-files.txt
- .claude/settings.json
- .claude/.session-init/consent
- .claude/.session-init/pending
```

### 期待動作

```
1. HARD_BLOCK ファイルへの Edit/Write → exit 2 でブロック
2. 理由メッセージが表示される
3. admin モードでも回避不可
4. 誤削除からの復旧手順が明確
```

### テスト方法

```bash
# 検証: HARD_BLOCK ファイルがブロックされる
scripts/contract.sh is_hard_block "CLAUDE.md"
# → 終了コード 0（保護対象）

scripts/contract.sh is_hard_block "README.md"
# → 終了コード 1（保護対象外）

# E2E テスト
bash scripts/e2e-contract-test.sh | grep "HARD_BLOCK"
```

### 復旧手順

```bash
# CLAUDE.md を誤って変更した場合
git checkout HEAD -- CLAUDE.md

# consent/pending ファイルが消えた場合
bash .claude/hooks/session-start.sh
```

---

## シナリオ 4: 報酬詐欺防止

**目的**: LLM が自己承認で完了を偽装できないこと

### 期待動作

```
1. done_criteria は playbook 作成時に定義
2. phase 完了前に critic SubAgent が検証
3. critic は test_command を実行して PASS/FAIL 判定
4. Claude 自身が critic の結果を書き換えられない
5. FAIL の場合は phase 完了をブロック
```

### 詐欺の抜け道と対策

| 抜け道 | 対策 |
|--------|------|
| done_criteria を曖昧に書く | pm が具体的な test_command を強制 |
| critic を呼ばずに完了宣言 | critic-guard.sh でブロック |
| test_command を通るよう調整 | reviewer が事後チェック |
| 存在確認だけのテスト | grep -q より実行テストを推奨 |

### テスト方法

```bash
# 検証: critic なしで phase 完了を試みる
# → critic-guard.sh が警告

# 検証: done_criteria のテスト
bash scripts/e2e-contract-test.sh | grep "critic"
```

### 関連コンポーネント

- critic SubAgent: done_criteria 検証
- critic-guard.sh: 検証漏れ防止
- pm SubAgent: test_command 付き playbook 作成

---

## シナリオ 5: README/実装/テスト一致

**目的**: ドキュメントと実態が乖離しないこと

### 期待動作

```
1. README の数値は自動生成
2. 手動更新は嘘の温床なので禁止
3. governance/core-manifest.yaml で Core/Non-Core を定義
4. 未登録 Hook、未使用 SubAgent を可視化
5. 定期的な整合性チェック
```

### 乖離検出方法

```bash
# 1. 統計の自動生成
bash scripts/generate-readme-stats.sh

# 出力例:
# hooks: 35 (registered: 29)  ← 6個の未登録 Hook がある
# milestones: 47 (achieved: 46)  ← 1個が進行中

# 2. README 更新
bash scripts/generate-readme-stats.sh --update

# 3. 仕様同期チェック
bash scripts/check-spec-sync.sh
```

### テスト方法

```bash
# 検証: 挙動テスト
bash scripts/behavior-test.sh

# 検証: 未使用ファイル検出
bash scripts/find-unused.sh
```

### 関連コンポーネント

- governance/core-manifest.yaml: Core/Non-Core の正本
- scripts/behavior-test.sh: 挙動テスト
- scripts/find-unused.sh: 未使用ファイル検出

---

## まとめ

| シナリオ | 検証コマンド | 主要コンポーネント |
|----------|--------------|-------------------|
| Playbook Gate | `bash scripts/behavior-test.sh` | playbook-guard, pre-bash-check |
| HARD_BLOCK 保護 | `bash scripts/behavior-test.sh` | check-protected-edit |
| デッドロック回避 | `bash scripts/behavior-test.sh` | pre-bash-check (例外処理) |
| 黄金動線 | pm/critic SubAgent が動作 | pm, critic |

---

## テスト方針（M098 で凍結）

```yaml
policy:
  grep_prohibition: true
  reason: |
    grep/test -f による「存在確認」は PASS 条件にしない。
    「ファイルがある」≠「動く」だから。

allowed_tests:
  - 挙動テスト（実行して exit code で判定）
  - scripts/behavior-test.sh による統合テスト

forbidden_tests:
  - grep -q "keyword" file && echo PASS
  - test -f path/to/file && echo PASS
  - ファイル数のカウント

enforcement:
  - PR レビューで grep ベースの done_when は reject
  - 正本は governance/core-manifest.yaml
```

---

## 更新履歴

| 日付 | 変更 |
|------|------|
| 2025-12-20 | grep 禁止ポリシーを追加（M098） |
| 2025-12-20 | 初版作成（M097） |
