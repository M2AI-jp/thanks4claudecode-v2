import { CandlestickData, Time } from "lightweight-charts";
import {
  twelveDataService,
  INTERVALS,
  IntervalKey,
  PollingMode,
} from "./twelve-data-service";

export interface PriceData {
  timestamp: number;
  open: number;
  high: number;
  low: number;
  close: number;
  volume?: number;
}

export interface TickData {
  timestamp: number;
  price: number;
  bid: number;
  ask: number;
}

// Data source type
export type DataSource = "live" | "simulator";

// Simulated price generator for demo/development
class PriceSimulator {
  private basePrice: number = 150.0;
  private volatility: number = 0.0002;
  private trend: number = 0;
  private trendDuration: number = 0;

  generateTick(): TickData {
    // Random trend changes
    if (this.trendDuration <= 0) {
      this.trend = (Math.random() - 0.5) * 0.001;
      this.trendDuration = Math.floor(Math.random() * 60) + 30;
    }
    this.trendDuration--;

    // Price movement with trend and noise
    const noise = (Math.random() - 0.5) * this.volatility * this.basePrice;
    const trendMove = this.trend * this.basePrice;
    this.basePrice += trendMove + noise;

    // Keep price in reasonable range
    if (this.basePrice > 160) this.basePrice = 159.5;
    if (this.basePrice < 140) this.basePrice = 140.5;

    const spread = 0.003 + Math.random() * 0.002;
    const bid = this.basePrice;
    const ask = this.basePrice + spread;

    return {
      timestamp: Date.now(),
      price: (bid + ask) / 2,
      bid,
      ask,
    };
  }

  generateCandle(timeframe: number = 60000): PriceData {
    const ticks: TickData[] = [];
    const numTicks = Math.floor(timeframe / 1000);

    for (let i = 0; i < numTicks; i++) {
      ticks.push(this.generateTick());
    }

    const prices = ticks.map((t) => t.price);
    return {
      timestamp: Math.floor(Date.now() / timeframe) * timeframe,
      open: prices[0],
      high: Math.max(...prices),
      low: Math.min(...prices),
      close: prices[prices.length - 1],
    };
  }
}

// Price service singleton with hybrid data source
class PriceService {
  private simulator: PriceSimulator;
  private subscribers: Map<string, (data: TickData) => void> = new Map();
  private intervalId: NodeJS.Timeout | null = null;
  private currentPrice: TickData | null = null;
  private candleCache: Map<string, CandlestickData<Time>[]> = new Map();
  private lastCandleTime: Map<string, number> = new Map();
  private dataSource: DataSource = "simulator";

  constructor() {
    this.simulator = new PriceSimulator();
    // Check if Twelve Data is configured
    if (twelveDataService.isConfigured()) {
      this.dataSource = "live";
    }
  }

  // Get current data source
  getDataSource(): DataSource {
    return this.dataSource;
  }

  // Set data source
  setDataSource(source: DataSource): void {
    this.dataSource = source;
  }

  // Set polling mode (for smart polling)
  setPollingMode(mode: PollingMode): void {
    twelveDataService.setPollingMode(mode);
  }

  // Get API usage stats
  getApiStats() {
    return twelveDataService.getUsageStats();
  }

  // Start price updates
  start(intervalMs: number = 1000): void {
    if (this.intervalId) return;

    this.intervalId = setInterval(() => {
      this.currentPrice = this.simulator.generateTick();
      this.notifySubscribers();
    }, intervalMs);

    // Generate initial price
    this.currentPrice = this.simulator.generateTick();
  }

  // Stop price updates
  stop(): void {
    if (this.intervalId) {
      clearInterval(this.intervalId);
      this.intervalId = null;
    }
  }

  // Subscribe to price updates
  subscribe(id: string, callback: (data: TickData) => void): () => void {
    this.subscribers.set(id, callback);

    // Send current price immediately
    if (this.currentPrice) {
      callback(this.currentPrice);
    }

    return () => {
      this.subscribers.delete(id);
    };
  }

  // Get current price
  getCurrentPrice(): TickData | null {
    if (this.dataSource === "live") {
      return twelveDataService.getCurrentPrice() || this.currentPrice;
    }
    return this.currentPrice;
  }

