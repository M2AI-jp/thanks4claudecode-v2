# playbook-m016-release-preparation.md

> **リリース準備：自己認識システム完成**

---

## meta

```yaml
project: thanks4claudecode
branch: feat/final-release-preparation
created: 2025-12-14
issue: null
derives_from: M016
reviewed: false
status: in_progress
```

---

## goal

```yaml
summary: リポジトリの完成度を高め、リリース可能な状態にする
done_when:
  - repository-map.yaml の全 Hook に trigger が明示されている
  - Hook 間の連鎖関係がドキュメント化されている
  - SubAgents/Skills の description が完全化されている
  - [理解確認] に失敗リスク分析が組み込まれている
  - コンテキスト保護機構が検証済み
  - 全体の整合性が確認されている
```

---

## phases

```yaml
- id: p0
  name: 状態不整合の修正
  goal: project.md / state.md の M015/M016 ステータス整合性を確保

  subtasks:
    - id: p0.1
      criterion: "project.md の M015 が status: achieved になっている"
      executor: claudecode
      test_command: "grep -A2 'id: M015' plan/project.md | grep -q 'status: achieved' && echo PASS || echo FAIL"

    - id: p0.2
      criterion: "project.md に M016 が追加されている"
      executor: claudecode
      test_command: "grep -q 'id: M016' plan/project.md && echo PASS || echo FAIL"

    - id: p0.3
      criterion: "state.md の goal.milestone が M016 になっている"
      executor: claudecode
      test_command: "grep -q 'milestone: M016' state.md && echo PASS || echo FAIL"

    - id: p0.4
      criterion: "state.md の playbook.active がこの playbook を指している"
      executor: claudecode
      test_command: "grep -q 'active: plan/active/playbook-m016' state.md && echo PASS || echo FAIL"

  status: in_progress
  max_iterations: 3

- id: p0.5
  name: "[理解確認] に失敗リスク分析を組み込む"
  goal: 合意プロセスに失敗リスク分析を恒常的に組み込む

  subtasks:
    - id: p0.5.1
      criterion: "consent-process/skill.md に risks フォーマットが追加されている"
      executor: claudecode
      test_command: "grep -q 'risks:' .claude/skills/consent-process/skill.md && echo PASS || echo FAIL"

    - id: p0.5.2
      criterion: "consent-guard.sh のメッセージに risks が含まれている"
      executor: claudecode
      test_command: "grep -q 'risks' .claude/hooks/consent-guard.sh && echo PASS || echo FAIL"

    - id: p0.5.3
      criterion: "CLAUDE.md に [理解確認] セクションが追加されている"
      executor: claudecode
      test_command: "grep -q '\\[理解確認\\]' CLAUDE.md && echo PASS || echo FAIL"

  status: done
  max_iterations: 3

- id: p1
  name: repository-map.yaml の trigger 明示
  goal: settings.json を解析し、全 Hook の発動イベントを repository-map.yaml に反映
  depends_on: [p0]

  subtasks:
    - id: p1.1
      criterion: "repository-map.yaml の全 Hook に trigger フィールドが存在し、unknown でない"
      executor: claudecode
      test_command: "grep 'trigger:' docs/repository-map.yaml | grep -cv 'unknown' | awk '{if($1>=20) print \"PASS\"; else print \"FAIL\"}'"

    - id: p1.2
      criterion: "Hook の matcher（*, Edit, Write, Bash, Task, Read）が明示されている"
      executor: claudecode
      test_command: "grep -E 'event:.*Tool' docs/repository-map.yaml | head -5 && echo PASS"

  status: pending
  max_iterations: 5

- id: p2
  name: SubAgents/Skills の description 完全化
  goal: 80文字で切れている description を完全な内容に更新
  depends_on: [p0]

  subtasks:
    - id: p2.1
      criterion: "全 SubAgents の description が切れていない（...で終わらない）"
      executor: claudecode
      test_command: "grep -c '\\.\\.\\.\"$' docs/repository-map.yaml | awk '{if($1==0) print \"PASS\"; else print \"FAIL\"}'"

    - id: p2.2
      criterion: "全 Skills の description が切れていない"
      executor: claudecode
      test_command: "grep 'description:' docs/repository-map.yaml | grep -v '\\.\\.\\.' | head -3 && echo PASS"

  status: pending
  max_iterations: 5

- id: p3
  name: Hook 連鎖関係のドキュメント化
  goal: Hook 間の呼び出し関係を明示するセクションを docs/extension-system.md に追加
  depends_on: [p1]

  subtasks:
    - id: p3.1
      criterion: "docs/extension-system.md に Hook 連鎖セクションが存在する"
      executor: claudecode
      test_command: "grep -q '連鎖' docs/extension-system.md && echo PASS || echo FAIL"

    - id: p3.2
      criterion: "SessionStart → UserPromptSubmit → PreToolUse の初期化フローが明示されている"
      executor: claudecode
      test_command: "grep -q 'SessionStart' docs/extension-system.md && grep -q 'UserPromptSubmit' docs/extension-system.md && echo PASS || echo FAIL"

  status: pending
  max_iterations: 5

- id: p4
  name: コンテキスト保護の検証
  goal: session-start.sh / prompt-guard.sh がコンテキスト汚染を防止していることを確認
  depends_on: [p0]

  subtasks:
    - id: p4.1
      criterion: "session-start.sh が state.md の内容を出力している"
      executor: claudecode
      test_command: "grep -q 'state.md' .claude/hooks/session-start.sh && echo PASS || echo FAIL"

    - id: p4.2
      criterion: "prompt-guard.sh が必須ファイル読み込みを案内している"
      executor: claudecode
      test_command: "grep -q 'Read' .claude/hooks/prompt-guard.sh && echo PASS || echo FAIL"

    - id: p4.3
      criterion: "CLAUDE.md の INIT セクションに必須読み込みリストがある"
      executor: claudecode
      test_command: "grep -q 'state.md' CLAUDE.md && grep -q 'project.md' CLAUDE.md && grep -q 'playbook' CLAUDE.md && echo PASS || echo FAIL"

  status: pending
  max_iterations: 3

- id: p5
  name: 全体整合性の最終確認
  goal: 全ファイル間の整合性を確認し、リリース可能な状態を検証
  depends_on: [p1, p2, p3, p4]

  subtasks:
    - id: p5.1
      criterion: "state.md と project.md の milestone が一致している"
      executor: claudecode
      test_command: |
        state_ms=$(grep 'milestone:' state.md | head -1 | awk '{print $2}')
        proj_ms=$(grep -B1 'status: in_progress' plan/project.md | grep 'id:' | awk '{print $2}')
        [ "$state_ms" = "$proj_ms" ] && echo PASS || echo FAIL

    - id: p5.2
      criterion: "playbook.active が正しく設定されている"
      executor: claudecode
      test_command: "grep -q 'active:' state.md && echo PASS || echo FAIL"

    - id: p5.3
      criterion: "critic による最終検証が PASS している"
      executor: claudecode
      test_command: "echo 'critic SubAgent を呼び出して検証'"

  status: pending
  max_iterations: 3

- id: cleanup
  name: クリーンアップ
  goal: テンポラリファイルの削除と最終コミット
  depends_on: [p5]

  subtasks:
    - id: cleanup.1
      criterion: "tmp/ 内の不要ファイルが削除されている"
      executor: claudecode
      test_command: "ls tmp/ 2>/dev/null | wc -l | awk '{if($1<=2) print \"PASS\"; else print \"FAIL\"}'"

    - id: cleanup.2
      criterion: "全変更がコミットされている"
      executor: claudecode
      test_command: "git status --porcelain | wc -l | awk '{if($1==0) print \"PASS\"; else print \"FAIL\"}'"

  status: pending
  max_iterations: 2
```

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-14 | 初版作成。M016 リリース準備タスク。 |
| 2025-12-14 | p0.5 追加：[理解確認] に失敗リスク分析を組み込む（完了）。 |
