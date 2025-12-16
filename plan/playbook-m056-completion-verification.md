# playbook-m056-completion-verification.md

> **playbook 完了検証システム（報酬詐欺防止の強化）**
>
> playbook 完了時に done_when が実際に満たされているか検証する仕組みを構築。
> 報酬詐欺（done_when 未達成で achieved）を構造的に防止する。

---

## meta

```yaml
project: thanks4claudecode
branch: feat/m056-completion-verification
created: 2025-12-17
issue: M056
derives_from: M056  # project.md milestone
reviewed: false
```

---

## goal

```yaml
summary: |
  playbook 完了時に「本当に完了したか」を自動検証し、
  done_when 未達成で achieved 状態になることを構造的に防止する

done_when:
  - playbook-format.md に完了検証フェーズ（p_final）が必須として追加されている
  - archive-playbook.sh が done_when の test_command を再実行して検証する
  - subtask-guard が final_tasks の status: done をブロックしない
  - 既存の achieved milestone の done_when が実際に満たされているか再検証完了
```

---

## phases

### p0: テンプレート拡張（p_final 必須化）

完了検証フェーズ（p_final）を playbook-format.md に追加し、
新規 playbook が必ず完了検証ロジックを含むようにする。

#### subtasks

- id: p0.1
  criterion: "playbook-format.md に p_final Phase の説明セクションが存在する"
  executor: claudecode
  test_command: "grep -q 'p_final.*完了検証' /Users/amano/Desktop/thanks4claudecode/plan/template/playbook-format.md && echo PASS || echo FAIL"
  validations:
    technical: "p_final セクションが YAML 形式で正しく記述されている"
    consistency: "p_final の目的と実装が整合している"
    completeness: "p_final の詳細な説明（なぜ必要か、何を検証するか）が含まれている"
  depends_on: []

- id: p0.2
  criterion: "playbook-format.md に p_final の subtask テンプレート例が含まれている"
  executor: claudecode
  test_command: "grep -A 20 'p_final' /Users/amano/Desktop/thanks4claudecode/plan/template/playbook-format.md | grep -q 'subtasks' && echo PASS || echo FAIL"
  validations:
    technical: "テンプレート例が実際に使用可能な形式である"
    consistency: "他の Phase の subtask フォーマットと一致している"
    completeness: "test_command の例が複数パターン含まれている"
  depends_on: [p0.1]

- id: p0.3
  criterion: "playbook-format.md に p_final 実装ガイドが追加されている"
  executor: claudecode
  test_command: "grep -q 'done_when の再検証' /Users/amano/Desktop/thanks4claudecode/plan/template/playbook-format.md && echo PASS || echo FAIL"
  validations:
    technical: "ガイドが具体的でフォローアブルである"
    consistency: "既存の criterion 記述ガイドと同じ形式を使用"
    completeness: "p_final に含めるべき項目（what, how, test_command）が全て説明されている"
  depends_on: [p0.2]

status: pending
max_iterations: 5

---

### p1: archive-playbook.sh 拡張（done_when 再検証）

archive-playbook.sh に done_when の test_command を実行し、
全て PASS でなければアーカイブをブロックするロジックを実装する。

#### subtasks

- id: p1.1
  criterion: "archive-playbook.sh に done_when 検証セクションが存在する"
  executor: claudecode
  test_command: "grep -q 'done_when' /Users/amano/Desktop/thanks4claudecode/.claude/hooks/archive-playbook.sh && echo PASS || echo FAIL"
  validations:
    technical: "done_when パースロジックが bash で実装可能である"
    consistency: "既存の playbook パース処理と同じ手法を使用"
    completeness: "複数の done_when 項目を全て処理できる"
  depends_on: []

- id: p1.2
  criterion: "archive-playbook.sh が playbook の test_command を実行して PASS/FAIL を判定する"
  executor: claudecode
  test_command: "grep -q 'test_command.*PASS' /Users/amano/Desktop/thanks4claudecode/.claude/hooks/archive-playbook.sh && echo PASS || echo FAIL"
  validations:
    technical: "test_command の実行結果を正確に判定できる"
    consistency: "LOOP セクション（CLAUDE.md）と同じ test_command 実行ロジックを使用"
    completeness: "全 done_when 項目について PASS/FAIL 判定が実行される"
  depends_on: [p1.1]

