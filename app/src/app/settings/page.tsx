"use client";

import { useState, useEffect, useCallback } from "react";
import Link from "next/link";

interface Settings {
  signal: {
    minScore: number;
    strictLevel: 1 | 2 | 3;
    cooldownBars: number;
  };
  indicators: {
    rsiOverbought: number;
    rsiOversold: number;
    adxThreshold: number;
    stochOB: number;
    stochOS: number;
  };
  learning: {
    learningRate: number;
    minWeight: number;
    maxWeight: number;
  };
  api: {
    apiKey: string;
    pollingMode: "normal" | "signal";
  };
}

interface WeightData {
  weights: Record<string, number>;
  defaults: Record<string, number>;
  weightChanges: Record<string, number>;
  tradeStats: {
    totalTrades: number;
    winRate: number;
  };
}

const DEFAULT_SETTINGS: Settings = {
  signal: {
    minScore: 4,
    strictLevel: 2,
    cooldownBars: 10,
  },
  indicators: {
    rsiOverbought: 70,
    rsiOversold: 30,
    adxThreshold: 25,
    stochOB: 80,
    stochOS: 20,
  },
  learning: {
    learningRate: 0.1,
    minWeight: 0.5,
    maxWeight: 2.0,
  },
  api: {
    apiKey: "",
    pollingMode: "normal",
  },
};

