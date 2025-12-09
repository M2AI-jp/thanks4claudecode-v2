# current-implementation.md

> **復旧可能な仕様書 - Claude Code 拡張システム実装リファレンス**
>
> このドキュメントは extension-system.md（公式仕様）と現在実装の対応を明記し、
> システム障害時の復旧手順を提供する「Single Source of Truth」です。
>
> 最終更新: 2025-12-09
> 基準文書: docs/extension-system.md

---

## 目次

1. [概要](#1-概要)
2. [Hooks 完全仕様](#2-hooks-完全仕様)
3. [SubAgents 完全仕様](#3-subagents-完全仕様)
4. [Skills 完全仕様](#4-skills-完全仕様)
5. [Commands 完全仕様](#5-commands-完全仕様)
6. [入力→処理→出力フロー](#6-入力処理出力フロー)
7. [依存関係図](#7-依存関係図)
8. [復旧手順](#8-復旧手順)
9. [削除可能ファイルリスト](#9-削除可能ファイルリスト)
10. [エンジニアリングエコシステム](#10-エンジニアリングエコシステム)
11. [コンテキスト外部化システム](#11-コンテキスト外部化システム)
12. [変更履歴](#12-変更履歴)

---

## 1. 概要

### 1.1 システム構成

```
三位一体アーキテクチャ:
  Hooks（構造的強制）+ SubAgents（検証）+ CLAUDE.md（思考制御）
  単独では機能しない。組み合わせて初めて強制力を持つ。
```

### 1.2 コンポーネント数

| カテゴリ | 実装数 | settings.json 登録 |
|---------|--------|-------------------|
| Hooks | 22 | 16 |
| SubAgents | 9 | - |
| Skills | 9 | - |
| Commands | 7 | - |

### 1.3 公式仕様との対応

| 公式仕様セクション | 現在実装 | 準拠状況 |
|------------------|---------|---------|
| 1.1 Hook イベント（10種） | 6種使用 | 部分実装 |
| 1.2 Hook タイプ（3種） | command のみ | 十分 |
| 2.1 SubAgent 定義 | 9個 | 完全準拠 |
| 3.1 Skill 定義 | 9個（4個不完全） | 部分実装 |
| 4.1 Command 定義 | 7個 | 完全準拠 |

---

## 2. Hooks 完全仕様

### 2.1 登録済み Hook 一覧（16個）

#### SessionStart(*)

| Hook | ファイル | 公式仕様 | timeout |
|------|---------|---------|---------|
| session-start | session-start.sh | 1.1 SessionStart | 5000ms |

**処理**: pending + consent ファイル作成、状態表示、必須 Read 指示

#### UserPromptSubmit(*)

| Hook | ファイル | 公式仕様 | timeout |
|------|---------|---------|---------|
| prompt-guard | prompt-guard.sh | 1.1 UserPromptSubmit | 3000ms |

**処理**: プロンプトとスコープの整合性確認（警告のみ）

#### PreToolUse(*)

| Hook | ファイル | 公式仕様 | timeout |
|------|---------|---------|---------|
| init-guard | init-guard.sh | 1.1 PreToolUse | 3000ms |
| check-main-branch | check-main-branch.sh | 1.1 PreToolUse | 3000ms |

**init-guard**: pending 存在時は Read 以外をブロック
**check-main-branch**: workspace + main ブランチでブロック

#### PreToolUse(Edit)

| Hook | ファイル | 公式仕様 | timeout |
|------|---------|---------|---------|
| consent-guard | consent-guard.sh | 1.1 PreToolUse | 3000ms |
| check-protected-edit | check-protected-edit.sh | 1.1 PreToolUse | 5000ms |
| playbook-guard | playbook-guard.sh | 1.1 PreToolUse | 3000ms |
| depends-check | depends-check.sh | 1.1 PreToolUse | 3000ms |
| check-file-dependencies | check-file-dependencies.sh | 1.1 PreToolUse | 3000ms |
| critic-guard | critic-guard.sh | 1.1 PreToolUse | 3000ms |
| scope-guard | scope-guard.sh | 1.1 PreToolUse | 3000ms |
| executor-guard | executor-guard.sh | 1.1 PreToolUse | 3000ms |

**発火順序**: settings.json の配列順（上から順に実行）

#### PreToolUse(Write)

Edit と同一 Hook（consent-guard 〜 executor-guard）が登録

#### PreToolUse(Bash)

| Hook | ファイル | 公式仕様 | timeout |
|------|---------|---------|---------|
| pre-bash-check | pre-bash-check.sh | 1.1 PreToolUse | 10000ms |
| check-coherence | check-coherence.sh | 1.1 PreToolUse | 5000ms |
| lint-check | lint-check.sh | 1.1 PreToolUse | 10000ms |

**lint-check**: git commit/add 前に静的解析を実行（ESLint, ShellCheck, Ruff）

#### PostToolUse(Task)

| Hook | ファイル | 公式仕様 | timeout |
|------|---------|---------|---------|
| log-subagent | log-subagent.sh | 1.1 PostToolUse | 3000ms |

**処理**: .claude/logs/subagent-dispatch.log に JSONL 形式で記録

#### PostToolUse(Edit)

| Hook | ファイル | 公式仕様 | timeout |
|------|---------|---------|---------|
| archive-playbook | archive-playbook.sh | 1.1 PostToolUse | 3000ms |

**処理**: 全 Phase が done なら アーカイブ提案を出力

#### Stop(*)

| Hook | ファイル | 公式仕様 | timeout |
|------|---------|---------|---------|
| stop-summary | stop-summary.sh | 1.1 Stop | 3000ms |

**処理**: Phase 状態サマリーを ASCIIart で出力

#### SessionEnd(*)

| Hook | ファイル | 公式仕様 | timeout |
|------|---------|---------|---------|
| session-end | session-end.sh | 1.1 SessionEnd | 5000ms |

**処理**: last_end 更新、未 push 警告、.session-init クリア、セッションサマリー自動生成（`.claude/logs/sessions/YYYY-MM-DD_session-NNN.md`）

### 2.2 未登録 Hook（6個）

| Hook | ファイル | 理由 |
|------|---------|------|
| check-state-update | check-state-update.sh | pre-bash-check.sh から間接呼出 |
| check-manifest-sync | check-manifest-sync.sh | 手動確認用 |
| check-playbook-quality | check-playbook-quality.sh | 手動確認用 |
| (SubagentStop) | - | PostToolUse(Task) で代替 |
| (PreCompact) | - | 優先度低 |
| (Notification) | - | 優先度低 |

### 2.3 Exit Code 仕様

| exit code | 意味 | 後続処理 |
|-----------|------|---------|
| 0 | 成功（通過） | ツール実行許可 |
| 2 | ブロック | ツール実行拒否、stderr をエラー表示 |
| その他 | 警告 | 警告表示、実行継続 |

---

## 3. SubAgents 完全仕様

### 3.1 SubAgent 一覧（9個）

| 名前 | ファイル | model | 自動委譲キーワード | 主な用途 |
|------|---------|-------|------------------|---------|
| critic | critic.md | haiku | MUST BE USED | done_criteria 検証 |
| pm | pm.md | haiku | PROACTIVELY | playbook 管理 |
| coherence | coherence.md | haiku | PROACTIVELY | 整合性チェック |
| state-mgr | state-mgr.md | haiku | AUTOMATICALLY | state.md 操作 |
| plan-guard | plan-guard.md | haiku | PROACTIVELY | 3層計画検証 |
| setup-guide | setup-guide.md | sonnet | AUTOMATICALLY | セットアップガイド |
| beginner-advisor | beginner-advisor.md | haiku | AUTOMATICALLY | 初心者説明 |
| reviewer | reviewer.md | haiku | (なし) | コードレビュー |
| health-checker | health-checker.md | haiku | (日本語) | 状態監視 |

### 3.2 frontmatter 仕様

```yaml
---
name: agent-name           # 必須: 小文字・ハイフン
description: 機能説明       # 必須: 自動委譲のトリガー
tools: Read, Grep, Bash    # 任意: 省略で全ツール継承
model: haiku               # 任意: sonnet|opus|haiku|inherit
---
```

### 3.3 呼び出し元

| SubAgent | Hook からの呼び出し | CLAUDE.md からの呼び出し | Command |
|----------|-------------------|------------------------|---------|
| critic | critic-guard.sh | CRITIQUE | /crit |
| pm | playbook-guard.sh | POST_LOOP | /playbook-init |
| coherence | check-coherence.sh | - | /lint |
| state-mgr | - | INIT, LOOP | /focus |

---

## 4. Skills 完全仕様

### 4.1 Skill 一覧（9個）

| 名前 | ファイル | frontmatter | 状態 |
|------|---------|-------------|------|
| state | SKILL.md | ✅ | 正常 |
| plan-management | SKILL.md | ✅ | 正常 |
| context-management | SKILL.md | ✅ + triggers | 正常 |
| execution-management | SKILL.md | ✅ + triggers | 正常 |
| learning | SKILL.md | ✅ + triggers | 正常 |
| frontend-design | SKILL.md | ❌ | 要修正 |
| lint-checker | skill.md | ❌ | 要修正（ファイル名も） |
| test-runner | skill.md | ❌ | 要修正（ファイル名も） |
| deploy-checker | skill.md | ❌ | 要修正（ファイル名も） |

### 4.2 frontmatter 仕様

```yaml
---
name: skill-name          # 必須: 小文字・数字・ハイフン
description: 機能説明      # 必須: 自動発見のキー
---
```

---

## 5. Commands 完全仕様

### 5.1 Command 一覧（7個）

| Command | ファイル | 関連 SubAgent | 用途 |
|---------|---------|--------------|------|
| /crit | crit.md | critic | done_criteria チェック |
| /playbook-init | playbook-init.md | pm | 新タスク開始 |
| /lint | lint.md | coherence | 整合性チェック |
| /focus | focus.md | state-mgr | フォーカス切替 |
| /test | test.md | - | done_criteria テスト |
| /rollback | rollback.md | - | Git ロールバック |
| /state-rollback | state-rollback.md | - | state.md 復元 |

---

## 6. 入力→処理→出力フロー

### 6.1 セッションライフサイクル

```
ユーザーがセッション開始
         │
         ▼
[SessionStart] session-start.sh
  → pending + consent 作成
  → 状態表示、必須 Read 指示
         │
         ▼
ユーザーがプロンプト送信
         │
         ▼
[UserPromptSubmit] prompt-guard.sh
  → スコープ確認（警告のみ）
         │
         ▼
LLM がツールを使用
         │
    ┌────┴────┬─────────┐
    ▼         ▼         ▼
  Read    Edit/Write   Bash
    │         │         │
    ▼         ▼         ▼
[PreToolUse(*)]
  init-guard.sh      → pending 時はブロック
  check-main-branch.sh → workspace+main でブロック
    │         │         │
    ▼         ▼         ▼
          [PreToolUse(Edit/Write)]
          consent-guard.sh      → 未合意でブロック
          check-protected-edit.sh → BLOCK ファイル保護
          playbook-guard.sh     → playbook=null でブロック
          depends-check.sh      → 依存警告
          critic-guard.sh       → done 変更時 critic 要求
          scope-guard.sh        → スコープ外警告
          executor-guard.sh     → executor 警告
                    │
                    ▼
            [PreToolUse(Bash)]
            pre-bash-check.sh
            check-coherence.sh → 不整合でブロック
         │
         ▼
    ツール実行
         │
         ▼
[PostToolUse]
  log-subagent.sh (Task)    → ログ記録
  archive-playbook.sh (Edit) → アーカイブ提案
         │
         ▼
LLM が応答完了
         │
         ▼
[Stop] stop-summary.sh
  → Phase 状態サマリー
         │
         ▼
セッション終了
         │
         ▼
[SessionEnd] session-end.sh
  → last_end 更新、クリーンアップ
```

### 6.2 連鎖の断絶箇所

| 区間 | 連続性 |
|------|--------|
| SessionStart → UserPromptSubmit | 自動 |
| UserPromptSubmit → PreToolUse | LLM 判断 |
| PreToolUse → ツール実行 | exit 0 で自動 |
| ツール実行 → PostToolUse | 自動 |
| Stop → SessionEnd | 自動 |

---

## 7. 依存関係図

### 7.1 Hook 間の依存

```
session-start.sh
    │
    ├── 作成: .session-init/pending   → init-guard.sh が参照
    ├── 作成: .session-init/consent   → consent-guard.sh が参照
    └── 更新: state.md               → 全 Hook が参照

playbook-guard.sh
    └── 参照: state.md (active_playbooks) → pm SubAgent が更新

critic-guard.sh
    └── 参照: state.md (self_complete) → critic SubAgent が更新
```

### 7.2 ドキュメント依存（参照コンテキスト）

```
セッション開始時の自動読み込み:
  ┌─────────────┐
  │  CLAUDE.md  │──────────────────────────────────────┐
  └─────────────┘                                       │
        │                                               │
        ▼                                               ▼
  ┌─────────────┐    ┌─────────────────┐    ┌──────────────────────┐
  │  state.md   │───→│  project.md     │───→│  playbook (active)   │
  └─────────────┘    └─────────────────┘    └──────────────────────┘
        │
        └── focus, playbook, goal を提供

参照時の自動読み込み（親ディレクトリ CLAUDE.md）:
  .claude/agents/* 参照時    → .claude/agents/CLAUDE.md
  .claude/skills/* 参照時    → .claude/skills/CLAUDE.md
  .claude/hooks/* 参照時     → .claude/hooks/CLAUDE.md
  .claude/context/* 参照時   → .claude/context/CLAUDE.md
  .claude/frameworks/* 参照時 → .claude/frameworks/CLAUDE.md
  docs/* 参照時              → docs/CLAUDE.md

Hooks → SubAgents → Skills 連鎖:
  playbook-guard.sh ─→ pm SubAgent     ─→ plan-management Skill
  critic-guard.sh   ─→ critic SubAgent ─→ .claude/frameworks/
  (expertise=beginner)                 ─→ beginner-advisor SubAgent
```

### 7.3 依存マトリクス

| コンポーネント | 参照先ドキュメント | 更新先 |
|--------------|------------------|--------|
| session-start.sh | state.md | state.md (session) |
| init-guard.sh | state.md, CLAUDE.md | - |
| playbook-guard.sh | state.md (playbook) | pm を呼び出し |
| critic-guard.sh | state.md (verification) | critic を呼び出し |
| pm SubAgent | project.md, playbook | playbook, state.md |
| critic SubAgent | .claude/frameworks/, playbook | state.md (verification) |
| Skills | 各 skill.md | - |

### 7.4 削除影響範囲

| 削除対象 | 復旧優先度 | 影響 |
|---------|----------|------|
| settings.json | **最高** | 全 Hook 停止 |
| session-start.sh | **最高** | 初期化なし |
| init-guard.sh | **最高** | 必須 Read なし |
| playbook-guard.sh | **最高** | playbook 強制なし |
| critic-guard.sh | 高 | 報酬詐欺防止なし |
| critic.md | 高 | 検証なし |
| pm.md | 高 | playbook 管理なし |

---

## 8. 復旧手順

### 8.1 settings.json 復旧

```bash
# git から復元
git checkout HEAD -- .claude/settings.json

# または最小構成で再作成
cat > .claude/settings.json << 'EOF'
{
  "permissions": {"defaultMode": "bypassPermissions"},
  "hooks": {
    "SessionStart": [{"matcher": "*", "hooks": [{"type": "command", "command": "bash .claude/hooks/session-start.sh"}]}],
    "PreToolUse": [
      {"matcher": "*", "hooks": [{"type": "command", "command": "bash .claude/hooks/init-guard.sh"}]},
      {"matcher": "Edit", "hooks": [{"type": "command", "command": "bash .claude/hooks/playbook-guard.sh"}]}
    ]
  }
}
EOF
```

### 8.2 Hook 復旧

```bash
# git から復元
git checkout HEAD -- .claude/hooks/

# または個別に復元
git checkout HEAD -- .claude/hooks/session-start.sh
git checkout HEAD -- .claude/hooks/init-guard.sh
git checkout HEAD -- .claude/hooks/playbook-guard.sh
```

### 8.3 SubAgent 復旧

```bash
# git から復元
git checkout HEAD -- .claude/agents/

# 最小版を作成する場合は phase-6-recovery.md を参照
```

### 8.4 state.md 復旧

```bash
# git から復元
git checkout HEAD -- state.md

# または最小構成で再作成
cat > state.md << 'EOF'
# state.md

## focus
```yaml
current: product
```

## active_playbooks
```yaml
product: null
```

## verification
```yaml
self_complete: false
```
EOF
```

### 8.5 復旧確認チェックリスト

```
□ settings.json が存在し JSON として有効
□ session-start.sh が実行可能
□ init-guard.sh が実行可能
□ playbook-guard.sh が実行可能
□ state.md が存在
□ 新セッションで session-start.sh の出力を確認
```

---

## 9. 削除可能ファイルリスト

> Phase 7 成果物より。削除しても仕組みが動作するファイル一覧。

### 9.1 即時削除可能

| ファイル | 削除根拠 |
|---------|---------|
| .archive/CONTEXT.md | CLAUDE.md + state.md + playbook に置換済み |
| .archive/file-dependencies.yaml | check-file-dependencies.sh に統合済み |
| .archive/requirements.yaml | project.md + playbook に置換済み |
| .archive/spec.yaml | extension-system.md + current-implementation.md に置換済み |
| .archive/plan/project-dev.md | 開発履歴（不要） |
| .archive/plan/test-history.md | テスト履歴（不要） |

### 9.2 Phase 成果物（統合後削除可能）

| ファイル | 状態 |
|---------|------|
| plan/active/phase-1-mapping.md | current-implementation.md に統合済み |
| plan/active/phase-2-inventory.md | current-implementation.md に統合済み |
| plan/active/phase-3-flow.md | current-implementation.md に統合済み |
| plan/active/phase-4-justification.md | current-implementation.md に統合済み |
| plan/active/phase-5-dependencies.md | current-implementation.md に統合済み |
| plan/active/phase-6-recovery.md | current-implementation.md に統合済み |
| plan/active/phase-7-cleanup-list.md | current-implementation.md に統合済み |

### 9.3 完了済み playbook（アーカイブ推奨）

```bash
# plan/active/ → .archive/plan/ へ移動
mv plan/active/playbook-action-based-guards.md .archive/plan/
mv plan/active/playbook-consent-integration.md .archive/plan/
mv plan/active/playbook-implementation-validation.md .archive/plan/
mv plan/active/playbook-plan-chain.md .archive/plan/
mv plan/active/playbook-session-redesign.md .archive/plan/
mv plan/active/playbook-structure-optimization.md .archive/plan/
mv plan/active/playbook-trinity-validation.md .archive/plan/
```

### 9.4 保持すべきファイル

| ファイル | 保持根拠 |
|---------|---------|
| docs/extension-system.md | 公式仕様の真実源（復旧に必須） |
| .claude/settings.json | Hook 登録（復旧に必須） |
| state.md | 状態管理（復旧に必須） |
| CLAUDE.md | 思考制御（復旧に必須） |

---

## 10. エンジニアリングエコシステム

> **設計思想**: 使うことでエンジニアの作法が自然と学べる環境を構築する。

### 10.1 Linter/Formatter 統合

言語別デファクトスタンダードを setup に統合。

| 言語 | Linter | Formatter | 設定ファイル |
|------|--------|-----------|-------------|
| JavaScript/TypeScript | ESLint | Prettier | .eslintrc.js, .prettierrc |
| Python | Ruff | Ruff | pyproject.toml |
| Shell | ShellCheck | shfmt | .shellcheckrc |
| Go | golangci-lint | gofmt | .golangci.yml |
| Rust | clippy | rustfmt | rustfmt.toml |
| Markdown | markdownlint | - | .markdownlint.yaml |

設定テンプレート: `.claude/templates/linter-formatter-config.md`

### 10.2 TDD LOOP 静的解析統合

```
TDD LOOP に静的解析ステップを追加:

  LOOP iteration
      │
      ▼
  [PreToolUse:Bash]
      │
      ├── lint-check.sh (git commit/add 前)
      │     ├── ESLint（package.json 存在時）
      │     ├── ShellCheck（.claude/hooks/ 配下）
      │     └── Ruff（pyproject.toml 存在時）
      │
      ▼
  ツール実行
```

Hook 登録: `.claude/settings.json` PreToolUse:Bash に lint-check.sh 追加

### 10.3 ShellCheck 導入

Hook スクリプト品質保証のため ShellCheck を導入。

```bash
# インストール
brew install shellcheck  # v0.11.0

# 実行
shellcheck .claude/hooks/*.sh
```

SC コード別対応方針（`.shellcheckrc`）:

| SC コード | 対応 | 理由 |
|----------|------|------|
| SC2053 | 修正必須 | バグの原因（glob 問題） |
| SC2086 | 修正必須 | セキュリティ（変数展開） |
| SC2155 | 許容 | 可読性優先 |
| SC2254 | 許容 | 意図的 glob 使用 |
| SC2034 | 無視 | false positive（出力用変数） |
| SC2011 | 無視 | 短スクリプトでは許容 |

### 10.4 学習モード

2軸の学習モード（`state.md` で設定）:

```yaml
learning_mode:
  operator: hybrid     # human | hybrid | llm
  expertise: intermediate  # beginner | intermediate | expert
```

| expertise | 出力調整 | SubAgent |
|-----------|---------|---------|
| beginner | 専門用語を比喩で説明、コマンド実行前に何をするか説明 | beginner-advisor 自動発火 |
| intermediate | 標準出力、必要時のみ補足 | - |
| expert | 簡潔な出力、説明省略 | - |

beginner-advisor 連携: `expertise = beginner` で自動発火

### 10.5 CodeRabbit 評価結果

| 項目 | 評価結果 |
|------|---------|
| CLI インストール | ✅ v0.3.4 |
| 認証 | ✅ github/M2AI-jp |
| レビュー精度 | ✅ playbook の誤りを検出（false positive なし） |
| TDD LOOP 統合 | ❌ 見送り（レートリミット問題） |
| 推奨利用 | 手動コマンド `/coderabbit`、GitHub App（PR レビュー） |

詳細評価レポート: `docs/coderabbit-evaluation.md`

**TDD LOOP 統合見送りの理由**:
- Free tier は 1 時間 1 レビューのレートリミット
- LOOP 内の頻繁な呼び出しに不向き
- 代替: 既存の critic SubAgent で十分

---

## 11. コンテキスト外部化システム

> **設計思想**: チャット履歴に依存しない状態管理。Claude の長時間作業でもユーザーが追跡可能。

### 11.1 context-log.md

Claude が「何を指示されて、何をしたか」を記録する外部ログ。

**ファイル**: `.claude/logs/context-log.md`

**記録フォーマット**:

```markdown
### [HH:MM] Entry: {タスク名}
- **User Prompt**: ユーザーの指示（原文または要約）
- **Intent**: Claude が解釈した意図
- **Actions**: 実行した処理
- **Result**: 結果・成果物
- **Technical Notes**: 技術的発見・制約（あれば）
- **Files Changed**: 変更したファイル
- **Playbook Phase**: 該当する Phase（あれば）
```

**記録タイミング**:

| タイミング | 必須/推奨 |
|-----------|----------|
| Phase 完了時（critic PASS 後） | 必須 |
| セッション終了前 | 必須 |
| ユーザーから新しい指示を受けたとき | 推奨 |
| 重要な技術的発見時 | 推奨 |
| 5回以上の Edit/Write 実行後 | 推奨 |

### 11.2 セッションサマリー自動生成

session-end.sh がセッション終了時に自動生成。

**格納先**: `.claude/logs/sessions/YYYY-MM-DD_session-NNN.md`

**Layer 構造**:

| Layer | 生成主体 | 内容 |
|-------|---------|------|
| Layer 1 | session-end.sh（自動） | git 状態、ブランチ、Phase 進捗、コミット履歴、変更ファイル |
| Layer 2 | Claude（手動追記推奨） | ユーザープロンプト、意図、処理結果 |

**技術的制約**: Shell Hook は Claude Code の会話履歴にアクセス不可。プロンプトの自動取得は不可能。

### 11.3 current-implementation.md 連携

context-log の蓄積に応じて current-implementation.md を更新。

**トリガー条件**:
- context-log の Entry が 5 件以上溜まった
- 構造的な変更（新 Hook、新 SubAgent、アーキテクチャ変更）

**関連 Skill**: context-management（`.claude/skills/context-management/SKILL.md`）

---

## 12. 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-10 | セクション 7 にドキュメント依存（参照コンテキスト）を追加。Hooks/SubAgents/Skills/ドキュメント間の依存を可視化。 |
| 2025-12-09 | コンテキスト外部化システム追加。context-log.md、セッションサマリー自動生成（sessions/）、current-implementation.md 連携を追加。Hook 登録数を 16 に修正。 |
| 2025-12-09 | エンジニアリングエコシステム追加。Linter/Formatter、静的解析、学習モード、ShellCheck、CodeRabbit 評価を統合。 |
| 2025-12-09 | 全面改訂。playbook-current-implementation-redesign Phase 1-8 の成果物を統合。復旧可能な仕様書として再設計。 |
| 2025-12-09 | 旧版: ユーザー確認事項ベースのドキュメントを廃止。 |

---

**参照ドキュメント**:
- docs/extension-system.md（公式仕様）
- CLAUDE.md（思考制御ルール）
- plan/project.md（Macro 計画）
