# playbook-m122-auto-update-essential-docs.md

> **M122 残課題: essential-documents.md 自動更新機構**

---

## meta

```yaml
schema_version: v2
project: thanks4claudecode
branch: feat/m122-auto-update-essential-docs
created: 2025-12-21
issue: null
derives_from: M122
reviewed: true  # reviewer PASS 2025-12-21

user_prompt_original: |
  M122 の残課題として「essential-documents.md の自動更新機構」を実装する playbook を作成してください。

  ## 背景
  - M122 で全87ファイルを精査し、essential-documents.md を作成済み
  - project.md の done_when に「essential-documents.md が自動更新される仕組みが構築されている」がある
  - これが未実装のため M122 を完遂できない

  ## 要件
  1. scripts/generate-essential-docs.sh を作成
     - core-manifest.yaml からコンポーネント情報を抽出
     - state.md から FREEZE_QUEUE を抽出
     - docs/essential-documents.md を生成

  2. session-start.sh に統合
     - core-manifest.yaml の更新を検出
     - 更新があれば自動再生成

  3. 動作確認
     - スクリプト実行で essential-documents.md が正しく生成される

  ## 制約
  - branch: feat/m122-auto-update-essential-docs
  - derives_from: M122
  - シンプルな実装を優先（過度な複雑化を避ける）
```

---

## goal

```yaml
summary: essential-documents.md を自動生成・更新する仕組みを構築
done_when:
  - scripts/generate-essential-docs.sh が存在し実行可能
  - generate-essential-docs.sh が core-manifest.yaml と state.md から essential-documents.md を正しく生成する
  - session-start.sh に core-manifest.yaml 更新検出ロジックが統合されている
  - スクリプト実行で docs/essential-documents.md が更新される
```

---

## phases

### p1: generate-essential-docs.sh 作成

**goal**: core-manifest.yaml と state.md から essential-documents.md を生成するスクリプトを作成

#### subtasks

- [x] **p1.1**: scripts/generate-essential-docs.sh が存在し実行可能である
  - executor: claudecode
  - test_command: `test -x scripts/generate-essential-docs.sh && echo PASS || echo FAIL`
  - validations:
    - technical: "スクリプトが存在し実行権限がある"
    - consistency: "他の scripts/*.sh と同じ形式"
    - completeness: "ファイルが存在する"

- [x] **p1.2**: generate-essential-docs.sh が bash -n で構文エラーなしである
  - executor: claudecode
  - test_command: `bash -n scripts/generate-essential-docs.sh && echo PASS || echo FAIL`
  - validations:
    - technical: "構文エラーがない"
    - consistency: "シェルスクリプトとして正しい"
    - completeness: "全行がパース可能"

- [x] **p1.3**: generate-essential-docs.sh が core-manifest.yaml からコンポーネント情報を抽出している
  - executor: claudecode
  - test_command: `grep -q 'core-manifest.yaml' scripts/generate-essential-docs.sh && echo PASS || echo FAIL`
  - validations:
    - technical: "core-manifest.yaml を参照している"
    - consistency: "正しいパスを使用"
    - completeness: "必要なセクションを抽出"

- [x] **p1.4**: generate-essential-docs.sh が state.md から FREEZE_QUEUE を抽出している
  - executor: claudecode
  - test_command: `grep -q 'FREEZE_QUEUE' scripts/generate-essential-docs.sh && echo PASS || echo FAIL`
  - validations:
    - technical: "state.md の FREEZE_QUEUE を参照"
    - consistency: "正しい形式で抽出"
    - completeness: "必要な情報を抽出"

**status**: done
**max_iterations**: 5

---

### p2: スクリプト動作確認

**goal**: 生成スクリプトが正しく essential-documents.md を生成することを確認

**depends_on**: [p1]

#### subtasks

- [x] **p2.1**: generate-essential-docs.sh を実行すると docs/essential-documents.md が更新される
  - executor: claudecode
  - test_command: `bash scripts/generate-essential-docs.sh && test -f docs/essential-documents.md && echo PASS || echo FAIL`
  - validations:
    - technical: "スクリプトが正常終了し、ファイルが生成される"
    - consistency: "既存の essential-documents.md の形式を維持"
    - completeness: "必要なセクションが全て含まれる"

