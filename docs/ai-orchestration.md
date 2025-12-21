# AI エージェントオーケストレーション

> **役割ベース executor 抽象化 - playbook の再利用性向上**
>
> **注**: 本ドキュメントには Orchestration Contract と Toolstack Patterns が統合されています（M122）

---

## 概要

AI エージェントオーケストレーションは、playbook の `executor` フィールドを
抽象的な役割名で指定できるようにする仕組みです。

**問題**: 現在の executor は具体的なツール名（claudecode, codex, coderabbit, user）を直接指定
**解決**: 抽象的な役割名（orchestrator, worker, reviewer, human）を使用し、実行時に解決

---

## 役割定義

| 役割 | 説明 | Toolstack A | Toolstack B | Toolstack C |
|------|------|-------------|-------------|-------------|
| orchestrator | 監督・調整・設計 | claudecode | claudecode | claudecode |
| worker | 本格的なコード実装 | claudecode | codex | codex |
| code_reviewer | コードレビュー | claudecode | claudecode | coderabbit |
| playbook_reviewer | playbook レビュー（worker の逆） | claudecode* | claudecode | claudecode |
| human | 人間の介入 | user | user | user |

> **注意**: `reviewer` は `code_reviewer` のエイリアスとして互換性のために残されています。
> 新規作成時は `code_reviewer` または `playbook_reviewer` を明示的に使用してください。
>
> **playbook_reviewer の特殊性**: worker の逆を返します。つまり：
> - Toolstack A: worker=claudecode のため、playbook_reviewer は「本来 codex であるべきところ claudecode にフォールバック」として警告を表示
> - Toolstack B/C: worker=codex のため、playbook_reviewer=claudecode（対称性を維持）

---

## 解決優先順位

役割名から具体的な executor への解決は以下の優先順位で行われます：

```
1. playbook.meta.roles（playbook 固有の override）
2. state.md config.roles（プロジェクト全体のデフォルト）
3. ハードコードされたデフォルト（上記の表）
```

### 例：解決フロー

```
playbook.subtask.executor: "worker"
              ↓
    ┌─────────────────────┐
    │  role-resolver.sh   │
    └─────────┬───────────┘
              ↓
    1. playbook.meta.roles.worker を確認 → 未定義
    2. state.md config.roles.worker を確認 → 未定義
    3. デフォルト（toolstack B）→ "codex"
              ↓
    executor-guard.sh で toolstack チェック
              ↓
           実行
```

---

## 使用方法

### playbook での役割指定

```yaml
# subtask で役割名を使用
- [ ] **p1.1**: 機能を実装する
  - executor: worker  # 抽象的な役割名
  - test_command: `npm test && echo PASS`
```

### playbook での役割 override

```yaml
# playbook meta で役割を override
meta:
  project: example
  roles:
    worker: claudecode  # この playbook では worker = claudecode
```

### state.md でのデフォルト設定

```yaml
# state.md config セクション
config:
  security: admin
  toolstack: B
  roles:
    orchestrator: claudecode
    worker: codex
    reviewer: claudecode
    human: user
```

---

## 互換性

既存の executor 名（claudecode, codex, coderabbit, user）はそのまま使用可能です。
役割名は追加オプションであり、既存の playbook を変更する必要はありません。

```yaml
# これまで通り直接指定も可能
- [ ] **p1.1**: 機能を実装する
  - executor: codex  # 具体的な executor 名（従来通り）
```

---

## Codex MCP 統合（M078）

> **TTY 制約を回避するため、Codex CLI から Codex MCP に移行**

### 背景

Codex CLI は対話型ターミナル（TTY）を必要とするため、Claude Code の SubAgent から
直接呼び出すことができませんでした（stdin がパイプになるため起動しない）。

### 解決策

Codex を MCP サーバーとして起動し、Claude Code から MCP ツールとして呼び出す。

```
Claude Code → mcp__codex__codex → Codex MCP Server → コード生成
```

### 設定方法

#### 1. .claude/mcp.json を作成

```json
{
  "mcpServers": {
    "codex": {
      "command": "codex",
      "args": ["mcp-server"],
      "env": {},
      "timeout": 600000
    }
  }
}
```

#### 2. Claude Code を再起動

MCP サーバー設定を読み込むため、Claude Code を再起動します。

#### 3. MCP ツールを使用

```yaml
# 新規セッション
mcp__codex__codex:
  prompt: "実装内容"
  model: "o3"  # オプション

# 継続会話
mcp__codex__codex-reply:
  prompt: "追加指示"
  conversationId: "前回のセッションID"
```

### 注意事項

- **タイムアウト**: Codex は処理に数分かかる場合があるため、timeout を 600000ms（10分）に設定
- **Codex CLI**: `npm install -g @openai/codex` でインストール済みであること
- **OPENAI_API_KEY**: 環境変数に設定済みであること

