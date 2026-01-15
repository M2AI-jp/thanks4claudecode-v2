// Prediction Engine - Machine Learning based candlestick prediction
// Uses logistic regression with online learning (SGD + L2 regularization)

import {
  OHLC,
  ema,
  rsi,
  macd,
  stochastic,
  adx,
  bollingerBands,
  detectPerfectOrder,
} from "./indicators";

// Feature vector for ML model
export interface Features {
  // Trend indicators
  emaTrend: number; // EMA perfect order (-1, 0, 1)
  macdHist: number; // MACD histogram normalized
  adxStrength: number; // ADX normalized (0-1)

  // Oscillators
  rsiNorm: number; // RSI normalized (0-1)
  stochK: number; // Stochastic K normalized (0-1)
  stochCross: number; // Stoch cross signal (-1, 0, 1)

  // Price position
  bbPosition: number; // Position in BB (-1 to 1)
  priceMomentum: number; // Recent price momentum

  // Pattern
  candlePattern: number; // Last candle pattern (-1, 0, 1)
}

// Prediction result
export interface PredictionResult {
  direction: "HIGH" | "LOW";
  confidence: number; // 0-1
  probability: number; // Raw probability for HIGH
  features: Features;
}

// Weight names for persistence
export type WeightName = keyof Features | "bias";

// Default weights (initialized to small random values)
const DEFAULT_WEIGHTS: Record<WeightName, number> = {
  emaTrend: 0.1,
  macdHist: 0.1,
  adxStrength: 0.1,
  rsiNorm: 0.1,
  stochK: 0.1,
  stochCross: 0.1,
  bbPosition: 0.1,
  priceMomentum: 0.1,
  candlePattern: 0.1,
  bias: 0,
};

// Learning parameters
const LEARNING_RATE = 0.01;
const L2_LAMBDA = 0.001; // L2 regularization strength
const MIN_SAMPLES_FOR_PREDICTION = 50; // Minimum candles needed

class PredictionEngine {
  private weights: Record<WeightName, number>;
  private trainingCount: number = 0;
  private correctPredictions: number = 0;

  constructor() {
    this.weights = { ...DEFAULT_WEIGHTS };
  }

  /**
   * Extract features from OHLC data
   */
  extractFeatures(candles: OHLC[]): Features | null {
    if (candles.length < MIN_SAMPLES_FOR_PREDICTION) {
      return null;
    }

    const closes = candles.map((c) => c.close);
    const lastIndex = candles.length - 1;

    // EMA trend (5, 13, 21)
    const ema5 = ema(closes, 5);
    const ema13 = ema(closes, 13);
    const ema21 = ema(closes, 21);
    const { bullish, bearish } = detectPerfectOrder(ema5, ema13, ema21);
    const emaTrend = bullish[lastIndex] ? 1 : bearish[lastIndex] ? -1 : 0;

    // MACD histogram
    const macdResult = macd(closes, 12, 26, 9);
    const macdHist = macdResult.histogram[lastIndex];
    const macdHistNorm = isNaN(macdHist)
      ? 0
      : Math.tanh(macdHist * 100); // Normalize with tanh

    // ADX strength
    const adxResult = adx(candles, 14);
    const adxValue = adxResult.adx[lastIndex];
    const adxStrength = isNaN(adxValue) ? 0.5 : adxValue / 100;

    // RSI normalized
    const rsiValues = rsi(closes, 14);
    const rsiValue = rsiValues[lastIndex];
    const rsiNorm = isNaN(rsiValue) ? 0.5 : rsiValue / 100;

    // Stochastic
    const stochResult = stochastic(candles, 14, 3, 3);
    const stochKValue = stochResult.k[lastIndex];
    const stochDValue = stochResult.d[lastIndex];
    const stochK = isNaN(stochKValue) ? 0.5 : stochKValue / 100;

    // Stoch cross detection
    let stochCross = 0;
    if (lastIndex > 0 && !isNaN(stochKValue) && !isNaN(stochDValue)) {
      const prevK = stochResult.k[lastIndex - 1];
      const prevD = stochResult.d[lastIndex - 1];
      if (!isNaN(prevK) && !isNaN(prevD)) {
        if (prevK <= prevD && stochKValue > stochDValue) {
          stochCross = 1; // Bullish cross
        } else if (prevK >= prevD && stochKValue < stochDValue) {
          stochCross = -1; // Bearish cross
        }
      }
    }

    // Bollinger Bands position
    const bbResult = bollingerBands(closes, 20, 2);
    const bbUpper = bbResult.upper[lastIndex];
    const bbLower = bbResult.lower[lastIndex];
    const bbMiddle = bbResult.middle[lastIndex];
    let bbPosition = 0;
    if (!isNaN(bbUpper) && !isNaN(bbLower) && bbUpper !== bbLower) {
      const currentClose = closes[lastIndex];
      bbPosition = (2 * (currentClose - bbMiddle)) / (bbUpper - bbLower);
      bbPosition = Math.max(-1, Math.min(1, bbPosition));
    }

    // Price momentum (last 5 candles)
    let priceMomentum = 0;
    if (lastIndex >= 5) {
      const momentum = closes[lastIndex] - closes[lastIndex - 5];
      const avgPrice = closes[lastIndex];
      priceMomentum = Math.tanh((momentum / avgPrice) * 100);
    }

    // Candle pattern (current candle)
    const currentCandle = candles[lastIndex];
    const candleBody = currentCandle.close - currentCandle.open;
    const candleRange = currentCandle.high - currentCandle.low;
    const candlePattern =
      candleRange === 0 ? 0 : Math.tanh((candleBody / candleRange) * 2);

    return {
      emaTrend,
      macdHist: macdHistNorm,
      adxStrength,
      rsiNorm,
      stochK,
      stochCross,
      bbPosition,
      priceMomentum,
      candlePattern,
    };
  }

