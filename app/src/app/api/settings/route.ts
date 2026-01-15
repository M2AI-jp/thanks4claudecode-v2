import { NextResponse } from "next/server";
import { db, appSettings } from "@/db";
import { eq } from "drizzle-orm";

// Settings keys
const SETTINGS_KEY = "app_settings";

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
    apiKey: process.env.TWELVE_DATA_API_KEY || "",
    pollingMode: "normal",
  },
};

// GET: Retrieve settings
export async function GET() {
  try {
    const result = await db.query.appSettings.findFirst({
      where: eq(appSettings.key, SETTINGS_KEY),
    });

    if (result) {
      const savedSettings = JSON.parse(result.value);
      // Merge with defaults to ensure all fields exist
      const settings: Settings = {
        signal: { ...DEFAULT_SETTINGS.signal, ...savedSettings.signal },
        indicators: { ...DEFAULT_SETTINGS.indicators, ...savedSettings.indicators },
        learning: { ...DEFAULT_SETTINGS.learning, ...savedSettings.learning },
        api: { ...DEFAULT_SETTINGS.api, ...savedSettings.api },
      };
      return NextResponse.json({ settings });
    }

    return NextResponse.json({ settings: DEFAULT_SETTINGS });
  } catch (error) {
    console.error("Failed to get settings:", error);
    return NextResponse.json({ settings: DEFAULT_SETTINGS });
  }
}

// POST: Save settings
export async function POST(request: Request) {
  try {
    const body = await request.json();
    const { settings } = body;

    if (!settings) {
      return NextResponse.json(
        { error: "Settings required" },
        { status: 400 }
      );
    }

    // Check if settings exist
    const existing = await db.query.appSettings.findFirst({
      where: eq(appSettings.key, SETTINGS_KEY),
    });

    const settingsJson = JSON.stringify(settings);

    if (existing) {
      await db
        .update(appSettings)
        .set({ value: settingsJson, updatedAt: Date.now() })
        .where(eq(appSettings.key, SETTINGS_KEY));
    } else {
      await db.insert(appSettings).values({
        key: SETTINGS_KEY,
        value: settingsJson,
      });
    }

    // Apply API key to environment if changed
    if (settings.api?.apiKey) {
      process.env.TWELVE_DATA_API_KEY = settings.api.apiKey;
    }

    return NextResponse.json({ success: true, settings });
  } catch (error) {
    console.error("Failed to save settings:", error);
    return NextResponse.json(
      { error: "Failed to save settings" },
      { status: 500 }
    );
  }
}
