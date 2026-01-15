import { NextResponse } from "next/server";
import { priceService, TIMEFRAMES, TimeframeKey } from "@/lib/price-service";
import { signalGenerator } from "@/lib/signal-generator";

export async function GET(request: Request) {
  const { searchParams } = new URL(request.url);
  const timeframe = (searchParams.get("timeframe") || "5m") as TimeframeKey; // Default to 5m
  const strictLevel = parseInt(searchParams.get("strictLevel") || "2", 10) as
    | 1
    | 2
    | 3;

  const timeframeMs = TIMEFRAMES[timeframe] || TIMEFRAMES["5m"];
  const candles = await priceService.getHistoricalCandlesAsync(200, timeframeMs);

  // Convert to OHLC format
  const ohlcData = candles.map((c) => ({
    open: c.open,
    high: c.high,
    low: c.low,
    close: c.close,
  }));

  // Update config and generate signal
  signalGenerator.updateConfig({ strictLevel });
  const signal = await signalGenerator.generate(ohlcData);

  return NextResponse.json({
    symbol: "USD/JPY",
    timeframe,
    strictLevel,
    signal,
    timestamp: Date.now(),
  });
}
