import { NextResponse } from "next/server";
import {
  learningEngine,
  WEIGHT_NAMES,
  DEFAULT_WEIGHTS,
} from "@/lib/learning-engine";
import { tradeService } from "@/lib/trade-service";

// GET: Get current weights and statistics
export async function GET() {
  try {
    // Initialize weights if not exists
    await learningEngine.initializeWeights();

    // Get weights and metadata
    const { weights, metadata } = await learningEngine.getWeightStats();

    // Get trade statistics for correlation analysis
    const stats = await tradeService.getStats();

    // Calculate weight changes from default
    const weightChanges: Record<string, number> = {};
    for (const name of WEIGHT_NAMES) {
      weightChanges[name] = weights[name] - DEFAULT_WEIGHTS[name];
    }

    return NextResponse.json({
      weights,
      metadata,
      weightChanges,
      defaults: DEFAULT_WEIGHTS,
      tradeStats: {
        totalTrades: stats.totalTrades,
        winRate: stats.winRate,
        highWinRate: stats.highWinRate,
        lowWinRate: stats.lowWinRate,
      },
    });
  } catch (error) {
    console.error("Failed to get weights:", error);
    return NextResponse.json(
      { error: "Failed to fetch weights" },
      { status: 500 }
    );
  }
}

// POST: Reset weights to default
export async function POST(request: Request) {
  try {
    const body = await request.json();
    const { action } = body;

    if (action === "reset") {
      await learningEngine.resetWeights();
      return NextResponse.json({
        success: true,
        message: "Weights reset to default",
        weights: DEFAULT_WEIGHTS,
      });
    }

    if (action === "initialize") {
      await learningEngine.initializeWeights();
      const weights = await learningEngine.getWeights();
      return NextResponse.json({
        success: true,
        message: "Weights initialized",
        weights,
      });
    }

    return NextResponse.json(
      { error: "Invalid action. Use 'reset' or 'initialize'" },
      { status: 400 }
    );
  } catch (error) {
    console.error("Failed to update weights:", error);
    return NextResponse.json(
      { error: "Failed to update weights" },
      { status: 500 }
    );
  }
}
