# project-format.md

> **プロジェクトの根幹計画テンプレート。setup 完了時に `plan/project.md` として生成。**

---

## 使い方

1. setup Phase 7 完了後、LLM がこのテンプレートを参照
2. `plan/project.md` として生成（テンプレート自体は編集しない）
3. ユーザーの意図、技術スタック、成功条件を記録
4. 以降の playbook はこの project.md を参照して作成

---

## テンプレート

```yaml
# plan/project.md

> **プロジェクトの根幹計画。setup 完了時に生成。**
> **playbook はこのファイルを参照して作成する。**

## meta

project: {プロジェクト名}
created: {YYYY-MM-DD}
type: {web_app | ai_chat | saas | static_site | simple_tool | automation}
location: projects/{プロジェクト名}/  # setup Phase 5 で作成されたプロジェクトディレクトリ

## vision

### ユーザーの意図

> {ユーザーが最初に言った「作りたいもの」をそのまま自然言語で記録}
> {例: 「可愛いキャラクターがしゃべる ChatGPT クローンを公開したい」}

### 成功の定義

- {何ができたら「完成」か}
- {例: キャラクター設定が反映された AI チャットが公開されている}
- {例: 友達が URL にアクセスして使える}

## tech_decisions

> **setup ヒアリングで決定した技術選択。LLM は以降のセッションでこれを参照する。**

### 言語
language: {TypeScript | JavaScript | Python}
reason: {選択理由}

### フレームワーク
frontend: {Next.js | React | Vue | none}
backend: {Next.js API Routes | Express | FastAPI | none}
mobile: {React Native + Expo | none}
reason: {選択理由}

### ライブラリ
ui:
  - {Tailwind CSS | MUI | ...}
state_management: {React Context | Zustand | Redux Toolkit | none}
data_fetching: {SWR | TanStack Query | tRPC | fetch}
form: {React Hook Form | Formik | none}
validation: {Zod | Yup | none}
auth: {NextAuth.js | Clerk | Supabase Auth | none}
database: {Prisma | Drizzle | Supabase | none}
ai: {Vercel AI SDK | LangChain | none}

### デプロイ
platform: {Vercel | GCP | AWS | Cloudflare | local}
reason: {選択理由}

## non_functional_requirements

> **setup ヒアリングで確認した非機能要件。設計判断の根拠となる。**

### 規模
users: {1 | 10 | 100 | 1000+}  # 想定ユーザー数
data_volume: {small | medium | large}  # 想定データ量

### パフォーマンス
response_time: {fast < 1s | normal < 3s | relaxed}
concurrent_users: {1 | 10 | 100 | 1000+}

### セキュリティ
requires_auth: {true | false}
handles_pii: {true | false}  # 個人情報
handles_payment: {true | false}  # 支払い情報

### 可用性
downtime_tolerance: {low | medium | high}  # 低=24/7必須, 高=たまに落ちてOK
requires_backup: {true | false}

### 予算
monthly_budget: {free | $10 | $50 | unlimited}
initial_investment: {none | low | medium | high}

### 期間
target_release: {YYYY-MM-DD | flexible}
mvp_deadline: {YYYY-MM-DD | flexible}

### 費用概算（必須）

> **setup で選択した構成に基づく月額費用の内訳。**

estimated_cost:
  monthly_total: {$0 | $X}  # 月額合計
  breakdown:
    hosting: {$0 | $X}      # Vercel, Cloudflare 等
    database: {$0 | $X}     # Neon, Supabase 等
    auth: {$0 | $X}         # Clerk, Auth0 等
    ai_api: {$0-X}          # OpenRouter, OpenAI 等（使用量による）
    payment: {0% | X%}      # Stripe 手数料等
    other: {$0 | $X}        # その他
  notes: |
    - 無料枠を超えると課金発生
    - AI API は使用量に応じて変動
    - {その他の注意事項}

## stack

> **tech_decisions から導出された最終スタック構成**

framework: {Next.js | React | Vue | ...}
language: {TypeScript | JavaScript | Python | ...}
deploy: {Vercel | GCP | AWS | local | ...}
database: {Neon | Supabase | PostgreSQL | none | ...}
external_apis:
  - {OpenAI | Google AI | Stripe | Resend | ...}

## constraints

- {制約条件があれば記載}
- {例: 費用は月額 $10 以内}
- {例: 1週間以内に MVP 完成}
- {なければ「特になし」}

## skills

# プロジェクトで使用する Claude Skills
# setup Phase 8.3 で自動生成される

lint-checker:
  role: コード品質チェック
  location: .claude/skills/lint-checker/skill.md

test-runner:
  role: テスト実行・検証
  location: .claude/skills/test-runner/skill.md

deploy-checker:
  role: デプロイ準備・検証
  location: .claude/skills/deploy-checker/skill.md

## 開発の必須事項

> LLM が確実に Skills を発火させるための記載

- TypeScript/JavaScript ファイルを作成・編集した後は、必ず `lint-checker` スキルを実行すること
- テストファイルを作成・編集した後は、必ず `test-runner` スキルを実行すること
- git push 前は、必ず `deploy-checker` スキルを実行すること

## milestones

- [ ] MVP 完成
- [ ] 公開
- [ ] {追加マイルストーン}

## notes

{その他メモ、LLM が参照すべき補足情報}
{例: キャラクター名は「アイ」、ツンデレ口調}
```

---

## project.md と playbook の関係

```
plan/project.md          根幹計画（プロジェクト全体）
     │
     ├── plan/active/playbook-mvp.md       Phase 1-N
     ├── plan/active/playbook-feature-x.md Phase 1-N
     └── ...
```

- project.md は「何を作るか」の全体像
- playbook は「どう作るか」の具体的タスク
- playbook 作成時は必ず project.md の vision を参照

---

## 生成タイミング

```
GUIDE.md Phase 7 完了
     ↓
LLM: 「setup 完了しました。開発計画を作成します。」
     ↓
plan/project.md 生成（このテンプレートを参照）
     ↓
state.md 更新:
  - project_context.generated: true
  - project_context.project_plan: plan/project.md
  - layer.setup.state: done
  - focus.current: product
     ↓
LLM: 「では、最初の開発計画を作りましょう。/init」
```

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-02 | 初版作成。setup → product 遷移の根幹計画テンプレート。 |
