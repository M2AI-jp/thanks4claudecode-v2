# playbook-m089-component-registry-normalization.md

> **コンポーネント台帳の正規化 - generate-repository-map.sh バグ修正と数値同期**

---

## meta

```yaml
schema_version: v2
project: thanks4claudecode
branch: feat/m089-component-registry
created: 2025-12-19
issue: null
derives_from: M089
reviewed: true
roles:
  worker: claudecode
```

---

## goal

```yaml
summary: generate-repository-map.sh のバグを修正し、repository-map.yaml を正しい数値で再生成する
done_when:
  - generate-repository-map.sh が exit 0 で完了する
  - repository-map.yaml の hooks が 33 と一致
  - repository-map.yaml の agents が 6 と一致
  - repository-map.yaml の skills が 9 と一致
  - repository-map.yaml の commands が 8 と一致
  - check-integrity.sh が PASS
```

---

## phases

### p1: generate-repository-map.sh のバグ修正

**goal**: plan/active ディレクトリが存在しない場合でもスクリプトが正常終了する

#### subtasks

- [x] **p1.1**: 566 行目の find コマンドが存在しないディレクトリでも exit 0 を返す
  - executor: claudecode
  - test_command: `bash .claude/hooks/generate-repository-map.sh && echo PASS || echo FAIL`
  - validations:
    - technical: "PASS - find コマンド実行前にディレクトリ存在チェックを追加"
    - consistency: "PASS - plan/active, plan/archive, count_files 関数全てに同様の修正を適用"
    - completeness: "PASS - 3箇所全てにエラー処理を実装"
  - validated: 2025-12-19T20:15:00

- [x] **p1.2**: スクリプト全体で存在しないディレクトリへのアクセスがエラーにならない
  - executor: claudecode
  - test_command: `bash -n .claude/hooks/generate-repository-map.sh && echo PASS || echo FAIL`
  - validations:
    - technical: "PASS - bash -n で構文エラーなし"
    - consistency: "PASS - set -euo pipefail と整合。ディレクトリチェックで find 実行前にガード"
    - completeness: "PASS - count_files 関数と直接呼び出し両方を修正"
  - validated: 2025-12-19T20:15:00

**status**: done
**max_iterations**: 5

---

### p2: repository-map.yaml の再生成と数値検証

**goal**: repository-map.yaml を再生成し、実ファイル数と完全に一致させる

**depends_on**: [p1]

#### subtasks

- [x] **p2.1**: generate-repository-map.sh を実行して repository-map.yaml を再生成する
  - executor: claudecode
  - test_command: `bash .claude/hooks/generate-repository-map.sh && test -f docs/repository-map.yaml && echo PASS || echo FAIL`
  - validations:
    - technical: "PASS - スクリプトが exit 0 で終了し、ファイルが生成された"
    - consistency: "PASS - 既存の repository-map.yaml が上書きされた"
    - completeness: "PASS - hooks, agents, skills, commands, summary セクション全て含まれている"
  - validated: 2025-12-19T20:20:00

- [x] **p2.2**: hooks の数が 33 である
  - executor: claudecode
  - test_command: `grep -A1 '^summary:' docs/repository-map.yaml | grep 'hooks:' | grep -q '33' && echo PASS || echo FAIL`
  - validations:
    - technical: "PASS - summary セクションで hooks: 33 を確認"
    - consistency: "PASS - ls .claude/hooks/*.sh | wc -l = 33 と一致"
    - completeness: "PASS - 全 Hook ファイルがカウントされている"
  - validated: 2025-12-19T20:20:00

- [x] **p2.3**: agents の数が 6 である
  - executor: claudecode
  - test_command: `grep -A2 '^summary:' docs/repository-map.yaml | grep 'agents:' | grep -q '6' && echo PASS || echo FAIL`
  - validations:
    - technical: "PASS - summary セクションで agents: 6 を確認"
    - consistency: "PASS - ls .claude/agents/*.md | wc -l = 6 と一致"
    - completeness: "PASS - 全 SubAgent ファイルがカウントされている"
  - validated: 2025-12-19T20:20:00

- [x] **p2.4**: skills の数が 9 である
  - executor: claudecode
  - test_command: `grep -A3 '^summary:' docs/repository-map.yaml | grep 'skills:' | grep -q '9' && echo PASS || echo FAIL`
  - validations:
    - technical: "PASS - summary セクションで skills: 9 を確認"
    - consistency: "PASS - ls -d .claude/skills/*/ | wc -l = 9 と一致"
    - completeness: "PASS - 全 Skill ディレクトリがカウントされている"
  - validated: 2025-12-19T20:20:00

- [x] **p2.5**: commands の数が 8 である
  - executor: claudecode
  - test_command: `grep -A5 '^summary:' docs/repository-map.yaml | grep 'commands:' | grep -q '8' && echo PASS || echo FAIL`
  - validations:
    - technical: "PASS - summary セクションで commands: 8 を確認"
    - consistency: "PASS - ls .claude/commands/*.md | wc -l = 8 と一致"
    - completeness: "PASS - 全 Command ファイルがカウントされている"
  - validated: 2025-12-19T20:20:00

