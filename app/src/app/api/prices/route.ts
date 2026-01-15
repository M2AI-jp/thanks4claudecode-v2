import { NextResponse } from "next/server";
import { priceService, TIMEFRAMES, TimeframeKey } from "@/lib/price-service";

export async function GET(request: Request) {
  const { searchParams } = new URL(request.url);
  const timeframe = (searchParams.get("timeframe") || "5m") as TimeframeKey; // Default to 5m
  const count = parseInt(searchParams.get("count") || "100", 10);

  const timeframeMs = TIMEFRAMES[timeframe] || TIMEFRAMES["5m"];

  // Use async method for live data support
  const candles = await priceService.getHistoricalCandlesAsync(count, timeframeMs);
  const currentPrice = priceService.getCurrentPrice();
  const dataSource = priceService.getDataSource();
  const apiStats = priceService.getApiStats();

  return NextResponse.json({
    symbol: "USD/JPY",
    timeframe,
    candles,
    currentPrice,
    dataSource,
    apiStats,
    timestamp: Date.now(),
  });
}
