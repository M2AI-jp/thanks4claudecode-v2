// Signal Generator based on Pine Script logic
import {
  OHLC,
  ema,
  rsi,
  macd,
  stochastic,
  adx,
  bollingerBands,
  atr,
  detectPerfectOrder,
  crossover,
  crossunder,
} from "./indicators";
import {
  learningEngine,
  type WeightName,
  DEFAULT_WEIGHTS,
} from "./learning-engine";

export interface SignalResult {
  direction: "HIGH" | "LOW" | null;
  score: number;
  details: SignalDetails;
  timestamp: number;
}

export interface SignalDetails {
  // Indicator values
  rsi: number;
  macdLine: number;
  macdSignal: number;
  macdHistogram: number;
  stochK: number;
  stochD: number;
  adxValue: number;
  plusDI: number;
  minusDI: number;
  atrValue: number;

  // EMA values
  emaFast: number;
  emaMid: number;
  emaSlow: number;
  perfectOrderBull: boolean;
  perfectOrderBear: boolean;

  // Bollinger Bands
  bbUpper: number;
  bbMiddle: number;
  bbLower: number;

  // Scoring breakdown
  highScore: number;
  lowScore: number;
  highComponents: ScoreComponents;
  lowComponents: ScoreComponents;

  // Triggers
  macdCrossUp: boolean;
  macdCrossDown: boolean;
  stochCrossUp: boolean;
  stochCrossDown: boolean;

  // Conditions
  strongTrend: boolean;
  volatilityOK: boolean;
}

export interface ScoreComponents {
  ema: number;
  macd: number;
  adx: number;
  rsi: number;
  stoch: number;
  price: number;
  candle: number;
  total: number;
}

export interface SignalGeneratorConfig {
  strictLevel: 1 | 2 | 3;
  minScore: number;
  cooldownBars: number;
  emaPeriods: [number, number, number];
  rsiPeriod: number;
  rsiOverbought: number;
  rsiOversold: number;
  macdFast: number;
  macdSlow: number;
  macdSignal: number;
  stochK: number;
  stochD: number;
  stochSmooth: number;
  stochOB: number;
  stochOS: number;
  adxPeriod: number;
  adxThreshold: number;
  bbPeriod: number;
  bbStdDev: number;
  atrPeriod: number;
}

const DEFAULT_CONFIG: SignalGeneratorConfig = {
  strictLevel: 2,
  minScore: 4,
  cooldownBars: 10,
  emaPeriods: [5, 13, 21],
  rsiPeriod: 14,
  rsiOverbought: 70,
  rsiOversold: 30,
  macdFast: 12,
  macdSlow: 26,
  macdSignal: 9,
  stochK: 14,
  stochD: 3,
  stochSmooth: 3,
  stochOB: 80,
  stochOS: 20,
  adxPeriod: 14,
  adxThreshold: 25,
  bbPeriod: 20,
  bbStdDev: 2,
  atrPeriod: 14,
};

export class SignalGenerator {
  private config: SignalGeneratorConfig;
  private lastSignalBar: number = -999;

  constructor(config: Partial<SignalGeneratorConfig> = {}) {
    this.config = { ...DEFAULT_CONFIG, ...config };
  }

  updateConfig(config: Partial<SignalGeneratorConfig>): void {
    this.config = { ...this.config, ...config };
  }

