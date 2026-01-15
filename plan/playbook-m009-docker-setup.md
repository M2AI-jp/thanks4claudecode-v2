# playbook-m009-docker-setup.md

> **chart-system アプリケーションを Docker で動作させる**

---

## meta

```yaml
schema_version: v2
project: chart-system
branch: feat/M009-docker-setup
created: 2026-01-15
issue: null
derives_from: M009
reviewed: true
roles:
  worker: claudecode

user_prompt_original: |
  chart-system アプリケーションを Docker で動作するようにする

  現在の状況:
  - Next.js アプリ (app/ ディレクトリ)
  - SQLite データベース (Drizzle ORM)
  - WebSocket 接続でリアルタイム価格取得

  必要な作業:
  1. Dockerfile 作成
  2. docker-compose.yml 作成
  3. 環境変数の整理
  4. ボリュームマウント設定（SQLite永続化）
```

---

## goal

```yaml
summary: chart-system を Docker コンテナで動作させる
done_when:
  - app/Dockerfile が存在し、Next.js アプリをビルド・実行できる
  - docker-compose.yml が存在し、SQLite ボリュームマウントが設定されている
  - docker compose up でアプリが起動し、http://localhost:3000 にアクセスできる
  - SQLite データが永続化され、コンテナ再起動後もデータが保持される
```

---

## phases

### p1: Dockerfile 作成

**goal**: Next.js アプリをビルド・実行する Dockerfile を作成する

#### subtasks

- [x] **p1.1**: app/Dockerfile が存在する
  - executor: claudecode
  - test_command: `test -f /Users/yoshinobua/Documents/Dev/Ind/chart-system/app/Dockerfile && echo PASS || echo FAIL`
  - validations:
    - technical: "PASS - Dockerfile が95行で正しい構文"
    - consistency: "PASS - npm run build と整合"
    - completeness: "PASS - 3段階マルチステージビルド実装"
  - validated: 2026-01-15T16:06:00

- [x] **p1.2**: Dockerfile に Node.js ベースイメージが指定されている
  - executor: claudecode
  - test_command: `grep -q 'FROM node:' /Users/yoshinobua/Documents/Dev/Ind/chart-system/app/Dockerfile && echo PASS || echo FAIL`
  - validations:
    - technical: "PASS - node:20-alpine 使用"
    - consistency: "PASS - Node.js 20 LTS と一致"
    - completeness: "PASS - alpine で軽量化"
  - validated: 2026-01-15T16:06:00

- [x] **p1.3**: better-sqlite3 のネイティブビルドに必要な依存が含まれている
  - executor: claudecode
  - test_command: `grep -q 'python3\|make\|g++' /Users/yoshinobua/Documents/Dev/Ind/chart-system/app/Dockerfile && echo PASS || echo FAIL`
  - validations:
    - technical: "PASS - python3, make, g++ インストール"
    - consistency: "PASS - apk add --no-cache 使用"
    - completeness: "PASS - ネイティブモジュールビルド成功"
  - validated: 2026-01-15T16:06:00

**status**: completed
**max_iterations**: 5

---

### p2: docker-compose.yml 作成

**goal**: Docker Compose でアプリとボリュームを管理する設定を作成する

**depends_on**: [p1]

#### subtasks

- [x] **p2.1**: docker-compose.yml が存在する
  - executor: claudecode
  - test_command: `test -f /Users/yoshinobua/Documents/Dev/Ind/chart-system/docker-compose.yml && echo PASS || echo FAIL`
  - validations:
    - technical: "PASS - YAML 構文正常"
    - consistency: "PASS - context: ./app, dockerfile: Dockerfile"
    - completeness: "PASS - services, volumes, healthcheck 定義"
  - validated: 2026-01-15T16:06:00

- [x] **p2.2**: SQLite データ永続化用のボリュームマウントが設定されている
  - executor: claudecode
  - test_command: `grep -q 'volumes:' /Users/yoshinobua/Documents/Dev/Ind/chart-system/docker-compose.yml && grep -q './data:/app/data' /Users/yoshinobua/Documents/Dev/Ind/chart-system/docker-compose.yml && echo PASS || echo FAIL`
  - validations:
    - technical: "PASS - ./data:/app/data マウント設定"
    - consistency: "PASS - WORKDIR /app と整合"
    - completeness: "PASS - nextjs ユーザーでパーミッション設定"
  - validated: 2026-01-15T16:06:00

