import { CandlestickData, Time } from "lightweight-charts";

// JST offset in seconds (adjusted for Twelve Data API)
const JST_OFFSET_SECONDS = 7 * 60 * 60;

export interface TwelveDataConfig {
  apiKey: string;
  symbol?: string;
}

export interface TickData {
  timestamp: number;
  price: number;
  bid: number;
  ask: number;
}

interface TwelveDataTimeSeries {
  meta: {
    symbol: string;
    interval: string;
    currency_base: string;
    currency_quote: string;
    type: string;
  };
  values: Array<{
    datetime: string;
    open: string;
    high: string;
    low: string;
    close: string;
  }>;
  status: string;
}

interface TwelveDataQuote {
  symbol: string;
  name: string;
  exchange: string;
  datetime: string;
  timestamp: number;
  open: string;
  high: string;
  low: string;
  close: string;
  previous_close: string;
  change: string;
  percent_change: string;
}

// Polling mode for smart API usage
export type PollingMode = "normal" | "signal";

// Twelve Data API Service
class TwelveDataService {
  private apiKey: string | null = null;
  private symbol: string = "USD/JPY";
  private baseUrl: string = "https://api.twelvedata.com";

  // Cache for candles
  private candleCache: Map<string, CandlestickData<Time>[]> = new Map();
  private lastFetchTime: Map<string, number> = new Map();
  private currentPrice: TickData | null = null;

  // Polling management
  private pollingMode: PollingMode = "normal";
  private apiCallsToday: number = 0;
  private lastResetDate: string = "";

  // Rate limiting
  private readonly DAILY_LIMIT = 800;
  private readonly NORMAL_INTERVAL = 5 * 60 * 1000; // 5 minutes
  private readonly SIGNAL_INTERVAL = 30 * 1000; // 30 seconds

  constructor(config?: TwelveDataConfig) {
    if (config?.apiKey) {
      this.apiKey = config.apiKey;
    }
    if (config?.symbol) {
      this.symbol = config.symbol;
    }
    this.resetDailyCounterIfNeeded();
  }

  // Set API key
  setApiKey(apiKey: string): void {
    this.apiKey = apiKey;
  }

  // Get current polling interval based on mode
  getPollingInterval(): number {
    return this.pollingMode === "signal"
      ? this.SIGNAL_INTERVAL
      : this.NORMAL_INTERVAL;
  }

  // Set polling mode
  setPollingMode(mode: PollingMode): void {
    this.pollingMode = mode;
  }

  // Check if API is configured
  isConfigured(): boolean {
    return this.apiKey !== null && this.apiKey.length > 0;
  }

  // Reset daily counter if new day
  private resetDailyCounterIfNeeded(): void {
    const today = new Date().toISOString().split("T")[0];
    if (this.lastResetDate !== today) {
      this.apiCallsToday = 0;
      this.lastResetDate = today;
    }
  }

  // Check if we can make an API call
  private canMakeApiCall(): boolean {
    this.resetDailyCounterIfNeeded();
    return this.apiCallsToday < this.DAILY_LIMIT;
  }

  // Get remaining API calls
  getRemainingCalls(): number {
    this.resetDailyCounterIfNeeded();
    return Math.max(0, this.DAILY_LIMIT - this.apiCallsToday);
  }

