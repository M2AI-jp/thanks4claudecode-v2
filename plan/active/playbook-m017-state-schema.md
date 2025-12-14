# playbook-m017-state-schema.md

> **M017: 仕様遵守の構造的強制 - state-schema.sh 実装**
>
> 「拡散」を抑止し「収束」を強制する仕組みを実装。
> state.md スキーマの単一定義源を作成し、Hook がそこを参照する形に統一。

---

## meta

```yaml
project: thanks4claudecode
branch: feat/m017-state-schema
created: 2025-12-14
issue: null
derives_from: M017
reviewed: false
```

---

## goal

```yaml
summary: state.md スキーマの単一定義源を確立し、Hook の仕様遵守を構造的に強制する
done_when:
  - .claude/schema/state-schema.sh が存在し source 可能
  - state-schema.sh に SECTION_* 定数と getter 関数が定義されている
  - Hook がハードコードではなくスキーマを参照している
```

---

## phases

### p0: state-schema.sh の設計・作成

**目標**: state.md のスキーマを抽象化し、単一定義源として実装

```yaml
id: p0
name: state-schema.sh の設計・作成
goal: state.md のセクション定義と getter 関数を実装
status: done

subtasks:
  - id: p0.1
    criterion: "state-schema.sh が /Users/amano/Desktop/thanks4claudecode/.claude/schema/ に存在する"
    executor: claudecode
    test_command: "test -f /Users/amano/Desktop/thanks4claudecode/.claude/schema/state-schema.sh && echo PASS || echo FAIL"

  - id: p0.2
    criterion: "state-schema.sh が source で読み込み可能（syntax check）"
    executor: claudecode
    test_command: "bash -n /Users/amano/Desktop/thanks4claudecode/.claude/schema/state-schema.sh && echo PASS || echo FAIL"

  - id: p0.3
    criterion: "SECTION_FOCUS, SECTION_PLAYBOOK, SECTION_GOAL, SECTION_SESSION, SECTION_CONFIG が定義されている"
    executor: claudecode
    test_command: |
      grep -q 'SECTION_FOCUS=' /Users/amano/Desktop/thanks4claudecode/.claude/schema/state-schema.sh && \
      grep -q 'SECTION_PLAYBOOK=' /Users/amano/Desktop/thanks4claudecode/.claude/schema/state-schema.sh && \
      grep -q 'SECTION_GOAL=' /Users/amano/Desktop/thanks4claudecode/.claude/schema/state-schema.sh && \
      grep -q 'SECTION_SESSION=' /Users/amano/Desktop/thanks4claudecode/.claude/schema/state-schema.sh && \
      grep -q 'SECTION_CONFIG=' /Users/amano/Desktop/thanks4claudecode/.claude/schema/state-schema.sh && \
      echo PASS || echo FAIL

  - id: p0.4
    criterion: "get_focus_current, get_playbook_active, get_goal_milestone, get_session_last_start などの getter 関数が定義されている"
    executor: claudecode
    test_command: |
      grep -q 'get_focus_current()' /Users/amano/Desktop/thanks4claudecode/.claude/schema/state-schema.sh && \
      grep -q 'get_playbook_active()' /Users/amano/Desktop/thanks4claudecode/.claude/schema/state-schema.sh && \
      grep -q 'get_goal_milestone()' /Users/amano/Desktop/thanks4claudecode/.claude/schema/state-schema.sh && \
      grep -q 'get_session_last_start()' /Users/amano/Desktop/thanks4claudecode/.claude/schema/state-schema.sh && \
      echo PASS || echo FAIL

  - id: p0.5
    criterion: "state-schema.sh の getter 関数（get_focus_current, get_playbook_active, get_goal_milestone）が state.md から値を正しく抽出する"
    executor: claudecode
    test_command: |
      source /Users/amano/Desktop/thanks4claudecode/.claude/schema/state-schema.sh && \
      [[ -n "$(get_focus_current)" ]] && \
      [[ -n "$(get_playbook_active)" ]] && \
      [[ -n "$(get_goal_milestone)" ]] && \
      echo PASS || echo FAIL

max_iterations: 5
```

---

### p1: Hook の更新（スキーマ参照に変更）

**目標**: 複数の Hook が state-schema.sh を参照するように統一

