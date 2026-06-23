"""
iFind B2B Compatibility Edge Function
======================================
Supabase Edge Function (Python runtime)
Endpoint: POST /functions/v1/b2b-match

MODEL 3: Random Forest Regression
Technology: scikit-learn RandomForestRegressor
Trained on: b2b_matches_clean.csv

Model files loaded from Supabase Storage bucket 'ai_models':
  - b2b_model.pkl    : The trained RandomForestRegressor
  - encoder_a.pkl    : LabelEncoder for category_a
  - encoder_b.pkl    : LabelEncoder for category_b
  - b2b_features.pkl : Feature column names (for validation)

REQUEST:
  POST /functions/v1/b2b-match
  Body: {
    "category_a": "Agriculture",
    "category_b": "Restaurant",
    "distance_km": 2.5
  }

RESPONSE:
  {"compatibility_score": 0.87}

ERROR HANDLING:
  - Unknown category  → Uses 'unknown' label with fallback encoding
  - Model missing     → 500 {"error": "Model not loaded"}
  - Any exception     → 500 {"error": "..."}
"""

import json
import os
import pickle
import urllib.request
import numpy as np

# ---------------------------------------------------------------------------
# Supabase Storage URLs for model files
# ---------------------------------------------------------------------------
STORAGE_BASE = os.environ.get(
    "AI_MODELS_BASE_URL",
    "https://yykzwfzlibszwldawgex.supabase.co/storage/v1/object/public/ai_models",
)

MODEL_URLS = {
    "b2b_model": f"{STORAGE_BASE}/b2b_model.pkl",
    "encoder_a": f"{STORAGE_BASE}/encoder_a.pkl",
    "encoder_b": f"{STORAGE_BASE}/encoder_b.pkl",
    "b2b_features": f"{STORAGE_BASE}/b2b_features.pkl",
}

# ---------------------------------------------------------------------------
# Module-level cache
# ---------------------------------------------------------------------------
_MODEL_CACHE: dict = {}


def _load_pkl_from_url(url: str):
    """Download and deserialize a pickle file from a URL."""
    with urllib.request.urlopen(url, timeout=30) as response:
        return pickle.loads(response.read())


def _ensure_models_loaded():
    """Load all model files into the module cache on first call."""
    if _MODEL_CACHE:
        return

    print("B2B: Cold start — downloading model files from Storage...")
    for key, url in MODEL_URLS.items():
        print(f"  Loading {key} from {url}...")
        _MODEL_CACHE[key] = _load_pkl_from_url(url)
    print("B2B: All model files loaded successfully.")


def _safe_encode(encoder, value: str) -> int:
    """Encode a category value, falling back to 0 for unknown categories."""
    try:
        return int(encoder.transform([value])[0])
    except (ValueError, KeyError):
        print(f"B2B: Unknown category '{value}', using fallback encoding 0.")
        return 0


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

    category_a = str(body.get("category_a", "")).strip()
    category_b = str(body.get("category_b", "")).strip()
    distance_km = float(body.get("distance_km", 0.0))

    if not category_a or not category_b:
        return {
            "statusCode": 400,
            "headers": headers,
            "body": json.dumps({"error": "category_a and category_b are required"}),
        }

    try:
        _ensure_models_loaded()

        model = _MODEL_CACHE["b2b_model"]
        encoder_a = _MODEL_CACHE["encoder_a"]
        encoder_b = _MODEL_CACHE["encoder_b"]

        # Encode categories
        cat_a_encoded = _safe_encode(encoder_a, category_a)
        cat_b_encoded = _safe_encode(encoder_b, category_b)

        # Compute same_category feature
        same_category = 1 if category_a.lower() == category_b.lower() else 0

        # Build feature vector: [distance_km, same_category, cat_a_encoded, cat_b_encoded]
        features = np.array([[distance_km, same_category, cat_a_encoded, cat_b_encoded]])

        # Predict compatibility score (0.0 – 1.0)
        score = float(model.predict(features)[0])
        score = max(0.0, min(1.0, score))  # Clamp to [0, 1]

        print(f"B2B: {category_a} ↔ {category_b} @ {distance_km}km → score={score:.4f}")

        return {
            "statusCode": 200,
            "headers": headers,
            "body": json.dumps({"compatibility_score": round(score, 4)}),
        }

    except Exception as e:
        print(f"B2B Error: {e}")
        return {
            "statusCode": 500,
            "headers": headers,
            "body": json.dumps({"error": str(e)}),
        }