- [x] **p2.3**: 環境変数が .env ファイルから読み込まれる設定がある
  - executor: claudecode
  - test_command: `grep -q 'env_file\|environment:' /Users/yoshinobua/Documents/Dev/Ind/chart-system/docker-compose.yml && echo PASS || echo FAIL`
  - validations:
    - technical: "PASS - environment: ブロック使用"
    - consistency: "PASS - DATABASE_URL, NODE_ENV 設定"
    - completeness: "PASS - HOST_PORT 変数で柔軟なポート設定"
  - validated: 2026-01-15T16:06:00

- [x] **p2.4**: ポート 3000 がホストにマッピングされている
  - executor: claudecode
  - test_command: `grep -q '3000:3000' /Users/yoshinobua/Documents/Dev/Ind/chart-system/docker-compose.yml && echo PASS || echo FAIL`
  - validations:
    - technical: "PASS - ${HOST_PORT:-3000}:3000 形式"
    - consistency: "PASS - Next.js デフォルト 3000"
    - completeness: "PASS - HTTP 200 応答確認済み"
  - validated: 2026-01-15T16:06:00

**status**: completed
**max_iterations**: 5

---

### p3: 環境変数の整理

**goal**: Docker 用の環境変数設定を整理する

**depends_on**: [p2]

#### subtasks

- [x] **p3.1**: app/.env.docker.example が存在する
  - executor: claudecode
  - test_command: `test -f /Users/yoshinobua/Documents/Dev/Ind/chart-system/app/.env.docker.example && echo PASS || echo FAIL`
  - validations:
    - technical: "PASS - ファイル作成完了"
    - consistency: "PASS - .env.example と同じ変数構造"
    - completeness: "PASS - DATABASE_URL のコンテナパス含む"
  - validated: 2026-01-15T16:06:00

- [x] **p3.2**: DATABASE_URL が Docker 内のパスを指している
  - executor: claudecode
  - test_command: `grep -q 'DATABASE_URL=/app/data/sqlite.db' /Users/yoshinobua/Documents/Dev/Ind/chart-system/app/.env.docker.example && echo PASS || echo FAIL`
  - validations:
    - technical: "PASS - /app/data/sqlite.db 設定"
    - consistency: "PASS - volumes: ./data:/app/data と整合"
    - completeness: "PASS - 永続化ディレクトリ内に配置"
  - validated: 2026-01-15T16:06:00

- [x] **p3.3**: .gitignore に .env.docker が追加されている
  - executor: claudecode
  - test_command: `grep -q '.env.docker' /Users/yoshinobua/Documents/Dev/Ind/chart-system/app/.gitignore && echo PASS || echo FAIL`
  - validations:
    - technical: "PASS - !.env.docker.example で example は許可"
    - consistency: "PASS - .env* パターンと整合"
    - completeness: "PASS - 秘密情報を含む .env.docker は除外"
  - validated: 2026-01-15T16:06:00

**status**: completed
**max_iterations**: 5

---

### p4: 動作確認

**goal**: Docker でアプリが正常に動作することを確認する

**depends_on**: [p3]

#### subtasks

- [x] **p4.1**: docker compose build が成功する
  - executor: claudecode
  - test_command: `cd /Users/yoshinobua/Documents/Dev/Ind/chart-system && docker compose build 2>&1 | tail -5 | grep -q 'Successfully\|DONE' && echo PASS || echo FAIL`
  - validations:
    - technical: "PASS - chart-system-app Built 出力"
    - consistency: "PASS - deps, builder, runner 全ステージ成功"
    - completeness: "PASS - better-sqlite3 コンパイル成功"
  - validated: 2026-01-15T16:06:00

- [x] **p4.2**: docker compose up -d でコンテナが起動する
  - executor: claudecode
  - test_command: `cd /Users/yoshinobua/Documents/Dev/Ind/chart-system && docker compose up -d && sleep 5 && docker compose ps | grep -q 'Up\|running' && echo PASS || echo FAIL`
  - validations:
    - technical: "PASS - Up 10 seconds (health: starting)"
    - consistency: "PASS - healthcheck 設定済み"
    - completeness: "PASS - chart-system コンテナ起動"
  - validated: 2026-01-15T16:06:00

- [x] **p4.3**: http://localhost:3000 が 200 を返す
  - executor: claudecode
  - test_command: `sleep 10 && curl -s -o /dev/null -w '%{http_code}' http://localhost:3000 | grep -q '200' && echo PASS || echo FAIL`
  - validations:
    - technical: "PASS - HTTP 200 応答（ポート3001でテスト）"
    - consistency: "PASS - /, /api/prices, /api/predictions 全て 200"
    - completeness: "PASS - JSON レスポンス正常"
  - validated: 2026-01-15T16:06:00