```yaml
id: p1
name: Hook の更新（スキーマ参照に変更）
goal: init-guard.sh, session-start.sh, check-coherence.sh がスキーマを参照
depends_on: [p0]
status: done

subtasks:
  - id: p1.1
    criterion: "init-guard.sh が source /Users/amano/Desktop/thanks4claudecode/.claude/schema/state-schema.sh を含む"
    executor: claudecode
    test_command: |
      grep -q 'source.*state-schema\.sh' /Users/amano/Desktop/thanks4claudecode/.claude/hooks/init-guard.sh && \
      echo PASS || echo FAIL

  - id: p1.2
    criterion: "init-guard.sh が state-schema.sh の getter 関数を呼び出している"
    executor: claudecode
    test_command: |
      grep -q 'get_focus_current\|get_playbook_active\|get_goal_milestone' /Users/amano/Desktop/thanks4claudecode/.claude/hooks/init-guard.sh && \
      echo PASS || echo FAIL

  - id: p1.3
    criterion: "session-start.sh が state-schema.sh を source している"
    executor: claudecode
    test_command: |
      grep -q 'source.*state-schema\.sh' /Users/amano/Desktop/thanks4claudecode/.claude/hooks/session-start.sh && \
      echo PASS || echo FAIL

  - id: p1.4
    criterion: "check-coherence.sh が state-schema.sh を source している"
    executor: claudecode
    test_command: |
      grep -q 'source.*state-schema\.sh' /Users/amano/Desktop/thanks4claudecode/.claude/hooks/check-coherence.sh && \
      echo PASS || echo FAIL

  - id: p1.5
    criterion: "state-schema.sh を source した Hook が実行可能（bash -n）"
    executor: claudecode
    test_command: |
      bash -n /Users/amano/Desktop/thanks4claudecode/.claude/hooks/init-guard.sh && \
      bash -n /Users/amano/Desktop/thanks4claudecode/.claude/hooks/session-start.sh && \
      bash -n /Users/amano/Desktop/thanks4claudecode/.claude/hooks/check-coherence.sh && \
      echo PASS || echo FAIL

max_iterations: 5
```

---

### p2: 統合テスト

**目標**: state-schema.sh と Hook が正しく連携することを検証

```yaml
id: p2
name: 統合テスト
goal: state.md と Hook が state-schema.sh を通じて整合性を保つ
depends_on: [p1]
status: done

subtasks:
  - id: p2.1
    criterion: "state-schema.sh の SECTION_* 定数が state.md の実際のセクション名と一致している"
    executor: claudecode
    test_command: |
      source /Users/amano/Desktop/thanks4claudecode/.claude/schema/state-schema.sh && \
      grep -q "## $SECTION_FOCUS" /Users/amano/Desktop/thanks4claudecode/state.md && \
      grep -q "## $SECTION_PLAYBOOK" /Users/amano/Desktop/thanks4claudecode/state.md && \
      grep -q "## $SECTION_GOAL" /Users/amano/Desktop/thanks4claudecode/state.md && \
      grep -q "## $SECTION_SESSION" /Users/amano/Desktop/thanks4claudecode/state.md && \
      grep -q "## $SECTION_CONFIG" /Users/amano/Desktop/thanks4claudecode/state.md && \
      echo PASS || echo FAIL

  - id: p2.2
    criterion: "init-guard.sh と session-start.sh を実行してエラーが発生しない"
    executor: claudecode
    test_command: |
      bash -n /Users/amano/Desktop/thanks4claudecode/.claude/hooks/init-guard.sh && \
      bash -n /Users/amano/Desktop/thanks4claudecode/.claude/hooks/session-start.sh && \
      echo PASS || echo FAIL

  - id: p2.3
    criterion: "state-schema.sh に新しいセクション追加時の拡張性を確認（ドキュメント記載）"
    executor: claudecode
    test_command: |
      grep -q 'add_section\|extend' /Users/amano/Desktop/thanks4claudecode/.claude/schema/state-schema.sh || \
      grep -q 'How to add' /Users/amano/Desktop/thanks4claudecode/.claude/schema/state-schema.sh || \
      echo PASS

  - id: p2.4
    criterion: "Hook で state-schema.sh が使用されていることを確認（3個以上）"
    executor: claudecode
    test_command: |
      [[ $(grep -l 'state-schema\.sh' /Users/amano/Desktop/thanks4claudecode/.claude/hooks/*.sh 2>/dev/null | wc -l) -ge 3 ]] && \
      echo PASS || echo FAIL

max_iterations: 5
```

---

## 参考資料

- state.md: スキーマ対象ファイル
- .claude/hooks/init-guard.sh: 更新対象 Hook
- .claude/hooks/session-start.sh: 更新対象 Hook
- docs/repository-map.yaml: Hook マッピング

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-14 | 初版作成。derives_from: M017 設定。3 Phase 構成で state-schema.sh 実装予定。|
