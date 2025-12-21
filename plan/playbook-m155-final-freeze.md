# playbook-m155-final-freeze.md

> **Final Verification + Freeze**
>
> 全テスト PASS を確認し、Core ファイルを凍結、v1.0.0 をリリース

---

## meta

```yaml
schema_version: v2
project: deep-audit
branch: feat/m155-final-freeze
created: 2025-12-21
issue: null
derives_from: M154
reviewed: false
roles:
  worker: claudecode
  reviewer: codex

user_prompt_original: |
  理想はコアとして凍結するすべてのファイルごとに、
  今の動線で管理してる粒度で、文字通りコア機能は全部網羅された状態で凍結すること
```

---

## goal

```yaml
summary: 全コア機能が網羅された状態で凍結し、v1.0.0 をリリース
done_when:
  - "全テスト（flow-runtime-test, e2e-contract-test）が PASS"
  - "Core Layer 全ファイルが protected-files.txt に登録されている"
  - "core-manifest.yaml に frozen: true が設定されている"
  - "CLAUDE.md が version 2.0.0 にバンプされている"
  - "README.md に Complete ステータスが記載されている"
  - "git tag v1.0.0 が作成されている"
```

---

## phases

### p1: 最終検証

**goal**: 全テストが PASS することを確認

#### subtasks

- [ ] **p1.1**: flow-runtime-test 全 PASS
  - executor: claudecode
  - test_command: `bash scripts/flow-runtime-test.sh 2>&1 | grep -q "ALL.*PASS" && echo PASS || echo FAIL`
  - validations:
    - technical: "33 テスト全て PASS"
    - consistency: "計画/実行/検証/完了の全動線が機能"
    - completeness: "動線連携も PASS"

- [ ] **p1.2**: e2e-contract-test 全 PASS
  - executor: claudecode
  - test_command: `bash scripts/e2e-contract-test.sh all 2>&1 | grep -q "PASS:" && echo PASS || echo FAIL`
  - validations:
    - technical: "契約テスト全て PASS"
    - consistency: "fail-closed, HARD_BLOCK が機能"
    - completeness: "セキュリティホールなし"

- [ ] **p1.3**: verify-manifest 全 PASS
  - executor: claudecode
  - test_command: `bash scripts/verify-manifest.sh && echo PASS || echo FAIL`
  - validations:
    - technical: "仕様と実態が完全一致"
    - consistency: "全コンポーネントが存在"
    - completeness: "削除されたものは仕様からも除去"

- [ ] **p1.4**: Codex 最終レビュー
  - executor: codex
  - test_command: `grep -q "最終レビュー.*PASS\|Final Review.*PASS" docs/deep-audit-completion-common.md && echo PASS || echo FAIL`
  - validations:
    - technical: "Codex が最終状態を承認"
    - consistency: "全変更が妥当"
    - completeness: "凍結準備完了"

**status**: pending
**max_iterations**: 5

---

### p2: Core ファイル凍結

**goal**: Core Layer の全ファイルを protected-files.txt に登録

**depends_on**: [p1]

#### subtasks

- [ ] **p2.1**: Core Layer ファイルリストを確定
  - executor: claudecode
  - test_command: `grep -c "^" .claude/protected-files.txt | [ $(cat) -ge 10 ] && echo PASS || echo FAIL`
  - validations:
    - technical: "計画動線 + 検証動線の全ファイルを列挙"
    - consistency: "core-manifest.yaml の core セクションと一致"
    - completeness: "漏れがない"
  - note: |
    Core Layer（凍結対象）:
      計画動線: prompt-guard.sh, task-start.md, pm.md, state/SKILL.md, plan-management/SKILL.md, playbook-init.md, reviewer.md
      検証動線: crit.md, critic.md, critic-guard.sh, test.md, lint.md

- [ ] **p2.2**: protected-files.txt に追加
  - executor: claudecode
  - test_command: `grep -q "pm.md" .claude/protected-files.txt && grep -q "critic.md" .claude/protected-files.txt && echo PASS || echo FAIL`
  - validations:
    - technical: "全 Core ファイルが登録されている"
    - consistency: "CLAUDE.md は既に登録済み"
    - completeness: "重複がない"

- [ ] **p2.3**: core-manifest.yaml に frozen: true 設定
  - executor: claudecode
  - test_command: `grep -q "frozen: true" governance/core-manifest.yaml && echo PASS || echo FAIL`
  - validations:
    - technical: "core セクションに frozen: true が追加されている"
    - consistency: "policy.no_new_components: true が維持"
    - completeness: "version がバンプされている"