  /**
   * Sigmoid function
   */
  private sigmoid(x: number): number {
    return 1 / (1 + Math.exp(-x));
  }

  /**
   * Calculate weighted sum
   */
  private weightedSum(features: Features): number {
    let sum = this.weights.bias;

    sum += features.emaTrend * this.weights.emaTrend;
    sum += features.macdHist * this.weights.macdHist;
    sum += features.adxStrength * this.weights.adxStrength;
    sum += features.rsiNorm * this.weights.rsiNorm;
    sum += features.stochK * this.weights.stochK;
    sum += features.stochCross * this.weights.stochCross;
    sum += features.bbPosition * this.weights.bbPosition;
    sum += features.priceMomentum * this.weights.priceMomentum;
    sum += features.candlePattern * this.weights.candlePattern;

    return sum;
  }

  /**
   * Predict next candle direction
   */
  predict(candles: OHLC[]): PredictionResult | null {
    const features = this.extractFeatures(candles);
    if (!features) {
      return null;
    }

    const weightedSum = this.weightedSum(features);
    const probability = this.sigmoid(weightedSum);

    // Confidence is how far from 0.5 (uncertainty)
    const confidence = Math.abs(probability - 0.5) * 2;

    return {
      direction: probability >= 0.5 ? "HIGH" : "LOW",
      confidence,
      probability,
      features,
    };
  }

  /**
   * Train model with actual result (online learning with SGD)
   */
  train(
    features: Features,
    actualDirection: "HIGH" | "LOW"
  ): { loss: number; accuracy: number } {
    const y = actualDirection === "HIGH" ? 1 : 0;
    const weightedSum = this.weightedSum(features);
    const prediction = this.sigmoid(weightedSum);

    // Binary cross-entropy loss
    const loss = -(y * Math.log(prediction + 1e-15) + (1 - y) * Math.log(1 - prediction + 1e-15));

    // Gradient: (prediction - y) * feature
    const error = prediction - y;

    // Update weights with SGD + L2 regularization
    const featureKeys: (keyof Features)[] = [
      "emaTrend",
      "macdHist",
      "adxStrength",
      "rsiNorm",
      "stochK",
      "stochCross",
      "bbPosition",
      "priceMomentum",
      "candlePattern",
    ];

    for (const key of featureKeys) {
      const gradient = error * features[key];
      const l2Term = L2_LAMBDA * this.weights[key];
      this.weights[key] -= LEARNING_RATE * (gradient + l2Term);
    }

    // Update bias (no L2 for bias)
    this.weights.bias -= LEARNING_RATE * error;

    // Track accuracy
    this.trainingCount++;
    const predictedDirection = prediction >= 0.5 ? "HIGH" : "LOW";
    if (predictedDirection === actualDirection) {
      this.correctPredictions++;
    }

    const accuracy =
      this.trainingCount > 0
        ? this.correctPredictions / this.trainingCount
        : 0;

    return { loss, accuracy };
  }

  /**
   * Get current weights
   */
  getWeights(): Record<WeightName, number> {
    return { ...this.weights };
  }

  /**
   * Set weights (for loading from DB)
   */
  setWeights(weights: Record<WeightName, number>): void {
    this.weights = { ...weights };
  }

  /**
   * Get training statistics
   */
  getStats(): { trainingCount: number; accuracy: number } {
    return {
      trainingCount: this.trainingCount,
      accuracy:
        this.trainingCount > 0
          ? this.correctPredictions / this.trainingCount
          : 0,
    };
  }

  /**
   * Reset model to default weights
   */
  reset(): void {
    this.weights = { ...DEFAULT_WEIGHTS };
    this.trainingCount = 0;
    this.correctPredictions = 0;
  }
}

// Singleton instance
export const predictionEngine = new PredictionEngine();

// Export class for testing
export { PredictionEngine };
