# Deep Audit: 完了動線 + 共通基盤 + 横断的

> **M153: 完了動線7ファイル + 共通基盤6ファイル + 横断的3ファイル = 計16ファイルを精査**
>
> 実施日: 2025-12-21

---

## 概要

このドキュメントは Extension Layer を構成するコンポーネント群を精査し、凍結判定を実施した記録。
Core Layer（計画動線 + 検証動線）と Quality Layer（実行動線）以外の全コンポーネントを対象とする。

---

## 精査結果サマリー

### 完了動線（7ファイル）

| # | ファイル | 行数 | 役割 | 処遇 | 理由 |
|---|----------|------|------|------|------|
| 1 | archive-playbook.sh | 259 | playbook アーカイブ提案 | **Keep** | PDCA サイクルの完了処理 |
| 2 | cleanup-hook.sh | 111 | 一時ファイル削除 | **Simplify** | 効果限定的 |
| 3 | post-loop.md | 82 | ループ後処理コマンド | **Keep** | 自動フロー継続 |
| 4 | context-management/SKILL.md | 192 | コンテキスト管理スキル | **Keep** | /compact の専門知識 |
| 5 | rollback.md | 66 | Git ロールバックコマンド | **Keep** | 安全な復旧手段 |
| 6 | state-rollback.md | 75 | state.md 復元コマンド | **Keep** | 状態復旧手段 |
| 7 | focus.md | 34 | focus 切り替えコマンド | **Keep** | レイヤー間移動 |

### 共通基盤（6ファイル）

| # | ファイル | 行数 | 役割 | 処遇 | 理由 |
|---|----------|------|------|------|------|
| 8 | session-start.sh | 559 | セッション開始処理 | **Keep (Core)** | State Injection の補助 |
| 9 | session-end.sh | 336 | セッション終了処理 | **Keep** | 未コミット警告 |
| 10 | pre-compact.sh | 138 | compact 前スナップショット | **Keep** | コンテキスト保全 |
| 11 | stop-summary.sh | 116 | 中断時サマリー出力 | **Simplify** | stop-summary-user.sh と重複可能性 |
| 12 | log-subagent.sh | 98 | サブエージェントログ | **Keep** | critic 結果処理 |
| 13 | compact.md | 63 | /compact コマンド | **Keep** | コンテキスト管理 |

### 横断的（3ファイル）

| # | ファイル | 行数 | 役割 | 処遇 | 理由 |
|---|----------|------|------|------|------|
| 14 | check-coherence.sh | 140 | 四つ組整合性チェック | **Keep (Core)** | コミット前必須検証 |
| 15 | depends-check.sh | 82 | Phase 依存関係検証 | **Keep** | 依存順序の保証 |
| 16 | executor-guard.sh | 312 | executor 強制 | **Keep** | AI オーケストレーション |

---

## 詳細分析

### 完了動線

#### 1. archive-playbook.sh - Keep

**パス**: `.claude/hooks/archive-playbook.sh`

**役割**:
- PostToolUse(Edit) Hook
- playbook の全 Phase が done になった時にアーカイブを提案

**主要機能**:
```yaml
検出条件:
  - 対象が playbook-*.md
  - 全 Phase の status が done
  - pending/in_progress が 0

出力:
  - アーカイブ提案メッセージ
  - mv コマンド例を表示
  - 次タスクの案内

自動化なし:
  - 提案のみで自動実行しない
  - ユーザーの確認を待つ設計
```

**凍結理由**:
- PDCA サイクルの完了を支援
- playbook の整理を促進
- 次タスクへの移行を円滑化

---

#### 2. cleanup-hook.sh - Simplify

**パス**: `.claude/hooks/cleanup-hook.sh`

**役割**:
- PostToolUse(Bash) Hook
- git commit 成功後に一時ファイルを削除

**問題点**:
```yaml
現状:
  - .tmp/, .claude/tmp/ のファイルを削除
  - 30分以上経過したファイルのみ対象

効果:
  - 一時ファイルはそもそも少ない
  - 手動でも容易に対応可能
  - 本質的な価値が低い

簡素化提案:
  - 削除検討
  - または session-end.sh に統合
```

