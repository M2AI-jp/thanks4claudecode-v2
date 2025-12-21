# Deep Audit: 実行動線（Execution Flow）

> **M152: 実行動線の全10ファイルを精査し、凍結判定を実施**
>
> 実施日: 2025-12-21

---

## 概要

実行動線は「playbook → Edit/Write → Guard発火」のフローを構成するコンポーネント群。
コード変更時の品質と安全性を構造的に保証する。

---

## 精査結果サマリー

| # | ファイル | 行数 | 役割 | 処遇 | 理由 |
|---|----------|------|------|------|------|
| 1 | init-guard.sh | 180 | 必須ファイル Read 強制 | **Keep** | セッション開始の初期化 |
| 2 | playbook-guard.sh | 124 | playbook=null ブロック | **Keep (Core)** | Golden Path の構造的強制 |
| 3 | subtask-guard.sh | 172 | 3観点検証強制 | **Keep** | 品質保証の構造化 |
| 4 | scope-guard.sh | 129 | スコープ変更検出 | **Simplify** | 警告のみで効果限定的 |
| 5 | check-protected-edit.sh | 243 | ファイル保護 | **Keep (Core)** | HARD_BLOCK の実装 |
| 6 | pre-bash-check.sh | 128 | Bash コマンドチェック | **Keep (Core)** | 危険コマンドのブロック |
| 7 | check-main-branch.sh | 102 | main ブランチ保護 | **Keep** | ブランチ規律の強制 |
| 8 | lint-check.sh | 96 | コミット前静的解析 | **Keep** | コード品質チェック |
| 9 | lint-checker/SKILL.md | 135 | コード品質スキル | **Keep** | 静的解析の専門知識 |
| 10 | test-runner/SKILL.md | 161 | テスト実行スキル | **Keep** | テストの専門知識 |

---

## 詳細分析

### 1. init-guard.sh - Keep

**パス**: `.claude/hooks/init-guard.sh`

**役割**:
- PreToolUse(*) Hook
- 必須ファイル（state.md, playbook）が Read されるまで他のツールをブロック

**主要機能**:
```yaml
必須ファイル:
  - state.md: 常に必須
  - playbook: session-start.sh で設定された場合

バイパス条件:
  - admin モード: 必須ファイル Read チェックのみバイパス
  - Read/Grep/Glob: 常に許可（情報収集）
  - Bash の基本コマンド: sed, grep, cat, echo, ls 等

単一責任:
  - 必須ファイル Read 強制のみ担当
  - playbook 存在チェックは playbook-guard.sh が担当
```

**凍結理由**:
- セッション開始時の初期化を保証
- コンテキスト理解なしの作業開始を防止

---

### 2. playbook-guard.sh - Keep (Core)

**パス**: `.claude/hooks/playbook-guard.sh`

**役割**:
- PreToolUse(Edit/Write) Hook
- playbook=null での Edit/Write をブロック

**主要機能**:
```yaml
コア契約実装:
  - M079: security モードに関係なく playbook チェック維持
  - CLAUDE.md Core Contract "Playbook Gate" を実装

常に許可:
  - state.md への編集
  - playbook ファイル自体の作成/編集（ブートストラップ例外）

ブロック条件:
  - playbook が null または空
  - 対処法: pm エージェントを呼び出す

警告条件:
  - reviewed: false の playbook
  - reviewer による検証を推奨
```

**凍結理由**:
- Golden Path の構造的強制
- Core Contract の中核実装
- これがなければ playbook なしで作業開始可能

---

### 3. subtask-guard.sh - Keep

**パス**: `.claude/hooks/subtask-guard.sh`

**役割**:
- PreToolUse(Edit) Hook
- subtask 完了変更時に 3観点検証を強制

**主要機能**:
```yaml
3観点検証:
  - technical: 技術的に正しく動作するか
  - consistency: 他コンポーネントと整合性があるか
  - completeness: 必要な変更が全て完了しているか

V12 対応:
  - チェックボックス形式 `- [ ]` → `- [x]` を検出
  - V11 形式 `status: done` も検出

STRICT モード:
  - STRICT=1 (デフォルト): validations 不足でブロック
  - STRICT=0: 警告のみ

例外:
  - final_tasks の変更は許可
```

**凍結理由**:
- subtask 単位の品質保証
- 報酬詐欺防止の補助メカニズム

---

### 4. scope-guard.sh - Simplify

**パス**: `.claude/hooks/scope-guard.sh`

**役割**:
- PreToolUse(Edit/Write) Hook
- done_when/done_criteria の無断変更を検出

**問題点**:
```yaml
現状:
  - デフォルトは WARN のみ（ブロックしない）
  - STRICT_MODE=true でブロック可能だが使われていない

効果:
  - 警告が表示されるだけで抑止力が弱い
  - pm 経由を促すが強制ではない

簡素化提案:
  - STRICT_MODE=true をデフォルトにする
  - または pm.md のスコープ管理に統合
  - 警告のみなら削除検討
```

---

### 5. check-protected-edit.sh - Keep (Core)

**パス**: `.claude/hooks/check-protected-edit.sh`

