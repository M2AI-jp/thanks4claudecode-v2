// Learning Engine for self-optimizing signal weights
import { db, modelWeights, type ModelWeight } from "@/db";
import { eq } from "drizzle-orm";

// Weight names matching ScoreComponents
export const WEIGHT_NAMES = [
  "ema_weight",
  "macd_weight",
  "adx_weight",
  "rsi_weight",
  "stoch_weight",
  "price_weight",
  "candle_weight",
] as const;

export type WeightName = (typeof WEIGHT_NAMES)[number];

// Default weights (all start at 1.0)
export const DEFAULT_WEIGHTS: Record<WeightName, number> = {
  ema_weight: 1.0,
  macd_weight: 1.0,
  adx_weight: 1.0,
  rsi_weight: 1.0,
  stoch_weight: 1.0,
  price_weight: 1.0,
  candle_weight: 1.0,
};

// Weight constraints
const MIN_WEIGHT = 0.5;
const MAX_WEIGHT = 2.0;
const LEARNING_RATE = 0.1;

// Component scores from signal
export interface ComponentScores {
  ema: number;
  macd: number;
  adx: number;
  rsi: number;
  stoch: number;
  price: number;
  candle: number;
}

// Trade result for learning
export interface TradeResult {
  direction: "HIGH" | "LOW";
  result: "WIN" | "LOSE";
  components: ComponentScores;
}

class LearningEngine {
  private weightsCache: Record<WeightName, number> | null = null;
  private lastCacheUpdate: number = 0;
  private readonly CACHE_TTL = 60000; // 1 minute

  // Initialize weights in database if not exists
  async initializeWeights(): Promise<void> {
    for (const name of WEIGHT_NAMES) {
      const existing = await db.query.modelWeights.findFirst({
        where: eq(modelWeights.name, name),
      });

      if (!existing) {
        await db.insert(modelWeights).values({
          name,
          value: DEFAULT_WEIGHTS[name],
        });
      }
    }
    this.weightsCache = null; // Invalidate cache
  }

  // Get current weights from database (with caching)
  async getWeights(): Promise<Record<WeightName, number>> {
    const now = Date.now();

    // Return cached weights if still valid
    if (this.weightsCache && now - this.lastCacheUpdate < this.CACHE_TTL) {
      return this.weightsCache;
    }

    const weights: Record<WeightName, number> = { ...DEFAULT_WEIGHTS };

    const dbWeights = await db.query.modelWeights.findMany();

    for (const w of dbWeights) {
      if (WEIGHT_NAMES.includes(w.name as WeightName)) {
        weights[w.name as WeightName] = w.value;
      }
    }

    this.weightsCache = weights;
    this.lastCacheUpdate = now;

    return weights;
  }

  // Update weights based on trade result
  async updateWeights(tradeResult: TradeResult): Promise<void> {
    const { result, components } = tradeResult;

    // Calculate average component score
    const scores = Object.values(components);
    const avgScore = scores.reduce((a, b) => a + b, 0) / scores.length;

    // Get current weights
    const weights = await this.getWeights();

    // Update each weight based on result
    const updates: Array<{ name: WeightName; value: number }> = [];

    for (const [key, score] of Object.entries(components)) {
      const weightName = `${key}_weight` as WeightName;
      const currentWeight = weights[weightName];

      // Determine adjustment based on whether this component contributed
      // If score > avg, this component was more influential
      const influence = score > avgScore ? 0.1 : 0.05;
      let adjustment = LEARNING_RATE * influence;

      if (result === "WIN") {
        // Increase weight for winning components
        adjustment = adjustment;
      } else {
        // Decrease weight for losing components
        adjustment = -adjustment;
      }

      // Calculate new weight with clamping
      let newWeight = currentWeight + adjustment;
      newWeight = Math.max(MIN_WEIGHT, Math.min(MAX_WEIGHT, newWeight));

      updates.push({ name: weightName, value: newWeight });
    }

    // Batch update to database
    for (const update of updates) {
      await db
        .update(modelWeights)
        .set({ value: update.value, updatedAt: Date.now() })
        .where(eq(modelWeights.name, update.name));
    }

    // Invalidate cache
    this.weightsCache = null;
  }

  // Get weight statistics with correlation to win rate
  async getWeightStats(): Promise<{
    weights: Record<WeightName, number>;
    metadata: Record<WeightName, { updatedAt: number }>;
  }> {
    const weights = await this.getWeights();
    const metadata: Record<WeightName, { updatedAt: number }> = {} as Record<
      WeightName,
      { updatedAt: number }
    >;

    const dbWeights = await db.query.modelWeights.findMany();

    for (const w of dbWeights) {
      if (WEIGHT_NAMES.includes(w.name as WeightName)) {
        metadata[w.name as WeightName] = { updatedAt: w.updatedAt };
      }
    }

    return { weights, metadata };
  }

  // Reset weights to default
  async resetWeights(): Promise<void> {
    for (const name of WEIGHT_NAMES) {
      await db
        .update(modelWeights)
        .set({ value: DEFAULT_WEIGHTS[name], updatedAt: Date.now() })
        .where(eq(modelWeights.name, name));
    }
    this.weightsCache = null;
  }

  // Convert component name to weight name
  static componentToWeightName(component: keyof ComponentScores): WeightName {
    return `${component}_weight` as WeightName;
  }

  // Apply weights to component scores
  applyWeights(
    components: ComponentScores,
    weights: Record<WeightName, number>
  ): ComponentScores {
    return {
      ema: components.ema * weights.ema_weight,
      macd: components.macd * weights.macd_weight,
      adx: components.adx * weights.adx_weight,
      rsi: components.rsi * weights.rsi_weight,
      stoch: components.stoch * weights.stoch_weight,
      price: components.price * weights.price_weight,
      candle: components.candle * weights.candle_weight,
    };
  }

  // Calculate weighted total
  calculateWeightedTotal(weightedComponents: ComponentScores): number {
    return (
      weightedComponents.ema +
      weightedComponents.macd +
      weightedComponents.adx +
      weightedComponents.rsi +
      weightedComponents.stoch +
      weightedComponents.price +
      weightedComponents.candle
    );
  }
}

// Singleton with globalThis for Next.js compatibility
const globalForLearningEngine = globalThis as unknown as {
  learningEngine: LearningEngine | undefined;
};

export const learningEngine =
  globalForLearningEngine.learningEngine ?? new LearningEngine();

if (process.env.NODE_ENV !== "production") {
  globalForLearningEngine.learningEngine = learningEngine;
}