  // Fetch time series data from Twelve Data
  async fetchTimeSeries(
    interval: string = "5min",
    outputsize: number = 200
  ): Promise<CandlestickData<Time>[]> {
    if (!this.isConfigured()) {
      console.warn("Twelve Data API key not configured");
      return [];
    }

    if (!this.canMakeApiCall()) {
      console.warn("Daily API limit reached, using cached data");
      return this.candleCache.get(interval) || [];
    }

    const cacheKey = `${this.symbol}_${interval}`;
    const lastFetch = this.lastFetchTime.get(cacheKey) || 0;
    const minInterval = this.getPollingInterval();

    // Check if we should use cache
    if (Date.now() - lastFetch < minInterval) {
      const cached = this.candleCache.get(cacheKey);
      if (cached && cached.length > 0) {
        return cached;
      }
    }

    try {
      const url = `${this.baseUrl}/time_series?symbol=${encodeURIComponent(
        this.symbol
      )}&interval=${interval}&outputsize=${outputsize}&apikey=${this.apiKey}`;

      const response = await fetch(url);
      this.apiCallsToday++;

      if (!response.ok) {
        throw new Error(`API error: ${response.status}`);
      }

      const data: TwelveDataTimeSeries = await response.json();

      if (data.status === "error") {
        throw new Error("API returned error status");
      }

      // Convert to CandlestickData format with JST offset
      const candles: CandlestickData<Time>[] = data.values
        .map((v) => ({
          time: (new Date(v.datetime).getTime() / 1000 + JST_OFFSET_SECONDS) as Time,
          open: parseFloat(v.open),
          high: parseFloat(v.high),
          low: parseFloat(v.low),
          close: parseFloat(v.close),
        }))
        .reverse(); // API returns newest first, we need oldest first

      // Update cache
      this.candleCache.set(cacheKey, candles);
      this.lastFetchTime.set(cacheKey, Date.now());

      // Update current price from latest candle
      if (candles.length > 0) {
        const latest = candles[candles.length - 1];
        this.currentPrice = {
          timestamp: Date.now(),
          price: latest.close,
          bid: latest.close - 0.001,
          ask: latest.close + 0.001,
        };
      }

      return candles;
    } catch (error) {
      console.error("Failed to fetch time series:", error);
      // Return cached data on error
      return this.candleCache.get(cacheKey) || [];
    }
  }

  // Fetch real-time quote
  async fetchQuote(): Promise<TickData | null> {
    if (!this.isConfigured()) {
      return null;
    }

    if (!this.canMakeApiCall()) {
      return this.currentPrice;
    }

    try {
      const url = `${this.baseUrl}/quote?symbol=${encodeURIComponent(
        this.symbol
      )}&apikey=${this.apiKey}`;

      const response = await fetch(url);
      this.apiCallsToday++;

      if (!response.ok) {
        throw new Error(`API error: ${response.status}`);
      }

      const data: TwelveDataQuote = await response.json();
      const price = parseFloat(data.close);

      this.currentPrice = {
        timestamp: data.timestamp * 1000,
        price,
        bid: price - 0.001,
        ask: price + 0.001,
      };

      return this.currentPrice;
    } catch (error) {
      console.error("Failed to fetch quote:", error);
      return this.currentPrice;
    }
  }

  // Get current price (cached)
  getCurrentPrice(): TickData | null {
    return this.currentPrice;
  }

  // Get API usage stats
  getUsageStats(): {
    callsToday: number;
    remaining: number;
    limit: number;
    pollingMode: PollingMode;
    pollingInterval: number;
  } {
    return {
      callsToday: this.apiCallsToday,
      remaining: this.getRemainingCalls(),
      limit: this.DAILY_LIMIT,
      pollingMode: this.pollingMode,
      pollingInterval: this.getPollingInterval(),
    };
  }
}

// Singleton with globalThis for Next.js compatibility
const globalForTwelveData = globalThis as unknown as {
  twelveDataService: TwelveDataService | undefined;
};

export const twelveDataService =
  globalForTwelveData.twelveDataService ?? new TwelveDataService();

if (process.env.NODE_ENV !== "production") {
  globalForTwelveData.twelveDataService = twelveDataService;
}

// Initialize from environment variable if available
if (process.env.TWELVE_DATA_API_KEY) {
  twelveDataService.setApiKey(process.env.TWELVE_DATA_API_KEY);
}

// Interval mapping
export const INTERVALS = {
  "1m": "1min",
  "5m": "5min",
  "15m": "15min",
  "1h": "1h",
} as const;

export type IntervalKey = keyof typeof INTERVALS;
