# playbook-m092-ssc-phase2.md

> **SSC Phase 2: 自己検証自動化 - README/project.md と実態の乖離を自動検出**

---

## meta

```yaml
schema_version: v2
project: thanks4claudecode
branch: feat/m092-ssc-phase2
created: 2025-12-19
issue: null
derives_from: M092
reviewed: false
```

---

## goal

```yaml
summary: playbook 完了時に SPEC_SNAPSHOT を更新し、README/project.md と実態の乖離を自動検出・警告する
done_when:
  - state.md に SPEC_SNAPSHOT セクションが存在する
  - playbook 完了時に SPEC_SNAPSHOT が自動更新される
  - README/project.md と実態の乖離検出時に警告が出力される
```

---

## phases

### p1: SPEC_SNAPSHOT セクションの設計と追加

**goal**: state.md に SPEC_SNAPSHOT セクションを追加し、数値スナップショットの構造を定義する

#### subtasks

- [x] **p1.1**: state.md に SPEC_SNAPSHOT セクションが存在する
  - executor: claudecode
  - test_command: `grep -q 'SPEC_SNAPSHOT' state.md && echo PASS || echo FAIL`
  - validations:
    - technical: "SPEC_SNAPSHOT セクションが YAML 形式で正しく記述されている"
    - consistency: "COMPONENT_REGISTRY セクションと同じ粒度で設計されている"
    - completeness: "readme/project の全必要フィールドが含まれている"

- [x] **p1.2**: SPEC_SNAPSHOT に readme.hooks が記録されている
  - executor: claudecode
  - test_command: `grep -A 10 'SPEC_SNAPSHOT' state.md | grep -q 'hooks:' && echo PASS || echo FAIL`
  - validations:
    - technical: "hooks 数値が整数で記録されている"
    - consistency: "README.md の Hook 数と一致している"
    - completeness: "last_checked タイムスタンプが含まれている"

- [x] **p1.3**: SPEC_SNAPSHOT に project.milestone_count が記録されている
  - executor: claudecode
  - test_command: `grep -A 15 'SPEC_SNAPSHOT' state.md | grep -q 'milestone_count:' && echo PASS || echo FAIL`
  - validations:
    - technical: "milestone_count が整数で記録されている"
    - consistency: "project.md の Milestone 数と一致している"
    - completeness: "achieved_count も記録されている"

**status**: done
**max_iterations**: 5

---

### p2: check-spec-sync.sh の実装

**goal**: README/project.md から数値を抽出し、実態と比較・警告するスクリプトを作成

**depends_on**: [p1]

#### subtasks

- [x] **p2.1**: .claude/hooks/check-spec-sync.sh が存在し実行可能である
  - executor: claudecode
  - test_command: `test -x .claude/hooks/check-spec-sync.sh && echo PASS || echo FAIL`
  - validations:
    - technical: "shebang が正しく、bash -n で構文エラーがない"
    - consistency: "他の Hook と同じ契約パターン（SKIP/WARN/PASS/BLOCK）を使用"
    - completeness: "必要な関数が全て実装されている"

- [x] **p2.2**: check-spec-sync.sh が README.md から Hook 数を抽出できる
  - executor: claudecode
  - test_command: `bash .claude/hooks/check-spec-sync.sh --extract-readme 2>&1 | grep -q 'hooks:' && echo PASS || echo FAIL`
  - validations:
    - technical: "grep/sed で正しく数値を抽出できる"
    - consistency: "README.md の記載形式と整合している"
    - completeness: "hooks, milestone_count を全て抽出"

- [x] **p2.3**: check-spec-sync.sh が project.md から Milestone 数を抽出できる
  - executor: claudecode
  - test_command: `bash .claude/hooks/check-spec-sync.sh --extract-project 2>&1 | grep -q 'total:' && echo PASS || echo FAIL`
  - validations:
    - technical: "grep -c で正しくカウントできる"
    - consistency: "project.md の記載形式と整合している"
    - completeness: "total, achieved, pending を全て抽出"

