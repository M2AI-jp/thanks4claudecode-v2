# playbook-m094-consent-auto-delete.md

> **Hook ベース合意検出機能（M094）**

---

## meta

```yaml
schema_version: v2
project: thanks4claudecode
branch: feat/m094-consent-auto-delete
created: 2025-12-19
issue: null
derives_from: M094
reviewed: false
roles:
  worker: claudecode
```

---

## goal

```yaml
summary: ユーザーが「OK」「了解」「はい」と応答した際に consent ファイルを自動削除する Hook ロジックを実装
done_when:
  - prompt-guard.sh に合意検出ロジックが追加されている
  - 「OK」「了解」「はい」パターンで consent ファイルが自動削除される
  - SKILL.md が更新されている
```

---

## phases

### p1: 合意検出ロジック実装

**goal**: prompt-guard.sh に合意パターン検出と consent 自動削除ロジックを追加

#### subtasks

- [ ] **p1.1**: prompt-guard.sh に合意パターン検出ロジックが存在する
  - executor: claudecode
  - test_command: `grep -q 'OK.*了解.*はい' .claude/hooks/prompt-guard.sh && echo PASS || echo FAIL`
  - validations:
    - technical: "正規表現パターンが正しく動作する"
    - consistency: "既存の prompt-guard.sh 構造と整合"
    - completeness: "主要な合意パターンがカバーされている"

- [ ] **p1.2**: consent ファイル削除ロジックが実装されている
  - executor: claudecode
  - test_command: `grep -q 'rm.*consent' .claude/hooks/prompt-guard.sh && echo PASS || echo FAIL`
  - validations:
    - technical: "rm コマンドが正しく動作する"
    - consistency: "consent ファイルパスが SKILL.md と一致"
    - completeness: "削除後のログ出力がある"

- [ ] **p1.3**: bash -n でシンタックスエラーがない
  - executor: claudecode
  - test_command: `bash -n .claude/hooks/prompt-guard.sh && echo PASS || echo FAIL`
  - validations:
    - technical: "スクリプトが構文エラーなし"
    - consistency: "既存機能が壊れていない"
    - completeness: "全パスが網羅されている"

**status**: pending
**max_iterations**: 5

---

### p2: ドキュメント更新

**goal**: SKILL.md を更新し、自動削除機能を文書化

**depends_on**: [p1]

#### subtasks

- [ ] **p2.1**: SKILL.md に自動削除機能の説明が追加されている
  - executor: claudecode
  - test_command: `grep -q '自動削除' .claude/skills/consent-process/SKILL.md && echo PASS || echo FAIL`
  - validations:
    - technical: "Markdown 形式が正しい"
    - consistency: "既存のドキュメント構造と整合"
    - completeness: "新機能が明確に説明されている"

**status**: pending

---

### p_final: 完了検証

**goal**: done_when が全て満たされていることを検証

**depends_on**: [p1, p2]

#### subtasks

- [ ] **p_final.1**: prompt-guard.sh に合意検出ロジックが追加されている
  - executor: claudecode
  - test_command: `grep -qE '(OK|了解|はい)' .claude/hooks/prompt-guard.sh && grep -q 'consent' .claude/hooks/prompt-guard.sh && echo PASS || echo FAIL`
  - validations:
    - technical: "合意パターンと consent 処理が存在"
    - consistency: "done_when と実装が一致"
    - completeness: "全パターンがカバー"

- [ ] **p_final.2**: SKILL.md が更新されている
  - executor: claudecode
  - test_command: `grep -q '自動削除' .claude/skills/consent-process/SKILL.md && echo PASS || echo FAIL`
  - validations:
    - technical: "ドキュメントが更新されている"
    - consistency: "実装と説明が一致"
    - completeness: "必要な情報が記載"

**status**: pending
**max_iterations**: 3

---

## final_tasks

- [ ] **ft1**: repository-map.yaml を更新する
  - command: `bash .claude/hooks/generate-repository-map.sh`
  - status: pending

- [ ] **ft2**: tmp/ 内の一時ファイルを削除する
  - command: `find tmp/ -type f ! -name 'README.md' -delete 2>/dev/null || true`
  - status: pending

- [ ] **ft3**: 変更を全てコミットする
  - command: `git add -A && git status`
  - status: pending
