# playbook-m097-anti-lie-system.md

> **「嘘が生まれない仕組み」を構築する**

---

## meta

```yaml
schema_version: v2
project: thanks4claudecode
branch: feat/m097-anti-lie-system
created: 2025-12-20
issue: null
derives_from: M097
reviewed: false
roles:
  worker: claudecode
```

---

## goal

```yaml
summary: README と実態の乖離を構造的に防止する「嘘が生まれない仕組み」を構築
done_when:
  - scripts/generate-readme-stats.sh が存在し実行可能
  - README.md の数値部分が <!-- STATS --> タグで囲まれ、スクリプトで更新可能
  - .claude/component-tiers.yaml に Core/Optional/Experimental 分類が存在
  - docs/completion-criteria.md に 5 つのシナリオが定義されている
```

---

## phases

### p1: README 自動生成システム

**goal**: README の数値を自動集計するスクリプトを作成し、手動更新の嘘を排除する

#### subtasks

- [ ] **p1.1**: scripts/generate-readme-stats.sh が存在する
  - executor: claudecode
  - test_command: `test -f scripts/generate-readme-stats.sh && echo PASS || echo FAIL`
  - validations:
    - technical: "スクリプトが bash -n でエラーなし"
    - consistency: "既存スクリプトと命名規則が一致"
    - completeness: "実行権限が付与されている"

- [ ] **p1.2**: generate-readme-stats.sh が Hook 数を正しく集計する
  - executor: claudecode
  - test_command: `bash scripts/generate-readme-stats.sh | grep -q 'hooks:' && echo PASS || echo FAIL`
  - validations:
    - technical: "実際の Hook 数と一致"
    - consistency: "state.md の COMPONENT_REGISTRY と同期"
    - completeness: "SubAgent/Skill/Command も集計"

- [ ] **p1.3**: generate-readme-stats.sh が Milestone 数を正しく集計する
  - executor: claudecode
  - test_command: `bash scripts/generate-readme-stats.sh | grep -q 'milestones:' && echo PASS || echo FAIL`
  - validations:
    - technical: "project.md の achieved milestone 数と一致"
    - consistency: "M001-M0XX の形式を正しくカウント"
    - completeness: "achieved と pending を区別"

- [ ] **p1.4**: README.md に <!-- STATS --> タグが挿入されている
  - executor: claudecode
  - test_command: `grep -q '<!-- STATS -->' README.md && echo PASS || echo FAIL`
  - validations:
    - technical: "開始・終了タグが正しく配置"
    - consistency: "既存の README 構造を壊さない"
    - completeness: "Hook/SubAgent/Skill/Milestone 全てがタグ内"

- [ ] **p1.5**: generate-readme-stats.sh --update が README.md を更新する
  - executor: claudecode
  - test_command: `bash scripts/generate-readme-stats.sh --update && echo PASS || echo FAIL`
  - validations:
    - technical: "更新後も README が valid な Markdown"
    - consistency: "STATS タグ外のコンテンツは変更されない"
    - completeness: "全ての数値が最新に更新"

**status**: pending
**max_iterations**: 5

---

### p2: コンポーネント三軍分け

**goal**: Hook/SubAgent/Skill を Core/Optional/Experimental に分類し、積み上げ正義を排除する

**depends_on**: [p1]

#### subtasks

- [ ] **p2.1**: .claude/component-tiers.yaml が存在する
  - executor: claudecode
  - test_command: `test -f .claude/component-tiers.yaml && echo PASS || echo FAIL`
  - validations:
    - technical: "YAML として valid"
    - consistency: "他の YAML ファイルと書式が一致"
    - completeness: "Core/Optional/Experimental セクションが存在"

- [ ] **p2.2**: component-tiers.yaml に Core コンポーネントが定義されている
  - executor: claudecode
  - test_command: `grep -q 'core:' .claude/component-tiers.yaml && echo PASS || echo FAIL`
  - validations:
    - technical: "必須機能のみが Core に分類"
    - consistency: "黄金動線に必要なコンポーネントが含まれる"
    - completeness: "各コンポーネントに理由が明記"

- [ ] **p2.3**: component-tiers.yaml に Optional コンポーネントが定義されている
  - executor: claudecode
  - test_command: `grep -q 'optional:' .claude/component-tiers.yaml && echo PASS || echo FAIL`
  - validations:
    - technical: "便利だが必須ではない機能が分類"
    - consistency: "Core と重複がない"
    - completeness: "各コンポーネントに理由が明記"

- [ ] **p2.4**: component-tiers.yaml に Experimental コンポーネントが定義されている
  - executor: claudecode
  - test_command: `grep -q 'experimental:' .claude/component-tiers.yaml && echo PASS || echo FAIL`
  - validations:
    - technical: "試験的機能が分類"
    - consistency: "Core/Optional と重複がない"
    - completeness: "各コンポーネントに廃止候補の理由が明記"

- [ ] **p2.5**: README.md にコンポーネント分類が反映されている
  - executor: claudecode
  - test_command: `grep -qE 'Core|Optional|Experimental' README.md && echo PASS || echo FAIL`
  - validations:
    - technical: "分類の説明が明確"
    - consistency: "component-tiers.yaml と一致"
    - completeness: "各カテゴリの意味が説明されている"

