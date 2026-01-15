// Prediction Service - Manages ML predictions with database persistence

import { db, predictionWeights, predictionHistory } from "@/db";
import { eq, desc } from "drizzle-orm";
import {
  predictionEngine,
  PredictionResult,
  WeightName,
  Features,
} from "./prediction-engine";
import { OHLC } from "./indicators";

// All weight names
const WEIGHT_NAMES: WeightName[] = [
  "emaTrend",
  "macdHist",
  "adxStrength",
  "rsiNorm",
  "stochK",
  "stochCross",
  "bbPosition",
  "priceMomentum",
  "candlePattern",
  "bias",
];

class PredictionService {
  private initialized = false;
  private lastPrediction: PredictionResult | null = null;
  private lastCandleTimestamp: number = 0;

  /**
   * Initialize prediction engine with weights from database
   */
  async initialize(): Promise<void> {
    if (this.initialized) return;

    try {
      const weights = await db.query.predictionWeights.findMany();

      if (weights.length > 0) {
        const weightMap: Record<WeightName, number> = {} as Record<
          WeightName,
          number
        >;

        for (const w of weights) {
          weightMap[w.name as WeightName] = w.value;
        }

        // Fill missing weights with defaults
        const currentWeights = predictionEngine.getWeights();
        for (const name of WEIGHT_NAMES) {
          if (!(name in weightMap)) {
            weightMap[name] = currentWeights[name];
          }
        }

        predictionEngine.setWeights(weightMap);
      }

      this.initialized = true;
    } catch (error) {
      console.error("Failed to initialize prediction service:", error);
      this.initialized = true; // Continue with defaults
    }
  }

  /**
   * Save current weights to database
   */
  async saveWeights(): Promise<void> {
    const weights = predictionEngine.getWeights();

    for (const name of WEIGHT_NAMES) {
      const existing = await db.query.predictionWeights.findFirst({
        where: eq(predictionWeights.name, name),
      });

      if (existing) {
        await db
          .update(predictionWeights)
          .set({ value: weights[name], updatedAt: Date.now() })
          .where(eq(predictionWeights.name, name));
      } else {
        await db.insert(predictionWeights).values({
          name,
          value: weights[name],
        });
      }
    }
  }

  /**
   * Make a prediction for the next candle
   */
  async predict(candles: OHLC[]): Promise<PredictionResult | null> {
    await this.initialize();

    const prediction = predictionEngine.predict(candles);
    if (prediction) {
      this.lastPrediction = prediction;
    }

    return prediction;
  }

  /**
   * Record a prediction to history
   */
  async recordPrediction(
    timestamp: number,
    prediction: PredictionResult
  ): Promise<void> {
    // Avoid duplicate predictions for the same candle
    if (timestamp === this.lastCandleTimestamp) {
      return;
    }
    this.lastCandleTimestamp = timestamp;

    await db.insert(predictionHistory).values({
      timestamp,
      prediction: prediction.direction,
      confidence: prediction.confidence,
      probability: prediction.probability,
      features: JSON.stringify(prediction.features),
    });
  }

  /**
   * Update prediction with actual result and train model
   */
  async updateWithActual(
    timestamp: number,
    actualDirection: "HIGH" | "LOW"
  ): Promise<{ loss: number; accuracy: number } | null> {
    // Find the prediction for this timestamp
    const record = await db.query.predictionHistory.findFirst({
      where: eq(predictionHistory.timestamp, timestamp),
    });

    if (!record || record.actual !== null) {
      return null; // Already updated or not found
    }

    // Parse features
    const features: Features = JSON.parse(record.features || "{}");

    // Train the model
    const result = predictionEngine.train(features, actualDirection);

    // Update the record
    await db
      .update(predictionHistory)
      .set({
        actual: actualDirection,
        correct: record.prediction === actualDirection ? 1 : 0,
      })
      .where(eq(predictionHistory.id, record.id));

    // Save weights periodically (every 10 updates)
    const stats = predictionEngine.getStats();
    if (stats.trainingCount % 10 === 0) {
      await this.saveWeights();
    }

    return result;
  }

  /**
   * Get prediction accuracy from history
   */
  async getAccuracy(limit: number = 100): Promise<{
    total: number;
    correct: number;
    accuracy: number;
  }> {
    const history = await db.query.predictionHistory.findMany({
      orderBy: [desc(predictionHistory.timestamp)],
      limit,
    });

    const completed = history.filter((h) => h.correct !== null);
    const correct = completed.filter((h) => h.correct === 1).length;

    return {
      total: completed.length,
      correct,
      accuracy: completed.length > 0 ? correct / completed.length : 0,
    };
  }

  /**
   * Get recent prediction history
   */
  async getHistory(limit: number = 50): Promise<
    Array<{
      timestamp: number;
      prediction: string;
      actual: string | null;
      confidence: number;
      correct: boolean | null;
    }>
  > {
    const history = await db.query.predictionHistory.findMany({
      orderBy: [desc(predictionHistory.timestamp)],
      limit,
    });

    return history.map((h) => ({
      timestamp: h.timestamp,
      prediction: h.prediction,
      actual: h.actual,
      confidence: h.confidence,
      correct: h.correct === null ? null : h.correct === 1,
    }));
  }

  /**
   * Get current weights
   */
  async getWeights(): Promise<Record<WeightName, number>> {
    await this.initialize();
    return predictionEngine.getWeights();
  }

  /**
   * Reset model to default weights
   */
  async reset(): Promise<void> {
    predictionEngine.reset();
    await this.saveWeights();

    // Clear history
    await db.delete(predictionHistory);
  }
}

// Singleton instance
export const predictionService = new PredictionService();
