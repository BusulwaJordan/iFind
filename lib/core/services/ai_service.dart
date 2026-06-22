// ⚠️ DEPRECATED: This file (AiService / OpenRouter) has been replaced.
//
// iFind now uses CUSTOM-TRAINED AI models running on Supabase Edge Functions.
// No third-party API keys are required.
//
// REPLACEMENT SERVICES:
//   → MODEL 1 (Proximity):       lib/core/services/proximity_service.dart
//   → MODEL 2 (B2C Recommender): lib/core/services/recommendation_service.dart
//   → MODEL 3 (B2B Matcher):     lib/core/services/b2b_service.dart
//
// PROVIDERS:                      lib/core/providers/ai_providers.dart
//
// This file is kept temporarily as a stub to avoid breaking existing imports
// until all call-sites are migrated. Do NOT add new code here.

@Deprecated('Use RecommendationService or B2bService instead.')
class AiService {
  @Deprecated('Use RecommendationService.getRecommendations() instead.')
  Future<List<Map<String, dynamic>>> rankNearbyBusinesses(
    String intent,
    List<Map<String, dynamic>> businesses,
  ) async {
    // No-op stub — returns empty list so existing call-sites don't crash
    // while migration is in progress.
    return [];
  }

  @Deprecated('No longer used — intent analysis is handled by local logic.')
  Future<Map<String, dynamic>> analyzeNeed(String text) async {
    return {'category': 'unknown', 'urgency': 'low', 'tags': []};
  }
}
