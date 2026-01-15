"use client";

import { useState, useEffect, useCallback, useRef } from "react";
import { SignalResult } from "@/lib/signal-generator";

interface SignalResponse {
  symbol: string;
  timeframe: string;
  strictLevel: number;
  signal: SignalResult;
  timestamp: number;
}

interface UseSignalOptions {
  timeframe?: string;
  strictLevel?: 1 | 2 | 3;
  refreshInterval?: number;
}

export function useSignal(options: UseSignalOptions = {}) {
  const { timeframe = "1m", strictLevel = 2, refreshInterval = 1000 } = options;

  const [signal, setSignal] = useState<SignalResult | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const intervalRef = useRef<NodeJS.Timeout | null>(null);

  const fetchSignal = useCallback(async () => {
    try {
      const response = await fetch(
        `/api/signals?timeframe=${timeframe}&strictLevel=${strictLevel}`
      );

      if (!response.ok) {
        throw new Error("Failed to fetch signal");
      }

      const data: SignalResponse = await response.json();
      setSignal(data.signal);
      setError(null);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Unknown error");
    } finally {
      setLoading(false);
    }
  }, [timeframe, strictLevel]);

  useEffect(() => {
    fetchSignal();

    intervalRef.current = setInterval(fetchSignal, refreshInterval);

    return () => {
      if (intervalRef.current) {
        clearInterval(intervalRef.current);
      }
    };
  }, [fetchSignal, refreshInterval]);

  return {
    signal,
    loading,
    error,
    refetch: fetchSignal,
  };
}
