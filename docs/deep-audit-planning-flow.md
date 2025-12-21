# Deep Audit: 計画動線（Planning Flow）

> **M150: 計画動線の全7ファイルを精査し、凍結判定を実施**
>
> 実施日: 2025-12-21

---

## 概要

計画動線は「要求 → pm → playbook → state.md」のフローを構成するコンポーネント群。
全てのタスク開始がこの動線を経由することで、品質と追跡性を保証する。

---

## 精査結果サマリー

| # | ファイル | 行数 | 役割 | 処遇 | 理由 |
|---|----------|------|------|------|------|
| 1 | prompt-guard.sh | 275 | State Injection + タスクブロック | **Keep (Core)** | Golden Path 強制の要 |
| 2 | task-start.md | 190 | project.md → pm → playbook フロー | **Keep** | 標準タスク開始手順 |
| 3 | pm.md | 442 | 全タスク開始の必須経由点 | **Keep (Core)** | playbook 作成の唯一の正規ルート |
| 4 | state/SKILL.md | 121 | state.md 管理の専門知識 | **Keep** | 状態管理に必須 |
| 5 | plan-management/SKILL.md | 119 | 多層計画管理 | **Keep** | playbook 運用知識 |
| 6 | playbook-init.md | 277 | playbook 作成ウィザード | **Simplify** | task-start.md と重複あり |
| 7 | reviewer.md | 307 | playbook/コード レビュー | **Keep (Core)** | ダブルチェックの要 |

---

## 詳細分析

### 1. prompt-guard.sh - Keep (Core)

**パス**: `.claude/hooks/prompt-guard.sh`

**役割**:
- UserPromptSubmit Hook として全プロンプトを処理
- State Injection: 常に state/project/playbook 情報を systemMessage に注入
- プロンプト保存: user-intent.md にログ（コンテキスト消失対策）
- タスク検出 + ブロック: playbook=null でタスク要求時に exit 2

**主要機能**:
```yaml
State Injection:
  - focus, milestone, phase, playbook を抽出
  - git branch, status を追加
  - 常に systemMessage で出力

タスク検出:
  - WORK_PATTERNS: 作って|実装して|追加して|修正して|...
  - QUESTION_PATTERNS: 質問は除外
  - discussion モード: 警告のみ
  - それ以外: exit 2 でブロック（M149-B）

スコープチェック:
  - スコープクリープパターン検出
  - 無関係なリクエストをブロック
```

**凍結理由**:
- Golden Path（pm 必須）の構造的強制
- これがなければ playbook=null で作業開始できてしまう
- Core Layer として保護必須

---

### 2. task-start.md - Keep

**パス**: `.claude/commands/task-start.md`

**役割**:
- 標準タスク開始コマンド
- project.md から done_when を参照し pm を呼び出す

**フロー**:
```
project.md 参照 → タスク選択 → ブランチ作成 → playbook 作成 → state.md 更新 → LOOP 開始
```

**主要ルール**:
- 全 playbook は derives_from を持つ
- pm を経由せずに playbook 作成禁止
- main ブランチでの直接作業禁止

**凍結理由**:
- pm 経由の構造的保証
- project.md との紐付けを強制
- 品質の一貫性を保証

---

### 3. pm.md - Keep (Core)

**パス**: `.claude/agents/pm.md`

**役割**:
- Project Manager Agent
- 全タスク開始の必須経由点
- playbook 作成・管理・進捗追跡

**主要機能**:
```yaml
計画の導出:
  - project.md の not_achieved を分析
  - depends_on を解決
  - decomposition を参照して playbook skeleton 生成

playbook 作成:
  - V11: subtasks 構造対応
  - executor + test_command 定義
  - criterion 検証可能性チェック

スコープ管理:
  - 「それは別タスクです」と NO を言う
  - スコープクリープを検出して警告

reviewer 連携:
  - pm が作成 → reviewer が検証
  - PASS なしで playbook 確定禁止
```

**凍結理由**:
- 計画動線の中核
- playbook 作成の唯一の正規ルート
- これがなければタスク管理が崩壊

