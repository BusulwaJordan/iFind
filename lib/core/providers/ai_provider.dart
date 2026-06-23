// ⚠️ DEPRECATED: This file has been replaced by lib/core/providers/ai_providers.dart
//
// The old AiService (OpenRouter) has been removed. All AI is now powered by
// custom-trained models on Supabase Edge Functions.
//
// Use these providers instead:
//   - proximityServiceProvider    → ProximityService (PostGIS RPC)
//   - recommendationServiceProvider → RecommendationService (B2C ALS model)
//   - b2bServiceProvider          → B2bService (B2B Random Forest model)

export 'package:ifind/core/providers/ai_providers.dart';
