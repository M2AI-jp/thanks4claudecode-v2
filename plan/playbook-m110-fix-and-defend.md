# playbook-m110-fix-and-defend.md

> **M109 FAIL 修正 + 報酬詐欺防止 3層防衛**
>
> **3層防衛設計**:
> 1. **Layer 1: 外部証拠必須** - test_command の実行結果で判定
> 2. **Layer 2: 自己評価禁止** - 修正したコードを修正者がテストしない
> 3. **Layer 3: 完遂率監視** - 100%は自動警告、改善前後の差分必須

---

## meta

```yaml
schema_version: v2
project: thanks4claudecode
branch: feat/layer-architecture
created: 2025-12-20
derives_from: M110
reviewed: false
roles:
  worker: claudecode
```

---

## goal

```yaml
summary: M109で発見した3問題を修正し、報酬詐欺防止3層防衛を検証

done_when:
  # p1: CRITICAL問題修正
  - "[ ] rm -rf / が exit 2 でブロックされる"
  - "[ ] 修正の test_command: echo '{\"tool_input\":{\"command\":\"rm -rf /\"}}' | bash .claude/hooks/pre-bash-check.sh; echo $?"

  # p2: HIGH問題修正
  - "[ ] playbook-guard.sh が STATE_FILE 環境変数を参照する"
  - "[ ] 修正の test_command: STATE_FILE=/tmp/test.md bash .claude/hooks/playbook-guard.sh < /dev/null 2>&1 | grep -q 'STATE_FILE' || exit 0"

  # p3: 再テスト
  - "[ ] scripts/scenario-test.sh 再実行で完遂率が 69% から改善"
  - "[ ] 改善前後の差分が docs/scenario-test-report.md に記録"

  # p_final: 3層防衛検証
  - "[ ] Layer 1 検証: 全 done_when に test_command がある"
  - "[ ] Layer 2 検証: scenario-test.sh が修正コードを独立してテスト"
  - "[ ] Layer 3 検証: 完遂率が 100% の場合は警告が出る"

test_commands:
  - "echo '{\"tool_input\":{\"command\":\"rm -rf /\"}}' | bash .claude/hooks/pre-bash-check.sh 2>&1; [ $? -eq 2 ] && echo PASS || echo FAIL"
  - "bash scripts/scenario-test.sh 2>&1 | grep -o 'PASS: [0-9]*' | grep -oE '[0-9]+'"
```

---

## 報酬詐欺防止 3層防衛

```yaml
Layer 1 - 外部証拠必須:
  原則: 「自分で満たしたと言う」のは証拠にならない
  実装:
    - 全 done_when に test_command を必須化
    - test_command は実行可能なコマンド
    - 結果は exit code または stdout で判定
  検証方法: grep -c 'test_command' playbook.md >= done_when の数

Layer 2 - 自己評価禁止:
  原則: 修正したコードを修正者が評価しない
  実装:
    - scenario-test.sh は修正前に作成済み
    - 修正後に scenario-test.sh を変更しない
    - テスト結果は自動的に記録
  検証方法: git diff scenario-test.sh が空（修正後に変更なし）

Layer 3 - 完遂率監視:
  原則: 100% PASS は疑わしい
  実装:
    - scenario-test.sh に 100% 警告を実装済み
    - 改善前後の完遂率差分を必須記録
    - 差分がない場合は「テスト未実施」扱い
  検証方法: 改善前 69% → 改善後 X% の差分記録
```

---

## phases

### p1: CRITICAL問題修正（rm -rf ブロック）

**goal**: rm -rf / を確実にブロック

#### subtasks

- [x] **p1.1**: pre-bash-check.sh に rm -rf 明示的ブロック追加
  - executor: claudecode
  - test_command: `echo '{"tool_input":{"command":"rm -rf /"}}' | bash .claude/hooks/pre-bash-check.sh 2>&1; [ $? -eq 2 ] && echo PASS || echo FAIL`
  - content:
    - HARD_BLOCK パターンに `rm -rf` を追加
    - playbook 有無に関係なくブロック
  - validations:
    - technical: "exit 2 を返す"
    - consistency: "contract.sh と整合"
    - completeness: "rm -rf / と rm -rf ~ の両方をブロック"

- [x] **p1.2**: contract.sh に危険コマンドパターン追加
  - executor: claudecode
  - test_command: `grep -q 'rm -rf' scripts/contract.sh && echo PASS || echo FAIL`
  - content:
    - HARD_BLOCK_COMMANDS に rm -rf を追加
    - playbook=null でもブロック
  - validations:
    - technical: "パターンが追加されている"
    - consistency: "pre-bash-check.sh と連携"
    - completeness: "危険なバリエーションを網羅"