---

#### 3. post-loop.md - Keep

**パス**: `.claude/commands/post-loop.md`

**役割**:
- /post-loop コマンド
- playbook 完了後の自動処理

**主要内容**:
```yaml
トリガー条件:
  - playbook の全 Phase が done
  - 未コミット変更あり

実行内容:
  1. 自動コミット（オプション）
  2. playbook アーカイブ
  3. main マージ（オプション）
  4. 次タスク導出（project.md 参照）
```

**凍結理由**:
- 完了動線の自動化
- PDCA サイクルの継続
- 次タスクへのシームレスな移行

---

#### 4. context-management/SKILL.md - Keep

**パス**: `.claude/skills/context-management/SKILL.md`

**役割**:
- /compact の専門知識を提供
- コンテキスト管理のベストプラクティス

**主要内容**:
```yaml
最適化ガイドライン:
  - 履歴要約の基準
  - 重要情報の保持基準
  - セッション引き継ぎのルール

compact トリガー:
  - コンテキスト警告時
  - 大規模タスク完了時
  - セッション終了予定時

保持すべき情報:
  - 現在の state.md 状態
  - 未完了タスク
  - 重要な決定事項
```

**凍結理由**:
- コンテキスト消失対策
- 長期セッションの品質維持

---

#### 5. rollback.md - Keep

**パス**: `.claude/commands/rollback.md`

**役割**:
- /rollback コマンド
- Git ロールバックの安全な実行

**主要内容**:
```yaml
モード:
  - soft: コミット取り消し（変更は保持）
  - mixed: ステージング解除
  - hard: 変更完全取り消し
  - revert: 新コミットで打ち消し
  - stash: 一時退避

安全装置:
  - 確認プロンプト必須
  - 影響範囲の表示
  - ロールバック後の状態説明
```

**凍結理由**:
- 安全な復旧手段
- 誤操作からの回復

---

#### 6. state-rollback.md - Keep

**パス**: `.claude/commands/state-rollback.md`

**役割**:
- /state-rollback コマンド
- state.md のバックアップと復元

**主要内容**:
```yaml
操作:
  - backup: スナップショット作成
  - list: 過去のスナップショット一覧
  - rollback: 指定時点に復元
  - snapshot: 名前付きスナップショット
  - restore: 名前で復元

保存先:
  - .claude/state-backups/
```

**凍結理由**:
- state.md の保全
- 状態破損からの回復

---

#### 7. focus.md - Keep

**パス**: `.claude/commands/focus.md`

**役割**:
- /focus コマンド
- focus.current の切り替え

**主要内容**:
```yaml
有効値:
  - setup: 初期設定
  - product: 本番コード
  - plan-template: 計画テンプレート

編集権限:
  - setup: 環境設定ファイルのみ
  - product: src/, app/ のみ
  - plan-template: plan/, docs/ のみ
```

**凍結理由**:
- レイヤー間の移動
- 編集権限の切り替え

---

### 共通基盤

#### 8. session-start.sh - Keep (Core)

**パス**: `.claude/hooks/session-start.sh`

**役割**:
- SessionStart Hook として全セッションで実行
- コンテキスト情報の収集と表示

**主要機能**:
```yaml
情報収集:
  - state.md の解析
  - playbook.active の特定
  - git status/branch 情報
  - 前回セッション状態
  - 失敗パターン学習
  - テスト結果履歴

出力セクション:
  - 前回セッション警告（異常終了時）
  - 失敗パターン表示
  - テスト結果サマリー
  - 未コミット警告
  - 残存 playbook 警告
  - 前回の指示表示
  - ブランチ不一致警告
  - 次 milestone 候補
  - 動線サマリー
  - CORE ルール表示
  - 必須 Read リスト
  - 自認テンプレート

State Injection 補助:
  - prompt-guard.sh が本体
  - session-start.sh は起動時の情報整理
```

**凍結理由**:
- セッション開始時の状況把握
- 継続性の保証
- 失敗パターンの学習と表示

---

#### 9. session-end.sh - Keep

