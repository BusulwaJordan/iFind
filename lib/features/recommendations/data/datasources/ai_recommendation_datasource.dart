import 'package:ifind/core/errors/exceptions.dart';
import 'package:ifind/core/services/ai_service.dart';
import 'package:ifind/features/business/data/models/business_model.dart';
import 'package:ifind/features/discovery/data/datasources/discovery_remote_datasource.dart';
import 'package:ifind/features/recommendations/data/models/recommendation_model.dart';

abstract class AiRecommendationDataSource {
  Future<List<RecommendationModel>> getAiRecommendations({
    required String intent,
    required double latitude,
    required double longitude,
    double radiusInMeters = 5000.0,
  });
}

class AiRecommendationDataSourceImpl implements AiRecommendationDataSource {
  final AiService aiService;
  final DiscoveryRemoteDataSource discoveryDataSource;

  AiRecommendationDataSourceImpl({
    required this.aiService,
    required this.discoveryDataSource,
  });

  @override
  Future<List<RecommendationModel>> getAiRecommendations({
    required String intent,
    required double latitude,
    required double longitude,
    double radiusInMeters = 5000.0,
  }) async {
    try {
      // 1. Get raw local shops from Postgres
      final List<BusinessModel> localShops = await discoveryDataSource.getNearbyBusinesses(
        latitude: latitude,
        longitude: longitude,
        radiusInMeters: radiusInMeters,
      );

      if (localShops.isEmpty) {
        return [];
      }

      // 2. Format them for AI
      // Limit to 20 to prevent enormous JSON payloads
      final shopsToAnalyze = localShops.take(20).map((b) => {
        'id': b.id,
        'name': b.name,
        'description': b.description,
        'category': b.category.toString(),
        'distance': b.distance,
      }).toList();

      // 3. Ask Gemini for rankings
      final rawRecommendations = await aiService.rankNearbyBusinesses(
        intent,
        shopsToAnalyze,
      );

      // 4. Map back to models
      return rawRecommendations
          .map((json) => RecommendationModel.fromJson(json))
          .toList();
    } catch (e) {
      throw ServerException('Failed to generate AI recommendations: $e');
    }
  }
}
