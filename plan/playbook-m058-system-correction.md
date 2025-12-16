# playbook-m058-system-correction.md

> **System Correction: archive-playbook.sh バグ修正 & M057 クリーンアップ & 設計誤りの根本修正**
>
> 以下の3つの重大な問題を同時に解決:
> 1. archive-playbook.sh が state.md 構造の誤りで動作していない
> 2. M057 playbook が plan/ と plan/archive/ の両方に存在（データ不整合）
> 3. 根本的な設計誤り: Claude Code がワーカーのままになっている

---

## meta

```yaml
project: System Correction - Multi-Issue Fix
branch: fix/m058-system-correction
created: 2025-12-17
issue: null
derives_from: M058
reviewed: false
```

---

## goal

```yaml
summary: |
  archive-playbook.sh のバグを修正し、M057 playbook のクリーンアップを完了させ、
  Codex/CodeRabbit がメインワーカーという根本設計に修正する。

done_when:
  - "[ ] archive-playbook.sh が state.md の正しい構造（playbook.active）を参照している"
  - "[ ] plan/playbook-m057-cli-migration.md が削除されている"
  - "[ ] plan/archive/playbook-m057-cli-migration.md のみが存在する"
  - "[ ] state.md の playbook.active が null に更新されている"
  - "[ ] project.md の M057 status が achieved に更新されている"
  - "[ ] project.md の M058 が新規マイルストーンとして追加されている"
  - "[ ] CLAUDE.md の「設計思想」セクションが Codex/CodeRabbit メインワーカーの方針に更新されている"
```

---

## phases

### p1: archive-playbook.sh バグ修正

**goal**: state.md の新しい構造（playbook.active フィールド）を参照するように修正

#### subtasks

- [ ] **p1.1**: archive-playbook.sh が `## playbook` セクション > `active:` フィールドを参照している
  - executor: claudecode
  - test_command: `grep -q 'playbook.*active' /Users/amano/Desktop/thanks4claudecode/.claude/hooks/archive-playbook.sh && echo PASS || echo FAIL`

- [ ] **p1.2**: state.md の古い `## active_playbooks` セクションへの参照が削除されている
  - executor: claudecode
  - test_command: `grep -q 'active_playbooks' /Users/amano/Desktop/thanks4claudecode/.claude/hooks/archive-playbook.sh && echo FAIL || echo PASS`

- [ ] **p1.3**: archive-playbook.sh の構文が正しい
  - executor: claudecode
  - test_command: `bash -n /Users/amano/Desktop/thanks4claudecode/.claude/hooks/archive-playbook.sh && echo PASS || echo FAIL`

### p2: M057 playbook のクリーンアップ

**goal**: plan/ から M057 playbook を削除し、archive 版のみに統一

#### subtasks

- [ ] **p2.1**: plan/playbook-m057-cli-migration.md が削除されている
  - executor: claudecode
  - test_command: `test ! -f /Users/amano/Desktop/thanks4claudecode/plan/playbook-m057-cli-migration.md && echo PASS || echo FAIL`

- [ ] **p2.2**: plan/archive/playbook-m057-cli-migration.md のみが存在する
  - executor: claudecode
  - test_command: `test -f /Users/amano/Desktop/thanks4claudecode/plan/archive/playbook-m057-cli-migration.md && echo PASS || echo FAIL`

### p3: state.md の更新

**goal**: state.md を正しい状態に更新する

#### subtasks

- [ ] **p3.1**: state.md の playbook.active が null に更新されている
  - executor: claudecode
  - test_command: `grep -A 1 '^active:' /Users/amano/Desktop/thanks4claudecode/state.md | grep -q 'null' && echo PASS || echo FAIL`

- [ ] **p3.2**: state.md の goal.milestone が M058 に更新されている
  - executor: claudecode
  - test_command: `grep 'milestone: M058' /Users/amano/Desktop/thanks4claudecode/state.md && echo PASS || echo FAIL`

- [ ] **p3.3**: state.md の goal.phase が p1 に更新されている
  - executor: claudecode
  - test_command: `grep 'phase: p1' /Users/amano/Desktop/thanks4claudecode/state.md && echo PASS || echo FAIL`

### p4: project.md の更新

**goal**: project.md に M058 を追加し、M057 を achieved に更新

#### subtasks

- [ ] **p4.1**: project.md の M057 status が achieved に更新されている
  - executor: claudecode
  - test_command: `grep -A 5 'id: M057' /Users/amano/Desktop/thanks4claudecode/plan/project.md | grep 'status: achieved' && echo PASS || echo FAIL`

- [ ] **p4.2**: project.md の M057 achieved_at タイムスタンプが追加されている
  - executor: claudecode
  - test_command: `grep -A 6 'id: M057' /Users/amano/Desktop/thanks4claudecode/plan/project.md | grep 'achieved_at:' && echo PASS || echo FAIL`