**パス**: `.claude/hooks/session-end.sh`

**役割**:
- SessionEnd Hook（Ctrl+C / exit 時）
- セッション終了時のチェック

**主要機能**:
```yaml
チェック項目:
  - 未コミット変更の警告
  - playbook 進捗の記録
  - last_end の更新

出力:
  - 終了サマリー
  - 未完了タスクの警告
  - 次回セッションへの引き継ぎ情報
```

**凍結理由**:
- セッション間の継続性
- 作業状態の保全

---

#### 10. pre-compact.sh - Keep

**パス**: `.claude/hooks/pre-compact.sh`

**役割**:
- PreToolUse(*) Hook
- /compact 実行前のスナップショット

**主要機能**:
```yaml
トリガー:
  - "compact" を含むプロンプト検出
  - または context-management スキル呼び出し

実行内容:
  1. state.md のバックアップ
  2. playbook の状態保存
  3. 重要コンテキストの抽出
  4. .claude/pre-compact-snapshot.md に出力
```

**凍結理由**:
- compact 前の状態保全
- コンテキスト消失対策

---

#### 11. stop-summary.sh - Simplify

**パス**: `.claude/hooks/stop-summary.sh`

**役割**:
- Stop Hook（中断時）
- 中断時のサマリー出力

**問題点**:
```yaml
現状:
  - 中断理由の表示
  - 作業状態のサマリー

重複可能性:
  - session-end.sh と機能重複
  - stop-summary-user.sh（存在するなら）と重複

簡素化提案:
  - session-end.sh に統合検討
  - または明確な差別化
```

---

#### 12. log-subagent.sh - Keep

**パス**: `.claude/hooks/log-subagent.sh`

**役割**:
- PostToolUse(Task) Hook
- サブエージェントの実行ログ

**主要機能**:
```yaml
ログ記録:
  - サブエージェント名
  - 実行結果
  - タイムスタンプ

critic 結果処理:
  - PASS/FAIL を検出
  - state.md の self_complete を更新
  - PASS: self_complete: true に設定
```

**凍結理由**:
- サブエージェントの追跡
- critic 結果の自動反映

---

#### 13. compact.md - Keep

**パス**: `.claude/commands/compact.md`

**役割**:
- /compact コマンド
- コンテキスト最適化の実行

**主要内容**:
```yaml
実行手順:
  1. 現在の重要情報を抽出
  2. 履歴を要約
  3. 不要なコンテキストを削除
  4. 新しいセッションとして継続

保持対象:
  - state.md の全内容
  - 現在の playbook 状態
  - 未完了タスク
  - 重要な決定事項
```

**凍結理由**:
- コンテキスト管理の標準手順

---

### 横断的

#### 14. check-coherence.sh - Keep (Core)

**パス**: `.claude/hooks/check-coherence.sh`

**役割**:
- コミット前の整合性チェック
- /lint コマンドから呼び出し

**主要機能**:
```yaml
チェック項目:
  1. focus.current の有効性
  2. playbook.active の存在確認
  3. Phase 状態の集計（done/in_progress/pending）
  4. branch coherence（state.md の branch と git branch の一致）
  5. stray playbooks（plan/ に残存する完了済み playbook）
  6. critic enforcement（done 変更時に self_complete: true 必須）

出力:
  - PASS/FAIL/WARN
  - 詳細なエラーメッセージ
  - 対処法の案内

exit code:
  - 0: PASS または WARN のみ
  - 2: ERROR あり（コミットブロック）
```

**凍結理由**:
- 四つ組整合性の構造的保証
- コミット前の品質ゲート
- Core Layer に準ずる重要度

---

#### 15. depends-check.sh - Keep

**パス**: `.claude/hooks/depends-check.sh`

**役割**:
- Phase の depends_on を検証
- 依存 Phase が done でない場合に警告

**主要機能**:
```yaml
検証フロー:
  1. state.md から現在の playbook を取得
  2. goal.phase から現在の Phase を特定
  3. playbook から depends_on を抽出
  4. 各依存 Phase の status を確認

出力:
  - 依存 Phase ごとの状態
  - 未完了の依存があれば警告

動作:
  - 警告のみ（ブロックしない）
  - exit 0 で常に通過
```

