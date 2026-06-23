import 'package:flutter/foundation.dart';
import 'package:ifind/core/errors/exceptions.dart';
import 'package:ifind/core/services/recommendation_service.dart';
import 'package:ifind/features/recommendations/data/models/recommendation_model.dart';

/// Abstract contract for the B2C recommendation data source.
abstract class AiRecommendationDataSource {
  /// Returns personalized business recommendations for [userId].
  ///
  /// [n] controls how many recommendations to return.
  /// Returns an empty list for new users (cold-start) — caller should fall
  /// back to popular/featured businesses.
  Future<List<RecommendationModel>> getRecommendationsForUser({
    required String userId,
    int n = 5,
  });
}

/// Implementation backed by our custom B2C ALS model running on a
/// Supabase Edge Function (`recommend-businesses`).
///
/// Model files are stored in the `ai_models` Supabase Storage bucket and
/// loaded on Edge Function cold-start. Subsequent requests are fast (<500ms).
class AiRecommendationDataSourceImpl implements AiRecommendationDataSource {
  final RecommendationService recommendationService;

  AiRecommendationDataSourceImpl({required this.recommendationService});

  @override
  Future<List<RecommendationModel>> getRecommendationsForUser({
    required String userId,
    int n = 5,
  }) async {
    try {
      debugPrint(
          'AiRecommendationDataSource: Fetching $n recs for user $userId');

      final results = await recommendationService.getRecommendations(
        userId: userId,
        n: n,
      );

      if (results.isEmpty) {
        debugPrint(
            'AiRecommendationDataSource: No recs returned (cold-start or new user)');
        return [];
      }

      // Map Edge Function results to RecommendationModel
      // The Edge Function returns: {business_id, name, category, score}
      // We adapt this to RecommendationModel which needs {businessId, aiReasoning}
      return results.map((rec) {
        final scorePercent = (rec.score * 100).round();
        final reasoning =
            '${rec.name} (${rec.category}) — $scorePercent% personalized match';
        return RecommendationModel(
          businessId: rec.businessId,
          aiReasoning: reasoning,
        );
      }).toList();
    } catch (e) {
      throw ServerException('Failed to get B2C recommendations: $e');
    }
  }
}