  // Convert timeframe ms to interval key
  private timeframeToInterval(timeframeMs: number): IntervalKey {
    if (timeframeMs <= 60000) return "1m";
    if (timeframeMs <= 300000) return "5m";
    if (timeframeMs <= 900000) return "15m";
    return "1h";
  }

  // Get historical candles (async for live data)
  async getHistoricalCandlesAsync(
    count: number = 100,
    timeframeMs: number = 300000 // Default to 5min
  ): Promise<CandlestickData<Time>[]> {
    // Try live data first
    if (this.dataSource === "live" && twelveDataService.isConfigured()) {
      const intervalKey = this.timeframeToInterval(timeframeMs);
      const interval = INTERVALS[intervalKey];
      const candles = await twelveDataService.fetchTimeSeries(interval, count);

      if (candles.length > 0) {
        // Update current price from latest candle
        const latest = candles[candles.length - 1];
        this.currentPrice = {
          timestamp: Date.now(),
          price: latest.close,
          bid: latest.close - 0.001,
          ask: latest.close + 0.001,
        };
        return candles;
      }
    }

    // Fall back to simulator
    return this.getHistoricalCandles(count, timeframeMs);
  }

  // Get historical candles with caching (sync, for simulator)
  getHistoricalCandles(
    count: number = 100,
    timeframeMs: number = 60000
  ): CandlestickData<Time>[] {
    const cacheKey = `${timeframeMs}`;
    const now = Date.now();
    const currentCandleTime = Math.floor(now / timeframeMs) * timeframeMs;

    // Check if we have cached candles
    let candles = this.candleCache.get(cacheKey);

    // Initialize cache if empty or too old
    if (!candles || candles.length === 0) {
      candles = [];
      const tempSimulator = new PriceSimulator();

      for (let i = count - 1; i >= 0; i--) {
        const candleTime = currentCandleTime - i * timeframeMs;
        const time = Math.floor(candleTime / 1000) as Time;
        const candle = tempSimulator.generateCandle(timeframeMs);
        candles.push({
          time,
          open: candle.open,
          high: candle.high,
          low: candle.low,
          close: candle.close,
        });
      }

      this.candleCache.set(cacheKey, candles);
      this.lastCandleTime.set(cacheKey, currentCandleTime);
      return candles;
    }

    // Update current (last) candle with latest price
    if (this.currentPrice && candles.length > 0) {
      const lastCandle = candles[candles.length - 1];
      const expectedTime = Math.floor(currentCandleTime / 1000) as Time;

      // Check if we need a new candle
      if (lastCandle.time !== expectedTime) {
        // New candle period started
        const newCandle: CandlestickData<Time> = {
          time: expectedTime,
          open: this.currentPrice.price,
          high: this.currentPrice.price,
          low: this.currentPrice.price,
          close: this.currentPrice.price,
        };
        candles.push(newCandle);

        // Keep only the requested count
        if (candles.length > count) {
          candles.shift();
        }

        this.lastCandleTime.set(cacheKey, currentCandleTime);
      } else {
        // Update current candle
        lastCandle.high = Math.max(lastCandle.high, this.currentPrice.price);
        lastCandle.low = Math.min(lastCandle.low, this.currentPrice.price);
        lastCandle.close = this.currentPrice.price;
      }
    }

    this.candleCache.set(cacheKey, candles);
    return candles;
  }

  private notifySubscribers(): void {
    if (!this.currentPrice) return;
    this.subscribers.forEach((callback) => {
      callback(this.currentPrice!);
    });
  }
}

// Export singleton instance using globalThis for Next.js compatibility
const globalForPriceService = globalThis as unknown as {
  priceService: PriceService | undefined;
};

export const priceService =
  globalForPriceService.priceService ?? new PriceService();

if (process.env.NODE_ENV !== "production") {
  globalForPriceService.priceService = priceService;
}

// Start the price service
priceService.start(1000);

// Timeframe constants
export const TIMEFRAMES = {
  "1m": 60 * 1000,
  "5m": 5 * 60 * 1000,
  "15m": 15 * 60 * 1000,
  "1h": 60 * 60 * 1000,
} as const;

export type TimeframeKey = keyof typeof TIMEFRAMES;