### 参考リンク

- [Codex MCP 公式ドキュメント](https://developers.openai.com/codex/mcp/)
- [Codex CLI GitHub](https://github.com/openai/codex)

---

## 実装詳細

### role-resolver.sh

役割名を具体的な executor に解決するユーティリティスクリプト。

```bash
# 使用例
echo 'worker' | bash .claude/hooks/role-resolver.sh
# 出力: codex（toolstack B の場合）

bash .claude/hooks/role-resolver.sh orchestrator
# 出力: claudecode
```

### executor-guard.sh との連携

executor-guard.sh は role-resolver.sh を呼び出し、解決後の executor を
toolstack に対してチェックします。

---

## Orchestration Contract（M122 統合）

> **旧: docs/orchestration-contract.md の内容を統合**

### 委譲ルール

#### Orchestrator → Worker

```yaml
delegation_trigger:
  - playbook が active
  - 実装タスクが明確
  - acceptance_criteria が定義済み

delegation_format:
  - タスク説明（what）
  - 完了条件（done_criteria）
  - 制約（constraints）
  - 期待成果物（deliverables）
```

#### Worker → Reviewer

```yaml
review_trigger:
  - 実装完了
  - テスト PASS
  - PR 作成済み
```

#### Reviewer → Human

```yaml
escalation_trigger:
  - 重大な設計問題
  - セキュリティ懸念
  - scope 外の変更検出
```

### コンテキスト分離（Codex 委譲時）

```yaml
context_isolation:
  rule: Codex は自身のコンテキストで動作
  benefit: Claude Code のコンテキストを汚染しない

information_transfer:
  - 必要最小限の情報のみ渡す
  - 結果は要約して受け取る
  - 詳細は必要時のみ展開
```

### エラーハンドリング

| シナリオ | アクション |
|---------|----------|
| Worker 失敗 | タスクを再分解 → 追加コンテキストで再委譲 → 3回失敗で Human エスカレーション |
| Reviewer 指摘 | Worker にフィードバック → 修正 → 再レビュー（PASS まで繰り返し） |
| Scope 逸脱 | 変更を REJECT → scope 内での代替案提示 |

### 監査・ログ

```yaml
mandatory_logging:
  - 委譲の開始/終了
  - レビュー結果
  - 状態遷移
  - エスカレーション

log_location: .claude/logs/orchestration.log
log_format: "[YYYY-MM-DD HH:MM:SS] [ROLE] [ACTION] detail"
```

---

## Toolstack Patterns（M122 統合）

> **旧: docs/toolstack-patterns.md の内容を統合**

### パターン一覧

| パターン | 構成 | 推奨ユースケース |
|----------|------|------------------|
| **A** | Claude Code のみ | シンプルさ重視、初心者 |
| **B** | Claude Code + Codex | 大規模コード生成、パフォーマンス重視 |
| **C** | Claude Code + Codex + CodeRabbit | フルスタック、品質重視 |

### パターン選択ガイド

```
┌─────────────────────────────────────────────────────────┐
│ Q1: 外部 CLI ツールの設定は問題ありませんか？            │
│                                                         │
│   NO  ──────────────────────────> パターン A             │
│   YES                                                   │
│    ↓                                                    │
│ Q2: 大規模コード生成が必要ですか？                        │
│                                                         │
│   NO  ──────────────────────────> パターン A             │
│   YES                                                   │
│    ↓                                                    │
│ Q3: AI によるコードレビューが欲しいですか？               │
│                                                         │
│   NO  ──────────────────────────> パターン B             │
│   YES ─────────────────────────> パターン C             │
└─────────────────────────────────────────────────────────┘
```

### Toolstack の変更方法

```yaml
1. state.md を編集:
   config:
     toolstack: B  # A, B, C のいずれか

2. CLI ツールをインストール（B または C の場合）:
   - Codex CLI: npm install -g @openai/codex
   - CodeRabbit CLI: npm install -g coderabbit

3. 環境変数を設定:
   - OPENAI_API_KEY（Codex 用）
```

### コンテキスト消費の比較

| パターン | 直接呼び出し | SubAgent 経由 |
|----------|-------------|---------------|
| A | 最小 | - |
| B | 大（Codex 結果） | 小（要約） |
| C | 大（Codex 結果） | 小（要約） |

**推奨**: パターン B/C では `codex-delegate` SubAgent を経由してください。

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-21 | M122: orchestration-contract.md と toolstack-patterns.md を統合 |
| 2025-12-21 | code_reviewer / playbook_reviewer 役割追加（M121） |
| 2025-12-18 | Codex MCP 統合追加（M078） |
| 2025-12-17 | 初版作成（M073） |