**status**: done
**max_iterations**: 5

---

### p3: 整合性テスト

**goal**: check-integrity.sh が PASS することを確認する

**depends_on**: [p2]

#### subtasks

- [x] **p3.1**: check-integrity.sh が PASS する
  - executor: claudecode
  - test_command: `bash .claude/hooks/check-integrity.sh 2>&1 | tail -1 | grep -q 'All checks passed' && echo PASS || echo FAIL`
  - validations:
    - technical: "PASS - check-integrity.sh が exit 0 で終了"
    - consistency: "PASS - 全チェック項目が PASS（Errors: 0, Warnings: 0）"
    - completeness: "PASS - エラーメッセージなし、PASSED: All referenced files exist"
  - validated: 2025-12-19T20:30:00

**status**: done
**max_iterations**: 3

---

### p_final: 完了検証（必須）

**goal**: playbook の done_when が全て満たされているか最終検証

**depends_on**: [p3]

#### subtasks

- [x] **p_final.1**: generate-repository-map.sh が exit 0 で完了する
  - executor: claudecode
  - test_command: `bash .claude/hooks/generate-repository-map.sh && echo PASS || echo FAIL`
  - validations:
    - technical: "PASS - スクリプトが exit 0 で正常終了"
    - consistency: "PASS - 出力に 'Repository map generated' が含まれる"
    - completeness: "PASS - エラーメッセージなし、Hooks: 33 | Agents: 6 | Skills: 9"
  - validated: 2025-12-19T20:35:00

- [x] **p_final.2**: repository-map.yaml の hooks が 33 と一致
  - executor: claudecode
  - test_command: `grep 'hooks: 33' docs/repository-map.yaml && echo PASS || echo FAIL`
  - validations:
    - technical: "PASS - hooks: 33 が summary セクションに存在"
    - consistency: "PASS - ls .claude/hooks/*.sh | wc -l = 33"
    - completeness: "PASS - 全 Hook がカウントされている"
  - validated: 2025-12-19T20:35:00

- [x] **p_final.3**: repository-map.yaml の agents が 6 と一致
  - executor: claudecode
  - test_command: `grep 'agents: 6' docs/repository-map.yaml && echo PASS || echo FAIL`
  - validations:
    - technical: "PASS - agents: 6 が summary セクションに存在"
    - consistency: "PASS - ls .claude/agents/*.md | wc -l = 6"
    - completeness: "PASS - 全 SubAgent がカウントされている"
  - validated: 2025-12-19T20:35:00

- [x] **p_final.4**: repository-map.yaml の skills が 9 と一致
  - executor: claudecode
  - test_command: `grep 'skills: 9' docs/repository-map.yaml && echo PASS || echo FAIL`
  - validations:
    - technical: "PASS - skills: 9 が summary セクションに存在"
    - consistency: "PASS - ls -d .claude/skills/*/ | wc -l = 9"
    - completeness: "PASS - 全 Skill ディレクトリがカウントされている"
  - validated: 2025-12-19T20:35:00

- [x] **p_final.5**: repository-map.yaml の commands が 8 と一致
  - executor: claudecode
  - test_command: `grep 'commands: 8' docs/repository-map.yaml && echo PASS || echo FAIL`
  - validations:
    - technical: "PASS - commands: 8 が summary セクションに存在"
    - consistency: "PASS - ls .claude/commands/*.md | wc -l = 8"
    - completeness: "PASS - 全 Command がカウントされている"
  - validated: 2025-12-19T20:35:00

- [x] **p_final.6**: check-integrity.sh が PASS
  - executor: claudecode
  - test_command: `bash .claude/hooks/check-integrity.sh 2>&1 | tail -1 | grep -q 'PASSED' && echo PASS || echo FAIL`
  - validations:
    - technical: "PASS - check-integrity.sh が exit 0 で終了"
    - consistency: "PASS - Errors: 0, Warnings: 0"
    - completeness: "PASS - PASSED: All referenced files exist"
  - validated: 2025-12-19T20:35:00

**status**: done
**max_iterations**: 3

---

## final_tasks

- [x] **ft1**: repository-map.yaml を更新する
  - command: `bash .claude/hooks/generate-repository-map.sh`
  - status: done
  - executed: 2025-12-19T20:40:00

- [x] **ft2**: tmp/ 内の一時ファイルを削除する
  - command: `find tmp/ -type f ! -name 'README.md' -delete 2>/dev/null || true`
  - status: done
  - executed: 2025-12-19T20:40:00

- [x] **ft3**: 変更を全てコミットする
  - command: `git add -A && git status`
  - status: done
  - executed: 2025-12-19T20:40:00

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-19 | 初版作成。M089 タスク依頼に基づく playbook 作成。 |
