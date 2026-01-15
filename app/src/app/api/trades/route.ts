import { NextResponse } from "next/server";
import { tradeService } from "@/lib/trade-service";

// GET: Get recent trades and stats
export async function GET(request: Request) {
  const { searchParams } = new URL(request.url);
  const limit = parseInt(searchParams.get("limit") || "50", 10);
  const statsOnly = searchParams.get("statsOnly") === "true";

  try {
    if (statsOnly) {
      const stats = await tradeService.getStats();
      return NextResponse.json({ stats });
    }

    const [trades, stats] = await Promise.all([
      tradeService.getRecentTrades(limit),
      tradeService.getStats(),
    ]);

    return NextResponse.json({ trades, stats });
  } catch (error) {
    return NextResponse.json(
      { error: "Failed to fetch trades" },
      { status: 500 }
    );
  }
}

// POST: Record a new trade
export async function POST(request: Request) {
  try {
    const body = await request.json();
    const { entryPrice, direction, signalId, score, strictLevel, components } = body;

    if (!entryPrice || !direction) {
      return NextResponse.json(
        { error: "Missing required fields" },
        { status: 400 }
      );
    }

    let finalSignalId = signalId;

    // If components are provided, record the signal first
    if (components && score !== undefined && strictLevel !== undefined) {
      const signal = await tradeService.recordSignal(
        direction,
        score,
        strictLevel,
        components
      );
      finalSignalId = signal.id;
    }

    const trade = await tradeService.recordTrade(entryPrice, direction, finalSignalId);
    return NextResponse.json({ trade });
  } catch (error) {
    return NextResponse.json(
      { error: "Failed to record trade" },
      { status: 500 }
    );
  }
}

// PUT: Complete a trade
export async function PUT(request: Request) {
  try {
    const body = await request.json();
    const { tradeId, exitPrice, payout } = body;

    if (!tradeId || !exitPrice) {
      return NextResponse.json(
        { error: "Missing required fields" },
        { status: 400 }
      );
    }

    const trade = await tradeService.completeTrade(tradeId, exitPrice, payout);

    if (!trade) {
      return NextResponse.json(
        { error: "Trade not found" },
        { status: 404 }
      );
    }

    return NextResponse.json({ trade });
  } catch (error) {
    return NextResponse.json(
      { error: "Failed to complete trade" },
      { status: 500 }
    );
  }
}

// DELETE: Delete a trade
export async function DELETE(request: Request) {
  const { searchParams } = new URL(request.url);
  const tradeId = parseInt(searchParams.get("id") || "0", 10);

  if (!tradeId) {
    return NextResponse.json(
      { error: "Missing trade ID" },
      { status: 400 }
    );
  }

  try {
    await tradeService.deleteTrade(tradeId);
    return NextResponse.json({ success: true });
  } catch (error) {
    return NextResponse.json(
      { error: "Failed to delete trade" },
      { status: 500 }
    );
  }
}
