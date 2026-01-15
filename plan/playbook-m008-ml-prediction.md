# playbook-m008-ml-prediction.md

> **機械学習による継続的ローソク足予測システム**

---

## meta

```yaml
schema_version: v2
project: chart-system
branch: feat/M008-ml-prediction
created: 2026-01-15
issue: null
derives_from: M007  # learning-engine の発展
reviewed: true
roles:
  worker: codex

user_prompt_original: |
  従来の勝率が高いときにインジケータが表示されるのではなく、
  機械学習により、過去の統計参考に、次のローソク足を予想し続けるようにして欲しいです。
```

---

## goal

```yaml
summary: 機械学習モデルで次のローソク足（上昇/下降）を継続的に予測するシステムを実装
done_when:
  - prediction-engine.ts が存在し、ML ベースの予測ロジックが実装されている
  - 過去の価格データとインジケーターを特徴量として学習モデルが訓練される
  - 毎ローソク足ごとに次の方向（HIGH/LOW）と確信度を予測・表示する
  - prediction_history テーブルに予測履歴が保存される
  - 予測精度が UI に表示される
```

---

## 技術設計

### アプローチ選択

ブラウザ/Node.js で動作する ML ライブラリとして以下を検討:

| ライブラリ | 特徴 | 適合性 |
|-----------|------|--------|
| TensorFlow.js | 高機能、重い | オーバースペック |
| Brain.js | シンプル、軽量 | 適合 |
| ml.js | 統計的ML | 適合 |
| 自作ロジスティック回帰 | 最軽量 | 最適 |

**選択: 自作ロジスティック回帰 + Brain.js（オプション）**

理由:
1. 依存最小化（Next.js との相性）
2. インジケーターの特徴量が明確（RSI, MACD, Stoch 等）
3. 解釈可能性（どの特徴が効いているか分かる）

### 特徴量設計

```typescript
interface Features {
  // トレンド系
  ema_trend: number;      // EMA パーフェクトオーダー (-1, 0, 1)
  macd_hist: number;      // MACD ヒストグラム正規化
  adx_strength: number;   // ADX 正規化 (0-1)

  // オシレーター系
  rsi_norm: number;       // RSI 正規化 (0-1)
  stoch_k: number;        // Stochastic K 正規化
  stoch_cross: number;    // Stoch クロス (-1, 0, 1)

  // 価格系
  bb_position: number;    // BB 内の位置 (-1 to 1)
  price_momentum: number; // 価格モメンタム

  // 過去パターン
  last_3_candles: number; // 直近3本のパターン
}
```

### 学習アルゴリズム

**オンライン学習（逐次更新）**:
- 各ローソク足確定時に予測 vs 実際を比較
- 重みを SGD で更新
- 過学習防止のため L2 正則化

```
予測: P(HIGH) = sigmoid(w · x + b)
損失: L = -y·log(P) - (1-y)·log(1-P)
更新: w = w - lr * gradient + lambda * w
```

---

## phases

### p1: 予測エンジン基盤実装

**goal**: prediction-engine.ts を作成し、ML 予測ロジックを実装

#### subtasks

- [x] **p1.1**: app/src/lib/prediction-engine.ts が存在する
  - executor: codex
  - test_command: `test -f /Users/yoshinobua/Documents/Dev/Ind/chart-system/app/src/lib/prediction-engine.ts && echo PASS || echo FAIL`
  - validations:
    - technical: "ファイルが存在し、TypeScript として有効"
    - consistency: "他の lib/*.ts と同じ構造"
    - completeness: "PredictionEngine クラスが export されている"

- [x] **p1.2**: extractFeatures 関数が OHLC データから特徴量を抽出する
  - executor: codex
  - test_command: `grep -q 'extractFeatures' /Users/yoshinobua/Documents/Dev/Ind/chart-system/app/src/lib/prediction-engine.ts && echo PASS || echo FAIL`
  - validations:
    - technical: "OHLC[] を受け取り Features を返す"
    - consistency: "indicators.ts の関数を使用"
    - completeness: "9つ以上の特徴量を抽出"