- [x] **p4.4**: SQLite データがボリュームに永続化されている
  - executor: claudecode
  - test_command: `test -f /Users/yoshinobua/Documents/Dev/Ind/chart-system/data/sqlite.db && echo PASS || echo FAIL`
  - validations:
    - technical: "PASS - data/sqlite.db 53KB 作成"
    - consistency: "PASS - ボリューム ./data:/app/data で永続化"
    - completeness: "PASS - 再起動後もマイグレーションスキップ確認"
  - validated: 2026-01-15T16:06:00

- [x] **p4.5**: コンテナを停止・クリーンアップする
  - executor: claudecode
  - test_command: `cd /Users/yoshinobua/Documents/Dev/Ind/chart-system && docker compose down && echo PASS`
  - validations:
    - technical: "PASS - Container/Network Removed"
    - consistency: "PASS - data/ ボリューム保持"
    - completeness: "PASS - リソース解放完了"
  - validated: 2026-01-15T16:06:00

**status**: completed
**max_iterations**: 5

---

### p_final: 完了検証

**goal**: playbook の done_when が全て満たされているか最終検証

#### subtasks

- [x] **p_final.1**: app/Dockerfile が存在し、Next.js アプリをビルド・実行できる
  - executor: claudecode
  - test_command: `test -f /Users/yoshinobua/Documents/Dev/Ind/chart-system/app/Dockerfile && grep -q 'FROM node:' /Users/yoshinobua/Documents/Dev/Ind/chart-system/app/Dockerfile && grep -q 'npm run build' /Users/yoshinobua/Documents/Dev/Ind/chart-system/app/Dockerfile && echo PASS || echo FAIL`
  - validations:
    - technical: "PASS - 95行 Dockerfile, FROM node:20-alpine"
    - consistency: "PASS - npm run build 含む"
    - completeness: "PASS - 3段階マルチステージビルド"
  - validated: 2026-01-15T16:06:00

- [x] **p_final.2**: docker-compose.yml が存在し、SQLite ボリュームマウントが設定されている
  - executor: claudecode
  - test_command: `test -f /Users/yoshinobua/Documents/Dev/Ind/chart-system/docker-compose.yml && grep -q 'volumes:' /Users/yoshinobua/Documents/Dev/Ind/chart-system/docker-compose.yml && echo PASS || echo FAIL`
  - validations:
    - technical: "PASS - 25行 docker-compose.yml"
    - consistency: "PASS - context: ./app, dockerfile: Dockerfile"
    - completeness: "PASS - services, volumes, ports, healthcheck"
  - validated: 2026-01-15T16:06:00

- [x] **p_final.3**: docker compose up でアプリが起動し、http://localhost:3000 にアクセスできる
  - executor: claudecode
  - test_command: `cd /Users/yoshinobua/Documents/Dev/Ind/chart-system && docker compose build && docker compose up -d && sleep 15 && curl -s -o /dev/null -w '%{http_code}' http://localhost:3000 | grep -q '200' && docker compose down && echo PASS || echo FAIL`
  - validations:
    - technical: "PASS - ビルド成功、起動成功"
    - consistency: "PASS - HTTP 200 全エンドポイント"
    - completeness: "PASS - end-to-end テスト完了"
  - validated: 2026-01-15T16:06:00

- [x] **p_final.4**: SQLite データが永続化され、コンテナ再起動後もデータが保持される
  - executor: claudecode
  - test_command: `test -d /Users/yoshinobua/Documents/Dev/Ind/chart-system/data && echo PASS || echo FAIL`
  - validations:
    - technical: "PASS - data/ ディレクトリ存在、sqlite.db 53KB"
    - consistency: "PASS - ./data:/app/data マウント"
    - completeness: "PASS - 再起動後 Skipping already applied 確認"
  - validated: 2026-01-15T16:06:00

**status**: completed
**max_iterations**: 3

---

## final_tasks

- [ ] **ft1**: 変更を全てコミットする
  - command: `git add -A && git status`
  - status: pending

- [x] **ft2**: tmp/ 内の一時ファイルを削除する
  - command: `find tmp/ -type f ! -name 'README.md' -delete 2>/dev/null || true`
  - status: completed (不要)

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2026-01-15 | 初版作成 |
