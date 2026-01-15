"use client";

import { useState, useEffect, useCallback } from "react";
import { TradeRecord, TradeStats } from "@/lib/trade-service";

interface TradeHistoryProps {
  onRecordTrade?: (direction: "HIGH" | "LOW", price: number) => void;
}

export default function TradeHistory({ onRecordTrade }: TradeHistoryProps) {
  const [trades, setTrades] = useState<TradeRecord[]>([]);
  const [stats, setStats] = useState<TradeStats | null>(null);
  const [loading, setLoading] = useState(true);

  const fetchTrades = useCallback(async () => {
    try {
      const response = await fetch("/api/trades?limit=20");
      const data = await response.json();
      setTrades(data.trades || []);
      setStats(data.stats || null);
    } catch (error) {
      console.error("Failed to fetch trades:", error);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchTrades();
    const interval = setInterval(fetchTrades, 5000);
    return () => clearInterval(interval);
  }, [fetchTrades]);

  const formatTime = (timestamp: number) => {
    return new Date(timestamp).toLocaleTimeString("ja-JP", {
      timeZone: "Asia/Tokyo",
      hour: "2-digit",
      minute: "2-digit",
      second: "2-digit",
    });
  };

  const formatDate = (timestamp: number) => {
    return new Date(timestamp).toLocaleDateString("ja-JP", {
      timeZone: "Asia/Tokyo",
      month: "2-digit",
      day: "2-digit",
    });
  };

  return (
    <div className="bg-slate-800 rounded-lg p-4">
      <h3 className="text-sm font-medium text-slate-400 mb-3">Trade History</h3>

      {/* Statistics */}
      {stats && (
        <div className="grid grid-cols-3 gap-2 mb-4 text-xs">
          <div className="bg-slate-700 rounded p-2 text-center">
            <div className="text-slate-400">Win Rate</div>
            <div
              className={`font-bold text-lg ${
                stats.winRate >= 55
                  ? "text-green-400"
                  : stats.winRate >= 50
                  ? "text-yellow-400"
                  : "text-red-400"
              }`}
            >
              {stats.winRate.toFixed(1)}%
            </div>
            <div className="text-slate-500">
              {stats.wins}W / {stats.losses}L
            </div>
          </div>
          <div className="bg-slate-700 rounded p-2 text-center">
            <div className="text-slate-400">HIGH</div>
            <div
              className={`font-bold ${
                stats.highWinRate >= 55 ? "text-green-400" : "text-slate-300"
              }`}
            >
              {stats.highWinRate.toFixed(1)}%
            </div>
            <div className="text-slate-500">
              {stats.highWins}/{stats.highTotal}
            </div>
          </div>
          <div className="bg-slate-700 rounded p-2 text-center">
            <div className="text-slate-400">LOW</div>
            <div
              className={`font-bold ${
                stats.lowWinRate >= 55 ? "text-green-400" : "text-slate-300"
              }`}
            >
              {stats.lowWinRate.toFixed(1)}%
            </div>
            <div className="text-slate-500">
              {stats.lowWins}/{stats.lowTotal}
            </div>
          </div>
        </div>
      )}

      {/* Trade List */}
      <div className="max-h-64 overflow-y-auto">
        {loading ? (
          <div className="text-center text-slate-500 py-4">Loading...</div>
        ) : trades.length === 0 ? (
          <div className="text-center text-slate-500 py-4">No trades yet</div>
        ) : (
          <table className="w-full text-xs">
            <thead className="text-slate-400 border-b border-slate-700">
              <tr>
                <th className="text-left py-1">Time</th>
                <th className="text-left py-1">Dir</th>
                <th className="text-right py-1">Entry</th>
                <th className="text-right py-1">Exit</th>
                <th className="text-center py-1">Result</th>
              </tr>
            </thead>
            <tbody>
              {trades.map((trade) => (
                <tr
                  key={trade.id}
                  className="border-b border-slate-700/50 hover:bg-slate-700/30"
                >
                  <td className="py-1 text-slate-400">
                    <div>{formatDate(trade.entryTime)}</div>
                    <div>{formatTime(trade.entryTime)}</div>
                  </td>
                  <td
                    className={`py-1 font-bold ${
                      trade.direction === "HIGH"
                        ? "text-green-400"
                        : "text-red-400"
                    }`}
                  >
                    {trade.direction}
                  </td>
                  <td className="py-1 text-right text-slate-300">
                    {trade.entryPrice.toFixed(3)}
                  </td>
                  <td className="py-1 text-right text-slate-300">
                    {trade.exitPrice ? trade.exitPrice.toFixed(3) : "---"}
                  </td>
                  <td className="py-1 text-center">
                    {trade.result === "WIN" ? (
                      <span className="text-green-400 font-bold">WIN</span>
                    ) : trade.result === "LOSE" ? (
                      <span className="text-red-400 font-bold">LOSE</span>
                    ) : (
                      <span className="text-yellow-400">Pending</span>
                    )}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>

      {/* Payout Summary */}
      {stats && stats.totalTrades > 0 && (
        <div className="mt-3 pt-3 border-t border-slate-700 text-xs">
          <div className="flex justify-between">
            <span className="text-slate-400">Total P/L:</span>
            <span
              className={`font-bold ${
                stats.totalPayout >= 0 ? "text-green-400" : "text-red-400"
              }`}
            >
              {stats.totalPayout >= 0 ? "+" : ""}
              {stats.totalPayout.toFixed(2)}
            </span>
          </div>
        </div>
      )}
    </div>
  );
}
