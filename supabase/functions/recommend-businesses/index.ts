import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Content-Type": "application/json",
};

type Interaction = {
  business_id: string;
  interaction_type: string;
};

type Business = {
  id: string;
  name: string;
  category: string;
  rating_average: number | null;
  rating_count: number | null;
  created_at: string | null;
};

const interactionWeights: Record<string, number> = {
  view: 1,
  search_click: 2,
  profile_view: 2.5,
  saved_business: 4,
  inquiry_sent: 5,
  review_posted: 6,
};

const maxCandidateBusinesses = 2000;

function jsonResponse(status: number, body: unknown) {
  return new Response(JSON.stringify(body), {
    status,
    headers: corsHeaders,
  });
}

function getSupabaseClient() {
  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY");
  const key = serviceRoleKey ?? anonKey;

  if (!supabaseUrl || !key) {
    throw new Error("Missing SUPABASE_URL or Supabase API key.");
  }

  return createClient(supabaseUrl, key, {
    auth: { persistSession: false },
  });
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
    const userId = String(body.user_id ?? "").trim();
    const n = Math.max(1, Math.min(Number(body.n ?? 5), 30));

    if (!userId) {
      return jsonResponse(400, { error: "user_id is required" });
    }

    const supabase = getSupabaseClient();

    const { data: businesses, error: businessesError } = await supabase
      .from("businesses")
      .select("id,name,category,rating_average,rating_count,created_at")
      .eq("is_verified", true)
      .order("rating_average", { ascending: false, nullsFirst: false })
      .order("rating_count", { ascending: false, nullsFirst: false })
      .limit(maxCandidateBusinesses);

    if (businessesError) throw businessesError;

    const candidateBusinesses = (businesses ?? []) as Business[];
    if (candidateBusinesses.length === 0) {
      return jsonResponse(200, []);
    }

    const { data: interactions, error: interactionsError } = await supabase
      .from("interactions")
      .select("business_id,interaction_type")
      .eq("user_id", userId)
      .order("created_at", { ascending: false })
      .limit(200);

    if (interactionsError) throw interactionsError;

    const userInteractions = (interactions ?? []) as Interaction[];
    const interactedBusinessIds = [
      ...new Set(userInteractions.map((item) => item.business_id)),
    ];

    let interactedBusinesses: Business[] = [];
    if (interactedBusinessIds.length > 0) {
      const { data, error } = await supabase
        .from("businesses")
        .select("id,name,category,rating_average,rating_count,created_at")
        .in("id", interactedBusinessIds);

      if (error) throw error;
      interactedBusinesses = (data ?? []) as Business[];
    }

    const categoryByBusinessId = new Map(
      interactedBusinesses.map((business) => [business.id, business.category]),
    );
    const categoryScores = new Map<string, number>();
    const seenBusinessIds = new Set<string>();

    for (const interaction of userInteractions) {
      seenBusinessIds.add(interaction.business_id);
      const category = categoryByBusinessId.get(interaction.business_id);
      if (!category) continue;

      const weight = interactionWeights[interaction.interaction_type] ?? 1;
      categoryScores.set(category, (categoryScores.get(category) ?? 0) + weight);
    }

    const scored = candidateBusinesses
      .map((business) => {
        const categoryAffinity = categoryScores.get(business.category) ?? 0;
        const rating = Number(business.rating_average ?? 0);
        const ratingCount = Number(business.rating_count ?? 0);
        const popularity = Math.log1p(ratingCount);
        const explorationBoost = seenBusinessIds.has(business.id) ? 0 : 0.4;

        const rawScore =
          categoryAffinity * 0.55 +
          rating * 0.25 +
          popularity * 0.15 +
          explorationBoost;

        return {
          business_id: business.id,
          name: business.name,
          category: business.category,
          score: Number(Math.max(rawScore, 0.05).toFixed(4)),
        };
      })
      .sort((a, b) => b.score - a.score)
      .slice(0, n);

    return jsonResponse(200, scored);
  } catch (error) {
    console.error("recommend-businesses error", error);
    return jsonResponse(500, {
      error: error instanceof Error ? error.message : String(error),
    });
  }
});