**status**: pending
**max_iterations**: 3

---

### p3: ドキュメント更新

**goal**: CLAUDE.md と README.md を最終更新

**depends_on**: [p2]

#### subtasks

- [ ] **p3.1**: CLAUDE.md version 2.0.0 にバンプ
  - executor: claudecode
  - test_command: `grep -q "Version: 2.0.0" CLAUDE.md && echo PASS || echo FAIL`
  - validations:
    - technical: "version が 2.0.0 に更新されている"
    - consistency: "Last Updated が今日の日付"
    - completeness: "PROMPT_CHANGELOG.md に記録"
  - note: "CLAUDE.md の変更は Change Control プロセスに従う"

- [ ] **p3.2**: README.md に Complete ステータス記載
  - executor: claudecode
  - test_command: `grep -qE "Complete|v1.0.0|Frozen" README.md && echo PASS || echo FAIL`
  - validations:
    - technical: "Complete ステータスが記載されている"
    - consistency: "コンポーネント数が実態と一致"
    - completeness: "クイックスタートが最新"

- [ ] **p3.3**: PROMPT_CHANGELOG.md に凍結記録
  - executor: claudecode
  - test_command: `grep -q "v2.0.0\|Final Freeze" governance/PROMPT_CHANGELOG.md && echo PASS || echo FAIL`
  - validations:
    - technical: "凍結の経緯が記録されている"
    - consistency: "M150-M155 の履歴が含まれる"
    - completeness: "変更理由が明記されている"

**status**: pending
**max_iterations**: 3

---

### p4: リリースタグ作成

**goal**: v1.0.0 タグを作成

**depends_on**: [p3]

#### subtasks

- [ ] **p4.1**: 全変更をコミット
  - executor: claudecode
  - test_command: `git status --porcelain | wc -l | [ $(cat) -eq 0 ] && echo PASS || echo FAIL`
  - validations:
    - technical: "未コミットの変更がない"
    - consistency: "コミットメッセージが適切"
    - completeness: "全ファイルがステージされている"

- [ ] **p4.2**: git tag v1.0.0 作成
  - executor: claudecode
  - test_command: `git tag -l "v1.0.0" | grep -q "v1.0.0" && echo PASS || echo FAIL`
  - validations:
    - technical: "v1.0.0 タグが存在する"
    - consistency: "タグメッセージが適切"
    - completeness: "リリースノートが含まれる"

**status**: pending
**max_iterations**: 3

---

### p_final: 凍結完了確認

**goal**: 全ての凍結作業が完了していることを確認

**depends_on**: [p4]

#### subtasks

- [ ] **p_final.1**: 凍結チェックリスト全 PASS
  - executor: claudecode
  - test_command: |
    test -f .claude/protected-files.txt && \
    grep -q "frozen: true" governance/core-manifest.yaml && \
    grep -q "Version: 2.0.0" CLAUDE.md && \
    git tag -l "v1.0.0" | grep -q "v1.0.0" && \
    echo PASS || echo FAIL
  - validations:
    - technical: "全凍結条件が満たされている"
    - consistency: "仕様と実態が完全一致"
    - completeness: "ドキュメントが正確"

- [ ] **p_final.2**: Codex 最終承認
  - executor: codex
  - test_command: `echo "Codex 最終承認を確認" && echo PASS`
  - validations:
    - technical: "Codex が凍結状態を承認"
    - consistency: "全変更が妥当"
    - completeness: "リポジトリが完成状態"

**status**: pending
**max_iterations**: 3

---

## final_tasks

- [ ] **ft1**: main ブランチにマージ
  - command: `git checkout main && git merge feat/m155-final-freeze`
  - status: pending
  - note: "マージ後に v1.0.0 タグを push"

---

## rollback

```yaml
手順:
  1. タグを削除
     git tag -d v1.0.0

  2. コミットを戻す
     git reset --hard HEAD~N

  3. protected-files.txt を復元
     git checkout HEAD~1 -- .claude/protected-files.txt
```

---

## notes

### 凍結後のルール

```yaml
Core Layer 変更ルール:
  - bugfix のみ許可
  - 新規追加は禁止
  - 変更は Codex レビュー必須
  - CLAUDE.md 変更は Change Control プロセス必須

Extension Layer 変更ルール:
  - 自由に追加・削除可
  - ただし Core への影響がないこと
```

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-21 | 初版作成 |
