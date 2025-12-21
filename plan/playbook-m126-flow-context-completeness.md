# playbook-m126-flow-context-completeness.md

> **動線コンテキスト内部参照の完全化**

---

## meta

```yaml
schema_version: v2
project: thanks4claudecode
branch: feat/m126-flow-context-completeness
created: 2025-12-21
issue: null
derives_from: M126
reviewed: true
roles:
  worker: claudecode
  reviewer: codex

user_prompt_original: |
  M126 playbook を作成してください。

  ## マイルストーン: M126 動線コンテキスト内部参照の完全化

  ### 背景
  - Skills は `/skill-name` で呼べる形式（コマンド化）が推奨される
  - 既存の動線（Hook, SubAgent, Skill, Command）に機能不全がある:
    - 削除済みファイル（repository-map.yaml, generate-repository-map.sh, check-spec-sync.sh）への参照が残っている
    - Skills と Commands の対応が不完全

  ### 監査結果（既に判明した問題）
  1. `cleanup-hook.sh`: 削除済みスクリプト（generate-repository-map.sh, check-spec-sync.sh）への参照
  2. Skills と Commands の対応:
     - context-management → コマンドなし（要追加: /compact）
     - post-loop → コマンドなし（要追加）
     - plan-management → /playbook-init, /task-start に分散

  ### 目的
  1. 動線の内部参照を完全に整合させる（削除済みファイルへの参照を除去）
  2. Skills を Commands として正規化（/skill-name で呼べる形式に統一）

  ### done_criteria
  - 全 Hook が存在するファイルのみを参照している
  - 全 Skill に対応する Command が存在する
  - 動線テストスクリプトが PASS する

  ### Phase 構成案
  1. p1: Hook 内部参照の修正（cleanup-hook.sh 等）
  2. p2: 不足 Command の追加（/compact, /post-loop 等）
  3. p3: 動線整合性テストの作成と実行

  ### roles
  - worker: claudecode（ドキュメント・設定修正）
  - reviewer: codex
```

---

## goal

```yaml
summary: 動線コンテキストの内部参照を完全に整合させ、Skills を Commands として正規化する
done_when:
  - "cleanup-hook.sh から削除済みスクリプト/ファイル（generate-repository-map.sh, check-spec-sync.sh, repository-map.yaml）への参照が除去されている"
  - "全 Hook が存在するファイルのみを参照している"
  - "固定 6 Skill に対応する Command が存在する: lint-checker→lint.md, state→focus.md, post-loop→post-loop.md, context-management→compact.md, test-runner→test.md, plan-management→task-start.md"
  - "scripts/flow-integrity-test.sh が PASS する"
```

---

## phases

### p1: Hook 内部参照の修正

**goal**: 削除済みスクリプトへの参照を除去し、Hook が存在するファイルのみを参照するようにする

#### subtasks

- [ ] **p1.1**: cleanup-hook.sh から削除済みスクリプト/ファイル参照が除去されている
  - executor: claudecode
  - test_command: `test -f .claude/hooks/cleanup-hook.sh && { grep -qE 'generate-repository-map\.sh|check-spec-sync\.sh|repository-map\.yaml' .claude/hooks/cleanup-hook.sh && { echo FAIL; exit 1; } || echo PASS; }`
  - validations:
    - technical: "Hook が bash -n で構文エラーなし"
    - consistency: "参照先ファイルが全て存在する"
    - completeness: "cleanup 機能が正常動作する"

- [ ] **p1.2**: 全 Hook が存在しないファイルを参照していない
  - executor: claudecode
  - test_command: `bash scripts/check-hook-references.sh && echo PASS || { echo FAIL; exit 1; }`
  - validations:
    - technical: "参照チェックスクリプトが正常終了"
    - consistency: "全 Hook で参照先が存在"
    - completeness: "未参照ファイルの警告がない"

**status**: pending
**max_iterations**: 5

---

### p2: 不足 Command の追加

**goal**: 全 Skill に対応する Command を追加し、/skill-name で呼べる形式に統一する

**depends_on**: [p1]

#### subtasks

- [ ] **p2.1**: /compact コマンドが存在する（context-management Skill 対応）
  - executor: claudecode
  - test_command: `test -f .claude/commands/compact.md && echo PASS || { echo FAIL; exit 1; }`
  - validations:
    - technical: "コマンドファイルが正しい Markdown 形式"
    - consistency: "context-management Skill と整合"
    - completeness: "コンテキスト管理機能が呼び出せる"

- [ ] **p2.2**: /post-loop コマンドが存在する（post-loop Skill 対応）
  - executor: claudecode
  - test_command: `test -f .claude/commands/post-loop.md && echo PASS || { echo FAIL; exit 1; }`
  - validations:
    - technical: "コマンドファイルが正しい Markdown 形式"
    - consistency: "post-loop Skill と整合"
    - completeness: "完了後処理が呼び出せる"

- [ ] **p2.3**: 全 Skill に対応する Command が存在する（6 Skills → 6 Commands）
  - executor: claudecode
  - test_command: `for cmd in lint focus post-loop compact test task-start; do test -f ".claude/commands/${cmd}.md" || { echo "FAIL: ${cmd}.md missing"; exit 1; }; done && echo PASS`
  - validations:
    - technical: "全コマンドファイルが存在"
    - consistency: "Skill と Command が 1:1 対応"
    - completeness: "全機能がコマンド化されている"