---

### 4. state/SKILL.md - Keep

**パス**: `.claude/skills/state/SKILL.md`

**役割**:
- state.md 管理の専門知識を提供
- Skill として Claude に知識を注入

**主要内容**:
- state.md の構造定義
- focus の有効値と編集権限
- CRITIQUE の実行方法
- playbook 必須ルール

**凍結理由**:
- state.md の正しい操作方法を保証
- CRITIQUE の実行形式を標準化
- playbook 必須ルールを明文化

---

### 5. plan-management/SKILL.md - Keep

**パス**: `.claude/skills/plan-management/SKILL.md`

**役割**:
- 多層計画管理の専門知識
- roadmap → milestones → playbooks → phases の階層

**主要内容**:
- Plan Hierarchy Structure
- Phase Transition Rules
- Four-Tuple Coherence（focus/layer/playbook/branch）
- Session Start Checklist

**凍結理由**:
- playbook 運用の知識を標準化
- phase 遷移ルールを明文化
- 整合性確認の手順を提供

---

### 6. playbook-init.md - Simplify

**パス**: `.claude/commands/playbook-init.md`

**役割**:
- 新しい playbook を作成するウィザード
- /init コマンドとして提供

**重複点**:
- task-start.md と同じ目的
- 両方とも pm を呼び出す
- フローが似ている

**簡素化提案**:
```yaml
現状:
  - task-start.md: project.md 経由必須
  - playbook-init.md: 直接作成可能（旧互換）

提案:
  - playbook-init.md を「task-start.md へのエイリアス」に簡素化
  - または、task-start.md に統合して playbook-init.md を削除

判断:
  - 旧互換性のため残す
  - ただし内容を task-start.md への参照に簡素化
  - 重複するフロー図・手順は削除
```

---

### 7. reviewer.md - Keep (Core)

**パス**: `.claude/agents/reviewer.md`

**役割**:
- Code & Design Reviewer Agent
- playbook レビューの主責務

**主要機能**:
```yaml
playbook レビュー:
  - done_when の検証可能性チェック
  - test_command の適切性評価
  - Phase 依存関係の確認

動的 Reviewer 選択:
  - config.roles.reviewer に基づく
  - claudecode または codex を選択

PASS/FAIL 判定:
  - PASS: reviewed: true に更新
  - FAIL: 修正提案を返却
  - 最大 3回リトライ
```

**凍結理由**:
- ダブルチェックの構造的保証
- 「作成者 ≠ 検証者」の原則
- playbook 品質の門番

---

## テスト結果

```
Flow Runtime Test Results
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  PASS: 33
  FAIL: 0

  ALL FLOW RUNTIME TESTS PASSED
```

計画動線関連テスト（P1-P7）: 全て PASS

---

## Codex レビュー結果

```yaml
レビュー日: 2025-12-21
レビュアー: Codex

全体評価: Approved

コメント:
  - prompt-guard.sh: State Injection は効果的。exit 2 ブロックは適切。
  - pm.md: V11 subtasks 構造は良い設計。reviewer 連携も明確。
  - reviewer.md: 動的 Reviewer 選択は柔軟性あり。

改善提案:
  - playbook-init.md: task-start.md との重複を解消すべき
  - state/SKILL.md: plan-management/SKILL.md との境界を明確化すべき

結論: 計画動線は適切に設計されている。簡素化の余地あり。
```

---

## 結論

### Core として凍結するファイル（3ファイル）

1. **prompt-guard.sh** - Golden Path 強制の要
2. **pm.md** - playbook 作成の唯一の正規ルート
3. **reviewer.md** - ダブルチェックの要

### Keep として維持するファイル（3ファイル）

4. **task-start.md** - 標準タスク開始手順
5. **state/SKILL.md** - 状態管理知識
6. **plan-management/SKILL.md** - 計画管理知識

### Simplify として簡素化するファイル（1ファイル）

7. **playbook-init.md** - task-start.md への参照に簡素化

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-21 | 初版作成 - M150 計画動線 Deep Audit |
