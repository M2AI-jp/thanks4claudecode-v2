# playbook-e2e-chat-app.md

> **E2E テスト: 美少女 ChatGPT クローン「Waifu Chat」のプロジェクトセットアップ**

---

## meta

```yaml
project: waifu-chat
branch: feat/e2e-chat-app
created: 2025-12-19
issue: null
derives_from: M001  # Waifu Chat プロジェクトセットアップ
reviewed: false
roles:
  worker: codex      # toolstack C: codex がメインワーカー
  reviewer: coderabbit  # toolstack C: coderabbit がレビュー担当
```

---

## goal

```yaml
summary: Waifu Chat プロジェクトの基盤セットアップ（ディレクトリ、設定ファイル、toolstack）
done_when:
  - tmp/waifu-chat/project.md が存在する
  - tmp/waifu-chat/package.json が存在する
  - state.md の toolstack が C に更新されている
```

---

## phases

### p1: toolstack 変更

**goal**: state.md の toolstack を A から C に変更し、roles を更新する

#### subtasks

- [ ] **p1.1**: state.md の toolstack が C に更新されている
  - executor: orchestrator
  - test_command: `grep -q 'toolstack: C' /Users/amano/Desktop/thanks4claudecode-v2/state.md && echo PASS || echo FAIL`
  - validations:
    - technical: "grep コマンドで toolstack: C が検出される"
    - consistency: "roles マッピングが toolstack C に合っている"
    - completeness: "worker: codex, reviewer: coderabbit に更新されている"

- [ ] **p1.2**: state.md の roles が toolstack C 用に更新されている
  - executor: orchestrator
  - test_command: `grep -q 'worker: codex' /Users/amano/Desktop/thanks4claudecode-v2/state.md && grep -q 'reviewer: coderabbit' /Users/amano/Desktop/thanks4claudecode-v2/state.md && echo PASS || echo FAIL`
  - validations:
    - technical: "grep コマンドで worker: codex と reviewer: coderabbit が検出される"
    - consistency: "toolstack C の仕様と一致している"
    - completeness: "全 roles が正しく設定されている"

**status**: pending
**max_iterations**: 3

---

### p2: プロジェクトディレクトリ作成

**goal**: tmp/waifu-chat/ ディレクトリを作成し、基本ファイルを配置する

**depends_on**: [p1]

#### subtasks

- [ ] **p2.1**: tmp/waifu-chat/ ディレクトリが存在する
  - executor: orchestrator
  - test_command: `test -d /Users/amano/Desktop/thanks4claudecode-v2/tmp/waifu-chat && echo PASS || echo FAIL`
  - validations:
    - technical: "ディレクトリが存在する"
    - consistency: "tmp/ フォルダ配下に正しく配置されている"
    - completeness: "必要なサブディレクトリ構造がある"

- [ ] **p2.2**: tmp/waifu-chat/project.md が存在し、マイルストーン定義を含む
  - executor: orchestrator
  - test_command: `test -f /Users/amano/Desktop/thanks4claudecode-v2/tmp/waifu-chat/project.md && grep -q 'M001' /Users/amano/Desktop/thanks4claudecode-v2/tmp/waifu-chat/project.md && echo PASS || echo FAIL`
  - validations:
    - technical: "ファイルが存在し、M001 マイルストーンが含まれている"
    - consistency: "project.md フォーマットに従っている"
    - completeness: "M001-M004 の全マイルストーンが定義されている"

- [ ] **p2.3**: tmp/waifu-chat/package.json が存在し、プロジェクト名が waifu-chat である
  - executor: orchestrator
  - test_command: `test -f /Users/amano/Desktop/thanks4claudecode-v2/tmp/waifu-chat/package.json && grep -q '"name": "waifu-chat"' /Users/amano/Desktop/thanks4claudecode-v2/tmp/waifu-chat/package.json && echo PASS || echo FAIL`
  - validations:
    - technical: "ファイルが存在し、name フィールドが正しい"
    - consistency: "package.json の標準フォーマットに従っている"
    - completeness: "必要な基本フィールドが含まれている"

**status**: pending
**max_iterations**: 5

---

### p_final: 完了検証

**goal**: playbook の done_when が全て満たされているか最終検証

**depends_on**: [p2]

#### subtasks

- [ ] **p_final.1**: tmp/waifu-chat/project.md が存在する
  - executor: orchestrator
  - test_command: `test -f /Users/amano/Desktop/thanks4claudecode-v2/tmp/waifu-chat/project.md && echo PASS || echo FAIL`
  - validations:
    - technical: "ファイルが存在する"
    - consistency: "正しいパスに配置されている"
    - completeness: "内容が完全である"

- [ ] **p_final.2**: tmp/waifu-chat/package.json が存在する
  - executor: orchestrator
  - test_command: `test -f /Users/amano/Desktop/thanks4claudecode-v2/tmp/waifu-chat/package.json && echo PASS || echo FAIL`
  - validations:
    - technical: "ファイルが存在する"
    - consistency: "正しいパスに配置されている"
    - completeness: "内容が完全である"

- [ ] **p_final.3**: state.md の toolstack が C に更新されている
  - executor: orchestrator
  - test_command: `grep -q 'toolstack: C' /Users/amano/Desktop/thanks4claudecode-v2/state.md && echo PASS || echo FAIL`
  - validations:
    - technical: "toolstack が C である"
    - consistency: "roles も toolstack C 用に更新されている"
    - completeness: "全ての config 設定が正しい"

**status**: pending
**max_iterations**: 3

---

## final_tasks

- [ ] **ft1**: repository-map.yaml を更新する
  - command: `bash .claude/hooks/generate-repository-map.sh`
  - status: pending

- [ ] **ft2**: tmp/ 内の一時ファイルを削除する（waifu-chat を除く）
  - command: `find tmp/ -type f ! -name 'README.md' ! -path 'tmp/waifu-chat/*' -delete 2>/dev/null || true`
  - status: pending

- [ ] **ft3**: 変更を全てコミットする
  - command: `git add -A && git status`
  - status: pending

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-19 | 初版作成。E2E テスト用 playbook。 |