  async generate(candles: OHLC[]): Promise<SignalResult> {
    if (candles.length < 50) {
      return {
        direction: null,
        score: 0,
        details: this.getEmptyDetails(),
        timestamp: Date.now(),
      };
    }

    // Get weights from learning engine
    let weights: Record<WeightName, number>;
    try {
      weights = await learningEngine.getWeights();
    } catch {
      weights = DEFAULT_WEIGHTS;
    }

    const closes = candles.map((c) => c.close);
    const currentIdx = candles.length - 1;

    // Calculate indicators
    const emaFast = ema(closes, this.config.emaPeriods[0]);
    const emaMid = ema(closes, this.config.emaPeriods[1]);
    const emaSlow = ema(closes, this.config.emaPeriods[2]);
    const { bullish: poBull, bearish: poBear } = detectPerfectOrder(
      emaFast,
      emaMid,
      emaSlow
    );

    const rsiValues = rsi(closes, this.config.rsiPeriod);
    const macdResult = macd(
      closes,
      this.config.macdFast,
      this.config.macdSlow,
      this.config.macdSignal
    );
    const stochResult = stochastic(
      candles,
      this.config.stochK,
      this.config.stochD,
      this.config.stochSmooth
    );
    const adxResult = adx(candles, this.config.adxPeriod);
    const bbResult = bollingerBands(
      closes,
      this.config.bbPeriod,
      this.config.bbStdDev
    );
    const atrValues = atr(candles, this.config.atrPeriod);
    const atrMA = ema(atrValues, 50);

    // Cross detections
    const macdCrossUp = crossover(macdResult.macd, macdResult.signal);
    const macdCrossDown = crossunder(macdResult.macd, macdResult.signal);
    const stochCrossUp = crossover(stochResult.k, stochResult.d);
    const stochCrossDown = crossunder(stochResult.k, stochResult.d);

    // Current values
    const currentRsi = rsiValues[currentIdx];
    const currentMacdLine = macdResult.macd[currentIdx];
    const currentMacdSignal = macdResult.signal[currentIdx];
    const currentMacdHist = macdResult.histogram[currentIdx];
    const currentStochK = stochResult.k[currentIdx];
    const currentStochD = stochResult.d[currentIdx];
    const currentAdx = adxResult.adx[currentIdx];
    const currentPlusDI = adxResult.plusDI[currentIdx];
    const currentMinusDI = adxResult.minusDI[currentIdx];
    const currentAtr = atrValues[currentIdx];
    const currentAtrMA = atrMA[currentIdx];
    const currentClose = closes[currentIdx];
    const currentEmaFast = emaFast[currentIdx];
    const currentEmaMid = emaMid[currentIdx];
    const currentEmaSlow = emaSlow[currentIdx];
    const currentBbUpper = bbResult.upper[currentIdx];
    const currentBbMiddle = bbResult.middle[currentIdx];
    const currentBbLower = bbResult.lower[currentIdx];

    // Conditions
    const strongTrend = currentAdx > this.config.adxThreshold;
    const bullDI = currentPlusDI > currentMinusDI;
    const bearDI = currentMinusDI > currentPlusDI;
    const volatilityOK = currentAtr > currentAtrMA * 0.7;

    // Calculate HIGH score with weights
    const highComponents = this.calculateHighScore(
      poBull[currentIdx],
      emaFast,
      currentIdx,
      macdCrossUp[currentIdx],
      currentMacdLine > currentMacdSignal,
      macdResult.histogram,
      strongTrend,
      bullDI,
      currentRsi,
      stochCrossUp[currentIdx],
      currentStochK,
      currentClose,
      currentEmaFast,
      currentEmaMid,
      currentBbMiddle,
      candles,
      weights
    );

    // Calculate LOW score with weights
    const lowComponents = this.calculateLowScore(
      poBear[currentIdx],
      emaFast,
      currentIdx,
      macdCrossDown[currentIdx],
      currentMacdLine < currentMacdSignal,
      macdResult.histogram,
      strongTrend,
      bearDI,
      currentRsi,
      stochCrossDown[currentIdx],
      currentStochK,
      currentClose,
      currentEmaFast,
      currentEmaMid,
      currentBbMiddle,
      candles,
      weights
    );

    // Determine signal
    const weightMult =
      this.config.strictLevel === 1
        ? 1.0
        : this.config.strictLevel === 2
        ? 1.2
        : 1.5;
    const adjustedMinScore = this.config.minScore * weightMult;

    // Triggers check based on strict level
    const highTrigger =
      macdCrossUp[currentIdx] ||
      stochCrossUp[currentIdx];
    const lowTrigger =
      macdCrossDown[currentIdx] ||
      stochCrossDown[currentIdx];

    const highMust =
      this.config.strictLevel === 1
        ? strongTrend
        : this.config.strictLevel === 2
        ? strongTrend && bullDI
        : strongTrend && bullDI && highTrigger;

    const lowMust =
      this.config.strictLevel === 1
        ? strongTrend
        : this.config.strictLevel === 2
        ? strongTrend && bearDI
        : strongTrend && bearDI && lowTrigger;

    // Cooldown check
    const cooldownOK = currentIdx - this.lastSignalBar >= this.config.cooldownBars;

    // Final signal determination
    let direction: "HIGH" | "LOW" | null = null;
    let score = 0;

    const highSignal =
      highComponents.total >= adjustedMinScore &&
      lowComponents.total < highComponents.total * 0.3 &&
      highMust &&
      volatilityOK &&
      cooldownOK;

    const lowSignal =
      lowComponents.total >= adjustedMinScore &&
      highComponents.total < lowComponents.total * 0.3 &&
      lowMust &&
      volatilityOK &&
      cooldownOK;

    if (highSignal) {
      direction = "HIGH";
      score = highComponents.total;
      this.lastSignalBar = currentIdx;
    } else if (lowSignal) {
      direction = "LOW";
      score = lowComponents.total;
      this.lastSignalBar = currentIdx;
    }

    return {
      direction,
      score,
      timestamp: Date.now(),
      details: {
        rsi: currentRsi,
        macdLine: currentMacdLine,
        macdSignal: currentMacdSignal,
        macdHistogram: currentMacdHist,
        stochK: currentStochK,
        stochD: currentStochD,
        adxValue: currentAdx,
        plusDI: currentPlusDI,
        minusDI: currentMinusDI,
        atrValue: currentAtr,
        emaFast: currentEmaFast,
        emaMid: currentEmaMid,
        emaSlow: currentEmaSlow,
        perfectOrderBull: poBull[currentIdx],
        perfectOrderBear: poBear[currentIdx],
        bbUpper: currentBbUpper,
        bbMiddle: currentBbMiddle,
        bbLower: currentBbLower,
        highScore: highComponents.total,
        lowScore: lowComponents.total,
        highComponents,
        lowComponents,
        macdCrossUp: macdCrossUp[currentIdx],
        macdCrossDown: macdCrossDown[currentIdx],
        stochCrossUp: stochCrossUp[currentIdx],
        stochCrossDown: stochCrossDown[currentIdx],
        strongTrend,
        volatilityOK,
      },
    };
  }