export default function SettingsPage() {
  const [settings, setSettings] = useState<Settings>(DEFAULT_SETTINGS);
  const [weights, setWeights] = useState<WeightData | null>(null);
  const [saving, setSaving] = useState(false);
  const [message, setMessage] = useState<{ type: "success" | "error"; text: string } | null>(null);
  const [activeTab, setActiveTab] = useState<"signal" | "indicators" | "learning" | "api" | "weights">("signal");

  // Fetch current settings
  useEffect(() => {
    const fetchSettings = async () => {
      try {
        const response = await fetch("/api/settings");
        if (response.ok) {
          const data = await response.json();
          setSettings(data.settings || DEFAULT_SETTINGS);
        }
      } catch (error) {
        console.error("Failed to fetch settings:", error);
      }
    };
    fetchSettings();
  }, []);

  // Fetch weights
  useEffect(() => {
    const fetchWeights = async () => {
      try {
        const response = await fetch("/api/weights");
        if (response.ok) {
          const data = await response.json();
          setWeights(data);
        }
      } catch (error) {
        console.error("Failed to fetch weights:", error);
      }
    };
    fetchWeights();
  }, []);

  const saveSettings = useCallback(async () => {
    setSaving(true);
    setMessage(null);
    try {
      const response = await fetch("/api/settings", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ settings }),
      });

      if (response.ok) {
        setMessage({ type: "success", text: "設定を保存しました" });
      } else {
        throw new Error("Failed to save");
      }
    } catch (error) {
      setMessage({ type: "error", text: "設定の保存に失敗しました" });
    } finally {
      setSaving(false);
    }
  }, [settings]);

  const resetWeights = useCallback(async () => {
    if (!confirm("重みをデフォルトにリセットしますか？")) return;

    try {
      const response = await fetch("/api/weights", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ action: "reset" }),
      });

      if (response.ok) {
        setMessage({ type: "success", text: "重みをリセットしました" });
        // Refresh weights
        const weightsResponse = await fetch("/api/weights");
        if (weightsResponse.ok) {
          setWeights(await weightsResponse.json());
        }
      }
    } catch (error) {
      setMessage({ type: "error", text: "リセットに失敗しました" });
    }
  }, []);

  const updateSetting = <K extends keyof Settings>(
    category: K,
    key: keyof Settings[K],
    value: Settings[K][keyof Settings[K]]
  ) => {
    setSettings((prev) => ({
      ...prev,
      [category]: {
        ...prev[category],
        [key]: value,
      },
    }));
  };

  return (
    <div className="min-h-screen bg-slate-900 text-white p-4">
      <div className="max-w-4xl mx-auto">
        {/* Header */}
        <div className="flex items-center justify-between mb-6">
          <h1 className="text-2xl font-bold">設定</h1>
          <Link
            href="/"
            className="px-4 py-2 bg-slate-700 hover:bg-slate-600 rounded-lg text-sm"
          >
            ← チャートに戻る
          </Link>
        </div>

        {/* Message */}
        {message && (
          <div
            className={`mb-4 p-3 rounded-lg ${
              message.type === "success"
                ? "bg-green-600/20 text-green-400 border border-green-600"
                : "bg-red-600/20 text-red-400 border border-red-600"
            }`}
          >
            {message.text}
          </div>
        )}

        {/* Tabs */}
        <div className="flex gap-2 mb-6 overflow-x-auto">
          {[
            { id: "signal", label: "シグナル" },
            { id: "indicators", label: "インジケーター" },
            { id: "learning", label: "学習エンジン" },
            { id: "api", label: "API設定" },
            { id: "weights", label: "重み管理" },
          ].map((tab) => (
            <button
              key={tab.id}
              onClick={() => setActiveTab(tab.id as typeof activeTab)}
              className={`px-4 py-2 rounded-lg text-sm whitespace-nowrap transition-colors ${
                activeTab === tab.id
                  ? "bg-blue-600 text-white"
                  : "bg-slate-800 text-slate-300 hover:bg-slate-700"
              }`}
            >
              {tab.label}
            </button>
          ))}
        </div>

        {/* Tab Content */}
        <div className="bg-slate-800 rounded-lg p-6">
          {/* Signal Settings */}
          {activeTab === "signal" && (
            <div className="space-y-6">
              <h2 className="text-lg font-semibold mb-4">シグナル設定</h2>

              <div>
                <label className="block text-sm text-slate-400 mb-2">
                  最小スコア (minScore)
                </label>
                <input
                  type="number"
                  value={settings.signal.minScore}
                  onChange={(e) =>
                    updateSetting("signal", "minScore", parseFloat(e.target.value))
                  }
                  className="w-full bg-slate-700 rounded px-3 py-2 text-white"
                  step="0.5"
                  min="1"
                  max="10"
                />
                <p className="text-xs text-slate-500 mt-1">
                  シグナル発生に必要な最低スコア（推奨: 4）
                </p>
              </div>

              <div>
                <label className="block text-sm text-slate-400 mb-2">
                  厳格レベル (strictLevel)
                </label>
                <div className="flex gap-2">
                  {([1, 2, 3] as const).map((level) => (
                    <button
                      key={level}
                      onClick={() => updateSetting("signal", "strictLevel", level)}
                      className={`flex-1 py-2 rounded ${
                        settings.signal.strictLevel === level
                          ? "bg-blue-600 text-white"
                          : "bg-slate-700 text-slate-300"
                      }`}
                    >
                      {level} - {level === 1 ? "緩い" : level === 2 ? "標準" : "厳格"}
                    </button>
                  ))}
                </div>
              </div>

              <div>
                <label className="block text-sm text-slate-400 mb-2">
                  クールダウン (bars)
                </label>
                <input
                  type="number"
                  value={settings.signal.cooldownBars}
                  onChange={(e) =>
                    updateSetting("signal", "cooldownBars", parseInt(e.target.value))
                  }
                  className="w-full bg-slate-700 rounded px-3 py-2 text-white"
                  min="1"
                  max="50"
                />
                <p className="text-xs text-slate-500 mt-1">
                  シグナル発生後の待機バー数
                </p>
              </div>
            </div>
          )}

          {/* Indicator Settings */}
          {activeTab === "indicators" && (
            <div className="space-y-6">
              <h2 className="text-lg font-semibold mb-4">インジケーター設定</h2>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm text-slate-400 mb-2">
                    RSI 買われ過ぎ
                  </label>
                  <input
                    type="number"
                    value={settings.indicators.rsiOverbought}
                    onChange={(e) =>
                      updateSetting("indicators", "rsiOverbought", parseInt(e.target.value))
                    }
                    className="w-full bg-slate-700 rounded px-3 py-2 text-white"
                    min="50"
                    max="90"
                  />
                </div>
                <div>
                  <label className="block text-sm text-slate-400 mb-2">
                    RSI 売られ過ぎ
                  </label>
                  <input
                    type="number"
                    value={settings.indicators.rsiOversold}
                    onChange={(e) =>
                      updateSetting("indicators", "rsiOversold", parseInt(e.target.value))
                    }
                    className="w-full bg-slate-700 rounded px-3 py-2 text-white"
                    min="10"
                    max="50"
                  />
                </div>
              </div>

              <div>
                <label className="block text-sm text-slate-400 mb-2">
                  ADX 閾値
                </label>
                <input
                  type="number"
                  value={settings.indicators.adxThreshold}
                  onChange={(e) =>
                    updateSetting("indicators", "adxThreshold", parseInt(e.target.value))
                  }
                  className="w-full bg-slate-700 rounded px-3 py-2 text-white"
                  min="10"
                  max="50"
                />
                <p className="text-xs text-slate-500 mt-1">
                  強いトレンドと判定するADXの閾値（推奨: 25）
                </p>
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm text-slate-400 mb-2">
                    Stochastic 買われ過ぎ
                  </label>
                  <input
                    type="number"
                    value={settings.indicators.stochOB}
                    onChange={(e) =>
                      updateSetting("indicators", "stochOB", parseInt(e.target.value))
                    }
                    className="w-full bg-slate-700 rounded px-3 py-2 text-white"
                    min="60"
                    max="95"
                  />
                </div>
                <div>
                  <label className="block text-sm text-slate-400 mb-2">
                    Stochastic 売られ過ぎ
                  </label>
                  <input
                    type="number"
                    value={settings.indicators.stochOS}
                    onChange={(e) =>
                      updateSetting("indicators", "stochOS", parseInt(e.target.value))
                    }
                    className="w-full bg-slate-700 rounded px-3 py-2 text-white"
                    min="5"
                    max="40"
                  />
                </div>
              </div>
            </div>
          )}

          {/* Learning Engine Settings */}
          {activeTab === "learning" && (
            <div className="space-y-6">
              <h2 className="text-lg font-semibold mb-4">学習エンジン設定</h2>

              <div>
                <label className="block text-sm text-slate-400 mb-2">
                  学習率
                </label>
                <input
                  type="number"
                  value={settings.learning.learningRate}
                  onChange={(e) =>
                    updateSetting("learning", "learningRate", parseFloat(e.target.value))
                  }
                  className="w-full bg-slate-700 rounded px-3 py-2 text-white"
                  step="0.01"
                  min="0.01"
                  max="0.5"
                />
                <p className="text-xs text-slate-500 mt-1">
                  重み更新の速度（小さいほど安定、大きいほど敏感）
                </p>
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm text-slate-400 mb-2">
                    最小重み
                  </label>
                  <input
                    type="number"
                    value={settings.learning.minWeight}
                    onChange={(e) =>
                      updateSetting("learning", "minWeight", parseFloat(e.target.value))
                    }
                    className="w-full bg-slate-700 rounded px-3 py-2 text-white"
                    step="0.1"
                    min="0.1"
                    max="1.0"
                  />
                </div>
                <div>
                  <label className="block text-sm text-slate-400 mb-2">
                    最大重み
                  </label>
                  <input
                    type="number"
                    value={settings.learning.maxWeight}
                    onChange={(e) =>
                      updateSetting("learning", "maxWeight", parseFloat(e.target.value))
                    }
                    className="w-full bg-slate-700 rounded px-3 py-2 text-white"
                    step="0.1"
                    min="1.0"
                    max="5.0"
                  />
                </div>
              </div>
            </div>
          )}

          {/* API Settings */}
          {activeTab === "api" && (
            <div className="space-y-6">
              <h2 className="text-lg font-semibold mb-4">API設定</h2>

              <div>
                <label className="block text-sm text-slate-400 mb-2">
                  Twelve Data API Key
                </label>
                <input
                  type="password"
                  value={settings.api.apiKey}
                  onChange={(e) => updateSetting("api", "apiKey", e.target.value)}
                  className="w-full bg-slate-700 rounded px-3 py-2 text-white"
                  placeholder="APIキーを入力"
                />
                <p className="text-xs text-slate-500 mt-1">
                  <a
                    href="https://twelvedata.com"
                    target="_blank"
                    rel="noopener noreferrer"
                    className="text-blue-400 hover:underline"
                  >
                    Twelve Data
                  </a>
                  でAPIキーを取得できます（無料: 800コール/日）
                </p>
              </div>

              <div>
                <label className="block text-sm text-slate-400 mb-2">
                  ポーリングモード
                </label>
                <div className="flex gap-2">
                  {(["normal", "signal"] as const).map((mode) => (
                    <button
                      key={mode}
                      onClick={() => updateSetting("api", "pollingMode", mode)}
                      className={`flex-1 py-2 rounded ${
                        settings.api.pollingMode === mode
                          ? "bg-blue-600 text-white"
                          : "bg-slate-700 text-slate-300"
                      }`}
                    >
                      {mode === "normal" ? "通常 (5分間隔)" : "シグナル (30秒間隔)"}
                    </button>
                  ))}
                </div>
              </div>
            </div>
          )}

          {/* Weight Management */}
          {activeTab === "weights" && (
            <div className="space-y-6">
              <h2 className="text-lg font-semibold mb-4">重み管理</h2>

              {weights ? (
                <>
                  <div className="bg-slate-700 rounded-lg p-4">
                    <h3 className="text-sm font-medium text-slate-400 mb-3">
                      統計
                    </h3>
                    <div className="grid grid-cols-2 gap-4 text-sm">
                      <div>
                        <span className="text-slate-400">総トレード数:</span>
                        <span className="ml-2 text-white">{weights.tradeStats.totalTrades}</span>
                      </div>
                      <div>
                        <span className="text-slate-400">勝率:</span>
                        <span className={`ml-2 ${weights.tradeStats.winRate >= 55 ? "text-green-400" : "text-white"}`}>
                          {weights.tradeStats.winRate.toFixed(1)}%
                        </span>
                      </div>
                    </div>
                  </div>

                  <div className="bg-slate-700 rounded-lg p-4">
                    <h3 className="text-sm font-medium text-slate-400 mb-3">
                      現在の重み
                    </h3>
                    <div className="space-y-2">
                      {Object.entries(weights.weights).map(([key, value]) => {
                        const change = weights.weightChanges[key] || 0;
                        return (
                          <div key={key} className="flex items-center justify-between text-sm">
                            <span className="text-slate-300">{key.replace("_weight", "")}</span>
                            <div className="flex items-center gap-2">
                              <span className="text-white">{(value as number).toFixed(3)}</span>
                              {change !== 0 && (
                                <span
                                  className={`text-xs ${
                                    change > 0 ? "text-green-400" : "text-red-400"
                                  }`}
                                >
                                  ({change > 0 ? "+" : ""}{change.toFixed(3)})
                                </span>
                              )}
                            </div>
                          </div>
                        );
                      })}
                    </div>
                  </div>

                  <button
                    onClick={resetWeights}
                    className="w-full py-2 bg-red-600/20 hover:bg-red-600/30 text-red-400 rounded-lg border border-red-600"
                  >
                    重みをデフォルトにリセット
                  </button>
                </>
              ) : (
                <p className="text-slate-400">読み込み中...</p>
              )}
            </div>
          )}
        </div>

        {/* Save Button */}
        {activeTab !== "weights" && (
          <div className="mt-6">
            <button
              onClick={saveSettings}
              disabled={saving}
              className={`w-full py-3 rounded-lg font-semibold ${
                saving
                  ? "bg-slate-600 text-slate-400 cursor-not-allowed"
                  : "bg-blue-600 hover:bg-blue-500 text-white"
              }`}
            >
              {saving ? "保存中..." : "設定を保存"}
            </button>
          </div>
        )}
      </div>
    </div>
  );
}