- [x] **p2.2**: 生成された essential-documents.md に Core Layer コンポーネントが含まれている
  - executor: claudecode
  - test_command: `grep -q 'Core Layer' docs/essential-documents.md && grep -q 'prompt-guard' docs/essential-documents.md && echo PASS || echo FAIL`
  - validations:
    - technical: "Core Layer セクションが存在"
    - consistency: "core-manifest.yaml と整合"
    - completeness: "計画動線・検証動線のコンポーネントが含まれる"

- [x] **p2.3**: 生成された essential-documents.md に FREEZE_QUEUE 情報が含まれている
  - executor: claudecode
  - test_command: `grep -q 'FREEZE_QUEUE' docs/essential-documents.md && echo PASS || echo FAIL`
  - validations:
    - technical: "FREEZE_QUEUE セクションが存在"
    - consistency: "state.md と整合"
    - completeness: "非推奨ドキュメントが列挙されている"

**status**: done
**max_iterations**: 5

---

### p3: session-start.sh 統合

**goal**: session-start.sh に core-manifest.yaml 更新検出と自動再生成を統合

**depends_on**: [p2]

#### subtasks

- [x] **p3.1**: session-start.sh に core-manifest.yaml 更新検出ロジックが追加されている
  - executor: claudecode
  - test_command: `grep -q 'core-manifest.yaml' .claude/hooks/session-start.sh && echo PASS || echo FAIL`
  - validations:
    - technical: "更新検出ロジックが存在"
    - consistency: "既存の session-start.sh 構造と整合"
    - completeness: "更新時に自動再生成を呼び出す"

- [x] **p3.2**: session-start.sh の修正が bash -n で構文エラーなしである
  - executor: claudecode
  - test_command: `bash -n .claude/hooks/session-start.sh && echo PASS || echo FAIL`
  - validations:
    - technical: "構文エラーがない"
    - consistency: "既存機能に影響なし"
    - completeness: "全行がパース可能"

**status**: done
**max_iterations**: 3

---

### p_final: 完了検証

**goal**: M122 の done_when「essential-documents.md が自動更新される仕組みが構築されている」を検証

**depends_on**: [p3]

#### subtasks

- [x] **p_final.1**: scripts/generate-essential-docs.sh が存在し実行可能である
  - executor: claudecode
  - test_command: `test -x scripts/generate-essential-docs.sh && echo PASS || echo FAIL`
  - validations:
    - technical: "スクリプトが存在し実行権限がある"
    - consistency: "scripts/ ディレクトリに配置されている"
    - completeness: "生成機能が完備"

- [x] **p_final.2**: スクリプト実行で essential-documents.md が正しい形式で生成される
  - executor: claudecode
  - test_command: `bash scripts/generate-essential-docs.sh && grep -q '計画動線' docs/essential-documents.md && grep -q 'FREEZE_QUEUE' docs/essential-documents.md && echo PASS || echo FAIL`
  - validations:
    - technical: "スクリプトが正常動作"
    - consistency: "動線単位の形式が維持されている"
    - completeness: "全必須セクションが含まれる"

- [x] **p_final.3**: session-start.sh で更新検出機能が動作する
  - executor: claudecode
  - test_command: `grep -q 'generate-essential-docs' .claude/hooks/session-start.sh && echo PASS || echo FAIL`
  - validations:
    - technical: "PASS - 更新検出と自動再生成の連携"
    - consistency: "PASS - session-start.sh の既存機能と共存"
    - completeness: "PASS - 自動更新機構が構築されている"
  - validated: 2025-12-21T12:01:00

**status**: done
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

```yaml
設計方針:
  - シンプルな実装を優先
  - 既存の essential-documents.md の形式を維持
  - core-manifest.yaml v3 の動線単位構造を反映
  - session-start.sh への統合は最小限の変更で

参照ファイル:
  - governance/core-manifest.yaml（コンポーネント情報源）
  - state.md（FREEZE_QUEUE 情報源）
  - docs/essential-documents.md（生成対象）
  - .claude/hooks/session-start.sh（統合先）
```

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-21 | 初版作成（pm による自動生成） |