- id: p1.3
  criterion: "archive-playbook.sh がアーカイブをブロックできる（FAIL 時）"
  executor: claudecode
  test_command: "grep -q 'exit 2.*done_when' /Users/amano/Desktop/thanks4claudecode/.claude/hooks/archive-playbook.sh && echo PASS || echo FAIL"
  validations:
    technical: "exit code 2 でブロック機能が実装されている"
    consistency: "既存の Hook のブロック機構（exit 2）と統一"
    completeness: "FAIL 時の警告メッセージが具体的（どの項目が FAIL したか明示）"
  depends_on: [p1.2]

- id: p1.4
  criterion: "archive-playbook.sh の構文チェックが通る"
  executor: claudecode
  test_command: "bash -n /Users/amano/Desktop/thanks4claudecode/.claude/hooks/archive-playbook.sh && echo PASS || echo FAIL"
  validations:
    technical: "シンタックスエラーがない"
    consistency: "bash -n による検証が通る"
    completeness: "全ての行が構文的に正しい"
  depends_on: [p1.3]

status: pending
max_iterations: 5

---

### p2: subtask-guard 修正（final_tasks 誤検出修正）

subtask-guard が final_tasks セクションの status: done 変更をブロックしないよう修正。
subtasks と final_tasks を区別するロジックを追加。

#### subtasks

- id: p2.1
  criterion: "subtask-guard.sh が final_tasks セクションを検出できる"
  executor: claudecode
  test_command: "grep -q 'final_tasks' /Users/amano/Desktop/thanks4claudecode/.claude/hooks/subtask-guard.sh && echo PASS || echo FAIL"
  validations:
    technical: "final_tasks を YAML パースで正確に検出できる"
    consistency: "既存の Hook スキーマ参照（state-schema.sh）と同じ方法を使用"
    completeness: "subtasks と final_tasks を区別するロジックがある"
  depends_on: []

- id: p2.2
  criterion: "subtask-guard.sh が final_tasks の status 変更をブロックしない"
  executor: claudecode
  test_command: "grep -A 5 'final_tasks' /Users/amano/Desktop/thanks4claudecode/.claude/hooks/subtask-guard.sh | grep -q 'skip\\|allow\\|bypass' && echo PASS || echo FAIL"
  validations:
    technical: "final_tasks 内の status: done 変更が許可される"
    consistency: "条件付きブロック（条件分岐）が実装されている"
    completeness: "全 final_tasks 項目について status 変更が許可される"
  depends_on: [p2.1]

- id: p2.3
  criterion: "subtask-guard.sh が subtasks の status 変更は依然ブロックする"
  executor: claudecode
  test_command: "grep -B 5 'final_tasks' /Users/amano/Desktop/thanks4claudecode/.claude/hooks/subtask-guard.sh | grep -q 'subtask' && echo PASS || echo FAIL"
  validations:
    technical: "subtasks セクションのチェックロジックが削除されていない"
    consistency: "3検証（technical/consistency/completeness）チェックが維持されている"
    completeness: "subtasks.status: done のバリデーションが有効"
  depends_on: [p2.2]

- id: p2.4
  criterion: "subtask-guard.sh の構文チェックが通る"
  executor: claudecode
  test_command: "bash -n /Users/amano/Desktop/thanks4claudecode/.claude/hooks/subtask-guard.sh && echo PASS || echo FAIL"
  validations:
    technical: "シンタックスエラーがない"
    consistency: "bash -n による検証が通る"
    completeness: "全ての行が構文的に正しい"
  depends_on: [p2.3]

status: pending
max_iterations: 5

---

### p3: 既存 milestone 再検証（M014 等の done_when 検証）

M014 などの achieved milestone の done_when が実際に満たされているか再検証。
未達成項目があれば報告し、修正タスクを提案。

#### subtasks

