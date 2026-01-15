import { sqliteTable, text, integer, real } from "drizzle-orm/sqlite-core";

// Price data (OHLCV)
export const prices = sqliteTable("prices", {
  id: integer("id").primaryKey({ autoIncrement: true }),
  timestamp: integer("timestamp").notNull(), // Unix timestamp
  open: real("open").notNull(),
  high: real("high").notNull(),
  low: real("low").notNull(),
  close: real("close").notNull(),
  volume: real("volume"),
  timeframe: text("timeframe").notNull().default("1m"), // 1m, 5m, 15m
  createdAt: integer("created_at").notNull().$defaultFn(() => Date.now()),
});

// Trading signals
export const signals = sqliteTable("signals", {
  id: integer("id").primaryKey({ autoIncrement: true }),
  timestamp: integer("timestamp").notNull(),
  direction: text("direction").notNull(), // HIGH or LOW
  score: real("score").notNull(),
  strictLevel: integer("strict_level").notNull().default(2),
  indicators: text("indicators"), // JSON string of indicator values
  createdAt: integer("created_at").notNull().$defaultFn(() => Date.now()),
});

// Trade records
export const trades = sqliteTable("trades", {
  id: integer("id").primaryKey({ autoIncrement: true }),
  signalId: integer("signal_id").references(() => signals.id),
  entryTime: integer("entry_time").notNull(),
  entryPrice: real("entry_price").notNull(),
  direction: text("direction").notNull(), // HIGH or LOW
  exitTime: integer("exit_time"),
  exitPrice: real("exit_price"),
  result: text("result"), // WIN, LOSE, or null (pending)
  payout: real("payout"),
  createdAt: integer("created_at").notNull().$defaultFn(() => Date.now()),
});

// Model weights for self-learning
export const modelWeights = sqliteTable("model_weights", {
  id: integer("id").primaryKey({ autoIncrement: true }),
  name: text("name").notNull().unique(), // e.g., "rsi_weight", "macd_weight"
  value: real("value").notNull(),
  updatedAt: integer("updated_at").notNull().$defaultFn(() => Date.now()),
});

// App settings (key-value store)
export const appSettings = sqliteTable("app_settings", {
  id: integer("id").primaryKey({ autoIncrement: true }),
  key: text("key").notNull().unique(),
  value: text("value").notNull(), // JSON string
  updatedAt: integer("updated_at").notNull().$defaultFn(() => Date.now()),
});

// ML Prediction weights
export const predictionWeights = sqliteTable("prediction_weights", {
  id: integer("id").primaryKey({ autoIncrement: true }),
  name: text("name").notNull().unique(), // e.g., "emaTrend", "macdHist", "bias"
  value: real("value").notNull(),
  updatedAt: integer("updated_at").notNull().$defaultFn(() => Date.now()),
});

// ML Prediction history
export const predictionHistory = sqliteTable("prediction_history", {
  id: integer("id").primaryKey({ autoIncrement: true }),
  timestamp: integer("timestamp").notNull(), // Candle timestamp
  prediction: text("prediction").notNull(), // HIGH or LOW
  actual: text("actual"), // HIGH, LOW, or null (pending)
  confidence: real("confidence").notNull(), // 0-1
  probability: real("probability").notNull(), // Raw probability
  features: text("features"), // JSON string of feature values
  correct: integer("correct"), // 1 = correct, 0 = incorrect, null = pending
  createdAt: integer("created_at").notNull().$defaultFn(() => Date.now()),
});

// Type exports
export type Price = typeof prices.$inferSelect;
export type NewPrice = typeof prices.$inferInsert;
export type Signal = typeof signals.$inferSelect;
export type NewSignal = typeof signals.$inferInsert;
export type Trade = typeof trades.$inferSelect;
export type NewTrade = typeof trades.$inferInsert;
export type ModelWeight = typeof modelWeights.$inferSelect;
export type NewModelWeight = typeof modelWeights.$inferInsert;
export type AppSetting = typeof appSettings.$inferSelect;
export type NewAppSetting = typeof appSettings.$inferInsert;
export type PredictionWeight = typeof predictionWeights.$inferSelect;
export type NewPredictionWeight = typeof predictionWeights.$inferInsert;
export type PredictionHistoryRecord = typeof predictionHistory.$inferSelect;
export type NewPredictionHistoryRecord = typeof predictionHistory.$inferInsert;
