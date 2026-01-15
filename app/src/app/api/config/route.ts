import { NextResponse } from "next/server";
import { twelveDataService } from "@/lib/twelve-data-service";
import { priceService } from "@/lib/price-service";

// GET: Get current configuration
export async function GET() {
  const isConfigured = twelveDataService.isConfigured();
  const dataSource = priceService.getDataSource();
  const apiStats = priceService.getApiStats();

  return NextResponse.json({
    isConfigured,
    dataSource,
    apiStats,
  });
}

// POST: Set API key
export async function POST(request: Request) {
  try {
    const body = await request.json();
    const { apiKey } = body;

    if (!apiKey || typeof apiKey !== "string") {
      return NextResponse.json(
        { error: "API key is required" },
        { status: 400 }
      );
    }

    // Set the API key
    twelveDataService.setApiKey(apiKey);

    // Switch to live data source
    priceService.setDataSource("live");

    return NextResponse.json({
      success: true,
      message: "API key configured successfully",
      dataSource: priceService.getDataSource(),
    });
  } catch (error) {
    return NextResponse.json(
      { error: "Failed to configure API key" },
      { status: 500 }
    );
  }
}

// PUT: Update polling mode
export async function PUT(request: Request) {
  try {
    const body = await request.json();
    const { pollingMode } = body;

    if (pollingMode !== "normal" && pollingMode !== "signal") {
      return NextResponse.json(
        { error: "Invalid polling mode. Use 'normal' or 'signal'" },
        { status: 400 }
      );
    }

    priceService.setPollingMode(pollingMode);

    return NextResponse.json({
      success: true,
      pollingMode,
      apiStats: priceService.getApiStats(),
    });
  } catch (error) {
    return NextResponse.json(
      { error: "Failed to update polling mode" },
      { status: 500 }
    );
  }
}
