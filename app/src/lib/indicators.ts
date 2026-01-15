// Technical Indicators Library
// Based on Pine Script logic from TradingView

export interface OHLC {
  open: number;
  high: number;
  low: number;
  close: number;
}

// Simple Moving Average
export function sma(data: number[], period: number): number[] {
  const result: number[] = [];
  for (let i = 0; i < data.length; i++) {
    if (i < period - 1) {
      result.push(NaN);
      continue;
    }
    let sum = 0;
    for (let j = 0; j < period; j++) {
      sum += data[i - j];
    }
    result.push(sum / period);
  }
  return result;
}

// Exponential Moving Average
export function ema(data: number[], period: number): number[] {
  const result: number[] = [];
  const multiplier = 2 / (period + 1);

  for (let i = 0; i < data.length; i++) {
    if (i < period - 1) {
      result.push(NaN);
      continue;
    }
    if (i === period - 1) {
      let sum = 0;
      for (let j = 0; j < period; j++) {
        sum += data[i - j];
      }
      result.push(sum / period);
    } else {
      result.push((data[i] - result[i - 1]) * multiplier + result[i - 1]);
    }
  }
  return result;
}

// RSI (Relative Strength Index)
export function rsi(closes: number[], period: number = 14): number[] {
  const result: number[] = [];
  const gains: number[] = [];
  const losses: number[] = [];

  for (let i = 0; i < closes.length; i++) {
    if (i === 0) {
      gains.push(0);
      losses.push(0);
      result.push(NaN);
      continue;
    }

    const change = closes[i] - closes[i - 1];
    gains.push(change > 0 ? change : 0);
    losses.push(change < 0 ? -change : 0);

    if (i < period) {
      result.push(NaN);
      continue;
    }

    if (i === period) {
      let avgGain = 0;
      let avgLoss = 0;
      for (let j = 1; j <= period; j++) {
        avgGain += gains[j];
        avgLoss += losses[j];
      }
      avgGain /= period;
      avgLoss /= period;

      if (avgLoss === 0) {
        result.push(100);
      } else {
        const rs = avgGain / avgLoss;
        result.push(100 - 100 / (1 + rs));
      }
    } else {
      const prevRsi = result[i - 1];
      const avgGain =
        ((100 / (100 - prevRsi) - 1) * (period - 1) + gains[i]) / period;
      const avgLoss = (1 * (period - 1) + losses[i]) / period;

      if (avgLoss === 0) {
        result.push(100);
      } else {
        const rs = avgGain / avgLoss;
        result.push(100 - 100 / (1 + rs));
      }
    }
  }
  return result;
}

// MACD
export interface MACDResult {
  macd: number[];
  signal: number[];
  histogram: number[];
}

export function macd(
  closes: number[],
  fastPeriod: number = 12,
  slowPeriod: number = 26,
  signalPeriod: number = 9
): MACDResult {
  const fastEma = ema(closes, fastPeriod);
  const slowEma = ema(closes, slowPeriod);

  const macdLine: number[] = [];
  for (let i = 0; i < closes.length; i++) {
    if (isNaN(fastEma[i]) || isNaN(slowEma[i])) {
      macdLine.push(NaN);
    } else {
      macdLine.push(fastEma[i] - slowEma[i]);
    }
  }

  const signalLine = ema(
    macdLine.filter((v) => !isNaN(v)),
    signalPeriod
  );

  // Pad signal line with NaN to match length
  const paddedSignal: number[] = [];
  let signalIdx = 0;
  for (let i = 0; i < closes.length; i++) {
    if (isNaN(macdLine[i])) {
      paddedSignal.push(NaN);
    } else if (signalIdx < signalLine.length) {
      paddedSignal.push(signalLine[signalIdx]);
      signalIdx++;
    } else {
      paddedSignal.push(NaN);
    }
  }

  const histogram: number[] = [];
  for (let i = 0; i < closes.length; i++) {
    if (isNaN(macdLine[i]) || isNaN(paddedSignal[i])) {
      histogram.push(NaN);
    } else {
      histogram.push(macdLine[i] - paddedSignal[i]);
    }
  }

  return { macd: macdLine, signal: paddedSignal, histogram };
}

// Stochastic
export interface StochasticResult {
  k: number[];
  d: number[];
}

export function stochastic(
  candles: OHLC[],
  kPeriod: number = 14,
  dPeriod: number = 3,
  smooth: number = 3
): StochasticResult {
  const rawK: number[] = [];

  for (let i = 0; i < candles.length; i++) {
    if (i < kPeriod - 1) {
      rawK.push(NaN);
      continue;
    }

    let highestHigh = -Infinity;
    let lowestLow = Infinity;
    for (let j = 0; j < kPeriod; j++) {
      highestHigh = Math.max(highestHigh, candles[i - j].high);
      lowestLow = Math.min(lowestLow, candles[i - j].low);
    }

    const range = highestHigh - lowestLow;
    if (range === 0) {
      rawK.push(50);
    } else {
      rawK.push(((candles[i].close - lowestLow) / range) * 100);
    }
  }

  const k = sma(rawK, smooth);
  const d = sma(k, dPeriod);

  return { k, d };
}

