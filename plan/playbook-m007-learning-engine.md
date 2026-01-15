# playbook-m007-learning-engine.md

> **自己学習エンジン: トレード結果に基づくシグナル重み付け最適化**

---

## meta

```yaml
schema_version: v2
project: chart-system
branch: feat/M007-learning-engine
created: 2026-01-15
issue: null
derives_from: null  # chart-system は独立プロジェクト
reviewed: false
roles:
  worker: codex

user_prompt_original: |
  M007: Learning Engine（自己学習エンジン）の playbook を作成してください。
  要件:
  1. トレード結果（勝敗）に基づいてシグナルの重み付けを最適化
  2. 各インジケーター（EMA, MACD, RSI, Stoch, ADX等）の重みを動的に調整
  3. 勝率向上のためのフィードバックループ
  4. model_weights テーブル（既存）を活用
  シンプルで効果的なアプローチを優先してください。
```

---

## goal

```yaml
summary: トレード結果からインジケーター重みを自動調整し、勝率を向上させる自己学習エンジンを実装
done_when:
  - learning-engine.ts が存在し、重み更新ロジックが実装されている
  - model_weights テーブルにデフォルト重みが初期化されている
  - completeTrade 時に自動で重み更新が実行される
  - signal-generator.ts が model_weights を参照してスコア計算する
  - 統計API（/api/weights）が重みの現状と勝率相関を返す
```

---

## phases

### p1: 学習エンジン基盤実装

**goal**: learning-engine.ts を作成し、重み更新アルゴリズムを実装

#### subtasks

- [ ] **p1.1**: app/src/lib/learning-engine.ts が存在する
  - executor: codex
  - test_command: `test -f /Users/yoshinobua/Documents/Dev/Ind/chart-system/app/src/lib/learning-engine.ts && echo PASS || echo FAIL`
  - validations:
    - technical: "ファイルが存在し、TypeScript として有効"
    - consistency: "他の lib/*.ts と同じ構造"
    - completeness: "export される関数/クラスがある"

- [ ] **p1.2**: LearningEngine クラスに updateWeights メソッドが存在する
  - executor: codex
  - test_command: `grep -q 'updateWeights' /Users/yoshinobua/Documents/Dev/Ind/chart-system/app/src/lib/learning-engine.ts && echo PASS || echo FAIL`
  - validations:
    - technical: "メソッドが定義されている"
    - consistency: "TradeRecord 型を受け取る"
    - completeness: "WIN/LOSE に応じた重み調整ロジックがある"

- [ ] **p1.3**: initializeWeights 関数が model_weights にデフォルト値を挿入する
  - executor: codex
  - test_command: `grep -q 'initializeWeights' /Users/yoshinobua/Documents/Dev/Ind/chart-system/app/src/lib/learning-engine.ts && echo PASS || echo FAIL`
  - validations:
    - technical: "DB への INSERT/UPSERT ロジックがある"
    - consistency: "modelWeights スキーマを使用"
    - completeness: "ema, macd, adx, rsi, stoch, price, candle の7種"

**status**: pending
**max_iterations**: 5

---

### p2: Signal Generator との統合

**goal**: signal-generator.ts が model_weights を参照してスコア計算を行う

**depends_on**: [p1]

#### subtasks

- [ ] **p2.1**: getWeights 関数が model_weights からリアルタイムで重みを取得する
  - executor: codex
  - test_command: `grep -q 'getWeights' /Users/yoshinobua/Documents/Dev/Ind/chart-system/app/src/lib/learning-engine.ts && echo PASS || echo FAIL`
  - validations:
    - technical: "DB クエリが正しい"
    - consistency: "modelWeights スキーマを使用"
    - completeness: "デフォルト値フォールバックがある"

- [ ] **p2.2**: signal-generator.ts の calculateHighScore/calculateLowScore が重みを使用する
  - executor: codex
  - test_command: `grep -q 'weight' /Users/yoshinobua/Documents/Dev/Ind/chart-system/app/src/lib/signal-generator.ts && echo PASS || echo FAIL`
  - validations:
    - technical: "重み掛け算がスコア計算に含まれる"
    - consistency: "learning-engine.ts から import"
    - completeness: "全7コンポーネントに重みが適用される"

**status**: pending
**max_iterations**: 5

---

### p3: Trade Service との統合

**goal**: completeTrade 時に自動で重み更新を実行する

**depends_on**: [p1]

#### subtasks

- [ ] **p3.1**: trade-service.ts の completeTrade が learningEngine.updateWeights を呼び出す
  - executor: codex
  - test_command: `grep -q 'updateWeights' /Users/yoshinobua/Documents/Dev/Ind/chart-system/app/src/lib/trade-service.ts && echo PASS || echo FAIL`
  - validations:
    - technical: "async 呼び出しが正しい"
    - consistency: "learning-engine.ts から import"
    - completeness: "TradeRecord と SignalRecord を渡す"

- [ ] **p3.2**: updateWeights がシグナルの indicators JSON を解析して個別スコアを取得する
  - executor: codex
  - test_command: `grep -q 'indicators' /Users/yoshinobua/Documents/Dev/Ind/chart-system/app/src/lib/learning-engine.ts && echo PASS || echo FAIL`
  - validations:
    - technical: "JSON.parse が正しい"
    - consistency: "SignalDetails 型と整合"
    - completeness: "7コンポーネントの個別スコアを抽出"

**status**: pending
**max_iterations**: 5