  private calculateHighScore(
    perfectOrder: boolean,
    emaFast: number[],
    idx: number,
    macdCrossUp: boolean,
    macdBull: boolean,
    macdHist: number[],
    strongTrend: boolean,
    bullDI: boolean,
    rsiValue: number,
    stochCrossUp: boolean,
    stochK: number,
    close: number,
    emaF: number,
    emaM: number,
    bbMid: number,
    candles: OHLC[],
    weights: Record<WeightName, number>
  ): ScoreComponents {
    // EMA rising check
    const emaRising =
      emaFast[idx] > emaFast[idx - 1] && emaFast[idx - 1] > emaFast[idx - 2];

    // Histogram rising
    const histRising =
      macdHist[idx] > macdHist[idx - 1] &&
      macdHist[idx - 1] > macdHist[idx - 2];

    // Recent candles bullish
    const recentBull =
      (candles[idx].close > candles[idx].open ? 1 : 0) +
        (candles[idx - 1].close > candles[idx - 1].open ? 1 : 0) +
        (candles[idx - 2].close > candles[idx - 2].open ? 1 : 0) >=
      2;

    // Calculate base scores
    const emaBase = perfectOrder && emaRising ? 2.0 : perfectOrder ? 1.0 : 0.5;
    const macdBase = macdCrossUp
      ? 2.5
      : macdBull && histRising
      ? 1.5
      : macdBull
      ? 0.5
      : 0;
    const adxBase = strongTrend && bullDI ? 2.0 : bullDI ? 0.5 : 0;
    const rsiBase = rsiValue < 30 ? 1.5 : rsiValue < 45 ? 0.5 : 0;
    const stochBase = stochCrossUp && stochK < 50 ? 2.0 : stochK < 20 ? 1.0 : 0;
    const priceBase = close > emaF && close > emaM && close > bbMid ? 1.0 : 0;
    const candleBase = recentBull ? 0.5 : 0;

    // Apply weights from learning engine
    const emaScore = emaBase * weights.ema_weight;
    const macdScore = macdBase * weights.macd_weight;
    const adxScore = adxBase * weights.adx_weight;
    const rsiScore = rsiBase * weights.rsi_weight;
    const stochScore = stochBase * weights.stoch_weight;
    const priceScore = priceBase * weights.price_weight;
    const candleScore = candleBase * weights.candle_weight;

    return {
      ema: emaScore,
      macd: macdScore,
      adx: adxScore,
      rsi: rsiScore,
      stoch: stochScore,
      price: priceScore,
      candle: candleScore,
      total:
        emaScore +
        macdScore +
        adxScore +
        rsiScore +
        stochScore +
        priceScore +
        candleScore,
    };
  }

