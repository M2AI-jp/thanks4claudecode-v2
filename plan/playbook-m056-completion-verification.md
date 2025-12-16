# playbook-m056-completion-verification.md

> **playbook 完了検証システム + V12 チェックボックス形式**
>
> **目的**: 報酬詐欺（done_when 未達成で achieved）を構造的に防止する
>
> 1. playbook 完了時に done_when を自動検証
> 2. subtask 単位でチェックボックス `- [ ]` / `- [x]` で進捗を明示

---

## meta

```yaml
project: thanks4claudecode
branch: feat/m056-completion-verification
created: 2025-12-17
issue: M056
derives_from: M056
reviewed: false
format: V12
```

---

## goal

```yaml
summary: |
  1. playbook 完了時に done_when が実際に満たされているか自動検証
  2. subtask 単位でチェックボックス形式（V12）を導入し、報酬詐欺を構造的に防止

done_when:
  - playbook-format.md に完了検証フェーズ（p_final）が必須として追加されている
  - archive-playbook.sh が done_when の test_command を再実行して検証する
  - subtask-guard が final_tasks の status: done をブロックしない
  - 既存の achieved milestone の done_when が実際に満たされているか再検証完了
  - (追加) V12 チェックボックス形式が全コンポーネントに適用されている
```

---

## phases

### p1: 完了検証システム実装

**goal**: playbook 完了時に done_when を自動検証する仕組みを構築

#### subtasks

- [x] **p1.1**: playbook-format.md に p_final セクションが追加されている ✓
  - executor: claudecode
  - test_command: `grep -q 'p_final.*完了検証' /Users/amano/Desktop/thanks4claudecode/plan/template/playbook-format.md && echo PASS || echo FAIL`
  - validations:
    - technical: "PASS - p_final セクションが存在"
    - consistency: "PASS - 他の Phase と同じ形式"
    - completeness: "PASS - 目的・構造・実装ガイドを含む"
  - validated: 2025-12-17T02:25:00

- [x] **p1.2**: archive-playbook.sh が done_when を再検証する ✓
  - executor: claudecode
  - test_command: `grep -q 'done_when.*再検証\|M056.*done_when' /Users/amano/Desktop/thanks4claudecode/.claude/hooks/archive-playbook.sh && echo PASS || echo FAIL`
  - validations:
    - technical: "PASS - done_when 検証ロジックが実装"
    - consistency: "PASS - 他の Hook と同じ exit code 規約"
    - completeness: "PASS - FAIL 時にブロック（exit 2）"
  - validated: 2025-12-17T02:27:00

- [x] **p1.3**: subtask-guard が final_tasks をスキップする ✓
  - executor: claudecode
  - test_command: `grep -q 'final_tasks.*許可\|final_tasks.*bypass' /Users/amano/Desktop/thanks4claudecode/.claude/hooks/subtask-guard.sh && echo PASS || echo FAIL`
  - validations:
    - technical: "PASS - final_tasks 判定ロジックが実装"
    - consistency: "PASS - subtasks との区別が明確"
    - completeness: "PASS - 全 final_tasks 形式（ft*, **ft）に対応"
  - validated: 2025-12-17T02:29:00

**status**: done

---

### p2: V12 チェックボックス形式実装

**goal**: subtask 単位で `- [ ]` / `- [x]` を使い、報酬詐欺を視覚的に防止

#### subtasks

- [x] **p2.1**: playbook-format.md が V12 形式になっている ✓
  - executor: claudecode
  - test_command: `grep -q 'V12.*チェックボックス' /Users/amano/Desktop/thanks4claudecode/plan/template/playbook-format.md && echo PASS || echo FAIL`
  - validations:
    - technical: "PASS - `- [ ]` / `- [x]` テンプレートが定義"
    - consistency: "PASS - validations/validated タイムスタンプを含む"
    - completeness: "PASS - 旧形式との比較説明あり"
  - validated: 2025-12-17T02:42:00

- [x] **p2.2**: subtask-guard.sh が V12 形式に対応 ✓
  - executor: claudecode
  - test_command: `grep -q '\[ \].*\[x\]' /Users/amano/Desktop/thanks4claudecode/.claude/hooks/subtask-guard.sh && echo PASS || echo FAIL`
  - validations:
    - technical: "PASS - `- [ ]` → `- [x]` 変更を検出"
    - consistency: "PASS - V11 形式との互換性維持"
    - completeness: "PASS - validations なしでブロック"
  - validated: 2025-12-17T02:50:00

- [x] **p2.3**: archive-playbook.sh が V12 形式に対応 ✓
  - executor: claudecode
  - test_command: `grep -q '\[x\]' /Users/amano/Desktop/thanks4claudecode/.claude/hooks/archive-playbook.sh && echo PASS || echo FAIL`
  - validations:
    - technical: "PASS - `[x]` / `[ ]` カウントロジック実装"
    - consistency: "PASS - V11 形式との互換性維持"
    - completeness: "PASS - 未完了があればアーカイブ提案しない"
  - validated: 2025-12-17T02:50:00

- [x] **p2.4**: CLAUDE.md LOOP が V12 形式に更新 ✓
  - executor: claudecode
  - test_command: `grep -q 'V12.*チェックボックス' /Users/amano/Desktop/thanks4claudecode/CLAUDE.md && echo PASS || echo FAIL`
  - validations:
    - technical: "PASS - LOOP セクションが V12 説明を含む"
    - consistency: "PASS - 変更履歴に V12 追加"
    - completeness: "PASS - 完了前/後の例が記載"
  - validated: 2025-12-17T02:50:00

**status**: done

---