---

### p4: 統計 API 実装

**goal**: 重みの現状と勝率相関を確認できる API を実装

**depends_on**: [p1, p2, p3]

#### subtasks

- [ ] **p4.1**: app/src/app/api/weights/route.ts が存在する
  - executor: codex
  - test_command: `test -f /Users/yoshinobua/Documents/Dev/Ind/chart-system/app/src/app/api/weights/route.ts && echo PASS || echo FAIL`
  - validations:
    - technical: "Next.js API Route 形式"
    - consistency: "他の api/*.ts と同じ構造"
    - completeness: "GET メソッドが export されている"

- [ ] **p4.2**: GET /api/weights が現在の重みと統計を返す
  - executor: codex
  - test_command: `grep -q 'export async function GET' /Users/yoshinobua/Documents/Dev/Ind/chart-system/app/src/app/api/weights/route.ts && echo PASS || echo FAIL`
  - validations:
    - technical: "JSON レスポンスを返す"
    - consistency: "modelWeights から取得"
    - completeness: "weights, stats, correlations を含む"

**status**: pending
**max_iterations**: 5

---

### p_final: 完了検証

**goal**: done_when の全項目が実際に満たされているか最終検証

#### subtasks

- [ ] **p_final.1**: learning-engine.ts が存在し、重み更新ロジックが実装されている
  - executor: claudecode
  - test_command: `test -f /Users/yoshinobua/Documents/Dev/Ind/chart-system/app/src/lib/learning-engine.ts && grep -q 'updateWeights' /Users/yoshinobua/Documents/Dev/Ind/chart-system/app/src/lib/learning-engine.ts && echo PASS || echo FAIL`
  - validations:
    - technical: "ファイルが存在し updateWeights 関数がある"
    - consistency: "export されている"
    - completeness: "重み更新ロジックが完全"

- [ ] **p_final.2**: model_weights テーブルにデフォルト重みが初期化されている
  - executor: claudecode
  - test_command: `grep -q 'initializeWeights' /Users/yoshinobua/Documents/Dev/Ind/chart-system/app/src/lib/learning-engine.ts && echo PASS || echo FAIL`
  - validations:
    - technical: "initializeWeights 関数が存在"
    - consistency: "7種の重みを初期化"
    - completeness: "DB 操作が正しい"

- [ ] **p_final.3**: completeTrade 時に自動で重み更新が実行される
  - executor: claudecode
  - test_command: `grep -q 'learningEngine\|updateWeights' /Users/yoshinobua/Documents/Dev/Ind/chart-system/app/src/lib/trade-service.ts && echo PASS || echo FAIL`
  - validations:
    - technical: "updateWeights 呼び出しがある"
    - consistency: "learning-engine.ts を import"
    - completeness: "TradeRecord を渡している"

- [ ] **p_final.4**: signal-generator.ts が model_weights を参照してスコア計算する
  - executor: claudecode
  - test_command: `grep -q 'weight' /Users/yoshinobua/Documents/Dev/Ind/chart-system/app/src/lib/signal-generator.ts && echo PASS || echo FAIL`
  - validations:
    - technical: "重みがスコア計算に使用される"
    - consistency: "learning-engine.ts から取得"
    - completeness: "全コンポーネントに適用"

- [ ] **p_final.5**: 統計API（/api/weights）が重みの現状と勝率相関を返す
  - executor: claudecode
  - test_command: `test -f /Users/yoshinobua/Documents/Dev/Ind/chart-system/app/src/app/api/weights/route.ts && grep -q 'GET' /Users/yoshinobua/Documents/Dev/Ind/chart-system/app/src/app/api/weights/route.ts && echo PASS || echo FAIL`
  - validations:
    - technical: "API Route が存在"
    - consistency: "GET メソッドが export"
    - completeness: "weights, stats を返す"

**status**: pending
**max_iterations**: 3

---

## final_tasks

- [ ] **ft1**: TypeScript コンパイルが通る
  - command: `cd /Users/yoshinobua/Documents/Dev/Ind/chart-system/app && npx tsc --noEmit`
  - status: pending

- [ ] **ft2**: 変更を全てコミットする
  - command: `git add -A && git status`
  - status: pending

---

## 設計メモ

### 重み更新アルゴリズム（シンプル版）

```typescript
// 指数移動平均ベースの更新
// WIN: weight += alpha * (component_score > avg ? 0.1 : 0.05)
// LOSE: weight -= alpha * (component_score > avg ? 0.1 : 0.05)
// alpha = 0.1 (学習率)
// weight は 0.5 ~ 2.0 の範囲にクランプ
```

### 7つのコンポーネント重み

| name | default | description |
|------|---------|-------------|
| ema_weight | 1.0 | EMA パーフェクトオーダー |
| macd_weight | 1.0 | MACD クロス/ヒストグラム |
| adx_weight | 1.0 | ADX トレンド強度 |
| rsi_weight | 1.0 | RSI 過売られ/買われ |
| stoch_weight | 1.0 | Stochastic クロス |
| price_weight | 1.0 | 価格位置（BB/EMA） |
| candle_weight | 1.0 | ローソク足パターン |

### フィードバックループ

```
1. シグナル生成時: 各コンポーネントの個別スコアを保存 (indicators JSON)
2. トレード完了時: WIN/LOSE に応じて重みを更新
3. 次回シグナル生成時: 更新された重みでスコア計算
```

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2026-01-15 | 初版作成 |
