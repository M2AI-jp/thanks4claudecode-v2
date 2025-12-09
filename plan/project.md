# project.md

> **Macro 計画: LLM 自律制御システム**
>
> Hooks + SubAgents + CLAUDE.md = 三位一体アーキテクチャ

---

## vision

```yaml
goal: どんなプロンプトでも同一ワークフローが発火し、入力→処理→出力が連鎖する仕組み
why: Claude Code は強力だが、計画なしで動くと暴走する
solution: 三位一体アーキテクチャによる多層防御
```

---

## architecture

```yaml
三位一体:
  Hooks: 構造的強制（exit 2 でブロック）
  SubAgents: 検証（critic/pm/coherence）
  CLAUDE.md: 思考制御（ガイドライン遵守）

核心: 単独では機能しない。組み合わせて初めて強制力を持つ。

workflow:
  1. SessionStart → pending 作成 → Read 強制
  2. PreToolUse → playbook チェック → ブロック or 通過
  3. LOOP → done_criteria 検証 → critic PASS
  4. Stop → サマリー出力 → POST_LOOP
```

---

## tasks

> **チェックボックス式タスク管理。担当: cc=claudecode, user=ユーザー, codex=Codex**

### active

```yaml
# 現在進行中のタスク
- id: t_foundation_redesign
  name: システム基盤再設計
  playbook: plan/active/playbook-system-foundation-redesign.md
  branch: feat/system-foundation-redesign
  tasks:
    - [x] コンテキストエコシステム検証 (cc)
    - [x] project.md 書き直し (cc) - 880→144行
    - [x] state.md 再設計 (cc) - 271→78行
    - [x] current-implementation.md 更新 (cc) - ドキュメント依存追記
    - [x] 最終検証・critic PASS (cc)
```

### backlog

```yaml
# 将来のタスク（優先度順）
- id: t_learning_skill
  name: 失敗パターン自動学習
  status: designed
  tasks:
    - [ ] failures.log 自動記録 Hook (cc)
    - [ ] 類似パターン検索 (cc)
    - [ ] Phase 開始時に自動提示 (cc)

- id: t_executor_extension
  name: 複数 Executor 拡張
  status: designed
  tasks:
    - [ ] executor-guard.sh 拡張 (cc)
    - [ ] Codex MCP 統合 (cc)
    - [ ] CodeRabbit 統合 (cc)
```

---

## achieved

> **完了済みタスク（サマリーのみ）**

```yaml
playbook-context-architecture:
  date: 2025-12-10
  summary: コンテキストを機能として管理
  result:
    - state.md 履歴分離
    - CLAUDE.md 32%削減（3 Skills 作成）
    - .claude/ フォルダ構造化
    - docs/ 構造化

playbook-system-completion:
  date: 2025-12-09
  summary: システム完成度向上
  result:
    - タスク開始プロセス標準化
    - git 自動化
    - ファイル棚卸し
    - setup 完成

playbook-engineering-ecosystem:
  date: 2025-12-09
  summary: エンジニアリングエコシステム拡張
  result:
    - Linter/Formatter 統合
    - TDD LOOP 静的解析
    - 学習モード実装
    - ShellCheck 導入

playbook-system-improvements:
  date: 2025-12-08
  summary: 10Phase の機能改善
  result: 13件の機能実装完了
```

---

## reference

```yaml
# 詳細設計ドキュメント
universal_workflow: docs/current-implementation.md#6-入力処理出力フロー
tdd_fraud_prevention: CLAUDE.md#LOOP, CLAUDE.md#CRITIQUE
hooks_integration: docs/current-implementation.md#2-hooks-完全仕様
subagents_spec: docs/current-implementation.md#3-subagents-完全仕様

# アーカイブ（必要時のみ参照）
vision_detail: .archive/plan/vision.md
meta_roadmap: .archive/plan/meta-roadmap.md
old_roadmap: .archive/plan/roadmap.md
```

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-10 | 全面書き換え。チェックボックス式・200行以下に圧縮。 |
| 2025-12-10 | playbook-context-architecture 完了。 |
| 2025-12-09 | system_completion/engineering_ecosystem 完了。 |