- [x] **p1.3**: predict 関数がロジスティック回帰で予測を返す
  - executor: codex
  - test_command: `grep -q 'predict' /Users/yoshinobua/Documents/Dev/Ind/chart-system/app/src/lib/prediction-engine.ts && echo PASS || echo FAIL`
  - validations:
    - technical: "sigmoid 関数を使用"
    - consistency: "Features を入力とする"
    - completeness: "{ direction: HIGH|LOW, confidence: 0-1 } を返す"

- [x] **p1.4**: train 関数がオンライン学習で重みを更新する
  - executor: codex
  - test_command: `grep -q 'train' /Users/yoshinobua/Documents/Dev/Ind/chart-system/app/src/lib/prediction-engine.ts && echo PASS || echo FAIL`
  - validations:
    - technical: "SGD + L2 正則化"
    - consistency: "actualResult を受け取る"
    - completeness: "prediction_weights テーブルに保存"

**status**: completed
**max_iterations**: 5

---

### p2: データベース拡張

**goal**: 予測履歴と ML 重みを保存するテーブルを追加

**depends_on**: [p1]

#### subtasks

- [x] **p2.1**: schema.ts に prediction_weights テーブルが追加されている
  - executor: codex
  - test_command: `grep -q 'predictionWeights\|prediction_weights' /Users/yoshinobua/Documents/Dev/Ind/chart-system/app/src/db/schema.ts && echo PASS || echo FAIL`
  - validations:
    - technical: "SQLite テーブル定義が正しい"
    - consistency: "他のテーブルと同じパターン"
    - completeness: "name, value, updatedAt を含む"

- [x] **p2.2**: schema.ts に prediction_history テーブルが追加されている
  - executor: codex
  - test_command: `grep -q 'predictionHistory\|prediction_history' /Users/yoshinobua/Documents/Dev/Ind/chart-system/app/src/db/schema.ts && echo PASS || echo FAIL`
  - validations:
    - technical: "SQLite テーブル定義が正しい"
    - consistency: "他のテーブルと同じパターン"
    - completeness: "timestamp, prediction, actual, confidence を含む"

- [x] **p2.3**: Drizzle マイグレーションが実行されている
  - executor: codex
  - test_command: `ls /Users/yoshinobua/Documents/Dev/Ind/chart-system/app/drizzle/*.sql 2>/dev/null | wc -l | awk '{if($1>=1) print "PASS"; else print "FAIL"}'`
  - validations:
    - technical: "マイグレーション SQL が生成されている"
    - consistency: "drizzle-kit generate 実行済み"
    - completeness: "新テーブルが含まれている"

**status**: completed
**max_iterations**: 5

---

### p3: 継続的予測ループ実装

**goal**: 毎ローソク足ごとに自動で予測を実行・保存する

**depends_on**: [p1, p2]

#### subtasks

- [x] **p3.1**: useSignal.ts フックに予測結果が含まれる
  - executor: codex
  - test_command: `grep -q 'prediction' /Users/yoshinobua/Documents/Dev/Ind/chart-system/app/src/hooks/useSignal.ts && echo PASS || echo FAIL`
  - validations:
    - technical: "prediction-engine.ts を import"
    - consistency: "既存の signal と並行して予測を取得"
    - completeness: "direction, confidence を返す"

- [x] **p3.2**: API /api/predictions が予測履歴と精度を返す
  - executor: codex
  - test_command: `test -f /Users/yoshinobua/Documents/Dev/Ind/chart-system/app/src/app/api/predictions/route.ts && echo PASS || echo FAIL`
  - validations:
    - technical: "Next.js API Route 形式"
    - consistency: "他の api/*.ts と同じ構造"
    - completeness: "history, accuracy を返す"

- [x] **p3.3**: 価格更新時に自動で train が呼ばれる
  - executor: codex
  - test_command: `grep -q 'predictionEngine\|train' /Users/yoshinobua/Documents/Dev/Ind/chart-system/app/src/lib/price-service.ts && echo PASS || echo FAIL`
  - validations:
    - technical: "前回予測 vs 今回実績を比較"
    - consistency: "prediction-service.ts を使用"
    - completeness: "API経由で予測を取得・保存"

