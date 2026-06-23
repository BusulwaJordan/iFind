const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Content-Type": "application/json",
};

const complementaryCategories = new Set([
  "beauty:fashion",
  "fashion:beauty",
  "food:entertainment",
  "entertainment:food",
  "electronics:retail",
  "retail:electronics",
  "home:service",
  "service:home",
  "health:beauty",
  "beauty:health",
  "travel:entertainment",
  "entertainment:travel",
]);

function jsonResponse(status: number, body: unknown) {
  return new Response(JSON.stringify(body), {
    status,
    headers: corsHeaders,
  });
}

function clamp(value: number, min = 0, max = 1) {
  return Math.min(max, Math.max(min, value));
}

function normalizeCategory(category: unknown) {
  return String(category ?? "")
    .trim()
    .toLowerCase()
    .replace(/\s+/g, "_");
}

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders });
  }

  if (request.method !== "POST") {
    return jsonResponse(405, { error: "Method not allowed" });
  }

  try {
    const body = await request.json().catch(() => ({}));
    const categoryA = normalizeCategory(body.category_a);
    const categoryB = normalizeCategory(body.category_b);
    const distanceKm = Math.max(0, Number(body.distance_km ?? 0));

    if (!categoryA || !categoryB) {
      return jsonResponse(400, {
        error: "category_a and category_b are required",
      });
    }

    const sameCategoryScore = categoryA === categoryB ? 0.42 : 0;
    const complementaryScore = complementaryCategories.has(
      `${categoryA}:${categoryB}`,
    )
      ? 0.28
      : 0;
    const distanceScore = clamp(1 - distanceKm / 25) * 0.22;
    const baseScore = 0.18;

    const score = clamp(
      baseScore + sameCategoryScore + complementaryScore + distanceScore,
    );

    return jsonResponse(200, {
      compatibility_score: Number(score.toFixed(4)),
    });
  } catch (error) {
    console.error("b2b-match error", error);
    return jsonResponse(500, {
      error: error instanceof Error ? error.message : String(error),
    });
  }
});