**役割**:
- PreToolUse(Edit/Write) Hook
- protected-files.txt に基づくファイル保護

**主要機能**:
```yaml
保護レベル:
  - HARD_BLOCK: 絶対守護（admin でも不可）
  - BLOCK: strict モードでブロック、trusted で警告
  - WARN: 警告のみ

M079 Core Contract:
  - HARD_BLOCK は security_mode に関係なく常に保護
  - CLAUDE.md, protected-files.txt 等

開発者モード:
  - developer モード: HARD_BLOCK 以外を無効化（非推奨）
```

**凍結理由**:
- ファイル保護の中核実装
- HARD_BLOCK メカニズムの実装
- Core Contract の一部

---

### 6. pre-bash-check.sh - Keep (Core)

**パス**: `.claude/hooks/pre-bash-check.sh`

**役割**:
- PreToolUse(Bash) Hook
- Bash コマンドの契約チェック

**主要機能**:
```yaml
契約チェック:
  - contract.sh を source して判定委譲
  - HARD_BLOCK ファイルへの書き込み検出
  - playbook=null で変更系コマンドをブロック

git commit 時:
  - 回帰テスト実行
  - check-coherence.sh 実行
  - check-state-update.sh 実行

Fail-closed:
  - jq がなければ exit 2（安全側に倒す）
```

**凍結理由**:
- Bash コマンドの安全性保証
- コミット前の品質チェック統合
- Core Contract の一部

---

### 7. check-main-branch.sh - Keep

**パス**: `.claude/hooks/check-main-branch.sh`

**役割**:
- PreToolUse(*) Hook
- main ブランチでの作業をブロック

**主要機能**:
```yaml
ブロック条件:
  - main/master ブランチ
  - focus.current = workspace

許可条件:
  - focus = setup/product/plan-template
  - Read/Grep/Glob（読み取りのみ）
  - git checkout/switch/branch（ブランチ操作）
  - state.md への編集（デッドロック回避）
```

**凍結理由**:
- ブランチ規律の構造的強制
- main への直接コミット防止

---

### 8. lint-check.sh - Keep

**パス**: `.claude/hooks/lint-check.sh`

**役割**:
- PreToolUse(Bash) Hook
- git commit 前の静的解析

**主要機能**:
```yaml
チェック対象:
  - JavaScript/TypeScript: ESLint
  - Shell: ShellCheck
  - Python: Ruff

動作:
  - 警告のみ（ブロックしない）
  - exit 0 で常に通過
```

**凍結理由**:
- コード品質の自動チェック
- コミット前の問題検出

---

### 9. lint-checker/SKILL.md - Keep

**パス**: `.claude/skills/lint-checker/SKILL.md`

**役割**:
- コード品質チェック専門スキル
- TypeScript/JavaScript の ESLint、型チェック

**主要内容**:
- チェック項目（ESLint、TypeScript、コーディング規約）
- 実行手順（pnpm lint, pnpm tsc）
- 出力形式
- 修正提案

**凍結理由**:
- 静的解析の専門知識を提供
- critic.md から参照される

---

### 10. test-runner/SKILL.md - Keep

**パス**: `.claude/skills/test-runner/SKILL.md`

**役割**:
- テスト実行・検証専門スキル
- Unit, E2E, 型チェック, ビルドテスト

**主要内容**:
- テスト種類（Unit, E2E, Type, Build）
- 実行手順
- 出力形式
- 失敗時の対応

**凍結理由**:
- テスト実行の専門知識を提供
- critic.md から参照される

---

## テスト結果

```
Flow Runtime Test Results
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  PASS: 33
  FAIL: 0

  ALL FLOW RUNTIME TESTS PASSED
```

実行動線関連テスト（E1-E9）: 全て PASS

---

## Codex レビュー結果

```yaml
レビュー日: 2025-12-21
レビュアー: Codex

全体評価: Approved

コメント:
  - playbook-guard.sh: Core Contract 実装として適切
  - check-protected-edit.sh: HARD_BLOCK メカニズムが堅牢
  - pre-bash-check.sh: Fail-closed 設計が良い

改善提案:
  - scope-guard.sh: STRICT_MODE=true をデフォルトにすべき
  - subtask-guard.sh: 172行は長め、分割検討

結論: 実行動線は Quality Layer として適切に設計されている。
```

---

## 結論

### Core として凍結するファイル（3ファイル）

1. **playbook-guard.sh** - Golden Path の構造的強制
2. **check-protected-edit.sh** - HARD_BLOCK の実装
3. **pre-bash-check.sh** - Bash コマンドの安全性保証

### Keep として維持するファイル（6ファイル）

4. **init-guard.sh** - セッション初期化
5. **subtask-guard.sh** - 3観点検証
6. **check-main-branch.sh** - ブランチ保護
7. **lint-check.sh** - コミット前静的解析
8. **lint-checker/SKILL.md** - 静的解析スキル
9. **test-runner/SKILL.md** - テスト実行スキル

### Simplify として簡素化するファイル（1ファイル）

10. **scope-guard.sh** - STRICT_MODE 強化または削除検討

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-21 | 初版作成 - M152 実行動線 Deep Audit |
