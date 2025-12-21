# playbook-m123-minor-fixes.md

> **M123: Minor issues 修正（codex レビュー指摘対応）**

---

## meta

```yaml
schema_version: v2
project: thanks4claudecode
branch: feat/m123-similar-function-consolidation
created: 2025-12-21
issue: null
derives_from: M123
reviewed: false
roles:
  reviewer: codex

user_prompt_original: |
  M123 の codex レビューで Minor issues が 3 件検出された。これらを修正する追加 playbook を作成する。

  修正対象（Minor issues）:
  1. session-start.sh 空文字列処理 - layer_summary が空の場合、出力が中途半端になる
  2. FREEZE_QUEUE 形式統一 - 「M123 統合」→「M123 MERGE」に統一
  3. playbook test_command の不一致 - 既存 playbook はアーカイブ予定のためスキップ
```

---

## goal

```yaml
summary: M123 の codex レビューで検出された Minor issues を修正する
done_when:
  - session-start.sh が essential-documents.md 不存在時でもエラーにならない
  - session-start.sh が layer_summary 空文字列時に適切な表示をする
  - state.md の FREEZE_QUEUE エントリが形式統一されている（M123 MERGE）
```

---

## phases

### p1: 修正実装

**goal**: Minor issues を修正する

#### subtasks

- [x] **p1.1**: session-start.sh の動線サマリー出力が空文字列チェック付きで実装されている
  - executor: claudecode
  - test_command: `grep -q 'if \[ -n' .claude/hooks/session-start.sh && echo PASS || echo FAIL`
  - validations:
    - technical: "PASS - 空文字列チェックが追加されている"
    - consistency: "PASS - 他の Hook と整合（bash スタイル）"
    - completeness: "PASS - 全4変数（CORE_LAYER, QUALITY_LAYER, EXTENSION_LAYER, TOTAL）がチェックされている"
  - validated: 2025-12-21T12:50:00

- [x] **p1.2**: state.md の FREEZE_QUEUE の M123 エントリが「M123 MERGE」形式に統一されている
  - executor: claudecode
  - test_command: `grep 'repository-map.yaml' state.md | grep -q 'M123 MERGE' && echo PASS || echo FAIL`
  - validations:
    - technical: "PASS - 形式が正しい（M123 MERGE）"
    - consistency: "PASS - 他の MERGE エントリと形式一致"
    - completeness: "PASS - M123 関連エントリがすべて修正済み"
  - validated: 2025-12-21T12:50:00

**status**: done
**max_iterations**: 3

---

### p2: 検証

**goal**: 修正が正しく動作することを検証する

**depends_on**: [p1]

#### subtasks

- [x] **p2.1**: session-start.sh が essential-documents.md 不存在時でもエラーにならない
  - executor: claudecode
  - test_command: `mv docs/essential-documents.md docs/essential-documents.md.bak 2>/dev/null; bash .claude/hooks/session-start.sh >/dev/null 2>&1; RES=$?; mv docs/essential-documents.md.bak docs/essential-documents.md 2>/dev/null; [ $RES -eq 0 ] && echo PASS || echo FAIL`
  - validations:
    - technical: "PASS - exit 0 で終了する"
    - consistency: "PASS - 他の条件分岐と整合"
    - completeness: "PASS - 全パスがエラーなく通る"
  - validated: 2025-12-21T12:50:00

- [x] **p2.2**: FREEZE_QUEUE の形式が統一されている
  - executor: claudecode
  - test_command: `! grep -E 'M123 統合' state.md && grep -q 'M123 MERGE' state.md && echo PASS || echo FAIL`
  - validations:
    - technical: "PASS - 旧形式が残っていない"
    - consistency: "PASS - 他の MERGE エントリと形式一致"
    - completeness: "PASS - M123 関連がすべて統一済み"
  - validated: 2025-12-21T12:50:00

**status**: done
**max_iterations**: 3

---

### p_final: 完了検証（必須）

**goal**: done_when が全て満たされているか最終検証

#### subtasks

- [x] **p_final.1**: session-start.sh の空文字列処理が正しく実装されている
  - executor: claudecode
  - test_command: `grep -A5 'if \[ -n' .claude/hooks/session-start.sh | grep -q 'CORE_LAYER\|QUALITY_LAYER\|TOTAL' && echo PASS || echo FAIL`
  - validations:
    - technical: "PASS - 空文字列チェックが存在する"
    - consistency: "PASS - bash スタイルガイドに準拠"
    - completeness: "PASS - 全変数がカバーされている"
  - validated: 2025-12-21T12:50:00

- [x] **p_final.2**: state.md の FREEZE_QUEUE が形式統一されている
  - executor: claudecode
  - test_command: `grep 'repository-map.yaml' state.md | grep -q 'M123 MERGE' && ! grep -E 'M123 統合' state.md && echo PASS || echo FAIL`
  - validations:
    - technical: "PASS - M123 MERGE 形式で記録されている"
    - consistency: "PASS - 他エントリと形式一致"
    - completeness: "PASS - 旧形式が残存していない"
  - validated: 2025-12-21T12:50:00

**status**: done
**max_iterations**: 3

---

## final_tasks

- [x] **ft1**: 変更を全てコミット
  - command: `git add -A && git commit`
  - status: done

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-21 | 初版作成（pm による自動生成 - M123 Minor fixes） |
