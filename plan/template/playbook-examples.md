# playbook-sample.md

> **playbook の具体的な記述例。**
>
> 3タイプ（web_app, natural_language, automation）の例を提供。

---

# 例1: web_app（TODO アプリ）

## meta

```yaml
project: todo-app
created: 2025-12-01
```

## goal

```yaml
summary: シンプルな TODO アプリを Next.js で構築し、Vercel にデプロイする
done_when:
  - TODO の追加・削除・完了切り替えができる
  - Vercel の URL でアプリにアクセスできる
  - ローカルストレージにデータが永続化される
```

## phases

```yaml
- id: p1
  name: 環境構築
  goal: Next.js プロジェクトを作成し、ローカルで動作確認する
  executor: codex
  done_criteria:
    - "npx create-next-app が成功する"
    - "npm run dev で http://localhost:3000 が表示される"
    - "README.md にプロジェクト概要が記載されている"
  status: pending

- id: p2
  name: UI 実装
  goal: TODO リストの UI コンポーネントを作成する
  executor: codex
  depends_on: [p1]
  done_criteria:
    - "TodoList コンポーネントが存在する"
    - "TodoItem コンポーネントが存在する"
    - "AddTodo コンポーネントが存在する"
    - "http://localhost:3000 で TODO リストが表示される"
  status: pending

- id: p3
  name: 状態管理
  goal: TODO の追加・削除・完了切り替えを実装する
  executor: codex
  depends_on: [p2]
  done_criteria:
    - "TODO を追加できる（入力 → ボタン → リストに追加）"
    - "TODO を削除できる（削除ボタン → リストから消える）"
    - "TODO の完了状態を切り替えられる（チェック → 取り消し線）"
  status: pending

- id: p4
  name: データ永続化
  goal: ローカルストレージに TODO を保存する
  executor: codex
  depends_on: [p3]
  done_criteria:
    - "ページリロード後も TODO が残っている"
    - "localStorage に todos キーでデータが保存されている"
  status: pending

- id: p5
  name: Vercel 登録
  goal: Vercel アカウントを作成し、GitHub 連携を設定する
  executor: user
  depends_on: [p1]
  done_criteria:
    - "Vercel アカウントが作成されている"
    - "GitHub リポジトリと Vercel が連携されている"
  notes: "ユーザーが Vercel ダッシュボードで実行"
  status: pending

- id: p6
  name: デプロイ
  goal: Vercel に本番デプロイする
  executor: codex
  depends_on: [p4, p5]
  done_criteria:
    - "git push で Vercel デプロイがトリガーされる"
    - "https://{project}.vercel.app でアプリにアクセスできる"
    - "全機能が本番環境で動作する"
  status: pending
```

---

# 例2: natural_language（小説執筆）

## meta

```yaml
project: mystery-novel
created: 2025-12-01
```

## goal

```yaml
summary: 5万字のミステリー短編小説を執筆する
done_when:
  - 全10章が完成している
  - 伏線が全て回収されている
  - 推敲・校正が完了している
```

## phases

```yaml
- id: p1
  name: プロット作成
  goal: 物語の骨格を設計する
  executor: codex
  done_criteria:
    - "登場人物リスト（5名以上）が作成されている"
    - "トリックの概要が決まっている"
    - "章立て（10章）のアウトラインがある"
    - "伏線リスト（5つ以上）が作成されている"
  status: pending

- id: p2
  name: キャラクター設計
  goal: 登場人物の詳細を決める
  executor: codex
  depends_on: [p1]
  done_criteria:
    - "各キャラクターのプロフィールが作成されている"
    - "動機・秘密が設定されている"
    - "キャラクター同士の関係図がある"
  status: pending

- id: p3
  name: 世界観レビュー
  goal: ユーザーがプロット・キャラクターを確認する
  executor: user
  depends_on: [p2]
  done_criteria:
    - "ユーザーがプロットを承認している"
    - "キャラクター設定に問題がない"
  notes: "ユーザーがレビューし、修正点をフィードバック"
  status: pending

- id: p4
  name: 第1章〜第3章執筆
  goal: 導入部を執筆する
  executor: codex
  depends_on: [p3]
  done_criteria:
    - "第1章（事件発生前）が完成している"
    - "第2章（事件発生）が完成している"
    - "第3章（捜査開始）が完成している"
    - "各章が3000〜5000字である"
  status: pending

- id: p5
  name: 第4章〜第7章執筆
  goal: 中盤を執筆する
  executor: codex
  depends_on: [p4]
  done_criteria:
    - "第4章〜第7章が完成している"
    - "伏線が適切に配置されている"
    - "各章が3000〜5000字である"
  status: pending

- id: p6
  name: 第8章〜第10章執筆
  goal: クライマックス〜結末を執筆する
  executor: codex
  depends_on: [p5]
  done_criteria:
    - "第8章（推理披露）が完成している"
    - "第9章（真相解明）が完成している"
    - "第10章（エピローグ）が完成している"
    - "全ての伏線が回収されている"
  status: pending

- id: p7
  name: 推敲・校正
  goal: 文章品質を向上させる
  executor: codex
  depends_on: [p6]
  done_criteria:
    - "誤字脱字がない"
    - "文体が統一されている"
    - "矛盾がない"
    - "総文字数が45000〜55000字である"
  status: pending

- id: p8
  name: 最終レビュー
  goal: ユーザーが完成原稿を確認する
  executor: user
  depends_on: [p7]
  done_criteria:
    - "ユーザーが原稿を承認している"
    - "修正依頼がない、または全て対応済み"
  status: pending
```