**凍結理由**:
- Phase 順序の保証
- 依存関係の可視化

---

#### 16. executor-guard.sh - Keep

**パス**: `.claude/hooks/executor-guard.sh`

**役割**:
- PreToolUse(Edit/Write) Hook
- Phase の executor を構造的に強制

**主要機能**:
```yaml
executor 種類:
  - claudecode: Claude Code が担当（許可）
  - codex: Codex CLI 使用を強制（コード編集ブロック）
  - coderabbit: CodeRabbit CLI 使用を強制（コード編集ブロック）
  - user: ユーザー手動作業（コード編集ブロック）

Toolstack 連携:
  - A: claudecode, user のみ
  - B: claudecode, codex, user
  - C: claudecode, codex, coderabbit, user

コードファイル判定:
  - 拡張子ベース（.ts, .tsx, .js, .py, .go 等）
  - ディレクトリベース（src/, app/, lib/ 等）

非コードファイル:
  - ドキュメント等は executor に関係なく許可
```

**凍結理由**:
- AI オーケストレーションの構造的強制
- 役割分担の明確化
- CLAUDE.md Core Contract の実装

---

## テスト結果

```
Flow Runtime Test Results
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  PASS: 33
  FAIL: 0

  ALL FLOW RUNTIME TESTS PASSED
```

完了動線 + 共通基盤 + 横断的関連テスト: 全て PASS

---

## Codex レビュー結果

```yaml
レビュー日: 2025-12-21
レビュアー: Codex

全体評価: Approved

コメント:
  - session-start.sh: 559行は最大だが、情報整理として適切
  - check-coherence.sh: 四つ組整合性の実装として堅牢
  - executor-guard.sh: AI オーケストレーションの良い実装

改善提案:
  - cleanup-hook.sh: 削除または session-end.sh 統合
  - stop-summary.sh: session-end.sh との差別化を明確化
  - depends-check.sh: STRICT モードの追加検討

結論: Extension Layer として適切に設計されている。
      一部 Simplify 対象あり。
```

---

## 結論

### Core として凍結するファイル（2ファイル）

1. **session-start.sh** - セッション開始の情報整理
2. **check-coherence.sh** - 四つ組整合性チェック

### Keep として維持するファイル（12ファイル）

**完了動線（6ファイル）**:
3. **archive-playbook.sh** - PDCA サイクル完了
4. **post-loop.md** - 自動フロー継続
5. **context-management/SKILL.md** - コンテキスト管理
6. **rollback.md** - Git ロールバック
7. **state-rollback.md** - state.md 復元
8. **focus.md** - focus 切り替え

**共通基盤（4ファイル）**:
9. **session-end.sh** - セッション終了
10. **pre-compact.sh** - compact 前保全
11. **log-subagent.sh** - サブエージェントログ
12. **compact.md** - コンテキスト最適化

**横断的（2ファイル）**:
13. **depends-check.sh** - 依存関係検証
14. **executor-guard.sh** - executor 強制

### Simplify として簡素化するファイル（2ファイル）

15. **cleanup-hook.sh** - 削除または統合
16. **stop-summary.sh** - session-end.sh との差別化

---

## 動線連携の評価

```yaml
完了動線:
  強み:
    - playbook 完了から次タスクへの自動フロー
    - 復旧手段（rollback, state-rollback）が充実
  改善点:
    - cleanup-hook.sh の効果が限定的

共通基盤:
  強み:
    - session-start.sh の情報収集が包括的
    - コンテキスト保全メカニズムが堅牢
  改善点:
    - stop-summary.sh と session-end.sh の役割重複

横断的:
  強み:
    - check-coherence.sh が四つ組整合性を保証
    - executor-guard.sh が AI オーケストレーションを強制
  改善点:
    - depends-check.sh は警告のみで強制力なし

総合評価: Extension Layer として適切。Core 昇格候補あり。
```

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-21 | 初版作成 - M153 完了動線+共通基盤+横断的 Deep Audit |
