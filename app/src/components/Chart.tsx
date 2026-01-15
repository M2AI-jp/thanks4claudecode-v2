"use client";

import { useEffect, useRef, useState, useCallback, useMemo } from "react";
import {
  createChart,
  IChartApi,
  ISeriesApi,
  CandlestickData,
  LineData,
  Time,
  ColorType,
  CandlestickSeries,
  LineSeries,
} from "lightweight-charts";
import { usePriceData } from "@/hooks/usePriceData";

// Calculate EMA
function calculateEMA(
  data: CandlestickData<Time>[],
  period: number
): LineData<Time>[] {
  const ema: LineData<Time>[] = [];
  const multiplier = 2 / (period + 1);
  let prevEMA = 0;

  for (let i = 0; i < data.length; i++) {
    if (i < period - 1) {
      continue;
    }
    if (i === period - 1) {
      let sum = 0;
      for (let j = 0; j < period; j++) {
        sum += data[i - j].close;
      }
      prevEMA = sum / period;
      ema.push({ time: data[i].time, value: prevEMA });
    } else {
      prevEMA = (data[i].close - prevEMA) * multiplier + prevEMA;
      ema.push({ time: data[i].time, value: prevEMA });
    }
  }

  return ema;
}

// Calculate Bollinger Bands
function calculateBollingerBands(
  data: CandlestickData<Time>[],
  period: number = 20,
  stdDev: number = 2
): {
  middle: LineData<Time>[];
  upper: LineData<Time>[];
  lower: LineData<Time>[];
} {
  const middle: LineData<Time>[] = [];
  const upper: LineData<Time>[] = [];
  const lower: LineData<Time>[] = [];

  for (let i = period - 1; i < data.length; i++) {
    let sum = 0;
    for (let j = 0; j < period; j++) {
      sum += data[i - j].close;
    }
    const sma = sum / period;

    let squaredSum = 0;
    for (let j = 0; j < period; j++) {
      squaredSum += Math.pow(data[i - j].close - sma, 2);
    }
    const std = Math.sqrt(squaredSum / period);

    middle.push({ time: data[i].time, value: sma });
    upper.push({ time: data[i].time, value: sma + stdDev * std });
    lower.push({ time: data[i].time, value: sma - stdDev * std });
  }

  return { middle, upper, lower };
}

interface ChartProps {
  showEMA?: boolean;
  showBB?: boolean;
  emaPeriods?: number[];
  bbPeriod?: number;
  bbStdDev?: number;
}

const DEFAULT_EMA_PERIODS = [5, 13, 21];

