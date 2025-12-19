# Hook Registry

> **全 33 Hook の分類台帳**
>
> 22個（登録済み）と 33個（実ファイル）の差分 11個は**設計通り**。
> 内部ライブラリ 5個 + コマンド用 1個 + 手動実行用 5個 = 11個

---

## 概要

| 分類 | 説明 | 個数 |
|------|------|------|
| **登録済み** | settings.json に登録され、自動実行される | 22 |
| **内部ライブラリ** | 登録済み Hook から呼び出される | 5 |
| **コマンド用** | .claude/commands/ から呼び出される | 1 |
| **手動実行** | 必要時に手動で実行するユーティリティ | 5 |

---

## 1. 登録済み Hook（22個）

settings.json に登録され、Claude Code のライフサイクルイベントで自動実行される。

| Hook | トリガー | 役割 |
|------|----------|------|
| `archive-playbook.sh` | PostToolUse:Edit | playbook 完了時の自動アーカイブ |
| `check-coherence.sh` | PreToolUse:Bash | state.md と playbook の整合性チェック |
| `check-main-branch.sh` | PreToolUse:* | main ブランチでの作業をブロック |
| `check-protected-edit.sh` | PreToolUse:Edit | 保護対象ファイルの編集をブロック |
| `cleanup-hook.sh` | PostToolUse:Edit | テンポラリファイル自動クリーンアップ |
| `consent-guard.sh` | PreToolUse:Edit | 合意プロセス強制 |
| `create-pr-hook.sh` | PostToolUse:Edit | PR 自動作成 |
| `critic-guard.sh` | PreToolUse:Edit | done への変更を構造的にブロック |
| `depends-check.sh` | PreToolUse:Edit | Phase の depends_on を検証 |
| `executor-guard.sh` | PreToolUse:Edit | executor を構造的に強制 |
| `init-guard.sh` | PreToolUse:* | セッション開始時の自己認識ガード |
| `lint-check.sh` | PreToolUse:Bash | 静的解析チェック |
| `log-subagent.sh` | PostToolUse:Task | SubAgent 発動ログ記録 |
| `playbook-guard.sh` | PreToolUse:Edit | playbook=null で Edit/Write をブロック |
| `pre-bash-check.sh` | PreToolUse:Bash | Bash コマンド実行前チェック |
| `pre-compact.sh` | PreCompact:* | 状態スナップショット保存 |
| `prompt-guard.sh` | UserPromptSubmit:* | ユーザープロンプト処理 |
| `scope-guard.sh` | PreToolUse:Edit | done_criteria の無断変更を検出 |
| `session-end.sh` | SessionEnd:* | セッション終了時チェック |
| `session-start.sh` | SessionStart:* | LLM の自己認識形成 |
| `stop-summary.sh` | Stop:* | Phase 状態サマリー |
| `subtask-guard.sh` | PreToolUse:Edit | subtask の 3 検証を強制 |

---

## 2. 内部ライブラリ Hook（5個）

登録済み Hook から呼び出される内部スクリプト。**削除不可**。

| Hook | 呼び出し元 | 役割 |
|------|------------|------|
| `create-pr.sh` | create-pr-hook.sh | PR 作成本体ロジック |
| `failure-logger.sh` | playbook-guard.sh | 失敗パターン記録 |
| `generate-repository-map.sh` | cleanup-hook.sh | repository-map.yaml 生成 |
| `role-resolver.sh` | executor-guard.sh | 役割名 → executor 名の解決 |
| `system-health-check.sh` | session-start.sh | システム健全性チェック |

---

## 3. コマンド用 Hook（1個）

.claude/commands/ から呼び出されるスクリプト。**削除不可**。

| Hook | 呼び出し元 | 役割 |
|------|------------|------|
| `test-done-criteria.sh` | commands/test.md | done_criteria テスト実行 |

---

## 4. 手動実行 Hook（5個）

settings.json には登録されず、必要時に手動で実行するユーティリティスクリプト。

| Hook | 用途 | 削除可否 |
|------|------|----------|
| `check-integrity.sh` | リポジトリ整合性チェック（playbook で使用） | ❌不可 |
| `playbook-validator.sh` | playbook 形式検証（test-hooks.sh で使用） | ❌不可 |
| `test-hooks.sh` | Hook テストスイート（M087 成果物） | ❌不可 |
| `audit-unused.sh` | 未使用ファイル監査 | ⚠️検討可 |
| `merge-pr.sh` | PR マージ（post-loop skill 文書に記載） | ⚠️検討可 |

---

## 5. 共通ライブラリ

| ファイル | 役割 |
|----------|------|
| `lib/common.sh` | 共通関数・定数 |

---

## 22個 vs 33個 の意味

```
33個 = 22個（登録済み）+ 11個（未登録）

未登録 11個の内訳:
├── 5個: 内部ライブラリ（登録済み Hook から呼ばれる）
├── 1個: コマンド用（commands/ から呼ばれる）
└── 5個: 手動実行用（うち2個は削除検討可）

結論: 差分 11個は設計通り。削除可能なのは最大2個。
```

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-19 | 分類を実態に合わせて修正（依存関係分析に基づく） |
| 2025-12-19 | 初版作成（M088 差分修正の一環） |
