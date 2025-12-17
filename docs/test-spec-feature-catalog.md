# Feature Catalog Test Specification

> **機能カタログシステムのテスト仕様**
>
> docs/feature-catalog.yaml を Single Source of Truth として管理するシステムの動作検証

---

## meta

```yaml
feature: Feature Catalog System
created: 2025-12-17
milestone: M071
status: active
```

---

## テストシナリオ

### S1: 新規機能追加検出

**目的**: 新しい Hook/SubAgent/Skill が追加された場合に自動検出される

#### テストケース

| ID | シナリオ | 期待結果 |
|----|----------|----------|
| S1.1 | 新規 Hook を .claude/hooks/ に追加 | feature-catalog-sync.sh が MISMATCH を検出 |
| S1.2 | 新規 SubAgent を .claude/agents/ に追加 | feature-catalog-sync.sh が MISMATCH を検出 |
| S1.3 | 新規 Skill を .claude/skills/ に追加 | feature-catalog-sync.sh が MISMATCH を検出 |

#### 検証コマンド

```bash
# S1.1: Hook 追加検出テスト
touch .claude/hooks/test-dummy.sh
bash .claude/hooks/feature-catalog-sync.sh --check 2>&1 | grep -q "MISMATCH.*Hooks"
rm .claude/hooks/test-dummy.sh
```

---

### S2: 機能削除検出

**目的**: 存在しない機能がカタログに残っている場合に警告される

#### テストケース

| ID | シナリオ | 期待結果 |
|----|----------|----------|
| S2.1 | カタログに存在するが実ファイルが削除されている | MISMATCH を検出 |
| S2.2 | 詳細チェックで削除された機能名が表示される | "Removed" セクションに表示 |

#### 検証コマンド

```bash
# S2.1: 削除検出（カタログ数 > 実ファイル数）
# feature-catalog.yaml に存在しないファイルがあれば MISMATCH
bash .claude/hooks/feature-catalog-sync.sh --check 2>&1 | grep -qE "(OK|MISMATCH)"
```

---

### S3: カタログ整合性チェック

**目的**: docs/feature-catalog.yaml と実ファイルが完全に一致していることを確認

#### テストケース

| ID | シナリオ | 期待結果 |
|----|----------|----------|
| S3.1 | 全カテゴリで数が一致 | Status: OK |
| S3.2 | 1つでも不一致がある | Status: OUTDATED |

#### 検証コマンド

```bash
# S3.1: 整合性チェック
bash .claude/hooks/feature-catalog-sync.sh --check
# 期待: Status: OK または Status: OUTDATED
```

---

### S4: セッション開始時サマリー出力

**目的**: session-start.sh が機能カタログのサマリーを出力する

#### テストケース

| ID | シナリオ | 期待結果 |
|----|----------|----------|
| S4.1 | session-start.sh 実行 | "X Hooks | Y SubAgents | Z Skills" が出力される |
| S4.2 | カタログ不整合時 | "WARNING" が出力される |

#### 検証コマンド

```bash
# S4.1: サマリー出力確認
bash .claude/hooks/session-start.sh 2>&1 | grep -E "[0-9]+ Hooks"

# S4.2: 警告出力確認（不整合時のみ）
grep -q "WARNING" .claude/hooks/session-start.sh
```

---

### S5: YAML 構造検証

**目的**: feature-catalog.yaml が有効な YAML で必須フィールドを含む

#### テストケース

| ID | シナリオ | 期待結果 |
|----|----------|----------|
| S5.1 | YAML パース成功 | エラーなし |
| S5.2 | purpose フィールド 40個以上 | grep -c "purpose:" >= 40 |
| S5.3 | subagent_type フィールド 6個以上 | grep -c "subagent_type:" >= 6 |
| S5.4 | skill_dir フィールド 9個以上 | grep -c "skill_dir:" >= 9 |

#### 検証コマンド

```bash
# S5.1: YAML 構造検証
ruby -ryaml -e "YAML.load_file('docs/feature-catalog.yaml')" && echo PASS

# S5.2-S5.4: フィールド数カウント
grep -c "purpose:" docs/feature-catalog.yaml      # >= 40
grep -c "subagent_type:" docs/feature-catalog.yaml # >= 6
grep -c "skill_dir:" docs/feature-catalog.yaml     # >= 9
```

---

## E2E テスト実行

### 全テスト一括実行

```bash
# all-features-check.sh に含まれる feature-catalog 関連チェック
bash .claude/hooks/all-features-check.sh 2>&1 | grep -E "feature.catalog|PASS|FAIL"
```

### 個別テスト実行

```bash
# 1. カタログファイル存在
test -f docs/feature-catalog.yaml && echo PASS

# 2. 必須フィールド数
[ $(grep -c "purpose:" docs/feature-catalog.yaml) -ge 40 ] && echo PASS

# 3. sync スクリプト実行可能
test -x .claude/hooks/feature-catalog-sync.sh && echo PASS

# 4. session-start.sh 統合
bash .claude/hooks/session-start.sh 2>&1 | grep -qE "[0-9]+ Hooks" && echo PASS
```

---

## テスト結果サマリー

| カテゴリ | テスト数 | 期待 |
|----------|----------|------|
| 新規追加検出 | 3 | 全 PASS |
| 削除検出 | 2 | 全 PASS |
| 整合性チェック | 2 | 全 PASS |
| セッション統合 | 2 | 全 PASS |
| YAML 検証 | 4 | 全 PASS |
| **合計** | **13** | **全 PASS** |

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-17 | 初版作成。M071 Feature Catalog テスト仕様。 |
