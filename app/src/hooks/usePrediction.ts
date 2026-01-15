"use client";

import { useState, useEffect, useCallback } from "react";

interface PredictionData {
  direction: "HIGH" | "LOW";
  confidence: number;
  probability: number;
}

interface AccuracyData {
  total: number;
  correct: number;
  accuracy: number;
}

interface HistoryItem {
  timestamp: number;
  prediction: string;
  actual: string | null;
  confidence: number;
  correct: boolean | null;
}

interface UsePredictionOptions {
  timeframe?: "1m" | "5m" | "15m";
  refreshInterval?: number;
}

interface UsePredictionResult {
  prediction: PredictionData | null;
  accuracy: AccuracyData;
  history: HistoryItem[];
  loading: boolean;
  error: string | null;
  refresh: () => Promise<void>;
}

export function usePrediction({
  timeframe = "5m",
  refreshInterval = 30000,
}: UsePredictionOptions = {}): UsePredictionResult {
  const [prediction, setPrediction] = useState<PredictionData | null>(null);
  const [accuracy, setAccuracy] = useState<AccuracyData>({
    total: 0,
    correct: 0,
    accuracy: 0,
  });
  const [history, setHistory] = useState<HistoryItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchPrediction = useCallback(async () => {
    try {
      const response = await fetch(
        `/api/predictions?timeframe=${timeframe}&historyLimit=20`
      );

      if (!response.ok) {
        throw new Error("Failed to fetch prediction");
      }

      const data = await response.json();

      setPrediction(data.prediction);
      setAccuracy(data.accuracy);
      setHistory(data.history || []);
      setError(null);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Unknown error");
    } finally {
      setLoading(false);
    }
  }, [timeframe]);

  useEffect(() => {
    fetchPrediction();

    const interval = setInterval(fetchPrediction, refreshInterval);
    return () => clearInterval(interval);
  }, [fetchPrediction, refreshInterval]);

  return {
    prediction,
    accuracy,
    history,
    loading,
    error,
    refresh: fetchPrediction,
  };
}
