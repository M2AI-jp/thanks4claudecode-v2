# project.md

> **Macro 計画: mission を達成するための具体的方針**
>
> 上位: plan/mission.md（全ての判断の基準）
> 下位: plan/playbook-*.md（具体的タスク）

---

## derives_from

```yaml
mission: plan/mission.md
mission_statement: |
  Claude Code の自律性と信頼性を最大化し、
  ユーザーの手作業に依存しないシステムを構築する。
```

---

## vision

```yaml
# mission を達成するための技術的ビジョン

goal: どんなプロンプトでも mission に立ち返り、自律的に正しく動作する
how: 三位一体アーキテクチャ（Hooks + SubAgents + CLAUDE.md）による多層防御

architecture:
  Hooks: 構造的強制（exit 2 でブロック、systemMessage で誘導）
  SubAgents: 検証（critic/pm/reviewer/health-checker）
  CLAUDE.md: 思考制御（mission 参照、報酬詐欺防止）

self_healing:
  Context_Continuity: compact 後も状態を復元
  Document_Freshness: 陳腐化を検知して自動更新
  Feature_Verification: Hook/SubAgent の動作を自動検証
  Self_Improvement: 失敗から学習して再発防止
```

---

## current_focus

```yaml
# 今取り組んでいること（mission の success_criteria に対応）

priority: 目的一貫性
reason: |
  ユーザープロンプトに引っ張られる問題が根本原因。
  mission を常に参照し、整合性をチェックする仕組みが必要。

active_work:
  - mission.md の SessionStart 統合
  - prompt-guard.sh での mission 整合性チェック
  - current-implementation.md の自動更新（実行レベル）
```

---

## done_when

```yaml
# mission 達成の具体的マイルストーン

autonomy:
  id: d_autonomy
  name: 自律性の確立
  status: in_progress
  criteria:
    - compact 後も mission を見失わない
    - 次タスクを自動導出して開始できる
    - ユーザープロンプトなしで 1 playbook を完遂できる

reliability:
  id: d_reliability
  name: 信頼性の確立
  status: achieved
  criteria:
    - 全 Hook が test-hooks.sh で PASS
    - settings.json と実ファイルが一致

self_awareness:
  id: d_self_awareness
  name: 自己認識の確立
  status: in_progress
  criteria:
    - current-implementation.md が常に最新（自動更新）
    - state.md が実状態と一致

self_healing:
  id: d_self_healing
  name: 自己修復の確立
  status: in_progress
  criteria:
    - 陳腐化ドキュメントを自動更新（提案ではなく実行）
    - Hook 故障を自動検知・修復

purpose_consistency:
  id: d_purpose_consistency
  name: 目的一貫性の確立
  status: not_started
  criteria:
    - SessionStart で mission.md を必ず読む
    - prompt-guard.sh で mission 整合性チェック
    - 報酬詐欺パターンを自己検出
```

---

## achieved

```yaml
# 完了済み（サマリーのみ）

self_healing_foundation:
  date: 2025-12-10
  summary: Self-Healing System 基盤実装
  result:
    - pre-compact.sh: snapshot.json 保存
    - session-start.sh: compact 復元、失敗学習ループ
    - doc-freshness-check.sh: 鮮度チェック
    - update-tracker.sh: 変更追跡
    - generate-implementation-doc.sh: ドキュメント自動生成
    - test-hooks.sh: 機能検証
    - system-health-check.sh: 健全性チェック
    - failure-logger.sh: 失敗記録

context_preservation:
  date: 2025-12-10
  summary: コンテキスト保持機能強化

plan_double_check:
  date: 2025-12-10
  summary: 計画ダブルチェック機能
```

---

## reference

```yaml
mission: plan/mission.md
current_implementation: docs/current-implementation.md
self_healing_design: plan/self-healing-system.md
```

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-10 | mission.md から導出される形に再構成。タスク管理→マイルストーン管理に変更。 |
