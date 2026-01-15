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
  HistogramSeries,
  HistogramData,
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

// Calculate EMA from number array
function calculateEMAFromArray(data: number[], period: number): number[] {
  const ema: number[] = [];
  const multiplier = 2 / (period + 1);
  let prevEMA = 0;

  for (let i = 0; i < data.length; i++) {
    if (i < period - 1) {
      ema.push(0);
      continue;
    }
    if (i === period - 1) {
      let sum = 0;
      for (let j = 0; j < period; j++) {
        sum += data[i - j];
      }
      prevEMA = sum / period;
      ema.push(prevEMA);
    } else {
      prevEMA = (data[i] - prevEMA) * multiplier + prevEMA;
      ema.push(prevEMA);
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

// Calculate RSI - returns array aligned with input data length
function calculateRSI(
  data: CandlestickData<Time>[],
  period: number = 14
): LineData<Time>[] {
  if (data.length < period + 1) return [];

  const rsi: LineData<Time>[] = [];
  let avgGain = 0;
  let avgLoss = 0;

  // Calculate initial average gain/loss
  for (let i = 1; i <= period; i++) {
    const change = data[i].close - data[i - 1].close;
    avgGain += change > 0 ? change : 0;
    avgLoss += change < 0 ? -change : 0;
  }
  avgGain /= period;
  avgLoss /= period;

  // Add padding for alignment with main chart
  for (let i = 0; i <= period; i++) {
    rsi.push({ time: data[i].time, value: 50 }); // neutral RSI for padding
  }

  // Calculate RSI for remaining data
  for (let i = period + 1; i < data.length; i++) {
    const change = data[i].close - data[i - 1].close;
    const gain = change > 0 ? change : 0;
    const loss = change < 0 ? -change : 0;

    avgGain = (avgGain * (period - 1) + gain) / period;
    avgLoss = (avgLoss * (period - 1) + loss) / period;

    const rs = avgLoss === 0 ? 100 : avgGain / avgLoss;
    const rsiValue = 100 - 100 / (1 + rs);

    rsi.push({ time: data[i].time, value: rsiValue });
  }

  return rsi;
}

// Calculate MACD - returns arrays aligned with input data length
function calculateMACD(
  data: CandlestickData<Time>[],
  fastPeriod: number = 12,
  slowPeriod: number = 26,
  signalPeriod: number = 9
): {
  macd: LineData<Time>[];
  signal: LineData<Time>[];
  histogram: HistogramData<Time>[];
} {
  const startIndex = slowPeriod - 1 + signalPeriod - 1;
  if (data.length < startIndex + 1) {
    return { macd: [], signal: [], histogram: [] };
  }

  const closes = data.map((d) => d.close);
  const fastEMA = calculateEMAFromArray(closes, fastPeriod);
  const slowEMA = calculateEMAFromArray(closes, slowPeriod);

  const macdLine: number[] = [];
  for (let i = 0; i < closes.length; i++) {
    if (i < slowPeriod - 1) {
      macdLine.push(0);
    } else {
      macdLine.push(fastEMA[i] - slowEMA[i]);
    }
  }

  const signalLine = calculateEMAFromArray(macdLine.slice(slowPeriod - 1), signalPeriod);

  const macd: LineData<Time>[] = [];
  const signal: LineData<Time>[] = [];
  const histogram: HistogramData<Time>[] = [];

  // Add padding for alignment with main chart
  for (let i = 0; i < startIndex; i++) {
    macd.push({ time: data[i].time, value: 0 });
    signal.push({ time: data[i].time, value: 0 });
    histogram.push({ time: data[i].time, value: 0, color: "#64748b" });
  }

  // Calculate MACD for remaining data
  for (let i = startIndex; i < data.length; i++) {
    const macdValue = macdLine[i];
    const signalValue = signalLine[i - slowPeriod + 1];
    const histValue = macdValue - signalValue;

    macd.push({ time: data[i].time, value: macdValue });
    signal.push({ time: data[i].time, value: signalValue });
    histogram.push({
      time: data[i].time,
      value: histValue,
      color: histValue >= 0 ? "#22c55e" : "#ef4444",
    });
  }

  return { macd, signal, histogram };
}

// Calculate Stochastic - returns arrays aligned with input data length
function calculateStochastic(
  data: CandlestickData<Time>[],
  kPeriod: number = 14,
  dPeriod: number = 3,
  smooth: number = 3
): {
  k: LineData<Time>[];
  d: LineData<Time>[];
} {
  const startIndex = kPeriod - 1 + smooth - 1 + dPeriod - 1;
  if (data.length < startIndex + 1) {
    return { k: [], d: [] };
  }

  const rawK: number[] = [];

  for (let i = kPeriod - 1; i < data.length; i++) {
    let highest = -Infinity;
    let lowest = Infinity;

    for (let j = 0; j < kPeriod; j++) {
      highest = Math.max(highest, data[i - j].high);
      lowest = Math.min(lowest, data[i - j].low);
    }

    const currentClose = data[i].close;
    const kValue = highest === lowest ? 50 : ((currentClose - lowest) / (highest - lowest)) * 100;
    rawK.push(kValue);
  }

  // Smooth K
  const smoothedK: number[] = [];
  for (let i = smooth - 1; i < rawK.length; i++) {
    let sum = 0;
    for (let j = 0; j < smooth; j++) {
      sum += rawK[i - j];
    }
    smoothedK.push(sum / smooth);
  }

  // Calculate D (SMA of smoothed K)
  const dValues: number[] = [];
  for (let i = dPeriod - 1; i < smoothedK.length; i++) {
    let sum = 0;
    for (let j = 0; j < dPeriod; j++) {
      sum += smoothedK[i - j];
    }
    dValues.push(sum / dPeriod);
  }

  const k: LineData<Time>[] = [];
  const d: LineData<Time>[] = [];

  // Add padding for alignment with main chart
  for (let i = 0; i < startIndex; i++) {
    k.push({ time: data[i].time, value: 50 });
    d.push({ time: data[i].time, value: 50 });
  }

  // Add calculated values
  for (let i = 0; i < dValues.length; i++) {
    const dataIndex = startIndex + i;
    if (dataIndex < data.length) {
      k.push({ time: data[dataIndex].time, value: smoothedK[i + dPeriod - 1] });
      d.push({ time: data[dataIndex].time, value: dValues[i] });
    }
  }

  return { k, d };
}

interface ChartProps {
  showEMA?: boolean;
  showBB?: boolean;
  showRSI?: boolean;
  showMACD?: boolean;
  showStoch?: boolean;
  emaPeriods?: number[];
  bbPeriod?: number;
  bbStdDev?: number;
}

const DEFAULT_EMA_PERIODS = [5, 13, 21];

export default function Chart({
  showEMA = true,
  showBB = true,
  showRSI = true,
  showMACD = true,
  showStoch = true,
  emaPeriods = DEFAULT_EMA_PERIODS,
  bbPeriod = 20,
  bbStdDev = 2,
}: ChartProps) {
  // Main chart refs
  const chartContainerRef = useRef<HTMLDivElement>(null);
  const chartRef = useRef<IChartApi | null>(null);
  const candlestickSeriesRef = useRef<ISeriesApi<"Candlestick"> | null>(null);
  const emaSeriesRefs = useRef<ISeriesApi<"Line">[]>([]);
  const bbSeriesRefs = useRef<{
    middle: ISeriesApi<"Line"> | null;
    upper: ISeriesApi<"Line"> | null;
    lower: ISeriesApi<"Line"> | null;
  }>({ middle: null, upper: null, lower: null });

  // RSI chart refs
  const rsiContainerRef = useRef<HTMLDivElement>(null);
  const rsiChartRef = useRef<IChartApi | null>(null);
  const rsiSeriesRef = useRef<ISeriesApi<"Line"> | null>(null);

  // MACD chart refs
  const macdContainerRef = useRef<HTMLDivElement>(null);
  const macdChartRef = useRef<IChartApi | null>(null);
  const macdLineRef = useRef<ISeriesApi<"Line"> | null>(null);
  const macdSignalRef = useRef<ISeriesApi<"Line"> | null>(null);
  const macdHistRef = useRef<ISeriesApi<"Histogram"> | null>(null);

  // Stochastic chart refs
  const stochContainerRef = useRef<HTMLDivElement>(null);
  const stochChartRef = useRef<IChartApi | null>(null);
  const stochKRef = useRef<ISeriesApi<"Line"> | null>(null);
  const stochDRef = useRef<ISeriesApi<"Line"> | null>(null);

  const isInitialLoadRef = useRef(true);

  const stableEmaPeriods = useMemo(() => emaPeriods, [emaPeriods.join(",")]);

  const [timeframe, setTimeframe] = useState<"1m" | "5m" | "15m">("5m");
  const { candles, currentPrice, loading, dataSource } = usePriceData({
    timeframe,
    count: 200,
    refreshInterval: 30000,
  });

  // Chart options
  const chartOptions = useCallback(
    (height: number) => ({
      layout: {
        background: { type: ColorType.Solid as const, color: "#0f172a" },
        textColor: "#94a3b8",
      },
      grid: {
        vertLines: { color: "#1e293b" },
        horzLines: { color: "#1e293b" },
      },
      height,
      timeScale: {
        timeVisible: true,
        secondsVisible: false,
        barSpacing: 6,
        rightOffset: 5,
      },
      crosshair: {
        mode: 1 as const,
      },
      rightPriceScale: {
        borderColor: "#1e293b",
        minimumWidth: 80,
      },
    }),
    []
  );

  // Initialize all charts
  useEffect(() => {
    if (!chartContainerRef.current) return;

    const charts: IChartApi[] = [];

    // Main chart
    const mainChart = createChart(chartContainerRef.current, {
      ...chartOptions(300),
      width: chartContainerRef.current.clientWidth,
    });
    chartRef.current = mainChart;
    charts.push(mainChart);

    // Add candlestick series
    const candlestickSeries = mainChart.addSeries(CandlestickSeries, {
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
        return mainChart.addSeries(LineSeries, {
          color: emaColors[index] || "#00BFFF",
          lineWidth: 1,
          title: `EMA${period}`,
        });
      });
    }

    // Add Bollinger Bands
    if (showBB) {
      bbSeriesRefs.current.middle = mainChart.addSeries(LineSeries, {
        color: "#708090",
        lineWidth: 1,
      });
      bbSeriesRefs.current.upper = mainChart.addSeries(LineSeries, {
        color: "#6A5ACD",
        lineWidth: 1,
      });
      bbSeriesRefs.current.lower = mainChart.addSeries(LineSeries, {
        color: "#6A5ACD",
        lineWidth: 1,
      });
    }

    // RSI chart
    if (showRSI && rsiContainerRef.current) {
      const rsiChart = createChart(rsiContainerRef.current, {
        ...chartOptions(120),
        width: rsiContainerRef.current.clientWidth,
      });
      rsiChartRef.current = rsiChart;
      charts.push(rsiChart);

      rsiSeriesRef.current = rsiChart.addSeries(LineSeries, {
        color: "#f59e0b",
        lineWidth: 2,
        title: "RSI",
        priceFormat: { type: "price", precision: 1, minMove: 0.1 },
      });

      // Add overbought/oversold lines
      rsiChart.addSeries(LineSeries, {
        color: "#ef4444",
        lineWidth: 1,
        lineStyle: 2,
        priceLineVisible: false,
        lastValueVisible: false,
      });
      rsiChart.addSeries(LineSeries, {
        color: "#22c55e",
        lineWidth: 1,
        lineStyle: 2,
        priceLineVisible: false,
        lastValueVisible: false,
      });
    }

    // MACD chart
    if (showMACD && macdContainerRef.current) {
      const macdChart = createChart(macdContainerRef.current, {
        ...chartOptions(120),
        width: macdContainerRef.current.clientWidth,
      });
      macdChartRef.current = macdChart;
      charts.push(macdChart);

      macdHistRef.current = macdChart.addSeries(HistogramSeries, {
        color: "#22c55e",
        priceFormat: { type: "price", precision: 5, minMove: 0.00001 },
      });
      macdLineRef.current = macdChart.addSeries(LineSeries, {
        color: "#3b82f6",
        lineWidth: 2,
        title: "MACD",
        priceFormat: { type: "price", precision: 5, minMove: 0.00001 },
      });
      macdSignalRef.current = macdChart.addSeries(LineSeries, {
        color: "#f59e0b",
        lineWidth: 2,
        title: "Signal",
        priceFormat: { type: "price", precision: 5, minMove: 0.00001 },
      });
    }

    // Stochastic chart
    if (showStoch && stochContainerRef.current) {
      const stochChart = createChart(stochContainerRef.current, {
        ...chartOptions(120),
        width: stochContainerRef.current.clientWidth,
      });
      stochChartRef.current = stochChart;
      charts.push(stochChart);

      stochKRef.current = stochChart.addSeries(LineSeries, {
        color: "#3b82f6",
        lineWidth: 2,
        title: "%K",
        priceFormat: { type: "price", precision: 1, minMove: 0.1 },
      });
      stochDRef.current = stochChart.addSeries(LineSeries, {
        color: "#f59e0b",
        lineWidth: 2,
        title: "%D",
        priceFormat: { type: "price", precision: 1, minMove: 0.1 },
      });
    }

    // Sync time scales between all charts using logical range
    let isSyncing = false;

    const syncAllCharts = (sourceChart: IChartApi) => {
      if (isSyncing) return;
      isSyncing = true;
      const range = sourceChart.timeScale().getVisibleLogicalRange();
      if (range) {
        charts.forEach((chart) => {
          if (chart !== sourceChart) {
            chart.timeScale().setVisibleLogicalRange(range);
          }
        });
      }
      isSyncing = false;
    };

    // All charts sync with each other
    charts.forEach((chart) => {
      chart.timeScale().subscribeVisibleLogicalRangeChange(() => {
        syncAllCharts(chart);
      });
    });

    // Handle resize
    const handleResize = () => {
      if (chartContainerRef.current) {
        const width = chartContainerRef.current.clientWidth;
        charts.forEach((chart) => chart.applyOptions({ width }));
      }
    };

    window.addEventListener("resize", handleResize);

    return () => {
      window.removeEventListener("resize", handleResize);
      charts.forEach((chart) => chart.remove());
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

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

    // Update RSI
    if (showRSI && rsiSeriesRef.current) {
      const rsiData = calculateRSI(candles, 14);
      rsiSeriesRef.current.setData(rsiData);
    }

    // Update MACD
    if (showMACD && macdLineRef.current && macdSignalRef.current && macdHistRef.current) {
      const macdData = calculateMACD(candles, 12, 26, 9);
      macdLineRef.current.setData(macdData.macd);
      macdSignalRef.current.setData(macdData.signal);
      macdHistRef.current.setData(macdData.histogram);
    }

    // Update Stochastic
    if (showStoch && stochKRef.current && stochDRef.current) {
      const stochData = calculateStochastic(candles, 14, 3, 3);
      stochKRef.current.setData(stochData.k);
      stochDRef.current.setData(stochData.d);
    }

    // Fit content only on initial load - sync all charts to main chart's logical range
    if (chartRef.current && isInitialLoadRef.current) {
      chartRef.current.timeScale().fitContent();
      // Sync sub-charts to main chart's visible logical range
      setTimeout(() => {
        const range = chartRef.current?.timeScale().getVisibleLogicalRange();
        if (range) {
          rsiChartRef.current?.timeScale().setVisibleLogicalRange(range);
          macdChartRef.current?.timeScale().setVisibleLogicalRange(range);
          stochChartRef.current?.timeScale().setVisibleLogicalRange(range);
        }
      }, 50);
      isInitialLoadRef.current = false;
    }
  }, [candles, showEMA, showBB, showRSI, showMACD, showStoch, stableEmaPeriods, bbPeriod, bbStdDev]);

  const handleTimeframeChange = useCallback((tf: "1m" | "5m" | "15m") => {
    setTimeframe(tf);
    isInitialLoadRef.current = true;
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
          <div className="absolute inset-0 bg-slate-900 rounded flex items-center justify-center z-10">
            <p className="text-slate-500">Loading chart...</p>
          </div>
        )}

        {/* Main Chart */}
        <div ref={chartContainerRef} className="w-full h-[300px]" />

        {/* RSI Sub-chart */}
        {showRSI && (
          <div className="mt-1 border-t border-slate-700">
            <div className="flex items-center justify-between px-2 py-1 text-xs text-slate-400">
              <span>RSI (14)</span>
              <span className="text-slate-500">70/30</span>
            </div>
            <div ref={rsiContainerRef} className="w-full h-[120px]" />
          </div>
        )}

        {/* MACD Sub-chart */}
        {showMACD && (
          <div className="mt-1 border-t border-slate-700">
            <div className="flex items-center justify-between px-2 py-1 text-xs text-slate-400">
              <span>MACD (12, 26, 9)</span>
              <div className="flex gap-2">
                <span className="text-blue-400">MACD</span>
                <span className="text-amber-400">Signal</span>
              </div>
            </div>
            <div ref={macdContainerRef} className="w-full h-[120px]" />
          </div>
        )}

        {/* Stochastic Sub-chart */}
        {showStoch && (
          <div className="mt-1 border-t border-slate-700">
            <div className="flex items-center justify-between px-2 py-1 text-xs text-slate-400">
              <span>Stochastic (14, 3, 3)</span>
              <div className="flex gap-2">
                <span className="text-blue-400">%K</span>
                <span className="text-amber-400">%D</span>
              </div>
            </div>
            <div ref={stochContainerRef} className="w-full h-[120px]" />
          </div>
        )}
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