**status**: pending
**max_iterations**: 5

---

### p3: 完成の定義

**goal**: 「完成」を5つのシナリオで明文化し、数字だけの成果から脱却する

**depends_on**: [p2]

#### subtasks

- [ ] **p3.1**: docs/completion-criteria.md が存在する
  - executor: claudecode
  - test_command: `test -f docs/completion-criteria.md && echo PASS || echo FAIL`
  - validations:
    - technical: "Markdown として valid"
    - consistency: "docs/ の他のドキュメントと形式が一致"
    - completeness: "目的セクションが存在"

- [ ] **p3.2**: シナリオ1「黄金動線」が定義されている
  - executor: claudecode
  - test_command: `grep -q '黄金動線' docs/completion-criteria.md && echo PASS || echo FAIL`
  - validations:
    - technical: "依頼→playbook→作業→検証→アーカイブの流れが明記"
    - consistency: "CLAUDE.md の Golden Path と一致"
    - completeness: "テスト方法が明記"

- [ ] **p3.3**: シナリオ2「メンテ作業デッドロック防止」が定義されている
  - executor: claudecode
  - test_command: `grep -q 'デッドロック' docs/completion-criteria.md && echo PASS || echo FAIL`
  - validations:
    - technical: "playbook=null でもメンテが可能な条件が明記"
    - consistency: "M096 の修正内容と整合"
    - completeness: "テスト方法が明記"

- [ ] **p3.4**: シナリオ3「HARD_BLOCK 保護」が定義されている
  - executor: claudecode
  - test_command: `grep -q 'HARD_BLOCK' docs/completion-criteria.md && echo PASS || echo FAIL`
  - validations:
    - technical: "保護対象ファイルと復旧手順が明記"
    - consistency: "protected-files.txt と一致"
    - completeness: "テスト方法が明記"

- [ ] **p3.5**: シナリオ4「報酬詐欺防止」が定義されている
  - executor: claudecode
  - test_command: `grep -q '報酬詐欺' docs/completion-criteria.md && echo PASS || echo FAIL`
  - validations:
    - technical: "詐欺の抜け道と対策が明記"
    - consistency: "critic/pm SubAgent の設計と一致"
    - completeness: "テスト方法が明記"

- [ ] **p3.6**: シナリオ5「README/実装/テスト一致」が定義されている
  - executor: claudecode
  - test_command: `grep -q 'README.*実装.*テスト' docs/completion-criteria.md && echo PASS || echo FAIL`
  - validations:
    - technical: "乖離検出方法が明記"
    - consistency: "generate-readme-stats.sh と連携"
    - completeness: "テスト方法が明記"

**status**: pending
**max_iterations**: 5

---

### p_final: 完了検証

**goal**: done_when の全項目を検証

**depends_on**: [p3]

#### subtasks

- [ ] **p_final.1**: scripts/generate-readme-stats.sh が存在し実行可能
  - executor: claudecode
  - test_command: `test -x scripts/generate-readme-stats.sh && bash -n scripts/generate-readme-stats.sh && echo PASS || echo FAIL`
  - validations:
    - technical: "スクリプトが正常に実行できる"
    - consistency: "他のスクリプトと命名規則が一致"
    - completeness: "実行権限が付与されている"

- [ ] **p_final.2**: README.md の数値部分が STATS タグで囲まれている
  - executor: claudecode
  - test_command: `grep -c '<!-- STATS -->' README.md | awk '{if($1>=2) print "PASS"; else print "FAIL"}'`
  - validations:
    - technical: "開始・終了タグが両方存在"
    - consistency: "タグ形式が HTML コメントとして valid"
    - completeness: "Hook/SubAgent/Skill/Milestone の数値がタグ内"

- [ ] **p_final.3**: component-tiers.yaml に 3 分類が存在
  - executor: claudecode
  - test_command: `grep -cE '^(core|optional|experimental):' .claude/component-tiers.yaml | awk '{if($1>=3) print "PASS"; else print "FAIL"}'`
  - validations:
    - technical: "YAML として valid"
    - consistency: "全コンポーネントがいずれかに分類"
    - completeness: "分類理由が明記"

- [ ] **p_final.4**: completion-criteria.md に 5 シナリオが存在
  - executor: claudecode
  - test_command: `grep -c '## シナリオ' docs/completion-criteria.md | awk '{if($1>=5) print "PASS"; else print "FAIL"}'`
  - validations:
    - technical: "Markdown として valid"
    - consistency: "各シナリオにテスト方法が明記"
    - completeness: "5 シナリオ全てが定義"

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

---

## notes

### 背景
外部 LLM から以下の指摘を受けた:
1. README と実態がズレている（Hook 数、Milestone 数など）
2. 「数字で成果を語る」構造が自己欺瞞を生む
3. Hook/SubAgent/Skill が「積み上げ＝正義」になっている
4. テストが grep ベースの存在確認で、本当の保証になっていない

### 設計方針
- **自動生成**: 手動で更新する数値は嘘の温床。自動生成で排除
- **三軍分け**: 全部同列ではなく、重要度で分類
- **シナリオベース**: 数字ではなく「動くシナリオ」で完成を定義