- [x] **p2.4**: check-spec-sync.sh が乖離検出時に WARNING を出力する
  - executor: claudecode
  - test_command: `echo 'FORCE_MISMATCH=1' | bash .claude/hooks/check-spec-sync.sh 2>&1 | grep -q 'WARNING' && echo PASS || echo FAIL`
  - validations:
    - technical: "WARNING 出力後に exit 0 で終了する（ブロックしない）"
    - consistency: "他の Hook の警告形式と一致"
    - completeness: "乖離の詳細（期待値 vs 実際値）が出力される"

**status**: done
**max_iterations**: 5

---

### p3: playbook 完了フローへの統合

**goal**: archive-playbook.sh または cleanup-hook.sh から check-spec-sync.sh を呼び出す

**depends_on**: [p2]

#### subtasks

- [x] **p3.1**: cleanup-hook.sh から check-spec-sync.sh が呼び出される
  - executor: claudecode
  - test_command: `grep -q 'check-spec-sync.sh' .claude/hooks/cleanup-hook.sh && echo PASS || echo FAIL`
  - validations:
    - technical: "正しいパスで呼び出されている"
    - consistency: "既存の generate-repository-map.sh 呼び出しと同じパターン"
    - completeness: "呼び出し結果のエラーハンドリングがある"

- [x] **p3.2**: check-spec-sync.sh が SPEC_SNAPSHOT を自動更新する
  - executor: claudecode
  - test_command: `bash .claude/hooks/check-spec-sync.sh --update 2>&1 | grep -q 'SPEC_SNAPSHOT updated' && echo PASS || echo FAIL`
  - validations:
    - technical: "sed で state.md を正しく更新できる"
    - consistency: "COMPONENT_REGISTRY 更新と同じパターン"
    - completeness: "last_checked タイムスタンプも更新される"

- [x] **p3.3**: playbook 完了時に SPEC_SNAPSHOT が実際に更新される
  - executor: claudecode
  - test_command: `grep -A 10 'SPEC_SNAPSHOT' state.md | grep -q 'last_checked:' && echo PASS || echo FAIL`
  - validations:
    - technical: "last_checked が ISO 8601 形式である"
    - consistency: "COMPONENT_REGISTRY の last_verified と同じ形式"
    - completeness: "全てのフィールドが更新されている"

**status**: done
**max_iterations**: 5

---

### p_final: 完了検証

**goal**: M092 の done_when が全て満たされていることを最終検証

**depends_on**: [p3]

#### subtasks

- [x] **p_final.1**: state.md に SPEC_SNAPSHOT セクションが存在する
  - executor: claudecode
  - test_command: `grep -q '## SPEC_SNAPSHOT' state.md && echo PASS || echo FAIL`
  - validations:
    - technical: "セクションヘッダーが正しいマークダウン形式"
    - consistency: "COMPONENT_REGISTRY と同じ構造"
    - completeness: "必要なフィールドが全て含まれている"

- [x] **p_final.2**: playbook 完了時に SPEC_SNAPSHOT が自動更新される
  - executor: claudecode
  - test_command: `grep -q 'check-spec-sync.sh' .claude/hooks/cleanup-hook.sh && bash .claude/hooks/check-spec-sync.sh --update && echo PASS || echo FAIL`
  - validations:
    - technical: "check-spec-sync.sh が正常に動作する"
    - consistency: "cleanup-hook.sh からの呼び出しが正しい"
    - completeness: "全てのフィールドが更新される"

- [x] **p_final.3**: README/project.md と実態の乖離検出時に警告が出力される
  - executor: claudecode
  - test_command: `bash .claude/hooks/check-spec-sync.sh 2>&1 | grep -qE 'WARNING|PASS' && echo PASS || echo FAIL`
  - validations:
    - technical: "乖離がなければ PASS、あれば WARNING を出力"
    - consistency: "他の Hook と同じ出力形式"
    - completeness: "乖離の詳細が出力される"

**status**: done
**max_iterations**: 3

---

## final_tasks

- [x] **ft1**: repository-map.yaml を更新する
  - command: `bash .claude/hooks/generate-repository-map.sh`
  - status: done

- [x] **ft2**: tmp/ 内の一時ファイルを削除する
  - command: `find tmp/ -type f ! -name 'README.md' -delete 2>/dev/null || true`
  - status: done

- [x] **ft3**: 変更を全てコミットする
  - command: `git add -A && git status`
  - status: done

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-19 | 初版作成。M092 SSC Phase 2 の playbook。 |