**status**: pending
**max_iterations**: 5

---

### p3: 動線整合性テストの作成と実行

**goal**: 動線の内部参照整合性を検証するテストスクリプトを作成し、PASS を確認する

**depends_on**: [p1, p2]

#### subtasks

- [ ] **p3.1**: scripts/flow-integrity-test.sh が存在する
  - executor: claudecode
  - test_command: `test -f scripts/flow-integrity-test.sh && test -x scripts/flow-integrity-test.sh && echo PASS || { echo FAIL; exit 1; }`
  - validations:
    - technical: "スクリプトが実行可能"
    - consistency: "テスト項目が goal.done_when と対応"
    - completeness: "Hook 参照 + Skill-Command 対応をテスト"

- [ ] **p3.2**: flow-integrity-test.sh が PASS を返す
  - executor: claudecode
  - test_command: `bash scripts/flow-integrity-test.sh && echo PASS || { echo FAIL; exit 1; }`
  - validations:
    - technical: "テストが正常実行"
    - consistency: "全項目が PASS"
    - completeness: "修正漏れがない"

- [ ] **p3.3**: essential-documents.md の実行動線セクションが更新されている（/compact, /post-loop 両方記載）
  - executor: claudecode
  - test_command: `grep -q '/compact' docs/essential-documents.md && grep -q '/post-loop' docs/essential-documents.md && echo PASS || { echo FAIL; exit 1; }`
  - validations:
    - technical: "ファイルが正しい形式"
    - consistency: "新 Command が反映"
    - completeness: "全コマンドが記載"

**status**: pending
**max_iterations**: 5

---

### p_final: 完了検証（必須）

**goal**: playbook の done_when が全て満たされているか最終検証

**depends_on**: [p3]

#### subtasks

- [ ] **p_final.1**: cleanup-hook.sh から削除済みスクリプト/ファイル参照が除去されている
  - executor: claudecode
  - test_command: `test -f .claude/hooks/cleanup-hook.sh && { grep -qE 'generate-repository-map\.sh|check-spec-sync\.sh|repository-map\.yaml' .claude/hooks/cleanup-hook.sh && { echo FAIL; exit 1; } || echo PASS; }`
  - validations:
    - technical: "grep コマンドが正常動作"
    - consistency: "Hook ファイルの内容が修正済み"
    - completeness: "全ての削除済み参照が除去"

- [ ] **p_final.2**: 全 Hook が存在するファイルのみを参照している
  - executor: claudecode
  - test_command: `bash scripts/check-hook-references.sh && echo PASS || { echo FAIL; exit 1; }`
  - validations:
    - technical: "チェックスクリプトが正常動作"
    - consistency: "全 Hook が検証対象"
    - completeness: "0 件の不正参照"

- [ ] **p_final.3**: 全 Skill に対応する Command が存在する（lint→lint.md, state→focus.md, post-loop→post-loop.md, context-management→compact.md, test-runner→test.md, plan-management→task-start.md）
  - executor: claudecode
  - test_command: `for cmd in lint focus post-loop compact test task-start; do test -f ".claude/commands/${cmd}.md" || { echo "FAIL: ${cmd}.md missing"; exit 1; }; done && echo PASS`
  - validations:
    - technical: "ファイル存在チェックが正常"
    - consistency: "全 Skill がカバー"
    - completeness: "対応表が完全"

- [ ] **p_final.4**: scripts/flow-integrity-test.sh が PASS する
  - executor: claudecode
  - test_command: `bash scripts/flow-integrity-test.sh && echo PASS || { echo FAIL; exit 1; }`
  - validations:
    - technical: "テスト実行が正常"
    - consistency: "全テストケースが PASS"
    - completeness: "done_when 全項目を検証"

**status**: pending
**max_iterations**: 3

---

## final_tasks

- [ ] **ft1**: essential-documents.md を更新する
  - command: `bash scripts/generate-essential-docs.sh`
  - status: pending

- [ ] **ft2**: tmp/ 内の一時ファイルを削除する
  - command: `find tmp/ -type f ! -name 'README.md' -delete 2>/dev/null || true`
  - status: pending

- [ ] **ft3**: 変更を全てコミットする
  - command: `git add -A && git status`
  - status: pending

---

## 補足情報

### 現状の Skill-Command 対応表

| Skill | 現在の Command | 対応状況 |
|-------|---------------|---------|
| lint-checker | /lint | OK |
| state | /focus, /state-rollback | OK（分散） |
| post-loop | なし | 要追加 |
| context-management | なし | 要追加（/compact） |
| test-runner | /test | OK |
| plan-management | /playbook-init, /task-start | OK（分散） |

### 削除済みファイル参照（修正対象）

```yaml
cleanup-hook.sh:
  - generate-repository-map.sh（削除済み）
  - check-spec-sync.sh（削除済み）
  - repository-map.yaml（FREEZE_QUEUE）
```

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-21 | 初版作成 |
