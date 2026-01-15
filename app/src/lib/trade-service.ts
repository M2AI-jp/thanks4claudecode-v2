// Trade recording and statistics service
import { db, trades, signals, type NewTrade, type Trade, type NewSignal } from "@/db";
import { eq, desc, and, gte, sql } from "drizzle-orm";
import { learningEngine, type ComponentScores, type TradeResult } from "./learning-engine";

export interface TradeRecord {
  id: number;
  signalId: number | null;
  entryTime: number;
  entryPrice: number;
  direction: string;
  exitTime: number | null;
  exitPrice: number | null;
  result: string | null;
  payout: number | null;
  createdAt: number;
}

export interface TradeStats {
  totalTrades: number;
  wins: number;
  losses: number;
  pending: number;
  winRate: number;
  highWins: number;
  highTotal: number;
  highWinRate: number;
  lowWins: number;
  lowTotal: number;
  lowWinRate: number;
  totalPayout: number;
}

export interface SignalRecord {
  id: number;
  timestamp: number;
  direction: string;
  score: number;
  strictLevel: number;
  indicators: string | null;
  createdAt: number;
}

class TradeService {
  // Record a new signal
  async recordSignal(
    direction: "HIGH" | "LOW",
    score: number,
    strictLevel: number,
    indicators?: Record<string, number>
  ): Promise<SignalRecord> {
    const newSignal: NewSignal = {
      timestamp: Date.now(),
      direction,
      score,
      strictLevel,
      indicators: indicators ? JSON.stringify(indicators) : null,
    };

    const result = await db.insert(signals).values(newSignal).returning();
    return result[0] as SignalRecord;
  }

  // Record a new trade
  async recordTrade(
    entryPrice: number,
    direction: "HIGH" | "LOW",
    signalId?: number
  ): Promise<TradeRecord> {
    const newTrade: NewTrade = {
      signalId: signalId || null,
      entryTime: Date.now(),
      entryPrice,
      direction,
    };

    const result = await db.insert(trades).values(newTrade).returning();
    return result[0] as TradeRecord;
  }

  // Complete a trade with result
  async completeTrade(
    tradeId: number,
    exitPrice: number,
    payout?: number
  ): Promise<TradeRecord | null> {
    const trade = await db.query.trades.findFirst({
      where: eq(trades.id, tradeId),
    });

    if (!trade) return null;

    // Determine win/loss
    const isWin =
      (trade.direction === "HIGH" && exitPrice > trade.entryPrice) ||
      (trade.direction === "LOW" && exitPrice < trade.entryPrice);

    const result = await db
      .update(trades)
      .set({
        exitTime: Date.now(),
        exitPrice,
        result: isWin ? "WIN" : "LOSE",
        payout: payout || (isWin ? 1.85 : -1), // Default payout ratio
      })
      .where(eq(trades.id, tradeId))
      .returning();

    const completedTrade = result[0] as TradeRecord;

    // Update learning engine weights based on trade result
    await this.updateLearningWeights(completedTrade);

    return completedTrade;
  }

  // Update learning engine weights based on trade result
  private async updateLearningWeights(trade: TradeRecord): Promise<void> {
    if (!trade.signalId || !trade.result) return;

    try {
      // Get the associated signal
      const signal = await db.query.signals.findFirst({
        where: eq(signals.id, trade.signalId),
      });

      if (!signal || !signal.indicators) return;

      // Parse indicators JSON to get component scores
      const indicators = JSON.parse(signal.indicators);

      // Extract component scores (these should be the base scores before weighting)
      const components: ComponentScores = {
        ema: indicators.ema || 0,
        macd: indicators.macd || 0,
        adx: indicators.adx || 0,
        rsi: indicators.rsi || 0,
        stoch: indicators.stoch || 0,
        price: indicators.price || 0,
        candle: indicators.candle || 0,
      };

      const tradeResult: TradeResult = {
        direction: trade.direction as "HIGH" | "LOW",
        result: trade.result as "WIN" | "LOSE",
        components,
      };

      await learningEngine.updateWeights(tradeResult);
    } catch (error) {
      console.error("Failed to update learning weights:", error);
    }
  }

  // Get recent trades
  async getRecentTrades(limit: number = 50): Promise<TradeRecord[]> {
    const result = await db.query.trades.findMany({
      orderBy: [desc(trades.createdAt)],
      limit,
    });
    return result as TradeRecord[];
  }

  // Get trade statistics
  async getStats(since?: number): Promise<TradeStats> {
    const whereClause = since
      ? gte(trades.createdAt, since)
      : undefined;

    const allTrades = await db.query.trades.findMany({
      where: whereClause,
    });

    const completed = allTrades.filter((t) => t.result !== null);
    const wins = completed.filter((t) => t.result === "WIN");
    const losses = completed.filter((t) => t.result === "LOSE");
    const pending = allTrades.filter((t) => t.result === null);

    const highTrades = completed.filter((t) => t.direction === "HIGH");
    const highWins = highTrades.filter((t) => t.result === "WIN");

    const lowTrades = completed.filter((t) => t.direction === "LOW");
    const lowWins = lowTrades.filter((t) => t.result === "WIN");

    const totalPayout = completed.reduce((sum, t) => sum + (t.payout || 0), 0);

    return {
      totalTrades: allTrades.length,
      wins: wins.length,
      losses: losses.length,
      pending: pending.length,
      winRate: completed.length > 0 ? (wins.length / completed.length) * 100 : 0,
      highWins: highWins.length,
      highTotal: highTrades.length,
      highWinRate:
        highTrades.length > 0 ? (highWins.length / highTrades.length) * 100 : 0,
      lowWins: lowWins.length,
      lowTotal: lowTrades.length,
      lowWinRate:
        lowTrades.length > 0 ? (lowWins.length / lowTrades.length) * 100 : 0,
      totalPayout,
    };
  }

  // Get trades by date range
  async getTradesByDateRange(
    startTime: number,
    endTime: number
  ): Promise<TradeRecord[]> {
    const result = await db.query.trades.findMany({
      where: and(
        gte(trades.entryTime, startTime),
        sql`${trades.entryTime} <= ${endTime}`
      ),
      orderBy: [desc(trades.entryTime)],
    });
    return result as TradeRecord[];
  }

  // Delete a trade
  async deleteTrade(tradeId: number): Promise<boolean> {
    const result = await db.delete(trades).where(eq(trades.id, tradeId));
    return true;
  }

  // Get pending trades (for auto-completion)
  async getPendingTrades(): Promise<TradeRecord[]> {
    const result = await db.query.trades.findMany({
      where: sql`${trades.result} IS NULL`,
      orderBy: [desc(trades.entryTime)],
    });
    return result as TradeRecord[];
  }
}

export const tradeService = new TradeService();
