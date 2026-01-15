"use client";

import { useState, useEffect, useCallback, useRef } from "react";
import { CandlestickData, Time } from "lightweight-charts";

export interface TickData {
  timestamp: number;
  price: number;
  bid: number;
  ask: number;
}

interface ApiStats {
  callsToday: number;
  remaining: number;
  limit: number;
  pollingMode: string;
  pollingInterval: number;
}

interface PriceResponse {
  symbol: string;
  timeframe: string;
  candles: CandlestickData<Time>[];
  currentPrice: TickData | null;
  dataSource: "live" | "simulator";
  apiStats: ApiStats;
  timestamp: number;
}

interface UsePriceDataOptions {
  timeframe?: string;
  count?: number;
  refreshInterval?: number;
}

export function usePriceData(options: UsePriceDataOptions = {}) {
  const { timeframe = "5m", count = 200, refreshInterval = 30000 } = options;

  const [candles, setCandles] = useState<CandlestickData<Time>[]>([]);
  const [currentPrice, setCurrentPrice] = useState<TickData | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [dataSource, setDataSource] = useState<"live" | "simulator">("simulator");
  const [apiStats, setApiStats] = useState<ApiStats | null>(null);
  const intervalRef = useRef<NodeJS.Timeout | null>(null);

  const fetchPrices = useCallback(async () => {
    try {
      const response = await fetch(
        `/api/prices?timeframe=${timeframe}&count=${count}`
      );

      if (!response.ok) {
        throw new Error("Failed to fetch prices");
      }

      const data: PriceResponse = await response.json();

      setCandles(data.candles);
      setCurrentPrice(data.currentPrice);
      setDataSource(data.dataSource);
      setApiStats(data.apiStats);
      setError(null);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Unknown error");
    } finally {
      setLoading(false);
    }
  }, [timeframe, count]);

  // Initial fetch and setup interval
  useEffect(() => {
    fetchPrices();

    intervalRef.current = setInterval(fetchPrices, refreshInterval);

    return () => {
      if (intervalRef.current) {
        clearInterval(intervalRef.current);
      }
    };
  }, [fetchPrices, refreshInterval]);

  // Update last candle with current price
  const updateLastCandle = useCallback(
    (price: number): CandlestickData<Time>[] => {
      if (candles.length === 0) return candles;

      const updatedCandles = [...candles];
      const lastCandle = { ...updatedCandles[updatedCandles.length - 1] };

      lastCandle.close = price;
      lastCandle.high = Math.max(lastCandle.high, price);
      lastCandle.low = Math.min(lastCandle.low, price);

      updatedCandles[updatedCandles.length - 1] = lastCandle;
      return updatedCandles;
    },
    [candles]
  );

  return {
    candles,
    currentPrice,
    loading,
    error,
    dataSource,
    apiStats,
    refetch: fetchPrices,
    updateLastCandle,
  };
}