- id: p3.1
  criterion: "project.md の全 achieved milestone を特定できる"
  executor: claudecode
  test_command: "grep -c 'status: achieved' /Users/amano/Desktop/thanks4claudecode/plan/project.md | awk '{if($1>=5) print \"PASS\"; else print \"FAIL\"}'"
  validations:
    technical: "achieved milestone の count が正確である"
    consistency: "project.md の最新状態を参照している"
    completeness: "[N]:achieved になっているマイルストーン数が正確に把握できている"
  depends_on: []

- id: p3.2
  criterion: "各 achieved milestone の done_when を再検証するスクリプトが作成されている"
  executor: claudecode
  test_command: "test -f /Users/amano/Desktop/thanks4claudecode/tmp/verify-milestones.sh && echo PASS || echo FAIL"
  validations:
    technical: "スクリプトが実行可能で bash -n による構文チェックが通る"
    consistency: "他の検証スクリプト（.claude/hooks/*.sh）と同じ形式"
    completeness: "全 milestone を処理するロジックを含む"
  depends_on: [p3.1]

- id: p3.3
  criterion: "スクリプトが M014～M025 の done_when を再実行して PASS/FAIL を判定する"
  executor: claudecode
  test_command: "bash /Users/amano/Desktop/thanks4claudecode/tmp/verify-milestones.sh 2>&1 | grep -q 'M014\\|M015' && echo PASS || echo FAIL"
  validations:
    technical: "各 milestone の test_command が実際に実行される"
    consistency: "テスト実行の方法が LOOP セクション（CLAUDE.md）と統一"
    completeness: "複数 milestone を順に処理できる"
  depends_on: [p3.2]

- id: p3.4
  criterion: "検証結果が tmp/verification-report.md にまとめられている"
  executor: claudecode
  test_command: "test -f /Users/amano/Desktop/thanks4claudecode/tmp/verification-report.md && grep -c 'PASS\\|FAIL' /Users/amano/Desktop/thanks4claudecode/tmp/verification-report.md | awk '{if($1>0) print \"PASS\"; else print \"FAIL\"}'"
  validations:
    technical: "レポートが構造化された形式（Markdown）である"
    consistency: "報告フォーマットが他のドキュメント（project.md など）と整合している"
    completeness: "全 milestone について PASS/FAIL が記載されている"
  depends_on: [p3.3]

- id: p3.5
  criterion: "未達成 done_when がある場合、修正タスク提案が included されている"
  executor: claudecode
  test_command: "grep -c 'FAIL' /Users/amano/Desktop/thanks4claudecode/tmp/verification-report.md | awk '{if($1==0) print \"PASS\"; else grep -q 'Action:' /Users/amano/Desktop/thanks4claudecode/tmp/verification-report.md && echo \"PASS\" || echo \"FAIL\"}'"
  validations:
    technical: "修正提案が実行可能なアクションである"
    consistency: "提案形式が project.md の milestone 形式と統一"
    completeness: "全 FAIL 項目について修正提案がある"
  depends_on: [p3.4]

status: pending
max_iterations: 5

---

### p4: p_final テンプレートの新規 playbook への適用

新規 playbook 作成時に p_final が必ず含まれるよう、
playbook テンプレート生成ロジック（pm SubAgent）を確認・修正。

#### subtasks

- id: p4.1
  criterion: "pm SubAgent が p_final を含む playbook を生成する確認テスト用 playbook が作成されている"
  executor: claudecode
  test_command: "test -f /Users/amano/Desktop/thanks4claudecode/tmp/test-playbook-m056-test.md && grep -q 'p_final' /Users/amano/Desktop/thanks4claudecode/tmp/test-playbook-m056-test.md && echo PASS || echo FAIL"
  validations:
    technical: "テスト playbook が valid YAML である"
    consistency: "既存 playbook フォーマットと統一"
    completeness: "p_final を含む完全な playbook 構造がある"
  depends_on: []

