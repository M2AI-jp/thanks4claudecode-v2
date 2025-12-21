# playbook-m142-hook-tests.md

> **動線単位での Hook 動作テスト**
>
> Hook 単体テストではなく、動線の中で Hook が発火・動作することを検証する。

---

## meta

```yaml
schema_version: v2
project: thanks4claudecode
branch: feat/m142-hook-tests
created: 2025-12-21
issue: null
derives_from: M142
reviewed: false
roles:
  worker: claudecode

user_prompt_original: |
  コア機能の確定と凍結が一番最初にあったほうがいいかな。
  凍結の前に動作保証がなされている必要がある。
  例えば何回言っても君、理解確認機能が直らないしね。
  今の機能全部、リストアップして。何で動作しないのか、棚卸ししながら、
  スモールステップで進めるしかない。

user_correction: |
  ねえ。何回言わせるの？テストはコンポーネント単位じゃなくて動線単位でやるんだよ。
  Hookだけテストする設計になってないだろうな？
```

---

## goal

```yaml
summary: 動線テストで全 Hook の動作を検証する
done_when:
  - "flow-runtime-test.sh が 4 動線で関連 Hook をテストしている"
  - "e2e-contract-test.sh が契約シナリオで Guard 動作を検証している"
  - "全動線テストが PASS（flow: 25+、e2e: 77+）"
```

---

## phases

### p1: 動線テストカバレッジ確認

**goal**: 動線テストが Hook をどれだけカバーしているか確認

#### subtasks

- [x] **p1.1**: 登録済み Hook の一覧を取得（20個）
  - executor: claudecode
  - test_command: `grep -oE 'hooks/[a-z-]+\.sh' .claude/settings.json | sed 's|hooks/||' | sort -u | wc -l`
  - validations:
    - PASS - 20 Hook が登録されている

- [x] **p1.2**: flow-runtime-test.sh のカバレッジを確認
  - executor: claudecode
  - test_command: `grep -oE '[a-z-]+\.sh' scripts/flow-runtime-test.sh | sort -u`
  - validations:
    - PASS - 5 Hook（archive-playbook, critic-guard, playbook-guard, pre-bash-check, session-end）

- [x] **p1.3**: e2e-contract-test.sh のカバレッジを確認
  - executor: claudecode
  - test_command: `bash scripts/e2e-contract-test.sh 2>&1 | tail -5`
  - validations:
    - PASS - contract.sh 経由で Guard ロジックをテスト（77 テスト）

**status**: done
**max_iterations**: 3

---

### p2: 動線テスト拡張

**goal**: 不足している動線テストを追加

**depends_on**: [p1]

#### subtasks

- [x] **p2.1**: 計画動線テストに session-start, prompt-guard を追加
  - executor: claudecode
  - test_command: `grep -E 'session-start|prompt-guard' scripts/flow-runtime-test.sh`
  - validations:
    - PASS - P6: session-start.sh, P7: prompt-guard.sh 追加

- [x] **p2.2**: 実行動線テストに init-guard, scope-guard を追加
  - executor: claudecode
  - test_command: `grep -E 'init-guard|scope-guard' scripts/flow-runtime-test.sh`
  - validations:
    - PASS - E6: init-guard.sh, E7: scope-guard.sh, E8: subtask-guard.sh, E9: depends-check.sh 追加

- [x] **p2.3**: 動線連携テストに check-coherence を追加
  - executor: claudecode
  - test_command: `grep -E 'check-coherence' scripts/flow-runtime-test.sh`
  - validations:
    - PASS - I6: check-coherence.sh, I7: lint-check.sh 追加

**status**: done
**max_iterations**: 5

---

### p_final: 完了検証（必須）

**goal**: 動線テストが全て PASS することを検証

#### subtasks

- [x] **p_final.1**: flow-runtime-test.sh が PASS
  - executor: claudecode
  - test_command: `bash scripts/flow-runtime-test.sh 2>&1 | tail -3`
  - validations:
    - PASS - 33 PASS / 0 FAIL

- [x] **p_final.2**: e2e-contract-test.sh が PASS
  - executor: claudecode
  - test_command: `bash scripts/e2e-contract-test.sh 2>&1 | tail -3`
  - validations:
    - PASS - 77 PASS / 0 FAIL

- [x] **p_final.3**: 動線カバレッジが向上している
  - executor: claudecode
  - test_command: `grep -oE '[a-z-]+\.sh' scripts/flow-runtime-test.sh | sort -u | wc -l`
  - validations:
    - PASS - 13 Hook がテストされている（前: 5）

**status**: done
**max_iterations**: 3

---

### p_e2e: 動線 E2E シミュレーション（追加）

**goal**: 4 動線が実際に機能することを E2E シミュレーションで検証

#### subtasks

- [x] **p_e2e.1**: シミュレーション環境準備
  - executor: claudecode
  - validations:
    - PASS - /tmp/e2e-simulation ディレクトリ作成
    - PASS - tmp.project.md 作成
    - PASS - state.md 初期化

- [x] **p_e2e.2**: 計画動線シミュレーション
  - executor: claudecode
  - validations:
    - PASS - playbook 作成
    - PASS - state.md 更新

- [x] **p_e2e.3**: 実行動線シミュレーション
  - executor: claudecode
  - validations:
    - PASS - Guard チェック（playbook-guard, init-guard）
    - PASS - ファイル作成（3 files）
    - PASS - npm run build 成功

- [x] **p_e2e.4**: 検証動線シミュレーション
  - executor: claudecode
  - validations:
    - PASS - /crit シミュレーション
    - PASS - 全 done_criteria PASS (3/3)
    - PASS - self_complete: true

- [x] **p_e2e.5**: 完了動線シミュレーション
  - executor: claudecode
  - validations:
    - PASS - playbook アーカイブ
    - PASS - state.md 更新（phase: done）
    - PASS - 次タスク導出（SIM-002）

- [x] **p_e2e.6**: ログ検証
  - executor: claudecode
  - validations:
    - PASS - 全 4 動線 SUCCESS
    - PASS - ログ保存（.claude/logs/e2e-flow-simulation.log）

**status**: done
**max_iterations**: 1

---

## final_tasks

- [ ] **ft1**: 変更を全てコミットする
  - command: `git add -A && git status`
  - status: pending

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-21 | 初版作成 |
| 2025-12-21 | 動線ベースに再定義（ユーザー指摘反映） |
| 2025-12-21 | E2E シミュレーション追加 |