export default function Chart({
  showEMA = true,
  showBB = true,
  emaPeriods = DEFAULT_EMA_PERIODS,
  bbPeriod = 20,
  bbStdDev = 2,
}: ChartProps) {
  const chartContainerRef = useRef<HTMLDivElement>(null);
  const chartRef = useRef<IChartApi | null>(null);
  const candlestickSeriesRef = useRef<ISeriesApi<"Candlestick"> | null>(null);
  const emaSeriesRefs = useRef<ISeriesApi<"Line">[]>([]);
  const bbSeriesRefs = useRef<{
    middle: ISeriesApi<"Line"> | null;
    upper: ISeriesApi<"Line"> | null;
    lower: ISeriesApi<"Line"> | null;
  }>({ middle: null, upper: null, lower: null });
  const isInitialLoadRef = useRef(true);

  // Memoize emaPeriods to prevent unnecessary re-renders
  const stableEmaPeriods = useMemo(() => emaPeriods, [emaPeriods.join(",")]);

  const [timeframe, setTimeframe] = useState<"1m" | "5m" | "15m">("5m");
  const { candles, currentPrice, loading, dataSource } = usePriceData({
    timeframe,
    count: 200,
    refreshInterval: 30000, // 30 seconds for smart polling
  });

  // Initialize chart
  useEffect(() => {
    if (!chartContainerRef.current) return;

    const chart = createChart(chartContainerRef.current, {
      layout: {
        background: { type: ColorType.Solid, color: "#0f172a" },
        textColor: "#94a3b8",
      },
      grid: {
        vertLines: { color: "#1e293b" },
        horzLines: { color: "#1e293b" },
      },
      width: chartContainerRef.current.clientWidth,
      height: 400,
      timeScale: {
        timeVisible: true,
        secondsVisible: false,
      },
      crosshair: {
        mode: 1,
      },
    });

    chartRef.current = chart;

    // Add candlestick series
    const candlestickSeries = chart.addSeries(CandlestickSeries, {
      upColor: "#22c55e",
      downColor: "#ef4444",
      borderUpColor: "#22c55e",
      borderDownColor: "#ef4444",
      wickUpColor: "#22c55e",
      wickDownColor: "#ef4444",
    });
    candlestickSeriesRef.current = candlestickSeries;

    // Add EMA lines
    if (showEMA) {
      const emaColors = ["#00BFFF", "#1E90FF", "#4169E1"];
      emaSeriesRefs.current = stableEmaPeriods.map((period, index) => {
        return chart.addSeries(LineSeries, {
          color: emaColors[index] || "#00BFFF",
          lineWidth: 1,
          title: `EMA${period}`,
        });
      });
    }

    // Add Bollinger Bands
    if (showBB) {
      bbSeriesRefs.current.middle = chart.addSeries(LineSeries, {
        color: "#708090",
        lineWidth: 1,
        title: "BB Middle",
      });
      bbSeriesRefs.current.upper = chart.addSeries(LineSeries, {
        color: "#6A5ACD",
        lineWidth: 1,
        title: "BB Upper",
      });
      bbSeriesRefs.current.lower = chart.addSeries(LineSeries, {
        color: "#6A5ACD",
        lineWidth: 1,
        title: "BB Lower",
      });
    }

    // Handle resize
    const handleResize = () => {
      if (chartContainerRef.current) {
        chart.applyOptions({ width: chartContainerRef.current.clientWidth });
      }
    };

    window.addEventListener("resize", handleResize);

    return () => {
      window.removeEventListener("resize", handleResize);
      chart.remove();
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []); // Only initialize once

  // Update data when candles change
  useEffect(() => {
    if (!candlestickSeriesRef.current || candles.length === 0) return;

    candlestickSeriesRef.current.setData(candles);

    // Update EMA
    if (showEMA) {
      stableEmaPeriods.forEach((period, index) => {
        if (emaSeriesRefs.current[index]) {
          const emaData = calculateEMA(candles, period);
          emaSeriesRefs.current[index].setData(emaData);
        }
      });
    }

    // Update Bollinger Bands
    if (showBB) {
      const bb = calculateBollingerBands(candles, bbPeriod, bbStdDev);
      bbSeriesRefs.current.middle?.setData(bb.middle);
      bbSeriesRefs.current.upper?.setData(bb.upper);
      bbSeriesRefs.current.lower?.setData(bb.lower);
    }

    // Fit content only on initial load
    if (chartRef.current && isInitialLoadRef.current) {
      chartRef.current.timeScale().fitContent();
      isInitialLoadRef.current = false;
    }
  }, [candles, showEMA, showBB, stableEmaPeriods, bbPeriod, bbStdDev]);

  const handleTimeframeChange = useCallback((tf: "1m" | "5m" | "15m") => {
    setTimeframe(tf);
    isInitialLoadRef.current = true; // Reset to fit content on timeframe change
  }, []);

  return (
    <div className="bg-slate-800 rounded-lg p-4">
      <div className="flex items-center justify-between mb-4">
        <div className="flex items-center gap-4">
          <h2 className="text-lg font-semibold text-white">USD/JPY</h2>
          <span
            className={`text-2xl font-bold ${
              currentPrice ? "text-green-400" : "text-slate-400"
            }`}
          >
            {currentPrice ? currentPrice.price.toFixed(3) : "---"}
          </span>
          {currentPrice && (
            <span className="text-xs text-slate-500">
              Bid: {currentPrice.bid.toFixed(3)} / Ask:{" "}
              {currentPrice.ask.toFixed(3)}
            </span>
          )}
          <span
            className={`text-xs px-2 py-0.5 rounded ${
              dataSource === "live"
                ? "bg-green-600 text-white"
                : "bg-yellow-600 text-white"
            }`}
          >
            {dataSource === "live" ? "LIVE" : "DEMO"}
          </span>
        </div>
        <div className="flex gap-2">
          {(["1m", "5m", "15m"] as const).map((tf) => (
            <button
              key={tf}
              onClick={() => handleTimeframeChange(tf)}
              className={`px-3 py-1 rounded text-sm transition-colors ${
                timeframe === tf
                  ? "bg-blue-600 text-white"
                  : "bg-slate-700 text-slate-300 hover:bg-slate-600"
              }`}
            >
              {tf}
            </button>
          ))}
        </div>
      </div>

      <div className="relative">
        {loading && (
          <div className="absolute inset-0 h-[400px] bg-slate-900 rounded flex items-center justify-center z-10">
            <p className="text-slate-500">Loading chart...</p>
          </div>
        )}
        <div ref={chartContainerRef} className="w-full h-[400px]" />
      </div>

      <div className="mt-2 flex gap-4 text-xs text-slate-400">
        {showEMA && (
          <div className="flex items-center gap-2">
            <span className="w-3 h-0.5 bg-[#00BFFF]"></span>
            <span>EMA5</span>
            <span className="w-3 h-0.5 bg-[#1E90FF]"></span>
            <span>EMA13</span>
            <span className="w-3 h-0.5 bg-[#4169E1]"></span>
            <span>EMA21</span>
          </div>
        )}
        {showBB && (
          <div className="flex items-center gap-2">
            <span className="w-3 h-0.5 bg-[#6A5ACD]"></span>
            <span>BB(20,2)</span>
          </div>
        )}
      </div>
    </div>
  );
}