- id: p4.2
  criterion: "p_final の done_criteria に各 subtask の test_command が含まれている"
  executor: claudecode
  test_command: "grep -A 20 'p_final:' /Users/amano/Desktop/thanks4claudecode/tmp/test-playbook-m056-test.md | grep -q 'test_command' && echo PASS || echo FAIL"
  validations:
    technical: "test_command が実行可能なコマンド形式である"
    consistency: "他の Phase の test_command パターンと統一"
    completeness: "全 subtask の検証に対応する test_command がある"
  depends_on: [p4.1]

- id: p4.3
  criterion: "テスト playbook で p_final Phase を実行して全 subtask が PASS する"
  executor: claudecode
  test_command: |
    cd /Users/amano/Desktop/thanks4claudecode && \
    bash -c 'source tmp/test-playbook-m056-test.md 2>/dev/null && echo PASS' || echo FAIL
  validations:
    technical: "test_command の実行が成功する"
    consistency: "実行方法が LOOP セクション（CLAUDE.md）の test_command 実行と統一"
    completeness: "全 subtask のテストが実行される"
  depends_on: [p4.2]

status: pending
max_iterations: 5

---

### p5: クリーンアップと最終検証

検証が完了したら tmp/ ファイルをクリーンアップし、
最終的に done_when が全て満たされているか確認。

#### subtasks

- id: p5.1
  criterion: "tmp/verify-milestones.sh が削除されている"
  executor: claudecode
  test_command: "test ! -f /Users/amano/Desktop/thanks4claudecode/tmp/verify-milestones.sh && echo PASS || echo FAIL"
  validations:
    technical: "ファイルが確実に削除されている"
    consistency: "tmp/ クリーンアップルール（docs/folder-management.md）に従っている"
    completeness: "中間成果物が残存しない"
  depends_on: [p3.5]

- id: p5.2
  criterion: "tmp/verification-report.md が削除されている"
  executor: claudecode
  test_command: "test ! -f /Users/amano/Desktop/thanks4claudecode/tmp/verification-report.md && echo PASS || echo FAIL"
  validations:
    technical: "ファイルが確実に削除されている"
    consistency: "tmp/ クリーンアップルール（docs/folder-management.md）に従っている"
    completeness: "中間成果物が残存しない"
  depends_on: [p5.1]

- id: p5.3
  criterion: "tmp/test-playbook-m056-test.md が削除されている"
  executor: claudecode
  test_command: "test ! -f /Users/amano/Desktop/thanks4claudecode/tmp/test-playbook-m056-test.md && echo PASS || echo FAIL"
  validations:
    technical: "テスト playbook が確実に削除されている"
    consistency: "tmp/ クリーンアップルール（docs/folder-management.md）に従っている"
    completeness: "テスト成果物が残存しない"
  depends_on: [p5.2]

- id: p5.4
  criterion: "全 done_when 項目が実装されている"
  executor: claudecode
  test_command: |
    (test -f /Users/amano/Desktop/thanks4claudecode/plan/template/playbook-format.md && \
     grep -q 'p_final.*完了検証' /Users/amano/Desktop/thanks4claudecode/plan/template/playbook-format.md && \
     grep -q 'done_when' /Users/amano/Desktop/thanks4claudecode/.claude/hooks/archive-playbook.sh && \
     grep -q 'final_tasks' /Users/amano/Desktop/thanks4claudecode/.claude/hooks/subtask-guard.sh) && echo PASS || echo FAIL
  validations:
    technical: "全ての実装ファイルが存在する"
    consistency: "各ファイルの実装が project.md の done_when と一致"
    completeness: "4つの done_when 項目が全て実装されている"
  depends_on: [p5.3]

status: pending
max_iterations: 5

---

## final_tasks

- id: ft1
  task: "repository-map.yaml を更新する"
  command: "bash /Users/amano/Desktop/thanks4claudecode/.claude/hooks/generate-repository-map.sh"
  status: pending

- id: ft2
  task: "tmp/ 内の一時ファイルを削除する"
  command: "find /Users/amano/Desktop/thanks4claudecode/tmp -type f ! -name 'CLAUDE.md' ! -name 'README.md' -delete"
  status: pending

- id: ft3
  task: "変更を全てコミットする"
  command: "cd /Users/amano/Desktop/thanks4claudecode && git add -A && git status"
  status: pending