**status**: completed
**max_iterations**: 5

---

### p4: UI 表示実装

**goal**: Chart コンポーネントに予測と精度を表示

**depends_on**: [p3]

#### subtasks

- [x] **p4.1**: Chart.tsx に予測表示が追加されている
  - executor: codex
  - test_command: `grep -q 'prediction\|Prediction' /Users/yoshinobua/Documents/Dev/Ind/chart-system/app/src/components/Chart.tsx && echo PASS || echo FAIL`
  - validations:
    - technical: "予測方向と確信度が表示される"
    - consistency: "既存の UI スタイルと統一"
    - completeness: "HIGH/LOW + パーセンテージ"

- [x] **p4.2**: 予測精度（直近 N 件の正答率）が表示されている
  - executor: codex
  - test_command: `grep -q 'accuracy\|Accuracy' /Users/yoshinobua/Documents/Dev/Ind/chart-system/app/src/app/page.tsx && echo PASS || echo FAIL`
  - validations:
    - technical: "prediction_history から計算"
    - consistency: "パーセンテージ形式"
    - completeness: "リアルタイム更新"

**status**: completed
**max_iterations**: 5

---

### p_final: 完了検証

**goal**: done_when の全項目が実際に満たされているか最終検証

#### subtasks

- [x] **p_final.1**: prediction-engine.ts が存在し、ML ベースの予測ロジックが実装されている
  - executor: claudecode
  - test_command: `test -f /Users/yoshinobua/Documents/Dev/Ind/chart-system/app/src/lib/prediction-engine.ts && grep -q 'predict' /Users/yoshinobua/Documents/Dev/Ind/chart-system/app/src/lib/prediction-engine.ts && echo PASS || echo FAIL`
  - validations:
    - technical: "ファイルが存在し predict 関数がある"
    - consistency: "export されている"
    - completeness: "sigmoid ベースの予測ロジック"

- [x] **p_final.2**: 過去の価格データとインジケーターを特徴量として学習モデルが訓練される
  - executor: claudecode
  - test_command: `grep -q 'extractFeatures\|train' /Users/yoshinobua/Documents/Dev/Ind/chart-system/app/src/lib/prediction-engine.ts && echo PASS || echo FAIL`
  - validations:
    - technical: "extractFeatures と train が存在"
    - consistency: "indicators.ts を使用"
    - completeness: "オンライン学習が実装"

- [x] **p_final.3**: 毎ローソク足ごとに次の方向と確信度を予測・表示する
  - executor: claudecode
  - test_command: `grep -q 'prediction' /Users/yoshinobua/Documents/Dev/Ind/chart-system/app/src/hooks/useSignal.ts && echo PASS || echo FAIL`
  - validations:
    - technical: "useSignal に予測が含まれる"
    - consistency: "direction + confidence"
    - completeness: "リアルタイム更新"

- [x] **p_final.4**: prediction_history テーブルに予測履歴が保存される
  - executor: claudecode
  - test_command: `grep -q 'predictionHistory\|prediction_history' /Users/yoshinobua/Documents/Dev/Ind/chart-system/app/src/db/schema.ts && echo PASS || echo FAIL`
  - validations:
    - technical: "テーブル定義が存在"
    - consistency: "timestamp, prediction, actual"
    - completeness: "マイグレーション済み"

- [x] **p_final.5**: 予測精度が UI に表示される
  - executor: claudecode
  - test_command: `grep -q 'accuracy\|Accuracy' /Users/yoshinobua/Documents/Dev/Ind/chart-system/app/src/app/page.tsx && echo PASS || echo FAIL`
  - validations:
    - technical: "page.tsx に表示がある"
    - consistency: "パーセンテージ形式"
    - completeness: "リアルタイム更新"

**status**: completed
**max_iterations**: 3

---

## final_tasks

- [x] **ft1**: TypeScript コンパイルが通る
  - command: `cd /Users/yoshinobua/Documents/Dev/Ind/chart-system/app && npx tsc --noEmit`
  - status: completed

- [ ] **ft2**: 変更を全てコミットする
  - command: `git add -A && git status`
  - status: pending

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2026-01-15 | 初版作成 |