---

# 例3: automation（Slack 通知 Bot）

## meta

```yaml
project: slack-notify-bot
created: 2025-12-01
```

## goal

```yaml
summary: GitHub の PR イベントを Slack に通知する Bot を作成する
done_when:
  - PR 作成時に Slack に通知される
  - PR マージ時に Slack に通知される
  - 本番環境で稼働している
```

## phases

```yaml
- id: p1
  name: 要件定義
  goal: 入力/出力/処理を明確にする
  executor: codex
  done_criteria:
    - "入力: GitHub Webhook イベント（PR created, merged）"
    - "出力: Slack メッセージ（チャンネル、フォーマット）"
    - "処理: イベント判定 → メッセージ生成 → Slack 送信"
  status: pending

- id: p2
  name: Slack App 作成
  goal: Slack App を作成し、Webhook URL を取得する
  executor: user
  done_criteria:
    - "Slack App が作成されている"
    - "Incoming Webhook が有効化されている"
    - "Webhook URL が取得されている"
  notes: "ユーザーが Slack API サイトで実行"
  status: pending

- id: p3
  name: GitHub Webhook 設定
  goal: リポジトリに Webhook を設定する
  executor: user
  depends_on: [p1]
  done_criteria:
    - "GitHub リポジトリに Webhook が設定されている"
    - "PR イベントがトリガーとして選択されている"
    - "Webhook URL（Bot エンドポイント）が設定されている"
  notes: "ユーザーが GitHub リポジトリ設定で実行"
  status: pending

- id: p4
  name: Bot 実装
  goal: Webhook を受け取り Slack に通知する処理を実装する
  executor: codex
  depends_on: [p1, p2]
  done_criteria:
    - "HTTP サーバーが起動する"
    - "/webhook エンドポイントが存在する"
    - "PR created イベントを処理できる"
    - "PR merged イベントを処理できる"
    - "Slack メッセージが送信される"
  status: pending

- id: p5
  name: ローカルテスト
  goal: ローカル環境で動作確認する
  executor: codex
  depends_on: [p4]
  done_criteria:
    - "curl でテストイベントを送信できる"
    - "Slack にテストメッセージが届く"
    - "エラーハンドリングが機能する"
  status: pending

- id: p6
  name: デプロイ
  goal: 本番環境にデプロイする
  executor: codex
  depends_on: [p3, p5]
  done_criteria:
    - "サーバーが公開 URL でアクセス可能"
    - "GitHub Webhook が本番 URL を指している"
    - "実際の PR で通知が届く"
  status: pending
```

---

## 記述のポイント

### 1. executor を明確に

```yaml
# ユーザーが実行すべきタスク
- id: p2
  name: Slack App 作成
  executor: user  # ← 外部サービス登録は user
  notes: "ユーザーが Slack API サイトで実行"
```

### 2. 依存関係を正確に

```yaml
# p6 は p3 と p5 の両方が完了しないと開始できない
- id: p6
  depends_on: [p3, p5]  # ← 複数依存を明記
```

### 3. タイプごとの特徴

| タイプ | 特徴 |
|--------|------|
| web_app | 環境構築 → 実装 → デプロイの流れ。外部サービス登録は user。 |
| natural_language | 設計 → 執筆 → 推敲の流れ。ユーザーレビューを挟む。 |
| automation | 要件定義 → 実装 → テストの流れ。外部 API 設定は user。 |

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-01 | V2: natural_language, automation の例を追加。 |
| 2025-12-01 | V1: web_app（TODO アプリ）の例。 |
