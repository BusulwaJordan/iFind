"""
iFind B2C Recommendation Edge Function
======================================
Supabase Edge Function (Python runtime)
Endpoint: POST /functions/v1/recommend-businesses

MODEL 2: Collaborative Filtering using ALS (Alternating Least Squares)
Technology: implicit library (AlternatingLeastSquares)
Trained on: interactions_clean.csv

Model files loaded from Supabase Storage bucket 'ai_models':
  - b2c_model.pkl       : The trained ALS model
  - user_to_idx.pkl     : Maps user_id → matrix row index
  - idx_to_business.pkl : Maps matrix column index → business_id
  - business_lookup.pkl : Maps business_id → {name, category, ...}

REQUEST:
  POST /functions/v1/recommend-businesses
  Body: {"user_id": "USR0038", "n": 5}

RESPONSE:
  [
    {"business_id": "...", "name": "...", "category": "...", "score": 0.87},
    ...
  ]

ERROR HANDLING:
  - User not in model → 404 {"error": "User not found", "recommendations": []}
  - Model missing     → 500 {"error": "Model not loaded"}
  - Any exception     → 500 {"error": "..."}
"""

import json
import os
import pickle
import urllib.request
from http.server import BaseHTTPRequestHandler

# ---------------------------------------------------------------------------
# Supabase Storage URLs for model files
# ---------------------------------------------------------------------------
STORAGE_BASE = os.environ.get(
    "AI_MODELS_BASE_URL",
    "https://yykzwfzlibszwldawgex.supabase.co/storage/v1/object/public/ai_models",
)

MODEL_URLS = {
    "b2c_model": f"{STORAGE_BASE}/b2c_model.pkl",
    "user_to_idx": f"{STORAGE_BASE}/user_to_idx.pkl",
    "idx_to_business": f"{STORAGE_BASE}/idx_to_business.pkl",
    "business_lookup": f"{STORAGE_BASE}/business_lookup.pkl",
}

# ---------------------------------------------------------------------------
# Module-level cache (persists across warm requests in the same instance)
# ---------------------------------------------------------------------------
_MODEL_CACHE: dict = {}


def _load_pkl_from_url(url: str):
    """Download and deserialize a pickle file from a URL."""
    with urllib.request.urlopen(url, timeout=30) as response:
        return pickle.loads(response.read())


def _ensure_models_loaded():
    """Load all model files into the module cache on first call."""
    if _MODEL_CACHE:
        return  # Already loaded (warm request)

    print("B2C: Cold start — downloading model files from Storage...")
    for key, url in MODEL_URLS.items():
        print(f"  Loading {key} from {url}...")
        _MODEL_CACHE[key] = _load_pkl_from_url(url)
    print("B2C: All model files loaded successfully.")


def _cors_headers():
    return {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
        "Access-Control-Allow-Methods": "POST, OPTIONS",
        "Content-Type": "application/json",
    }


def handler(request):
    """Supabase Edge Function handler."""
    headers = _cors_headers()

    # Handle CORS preflight
    if request.method == "OPTIONS":
        return {"statusCode": 200, "headers": headers, "body": ""}

    if request.method != "POST":
        return {
            "statusCode": 405,
            "headers": headers,
            "body": json.dumps({"error": "Method not allowed"}),
        }

    try:
        body = json.loads(request.body or "{}")
    except json.JSONDecodeError:
        return {
            "statusCode": 400,
            "headers": headers,
            "body": json.dumps({"error": "Invalid JSON body"}),
        }

    user_id = body.get("user_id", "").strip()
    n = int(body.get("n", 5))

    if not user_id:
        return {
            "statusCode": 400,
            "headers": headers,
            "body": json.dumps({"error": "user_id is required"}),
        }

    try:
        _ensure_models_loaded()

        model = _MODEL_CACHE["b2c_model"]
        user_to_idx = _MODEL_CACHE["user_to_idx"]
        idx_to_business = _MODEL_CACHE["idx_to_business"]
        business_lookup = _MODEL_CACHE["business_lookup"]

        # Check if user exists in the trained model
        if user_id not in user_to_idx:
            print(f"B2C: User '{user_id}' not found in model (cold-start new user).")
            return {
                "statusCode": 404,
                "headers": headers,
                "body": json.dumps({
                    "error": "User not found in model",
                    "recommendations": [],
                }),
            }

        user_idx = user_to_idx[user_id]

        # Get top N recommendations from the ALS model
        # model.recommend returns (item_ids, scores) arrays
        import scipy.sparse as sp

        # Build a dummy sparse user-item matrix row for this user
        item_ids, scores = model.recommend(
            user_idx,
            sp.csr_matrix((1, len(idx_to_business))),  # empty user interactions
            N=n,
            filter_already_liked_items=False,
        )

        recommendations = []
        for item_idx, score in zip(item_ids, scores):
            business_id = idx_to_business.get(int(item_idx))
            if business_id and business_id in business_lookup:
                info = business_lookup[business_id]
                recommendations.append({
                    "business_id": business_id,
                    "name": info.get("name", "Unknown"),
                    "category": info.get("category", "general"),
                    "score": round(float(score), 4),
                })

        return {
            "statusCode": 200,
            "headers": headers,
            "body": json.dumps(recommendations),
        }

    except Exception as e:
        print(f"B2C Error: {e}")
        return {
            "statusCode": 500,
            "headers": headers,
            "body": json.dumps({"error": str(e)}),
        }