  private calculateLowScore(
    perfectOrder: boolean,
    emaFast: number[],
    idx: number,
    macdCrossDown: boolean,
    macdBear: boolean,
    macdHist: number[],
    strongTrend: boolean,
    bearDI: boolean,
    rsiValue: number,
    stochCrossDown: boolean,
    stochK: number,
    close: number,
    emaF: number,
    emaM: number,
    bbMid: number,
    candles: OHLC[],
    weights: Record<WeightName, number>
  ): ScoreComponents {
    // EMA falling check
    const emaFalling =
      emaFast[idx] < emaFast[idx - 1] && emaFast[idx - 1] < emaFast[idx - 2];

    // Histogram falling
    const histFalling =
      macdHist[idx] < macdHist[idx - 1] &&
      macdHist[idx - 1] < macdHist[idx - 2];

    // Recent candles bearish
    const recentBear =
      (candles[idx].close < candles[idx].open ? 1 : 0) +
        (candles[idx - 1].close < candles[idx - 1].open ? 1 : 0) +
        (candles[idx - 2].close < candles[idx - 2].open ? 1 : 0) >=
      2;

    // Calculate base scores
    const emaBase = perfectOrder && emaFalling ? 2.0 : perfectOrder ? 1.0 : 0.5;
    const macdBase = macdCrossDown
      ? 2.5
      : macdBear && histFalling
      ? 1.5
      : macdBear
      ? 0.5
      : 0;
    const adxBase = strongTrend && bearDI ? 2.0 : bearDI ? 0.5 : 0;
    const rsiBase = rsiValue > 70 ? 1.5 : rsiValue > 55 ? 0.5 : 0;
    const stochBase = stochCrossDown && stochK > 50 ? 2.0 : stochK > 80 ? 1.0 : 0;
    const priceBase = close < emaF && close < emaM && close < bbMid ? 1.0 : 0;
    const candleBase = recentBear ? 0.5 : 0;

    // Apply weights from learning engine
    const emaScore = emaBase * weights.ema_weight;
    const macdScore = macdBase * weights.macd_weight;
    const adxScore = adxBase * weights.adx_weight;
    const rsiScore = rsiBase * weights.rsi_weight;
    const stochScore = stochBase * weights.stoch_weight;
    const priceScore = priceBase * weights.price_weight;
    const candleScore = candleBase * weights.candle_weight;

    return {
      ema: emaScore,
      macd: macdScore,
      adx: adxScore,
      rsi: rsiScore,
      stoch: stochScore,
      price: priceScore,
      candle: candleScore,
      total:
        emaScore +
        macdScore +
        adxScore +
        rsiScore +
        stochScore +
        priceScore +
        candleScore,
    };
  }

  private getEmptyDetails(): SignalDetails {
    return {
      rsi: 0,
      macdLine: 0,
      macdSignal: 0,
      macdHistogram: 0,
      stochK: 0,
      stochD: 0,
      adxValue: 0,
      plusDI: 0,
      minusDI: 0,
      atrValue: 0,
      emaFast: 0,
      emaMid: 0,
      emaSlow: 0,
      perfectOrderBull: false,
      perfectOrderBear: false,
      bbUpper: 0,
      bbMiddle: 0,
      bbLower: 0,
      highScore: 0,
      lowScore: 0,
      highComponents: {
        ema: 0,
        macd: 0,
        adx: 0,
        rsi: 0,
        stoch: 0,
        price: 0,
        candle: 0,
        total: 0,
      },
      lowComponents: {
        ema: 0,
        macd: 0,
        adx: 0,
        rsi: 0,
        stoch: 0,
        price: 0,
        candle: 0,
        total: 0,
      },
      macdCrossUp: false,
      macdCrossDown: false,
      stochCrossUp: false,
      stochCrossDown: false,
      strongTrend: false,
      volatilityOK: false,
    };
  }
}

// Singleton instance
export const signalGenerator = new SignalGenerator();