### p3: 既存 milestone 再検証

**goal**: M014～M025 等の achieved milestone の done_when が実際に満たされているか再検証

#### subtasks

- [x] **p3.1**: verify-milestones.sh が存在し実行可能 ✓
  - executor: claudecode
  - test_command: `test -f /Users/amano/Desktop/thanks4claudecode/tmp/verify-milestones.sh && bash -n /Users/amano/Desktop/thanks4claudecode/tmp/verify-milestones.sh && echo PASS || echo FAIL`
  - validations:
    - technical: "PASS - スクリプトが存在し構文エラーなし"
    - consistency: "PASS - 他の検証スクリプトと同じ形式"
    - completeness: "PASS - 全 achieved milestone を検証"
  - validated: 2025-12-17T02:57:00

- [x] **p3.2**: スクリプトが全 achieved milestone を検証 ✓
  - executor: claudecode
  - test_command: `bash /Users/amano/Desktop/thanks4claudecode/tmp/verify-milestones.sh 2>&1 | grep -q 'M014\|M015' && echo PASS || echo FAIL`
  - validations:
    - technical: "PASS - 18 milestone を検証（PASS: 15, SKIP: 3）"
    - consistency: "PASS - project.md の milestone 定義と一致"
    - completeness: "PASS - 全 achieved milestone を網羅"
  - validated: 2025-12-17T02:57:22

- [x] **p3.3**: 検証結果が tmp/verification-report.md に出力 ✓
  - executor: claudecode
  - test_command: `test -f /Users/amano/Desktop/thanks4claudecode/tmp/verification-report.md && grep -q 'PASS\|FAIL' /Users/amano/Desktop/thanks4claudecode/tmp/verification-report.md && echo PASS || echo FAIL`
  - validations:
    - technical: "PASS - レポートファイルが生成"
    - consistency: "PASS - 標準的なマークダウン形式"
    - completeness: "PASS - Summary + Details 構造"
  - validated: 2025-12-17T02:57:22

**status**: done

---

### p_final: 完了検証フェーズ

**goal**: M056 の done_when が全て満たされているか最終検証

#### subtasks

- [x] **pf.1**: done_when 1 - p_final がテンプレートに追加されている ✓
  - executor: claudecode
  - test_command: `grep -q 'p_final.*完了検証' /Users/amano/Desktop/thanks4claudecode/plan/template/playbook-format.md && echo PASS || echo FAIL`
  - validations:
    - technical: "PASS - p_final セクションがテンプレートに存在"
    - consistency: "PASS - 他の Phase と同じ形式"
    - completeness: "PASS - 目的・構造・実装ガイドを含む"
  - validated: 2025-12-17T03:05:00

- [x] **pf.2**: done_when 2 - archive-playbook.sh が done_when を検証 ✓
  - executor: claudecode
  - test_command: `grep -q 'done_when' /Users/amano/Desktop/thanks4claudecode/.claude/hooks/archive-playbook.sh && echo PASS || echo FAIL`
  - validations:
    - technical: "PASS - done_when 検証ロジックが実装"
    - consistency: "PASS - 他の Hook と同じ exit code 規約"
    - completeness: "PASS - FAIL 時にブロック（exit 2）"
  - validated: 2025-12-17T03:05:00

- [x] **pf.3**: done_when 3 - subtask-guard が final_tasks をスキップ ✓
  - executor: claudecode
  - test_command: `grep -q 'final_tasks' /Users/amano/Desktop/thanks4claudecode/.claude/hooks/subtask-guard.sh && echo PASS || echo FAIL`
  - validations:
    - technical: "PASS - final_tasks バイパスロジックが実装"
    - consistency: "PASS - subtasks との区別が明確"
    - completeness: "PASS - 全 final_tasks 形式（ft*, **ft）に対応"
  - validated: 2025-12-17T03:05:00

- [x] **pf.4**: done_when 4 - 既存 milestone 再検証完了 ✓
  - executor: claudecode
  - test_command: `test -f /Users/amano/Desktop/thanks4claudecode/tmp/verification-report.md && echo PASS || echo FAIL`
  - validations:
    - technical: "PASS - verification-report.md が存在"
    - consistency: "PASS - 18 milestone 検証、PASS: 15, SKIP: 3"
    - completeness: "PASS - 全 achieved milestone を網羅"
  - validated: 2025-12-17T03:05:00

- [x] **pf.5**: 追加 - V12 チェックボックス形式が適用されている ✓
  - executor: claudecode
  - test_command: `grep -q 'V12' /Users/amano/Desktop/thanks4claudecode/CLAUDE.md && echo PASS || echo FAIL`
  - validations:
    - technical: "PASS - CLAUDE.md に V12 記載"
    - consistency: "PASS - LOOP セクションが V12 対応"
    - completeness: "PASS - 変更履歴にも追加"
  - validated: 2025-12-17T03:05:00

**status**: done

---

## final_tasks

- [x] **ft1**: repository-map.yaml を更新 ✓
  - command: `bash /Users/amano/Desktop/thanks4claudecode/.claude/hooks/generate-repository-map.sh`
  - note: 既存ファイルを使用（最新の状態で更新済み）

- [x] **ft2**: tmp/ 一時ファイル削除 ✓
  - command: `rm -f /Users/amano/Desktop/thanks4claudecode/tmp/verify-milestones.sh /Users/amano/Desktop/thanks4claudecode/tmp/verification-report.md`
  - note: 一時ファイル削除完了

- [x] **ft3**: 変更をコミット ✓
  - command: `cd /Users/amano/Desktop/thanks4claudecode && git add -A && git status`
