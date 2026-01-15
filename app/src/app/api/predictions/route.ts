import { NextResponse } from "next/server";
import { predictionService } from "@/lib/prediction-service";
import { priceService, TIMEFRAMES } from "@/lib/price-service";
import { OHLC } from "@/lib/indicators";

// GET: Get current prediction and accuracy
export async function GET(request: Request) {
  try {
    const { searchParams } = new URL(request.url);
    const timeframe = (searchParams.get("timeframe") || "5m") as "1m" | "5m" | "15m";
    const historyLimit = parseInt(searchParams.get("historyLimit") || "50");

    // Get candle data
    const timeframeMs = TIMEFRAMES[timeframe] || TIMEFRAMES["5m"];
    const candleData = await priceService.getHistoricalCandlesAsync(200, timeframeMs);

    // Convert to OHLC format
    const candles: OHLC[] = candleData.map(c => ({
      open: c.open,
      high: c.high,
      low: c.low,
      close: c.close,
    }));

    if (candles.length < 50) {
      return NextResponse.json({
        prediction: null,
        accuracy: { total: 0, correct: 0, accuracy: 0 },
        history: [],
        message: "Not enough data for prediction",
      });
    }

    // Make prediction
    const prediction = await predictionService.predict(candles);

    // Get accuracy and history
    const accuracy = await predictionService.getAccuracy(100);
    const history = await predictionService.getHistory(historyLimit);
    const weights = await predictionService.getWeights();

    // Record this prediction if valid
    if (prediction && candles.length > 0) {
      // Use current timestamp for the prediction
      const timestamp = Math.floor(Date.now() / 1000);
      await predictionService.recordPrediction(timestamp, prediction);
    }

    return NextResponse.json({
      prediction: prediction
        ? {
            direction: prediction.direction,
            confidence: prediction.confidence,
            probability: prediction.probability,
          }
        : null,
      accuracy,
      history,
      weights,
    });
  } catch (error) {
    console.error("Failed to get prediction:", error);
    return NextResponse.json(
      { error: "Failed to get prediction" },
      { status: 500 }
    );
  }
}

// POST: Update prediction with actual result (for training)
export async function POST(request: Request) {
  try {
    const body = await request.json();
    const { timestamp, actualDirection } = body;

    if (!timestamp || !actualDirection) {
      return NextResponse.json(
        { error: "timestamp and actualDirection are required" },
        { status: 400 }
      );
    }

    if (actualDirection !== "HIGH" && actualDirection !== "LOW") {
      return NextResponse.json(
        { error: "actualDirection must be HIGH or LOW" },
        { status: 400 }
      );
    }

    const result = await predictionService.updateWithActual(
      timestamp,
      actualDirection
    );

    if (!result) {
      return NextResponse.json(
        { error: "Prediction not found or already updated" },
        { status: 404 }
      );
    }

    return NextResponse.json({
      success: true,
      loss: result.loss,
      accuracy: result.accuracy,
    });
  } catch (error) {
    console.error("Failed to update prediction:", error);
    return NextResponse.json(
      { error: "Failed to update prediction" },
      { status: 500 }
    );
  }
}

// DELETE: Reset model
export async function DELETE() {
  try {
    await predictionService.reset();
    return NextResponse.json({ success: true, message: "Model reset to defaults" });
  } catch (error) {
    console.error("Failed to reset model:", error);
    return NextResponse.json(
      { error: "Failed to reset model" },
      { status: 500 }
    );
  }
}