// ADX (Average Directional Index)
export interface ADXResult {
  adx: number[];
  plusDI: number[];
  minusDI: number[];
}

export function adx(candles: OHLC[], period: number = 14): ADXResult {
  const tr: number[] = [];
  const plusDM: number[] = [];
  const minusDM: number[] = [];

  for (let i = 0; i < candles.length; i++) {
    if (i === 0) {
      tr.push(candles[i].high - candles[i].low);
      plusDM.push(0);
      minusDM.push(0);
      continue;
    }

    const highDiff = candles[i].high - candles[i - 1].high;
    const lowDiff = candles[i - 1].low - candles[i].low;

    tr.push(
      Math.max(
        candles[i].high - candles[i].low,
        Math.abs(candles[i].high - candles[i - 1].close),
        Math.abs(candles[i].low - candles[i - 1].close)
      )
    );

    plusDM.push(highDiff > lowDiff && highDiff > 0 ? highDiff : 0);
    minusDM.push(lowDiff > highDiff && lowDiff > 0 ? lowDiff : 0);
  }

  const smoothTR = ema(tr, period);
  const smoothPlusDM = ema(plusDM, period);
  const smoothMinusDM = ema(minusDM, period);

  const plusDI: number[] = [];
  const minusDI: number[] = [];
  const dx: number[] = [];

  for (let i = 0; i < candles.length; i++) {
    if (isNaN(smoothTR[i]) || smoothTR[i] === 0) {
      plusDI.push(NaN);
      minusDI.push(NaN);
      dx.push(NaN);
      continue;
    }

    const pdi = (smoothPlusDM[i] / smoothTR[i]) * 100;
    const mdi = (smoothMinusDM[i] / smoothTR[i]) * 100;
    plusDI.push(pdi);
    minusDI.push(mdi);

    const diSum = pdi + mdi;
    if (diSum === 0) {
      dx.push(0);
    } else {
      dx.push((Math.abs(pdi - mdi) / diSum) * 100);
    }
  }

  const adxLine = ema(dx, period);

  return { adx: adxLine, plusDI, minusDI };
}

// Bollinger Bands
export interface BollingerBandsResult {
  middle: number[];
  upper: number[];
  lower: number[];
  bandwidth: number[];
}

export function bollingerBands(
  closes: number[],
  period: number = 20,
  stdDev: number = 2
): BollingerBandsResult {
  const middle = sma(closes, period);
  const upper: number[] = [];
  const lower: number[] = [];
  const bandwidth: number[] = [];

  for (let i = 0; i < closes.length; i++) {
    if (i < period - 1) {
      upper.push(NaN);
      lower.push(NaN);
      bandwidth.push(NaN);
      continue;
    }

    let squaredSum = 0;
    for (let j = 0; j < period; j++) {
      squaredSum += Math.pow(closes[i - j] - middle[i], 2);
    }
    const std = Math.sqrt(squaredSum / period);

    upper.push(middle[i] + stdDev * std);
    lower.push(middle[i] - stdDev * std);
    bandwidth.push(((upper[i] - lower[i]) / middle[i]) * 100);
  }

  return { middle, upper, lower, bandwidth };
}

// ATR (Average True Range)
export function atr(candles: OHLC[], period: number = 14): number[] {
  const tr: number[] = [];

  for (let i = 0; i < candles.length; i++) {
    if (i === 0) {
      tr.push(candles[i].high - candles[i].low);
      continue;
    }

    tr.push(
      Math.max(
        candles[i].high - candles[i].low,
        Math.abs(candles[i].high - candles[i - 1].close),
        Math.abs(candles[i].low - candles[i - 1].close)
      )
    );
  }

  return ema(tr, period);
}

// Perfect Order detection
export function detectPerfectOrder(
  emaFast: number[],
  emaMid: number[],
  emaSlow: number[]
): { bullish: boolean[]; bearish: boolean[] } {
  const bullish: boolean[] = [];
  const bearish: boolean[] = [];

  for (let i = 0; i < emaFast.length; i++) {
    if (isNaN(emaFast[i]) || isNaN(emaMid[i]) || isNaN(emaSlow[i])) {
      bullish.push(false);
      bearish.push(false);
      continue;
    }

    bullish.push(emaFast[i] > emaMid[i] && emaMid[i] > emaSlow[i]);
    bearish.push(emaFast[i] < emaMid[i] && emaMid[i] < emaSlow[i]);
  }

  return { bullish, bearish };
}

// Cross detection
export function crossover(series1: number[], series2: number[]): boolean[] {
  const result: boolean[] = [];
  for (let i = 0; i < series1.length; i++) {
    if (i === 0) {
      result.push(false);
      continue;
    }
    result.push(
      series1[i] > series2[i] && series1[i - 1] <= series2[i - 1]
    );
  }
  return result;
}

export function crossunder(series1: number[], series2: number[]): boolean[] {
  const result: boolean[] = [];
  for (let i = 0; i < series1.length; i++) {
    if (i === 0) {
      result.push(false);
      continue;
    }
    result.push(
      series1[i] < series2[i] && series1[i - 1] >= series2[i - 1]
    );
  }
  return result;
}
