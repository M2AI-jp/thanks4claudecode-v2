# 計画の仕組み（物語編）

> **新人が入社してからプロダクトを作れるようになるまでの物語**

---

## プロローグ: 新人の入社

ある日、新しい開発者がこの会社（リポジトリ）をフォークしてきた。

新人: 「ここで働きたいです！」

受付（session-start.sh）: 「ようこそ！まず **3F の setup フロア** に行ってください」

---

## 第1部: setup（環境構築）

### 第1章: 3F に到着

新人が 3F に着くと、**セットアップガイド**が出迎えた。

セットアップガイド: 「初めまして！環境構築を手伝いますね」

新人は `state.md` を見る。

```yaml
focus:
  current: setup
  session: task
```

セットアップガイド: 「まず Phase 0 から始めましょう。あなたは初心者ですか？経験者ですか？」

---

### 第2章: 8つの Phase

セットアップガイドは `setup/playbook-setup.md` を見せる。

```
Phase 0: ルート選択（Tutorial or Production）
Phase 1: Homebrew インストール
Phase 2: Git 設定
Phase 3: Node.js インストール
Phase 4: pnpm インストール
Phase 5: Claude Code インストール
Phase 6: リポジトリ設定
Phase 7: MCP サーバー接続
Phase 8: project.md 生成 ← ここで Macro 計画が生まれる
```

新人: 「8つもあるんですね」

セットアップガイド: 「大丈夫。1つずつ進めれば終わります」

---

### 第3章: Phase 8 - 社長就任

Phase 7 まで完了した新人。

セットアップガイド: 「最後の Phase です。あなたの **project.md** を作りましょう」

新人: 「project.md って何ですか？」

セットアップガイド: 「この会社での **あなたの目標** です。社長になって、何を作るか宣言してください」

新人は考えて、project.md を書く。

```yaml
vision:
  summary: ブログアプリを作る
  goal: 個人ブログを Next.js で構築する

done_when:
  - 記事一覧ページがある
  - 記事詳細ページがある
  - Markdown で書ける
  - Vercel にデプロイされている
```

セットアップガイド: 「素晴らしい！これであなたは **社長** です。4F の product フロアに行きましょう」

```yaml
focus:
  current: product  # setup → product に移行
```

---

## 第2部: product（プロダクト開発）

### 第4章: 4F に到着

新人（今は社長）が 4F に着いた。

スターター: 「おはようございます、社長！今日の予定を確認しますね」

スターターは project.md を見る。

スターター: 「Macro 計画は『ブログアプリを作る』ですね。でも playbook がありません」

---

### 第5章: 部長の誕生

スターター: 「**ピーエム**を呼びましょう」

ピーエム: 「はい、呼びました？playbook を作りますね」

ピーエムは社長（project.md）に確認する。

ピーエム: 「done_when の最初の項目は何ですか？」

社長: 「記事一覧ページがある、です」

ピーエム: 「では、最初の playbook はこれですね」

```yaml
# playbook-article-list.md
goal:
  summary: 記事一覧ページを作る
  done_when:
    - /articles で記事一覧が表示される

phases:
  - id: p1
    name: 設計
    executor: claudecode
  - id: p2
    name: 実装
    executor: codex
  - id: p3
    name: テスト
    executor: claudecode
```

ピーエムは **部長** になった。

---

### 第6章: 担当者の作業

部長（playbook）の下で、担当者（Claude）が働く。

担当者: 「Phase 1 の設計から始めます」

**executor: claudecode** なので、Claude Code が直接作業する。

---

Phase 2 になると...

担当者: 「実装は **executor: codex** です。Codex さんに頼みます」

Codex: 「了解。コードを書きます」

---

### 第7章: クリティックの審査

Phase 3 が終わり、担当者が「完了しました」と報告。

**クリティック**が現れる。

クリティック: 「証拠を見せてもらおうか」

- /articles にアクセスして記事一覧が表示される？ → 「curl で確認させて」
- テストは通った？ → 「実行結果を見せて」

クリティック: 「**PASS**。playbook 完了だ」

---

### 第8章: 社長への報告

部長（playbook）が完了した。

社長（project.md）がチェックする。

```yaml
done_when:
  - 記事一覧ページがある ✅  # 今完了
  - 記事詳細ページがある      # 次
  - Markdown で書ける
  - Vercel にデプロイされている
```

社長: 「まだ 3つ残っている。次の部長を任命しよう」

ピーエム: 「次は playbook-article-detail.md を作りますね」

**PDCA が回り始めた。**

---

## 3層計画のまとめ

| 役職 | ファイル | スコープ | 寿命 |
|------|----------|----------|------|
| 社長（Macro） | project.md | プロダクト全体 | プロジェクト完了まで |
| 部長（Medium） | playbook | 1機能 | 機能完了まで |
| 担当者（Micro） | Phase | 1セッション | Phase 完了まで |

---

## 4つのフロア

```
4F: product    ← 社長として働く場所（今ここ）
3F: setup      ← 新人研修のフロア（完了）
2F: workspace  ← 仕組み改善のフロア（管理者用）
1F: plan-template ← テンプレート管理（管理者用）
```

新人は 3F → 4F と昇格した。
2F と 1F は、この会社の仕組み自体を改善したい人が使う。

---

## 状態遷移: 1日の流れ

```
pending → designing → implementing → reviewing → state_update → done
  ↑                                                              |
  └──────────────────── 次の Phase ──────────────────────────────┘
```

**近道禁止:**
- pending → implementing（設計をスキップ）
- implementing → done（レビューをスキップ）

---

## 4つの歯車

```
focus.current ←→ layer.state
      ↑              ↓
   branch    ←→  playbook
```

これらは連動している。1つがズレると噛み合わない。

例:
- focus: product なのに playbook が workspace のものを指している → エラー
- branch: feat/article-list なのに playbook が別の機能 → エラー

**チェッカー**が常に監視している。

---

## エピローグ: 卒業

全ての done_when を満たした日。

社長（project.md）: 「done_when が全て ✅ になった」

```yaml
done_when:
  - 記事一覧ページがある ✅
  - 記事詳細ページがある ✅
  - Markdown で書ける ✅
  - Vercel にデプロイされている ✅
```

クリティック: 「最終確認。全て証拠付きで PASS」

社長: 「プロジェクト完了！」

🎉 **The End** 🎉

---

## 次の物語へ

新しいプロダクトを作りたくなったら...

1. 新しいリポジトリを作る
2. state.md を初期化（`focus.current: setup`）
3. また 3F から始める

または、このリポジトリで新しい project.md を書く。

物語は続く。
