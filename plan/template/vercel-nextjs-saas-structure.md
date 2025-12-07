# Vercel + Next.js SaaS テンプレート構造

> **お手本**: [next-saas-stripe-starter](https://github.com/mickasmt/next-saas-stripe-starter)
> **スター数**: 2.9k（2024年時点）

---

## 1. ディレクトリ構造

```
project-root/
├── .husky/              # Git hooks（コミットメッセージ検証等）
├── actions/             # Server Actions（データ変更操作）
├── app/                 # Next.js App Router（ページ・ルーティング）
├── assets/              # ソースアセット（SVG等、ビルド時処理）
├── components/          # React コンポーネント
├── config/              # アプリケーション設定
├── content/             # Contentlayer コンテンツ（MDX等）
├── emails/              # React Email テンプレート
├── hooks/               # カスタム React フック
├── lib/                 # ユーティリティ関数
├── prisma/              # Prisma スキーマ・マイグレーション
├── public/              # 公開静的アセット
├── styles/              # グローバルスタイル
├── types/               # TypeScript 型定義
│
├── auth.ts              # 認証設定（Auth.js）
├── auth.config.ts       # 認証プロバイダ設定
├── middleware.ts        # Next.js ミドルウェア
├── env.mjs              # 環境変数検証（Zod）
└── [設定ファイル群]      # eslint, prettier, tailwind, tsconfig 等
```

---

## 2. 各ディレクトリの役割

### 2.1 コア（Next.js 規約）

| ディレクトリ | 役割 | なぜここに置くか |
|-------------|------|-----------------|
| `app/` | ページ、レイアウト、API Routes | Next.js App Router の規約。ファイルベースルーティング |
| `public/` | 静的アセット（画像、favicon） | Next.js の規約。`/` から直接アクセス可能 |
| `middleware.ts` | リクエスト前処理 | Next.js の規約。認証チェック、リダイレクト等 |

### 2.2 ビジネスロジック

| ディレクトリ | 役割 | なぜここに置くか |
|-------------|------|-----------------|
| `actions/` | Server Actions | データ変更操作を分離。`app/` 内に書くと肥大化 |
| `lib/` | ユーティリティ | 再利用可能な関数。DB接続、認証ヘルパー等 |
| `hooks/` | カスタムフック | UI ロジックの再利用。状態管理、API呼び出し等 |

### 2.3 UI

| ディレクトリ | 役割 | なぜここに置くか |
|-------------|------|-----------------|
| `components/` | React コンポーネント | 再利用可能なUI部品。Shadcn/ui ベース |
| `styles/` | グローバルスタイル | Tailwind のベース設定、CSS変数 |
| `assets/` | ソースアセット | ビルド時に処理されるSVG等 |

### 2.4 データ

| ディレクトリ | 役割 | なぜここに置くか |
|-------------|------|-----------------|
| `prisma/` | DB スキーマ | ORM の規約。マイグレーション履歴も管理 |
| `types/` | TypeScript 型 | 型定義を集約。共有される型を一元管理 |
| `config/` | アプリ設定 | 環境に依存しない設定値。サイト名、ナビ項目等 |
| `content/` | MDX コンテンツ | ブログ記事、ドキュメント等の静的コンテンツ |

### 2.5 インフラ

| ディレクトリ | 役割 | なぜここに置くか |
|-------------|------|-----------------|
| `emails/` | メールテンプレート | React Email で JSX として作成 |
| `.husky/` | Git hooks | コミット時の自動チェック |

---

## 3. なぜこの構造が「美しい」か

### 3.1 関心の分離（Separation of Concerns）

```
UI層:        components/, hooks/, styles/
ロジック層:   actions/, lib/
データ層:     prisma/, types/
インフラ層:   emails/, config/
```

各層が独立しており、変更の影響範囲が限定される。

### 3.2 予測可能性（Predictability）

```
「〇〇はどこにある？」に即答できる:
  - ページを追加 → app/
  - ボタンを追加 → components/
  - API 呼び出し → lib/ or actions/
  - 型を追加 → types/
```

Next.js の規約に従うことで、誰が見ても同じ場所を期待する。

### 3.3 スケーラビリティ（Scalability）

```
機能追加時の拡張パターン:
  1. 新機能のページ → app/{feature}/page.tsx
  2. 新機能のコンポーネント → components/{feature}/
  3. 新機能の Server Action → actions/{feature}.ts
  4. 新機能の型 → types/{feature}.ts
```

機能ごとにファイルを追加するだけで、構造は維持される。

### 3.4 再利用性（Reusability）

```
共有可能な単位:
  - components/ui/    → どのページでも使える
  - hooks/           → どのコンポーネントでも使える
  - lib/             → サーバー/クライアント両方で使える
```

---

## 4. 技術スタック

### 4.1 必須（このテンプレートの前提）

| 技術 | 用途 | 理由 |
|------|------|------|
| Next.js 14+ | フレームワーク | App Router、Server Components |
| TypeScript | 型安全 | 大規模開発に必須 |
| Tailwind CSS | スタイリング | ユーティリティファースト |
| Prisma | ORM | TypeScript との親和性 |

### 4.2 推奨（このテンプレートで採用）

| 技術 | 用途 | 代替案 |
|------|------|--------|
| Auth.js v5 | 認証 | Clerk, Supabase Auth |
| Shadcn/ui | UI コンポーネント | Radix UI 直接利用 |
| Neon | PostgreSQL | Supabase, PlanetScale |
| Stripe | 決済 | Paddle, LemonSqueezy |
| Resend | メール | SendGrid, Postmark |
| Vercel | デプロイ | （このテンプレートは Vercel 特化） |

### 4.3 開発ツール

| ツール | 用途 |
|--------|------|
| ESLint | コード品質 |
| Prettier | コードフォーマット |
| Husky | Git hooks |
| Commitlint | コミットメッセージ検証 |

---

## 5. 命名規則

### 5.1 ファイル名

```yaml
コンポーネント: PascalCase
  - UserProfile.tsx
  - DashboardLayout.tsx

ユーティリティ: camelCase
  - formatDate.ts
  - useAuth.ts

設定: kebab-case or camelCase
  - tailwind.config.ts
  - prettier.config.js

ページ: 小文字（Next.js 規約）
  - app/dashboard/page.tsx
  - app/api/webhooks/route.ts
```

### 5.2 ディレクトリ名

```yaml
機能グループ: kebab-case
  - components/user-profile/
  - app/dashboard/settings/

UI カテゴリ: 単数形・小文字
  - components/ui/
  - components/form/
```

### 5.3 変数・関数名

```yaml
関数: camelCase + 動詞始まり
  - getUserById()
  - formatCurrency()
  - handleSubmit()

定数: SCREAMING_SNAKE_CASE
  - MAX_RETRY_COUNT
  - API_BASE_URL

型/インターフェース: PascalCase
  - User
  - DashboardProps
```

---

## 6. 新規プロジェクト作成時のチェックリスト

```yaml
Phase 1: 初期セットアップ
  - [ ] npx create-next-app@latest --typescript --tailwind --eslint
  - [ ] ディレクトリ構造を作成（この STRUCTURE.md 参照）
  - [ ] Shadcn/ui をセットアップ
  - [ ] Prisma をセットアップ

Phase 2: 認証・DB
  - [ ] Auth.js をセットアップ
  - [ ] Neon でデータベース作成
  - [ ] Prisma スキーマ定義

Phase 3: 機能実装
  - [ ] 基本レイアウト作成
  - [ ] 認証フロー実装
  - [ ] ダッシュボード実装

Phase 4: デプロイ
  - [ ] Vercel にデプロイ
  - [ ] 環境変数設定
  - [ ] ドメイン設定
```

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-01 | 初版作成。next-saas-stripe-starter から構造を抽出。 |