- [ ] **p4.3**: project.md に M058 マイルストーン が新規追加されている
  - executor: claudecode
  - test_command: `grep -q 'id: M058' /Users/amano/Desktop/thanks4claudecode/plan/project.md && echo PASS || echo FAIL`

- [ ] **p4.4**: M058 は M057 に depends_on している
  - executor: claudecode
  - test_command: `grep -A 10 'id: M058' /Users/amano/Desktop/thanks4claudecode/plan/project.md | grep -q 'depends_on:.*M057' && echo PASS || echo FAIL`

### p5: 設計思想の修正（根本的な誤りの修正）

**goal**: CLAUDE.md を更新して Claude Code がオーケストレーター、Codex がメインワーカーという設計に統一

#### subtasks

- [ ] **p5.1**: CLAUDE.md に「設計思想」セクションが追加され、Codex/CodeRabbit が実装ワーカーであることが明記されている
  - executor: claudecode
  - test_command: `grep -q 'Codex.*メインワーカー\\|メインワーカー.*Codex' /Users/amano/Desktop/thanks4claudecode/CLAUDE.md && echo PASS || echo FAIL`

- [ ] **p5.2**: CLAUDE.md の executor 説明（playbook-format.md 参照箇所）が Codex ベースに修正されている
  - executor: claudecode
  - test_command: `grep -A 10 'executor' /Users/amano/Desktop/thanks4claudecode/CLAUDE.md | grep -q 'codex.*本格実装' && echo PASS || echo FAIL`

- [ ] **p5.3**: CLAUDE.md の LOOP セクションで executor が正しく判定されている（Claude Code は設計のみ）
  - executor: claudecode
  - test_command: `grep -A 20 'executor で実行者を判定' /Users/amano/Desktop/thanks4claudecode/CLAUDE.md | grep -q 'claudecode.*設計\\|codex.*実装' && echo PASS || echo FAIL`

### p_final: 完了検証

**goal**: 全ての修正が正しく適用されたことを検証

#### subtasks

- [ ] **pf.1**: archive-playbook.sh が正しく state.md 構造を参照している
  - executor: claudecode
  - test_command: `bash -c 'source /Users/amano/Desktop/thanks4claudecode/.claude/hooks/archive-playbook.sh' 2>&1 | grep -q 'ARCHIVE_DIR' && echo PASS || echo FAIL'`

- [ ] **pf.2**: M057 playbook がアーカイブのみに存在する
  - executor: claudecode
  - test_command: `test ! -f /Users/amano/Desktop/thanks4claudecode/plan/playbook-m057-cli-migration.md && test -f /Users/amano/Desktop/thanks4claudecode/plan/archive/playbook-m057-cli-migration.md && echo PASS || echo FAIL`

- [ ] **pf.3**: state.md が整合性を持っている
  - executor: claudecode
  - test_command: `grep -q 'milestone: M058' /Users/amano/Desktop/thanks4claudecode/state.md && grep -q 'active: null' /Users/amano/Desktop/thanks4claudecode/state.md && echo PASS || echo FAIL`

---

## 詳細説明

### 問題1: archive-playbook.sh のバグ

archive-playbook.sh は以下の誤りがある:
- **行121-128**: `## active_playbooks` セクションを参照しているが、実際の state.md には存在しない
- **正しい構造**: `playbook.active:` フィールド

修正方法:
```bash
# 誤り
ACTIVE_SECTION=$(awk '/^## active_playbooks/,/^## [^a]/' state.md 2>/dev/null || true)

# 修正
PLAYBOOK_ACTIVE=$(grep -A 1 '^active:' state.md | tail -1 | xargs)
```

### 問題2: M057 playbook の重複

状態:
- `/Users/amano/Desktop/thanks4claudecode/plan/playbook-m057-cli-migration.md` ← 削除対象
- `/Users/amano/Desktop/thanks4claudecode/plan/archive/playbook-m057-cli-migration.md` ← 保持

修正方法:
- plan/ 版を削除
- archive/ 版のみを保持
- state.md の active を null に更新

### 問題3: 根本的な設計誤り

現在の誤った構造:
```yaml
Claude Code: コードの実装をしている（ワーカー）
Codex: 補助的（サブワーカー）
CodeRabbit: コードレビュー（補助）
```

本来の設計:
```yaml
Claude Code: オーケストレーター（監督・調整）
Codex: 本格的なコード実装（メインワーカー）
CodeRabbit: コードレビュー（QA ワーカー）
```

修正箇所:
- CLAUDE.md の executor 説明
- playbook-format.md の executor 選択ガイドライン
- .claude/agents/codex-delegate.md の呼び出しロジック

---

## 注意事項

- このタスクは「修正作業」なので、既存の完了した M057 を修正するのではなく、システムレベルの不具合を修正する
- M057 playbook 自体は archive/ で完全に保持される（データ喪失なし）
- CLAUDE.md の修正は思考フレームの修正であり、将来のタスクから適用される

