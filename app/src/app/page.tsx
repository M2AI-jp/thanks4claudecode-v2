"use client";

import { useState, useCallback } from "react";
import dynamic from "next/dynamic";
import Link from "next/link";
import { useSignal } from "@/hooks/useSignal";
import { usePriceData } from "@/hooks/usePriceData";
import { usePrediction } from "@/hooks/usePrediction";

const Chart = dynamic(() => import("@/components/Chart"), {
  ssr: false,
  loading: () => (
    <div className="bg-slate-800 rounded-lg p-4">
      <div className="h-96 bg-slate-900 rounded flex items-center justify-center">
        <p className="text-slate-500">Loading chart...</p>
      </div>
    </div>
  ),
});

const TradeHistory = dynamic(() => import("@/components/TradeHistory"), {
  ssr: false,
  loading: () => (
    <div className="bg-slate-800 rounded-lg p-4">
      <p className="text-slate-500">Loading...</p>
    </div>
  ),
});

export default function Home() {
  const [strictLevel, setStrictLevel] = useState<1 | 2 | 3>(2);
  const { signal } = useSignal({ timeframe: "5m", strictLevel, refreshInterval: 30000 });
  const { currentPrice, dataSource } = usePriceData({ timeframe: "5m", refreshInterval: 30000 });
  const { prediction, accuracy } = usePrediction({ timeframe: "5m", refreshInterval: 10000 });
  const [isTrading, setIsTrading] = useState(false);

  const details = signal?.details;

  const recordTrade = useCallback(
    async (direction: "HIGH" | "LOW") => {
      if (!currentPrice || isTrading) return;

      setIsTrading(true);
      try {
        // Get component scores for learning engine
        const components = direction === "HIGH"
          ? details?.highComponents
          : details?.lowComponents;

        // Record the trade with signal components
        const response = await fetch("/api/trades", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            entryPrice: currentPrice.price,
            direction,
            score: signal?.score || 0,
            strictLevel,
            components: components ? {
              ema: components.ema,
              macd: components.macd,
              adx: components.adx,
              rsi: components.rsi,
              stoch: components.stoch,
              price: components.price,
              candle: components.candle,
            } : undefined,
          }),
        });

        if (!response.ok) throw new Error("Failed to record trade");

        const { trade } = await response.json();

        // Auto-complete after 60 seconds (simulating 1-minute expiry)
        setTimeout(async () => {
          try {
            const priceResponse = await fetch("/api/prices?count=1");
            const priceData = await priceResponse.json();
            const exitPrice = priceData.currentPrice?.price || currentPrice.price;

            await fetch("/api/trades", {
              method: "PUT",
              headers: { "Content-Type": "application/json" },
              body: JSON.stringify({
                tradeId: trade.id,
                exitPrice,
              }),
            });
          } catch (error) {
            console.error("Failed to complete trade:", error);
          }
        }, 60000);
      } catch (error) {
        console.error("Failed to record trade:", error);
      } finally {
        setIsTrading(false);
      }
    },
    [currentPrice, isTrading, details, signal, strictLevel]
  );

  const getEmaOrderText = () => {
    if (!details) return "---";
    if (details.perfectOrderBull) return "Bull PO ✓";
    if (details.perfectOrderBear) return "Bear PO ✓";
    return "None";
  };

  const getMacdText = () => {
    if (!details) return "---";
    if (details.macdCrossUp) return "GC ✓";
    if (details.macdCrossDown) return "DC ✓";
    return details.macdLine > details.macdSignal ? "Bullish" : "Bearish";
  };

  return (
    <div className="p-4">
      <div className="max-w-7xl mx-auto">
        {/* Header */}
        <div className="flex justify-end mb-2">
          <Link
            href="/settings"
            className="px-3 py-1.5 bg-slate-700 hover:bg-slate-600 rounded-lg text-sm text-slate-300 transition-colors"
          >
            ⚙ 設定
          </Link>
        </div>

        {/* Chart */}
        <div className="mb-4">
          <Chart showEMA={true} showBB={true} />
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-4">
          {/* Left Column - Signal & Controls */}
          <div className="lg:col-span-2 space-y-4">
            {/* ML Prediction Panel */}
            <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
              <div className="bg-gradient-to-br from-slate-800 to-slate-900 rounded-lg p-4 border border-purple-500/30">
                <h3 className="text-sm font-medium text-purple-400 mb-2">
                  ML Prediction
                </h3>
                <p
                  className={`text-2xl font-bold ${
                    prediction?.direction === "HIGH"
                      ? "text-green-400"
                      : prediction?.direction === "LOW"
                      ? "text-red-400"
                      : "text-slate-300"
                  }`}
                >
                  {prediction?.direction || "---"}
                </p>
                <p className="text-xs text-slate-500 mt-1">
                  {prediction ? `${(prediction.confidence * 100).toFixed(0)}% confidence` : "Calculating..."}
                </p>
              </div>

              <div className="bg-slate-800 rounded-lg p-4">
                <h3 className="text-sm font-medium text-slate-400 mb-2">
                  Accuracy
                </h3>
                <p
                  className={`text-2xl font-bold ${
                    accuracy.accuracy >= 0.55
                      ? "text-green-400"
                      : accuracy.accuracy >= 0.5
                      ? "text-yellow-400"
                      : "text-slate-300"
                  }`}
                >
                  {accuracy.total > 0 ? `${(accuracy.accuracy * 100).toFixed(1)}%` : "--%"}
                </p>
                <p className="text-xs text-slate-500 mt-1">
                  {accuracy.correct}/{accuracy.total} correct
                </p>
              </div>

              <div className="bg-slate-800 rounded-lg p-4">
                <h3 className="text-sm font-medium text-slate-400 mb-2">
                  ADX
                </h3>
                <p
                  className={`text-2xl font-bold ${
                    details?.strongTrend ? "text-cyan-400" : "text-slate-300"
                  }`}
                >
                  {details?.adxValue ? details.adxValue.toFixed(1) : "--.-"}
                </p>
                <p className="text-xs text-slate-500 mt-1">
                  {details?.strongTrend ? "Strong ✓" : "Weak"}
                </p>
              </div>

              <div className="bg-slate-800 rounded-lg p-4">
                <h3 className="text-sm font-medium text-slate-400 mb-2">
                  Probability
                </h3>
                <p className="text-2xl font-bold text-slate-300">
                  {prediction ? `${(prediction.probability * 100).toFixed(1)}%` : "--%"}
                </p>
                <p className="text-xs text-slate-500 mt-1">
                  HIGH probability
                </p>
              </div>
            </div>

            {/* Trade Buttons */}
            <div className="grid grid-cols-2 gap-4">
              <button
                onClick={() => recordTrade("HIGH")}
                disabled={isTrading}
                className={`py-4 rounded-lg font-bold text-xl transition-all ${
                  prediction?.direction === "HIGH" && prediction.confidence > 0.3
                    ? "bg-green-500 hover:bg-green-400 text-white animate-pulse"
                    : "bg-green-600/30 hover:bg-green-600/50 text-green-400"
                } ${isTrading ? "opacity-50 cursor-not-allowed" : ""}`}
              >
                HIGH ▲
              </button>
              <button
                onClick={() => recordTrade("LOW")}
                disabled={isTrading}
                className={`py-4 rounded-lg font-bold text-xl transition-all ${
                  prediction?.direction === "LOW" && prediction.confidence > 0.3
                    ? "bg-red-500 hover:bg-red-400 text-white animate-pulse"
                    : "bg-red-600/30 hover:bg-red-600/50 text-red-400"
                } ${isTrading ? "opacity-50 cursor-not-allowed" : ""}`}
              >
                LOW ▼
              </button>
            </div>

            {/* Indicator Status */}
            <div className="bg-slate-800 rounded-lg p-4">
              <h3 className="text-sm font-medium text-slate-400 mb-3">
                Indicators
              </h3>
              <div className="grid grid-cols-2 md:grid-cols-4 gap-3 text-sm">
                <div>
                  <span className="text-slate-500">EMA:</span>
                  <span
                    className={`ml-2 ${
                      details?.perfectOrderBull
                        ? "text-green-400"
                        : details?.perfectOrderBear
                        ? "text-red-400"
                        : "text-slate-300"
                    }`}
                  >
                    {getEmaOrderText()}
                  </span>
                </div>
                <div>
                  <span className="text-slate-500">RSI:</span>
                  <span
                    className={`ml-2 ${
                      details && details.rsi < 30
                        ? "text-green-400"
                        : details && details.rsi > 70
                        ? "text-red-400"
                        : "text-slate-300"
                    }`}
                  >
                    {details?.rsi ? details.rsi.toFixed(1) : "--.-"}
                  </span>
                </div>
                <div>
                  <span className="text-slate-500">MACD:</span>
                  <span
                    className={`ml-2 ${
                      details?.macdLine && details.macdLine > details.macdSignal
                        ? "text-green-400"
                        : "text-red-400"
                    }`}
                  >
                    {getMacdText()}
                  </span>
                </div>
                <div>
                  <span className="text-slate-500">Stoch:</span>
                  <span
                    className={`ml-2 ${
                      details && details.stochK < 20
                        ? "text-green-400"
                        : details && details.stochK > 80
                        ? "text-red-400"
                        : "text-slate-300"
                    }`}
                  >
                    {details?.stochK ? details.stochK.toFixed(1) : "--.-"}
                  </span>
                </div>
                <div>
                  <span className="text-slate-500">DI:</span>
                  <span
                    className={`ml-2 ${
                      details && details.plusDI > details.minusDI
                        ? "text-green-400"
                        : "text-red-400"
                    }`}
                  >
                    {details
                      ? details.plusDI > details.minusDI
                        ? "Bull"
                        : "Bear"
                      : "---"}
                  </span>
                </div>
                <div>
                  <span className="text-slate-500">Vol:</span>
                  <span
                    className={`ml-2 ${
                      details?.volatilityOK ? "text-cyan-400" : "text-slate-300"
                    }`}
                  >
                    {details?.volatilityOK ? "OK ✓" : "Low"}
                  </span>
                </div>
                <div>
                  <span className="text-slate-500">ATR:</span>
                  <span className="ml-2 text-slate-300">
                    {details?.atrValue ? details.atrValue.toFixed(4) : "--.-"}
                  </span>
                </div>
                <div>
                  <span className="text-slate-500">BB:</span>
                  <span className="ml-2 text-slate-300">
                    {details?.bbMiddle ? details.bbMiddle.toFixed(3) : "--.-"}
                  </span>
                </div>
              </div>
            </div>

            {/* Score Breakdown */}
            {signal?.direction && (
              <div className="bg-slate-800 rounded-lg p-4">
                <h3 className="text-sm font-medium text-slate-400 mb-3">
                  Score Breakdown ({signal.direction})
                </h3>
                <div className="grid grid-cols-4 md:grid-cols-7 gap-2 text-xs">
                  {Object.entries(
                    signal.direction === "HIGH"
                      ? details?.highComponents || {}
                      : details?.lowComponents || {}
                  )
                    .filter(([key]) => key !== "total")
                    .map(([key, value]) => (
                      <div
                        key={key}
                        className="bg-slate-700 rounded p-2 text-center"
                      >
                        <div className="text-slate-400 uppercase">{key}</div>
                        <div
                          className={`font-bold ${
                            (value as number) > 0
                              ? "text-green-400"
                              : "text-slate-500"
                          }`}
                        >
                          +{(value as number).toFixed(1)}
                        </div>
                      </div>
                    ))}
                </div>
              </div>
            )}
          </div>

          {/* Right Column - Trade History */}
          <div className="lg:col-span-1">
            <TradeHistory />
          </div>
        </div>
      </div>
    </div>
  );
}