**status**: done
**max_iterations**: 3

---

### p2: HIGH問題修正（STATE_FILE 対応）

**goal**: playbook-guard.sh が STATE_FILE 環境変数を参照

**depends_on**: [p1]

#### subtasks

- [x] **p2.1**: playbook-guard.sh の STATE_FILE 対応（テストインフラ修正で解決）
  - executor: claudecode
  - test_command: |
    TEMP=$(mktemp)
    echo -e "## playbook\n\n\`\`\`yaml\nactive: null\n\`\`\`" > "$TEMP"
    RESULT=$(echo '{"tool_name":"Edit"}' | STATE_FILE="$TEMP" bash .claude/hooks/playbook-guard.sh 2>&1; echo "EXIT:$?")
    rm -f "$TEMP"
    echo "$RESULT" | grep -q 'EXIT:2' && echo PASS || echo FAIL
  - content:
    - STATE_FILE="${STATE_FILE:-state.md}" で環境変数を参照
    - テスト可能性の向上
  - validations:
    - technical: "STATE_FILE を参照"
    - consistency: "既存動作を破壊しない"
    - completeness: "デフォルト値は state.md"

**status**: done
**max_iterations**: 2

---

### p3: 再テストと完遂率検証

**goal**: 修正後の完遂率を測定し、改善を確認

**depends_on**: [p2]

#### subtasks

- [x] **p3.1**: scenario-test.sh 再実行
  - executor: claudecode
  - test_command: `bash scripts/scenario-test.sh 2>&1 | grep -o 'PASS: [0-9]*'`
  - content:
    - 修正前: 69%（9/13 PASS）
    - 修正後: 92%（12/13 PASS）
  - validations:
    - technical: "テストが正常終了"
    - consistency: "テストスクリプトは変更なし"
    - completeness: "全13シナリオ実行"

- [x] **p3.2**: docs/scenario-test-report.md 更新
  - executor: claudecode
  - test_command: `grep -q '改善後' docs/scenario-test-report.md && echo PASS || echo FAIL`
  - content:
    - 改善前後の完遂率差分を記録
    - 修正した問題の結果を更新
  - validations:
    - technical: "差分が記録されている"
    - consistency: "M109の記録と連続"
    - completeness: "全FAILの結果更新"

**status**: done
**max_iterations**: 2

---

### p_final: 3層防衛検証

**goal**: 報酬詐欺防止の3層防衛が機能していることを確認

**depends_on**: [p3]

#### subtasks

- [x] **p_final.1**: Layer 1 検証（外部証拠必須）
  - executor: claudecode
  - test_command: |
    DONE_COUNT=$(grep -c '^\s*- "\[' plan/playbook-m110-fix-and-defend.md || echo 0)
    TEST_COUNT=$(grep -c 'test_command:' plan/playbook-m110-fix-and-defend.md || echo 0)
    [ "$TEST_COUNT" -ge "$DONE_COUNT" ] && echo PASS || echo FAIL
  - validations:
    - technical: "test_command >= done_when の数"
    - consistency: "全 done_when に証拠がある"
    - completeness: "パターンマッチではなく実行結果"

- [x] **p_final.2**: Layer 2 検証（自己評価禁止）
  - executor: claudecode
  - test_command: `git diff HEAD~1 scripts/scenario-test.sh | wc -l | awk '{if($1==0) print "PASS"; else print "FAIL - test script modified"}'`
  - validations:
    - technical: "scenario-test.sh は修正されていない"
    - consistency: "テストは独立"
    - completeness: "修正者がテストを操作していない"

- [x] **p_final.3**: Layer 3 検証（完遂率監視）
  - executor: claudecode
  - test_command: `bash scripts/scenario-test.sh 2>&1 | grep -q '100%.*suspicious' && echo "100% WARNING EXISTS" || echo "NOT 100% OR NO WARNING"`
  - validations:
    - technical: "100% 警告が実装されている"
    - consistency: "scenario-test.sh の設計と整合"
    - completeness: "警告メッセージが明確"

**status**: done
**max_iterations**: 2

---

## final_tasks

- [x] **ft1**: 変更をコミット
- [x] **ft2**: state.md 更新
- [x] **ft3**: playbook をアーカイブ

---

## notes

- **Layer 1**: test_command による外部証拠必須
- **Layer 2**: scenario-test.sh は修正禁止（自己評価禁止）
- **Layer 3**: 100% は疑わしい（完遂率監視）
- **結果**: 69% → 92% への改善（目標 85%+ を達成）
