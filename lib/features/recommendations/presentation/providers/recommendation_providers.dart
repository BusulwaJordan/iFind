import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:ifind/core/providers/ai_provider.dart';
import 'package:ifind/features/discovery/presentation/providers/discovery_providers.dart';
import 'package:ifind/features/recommendations/data/datasources/ai_recommendation_datasource.dart';
import 'package:ifind/features/recommendations/data/repositories/recommendation_repository_impl.dart';
import 'package:ifind/features/recommendations/domain/entities/recommendation.dart';
import 'package:ifind/features/recommendations/domain/repositories/recommendation_repository.dart';

part 'recommendation_providers.g.dart';

@riverpod
AiRecommendationDataSource aiRecommendationDataSource(AiRecommendationDataSourceRef ref) {
  return AiRecommendationDataSourceImpl(
    aiService: ref.watch(aiServiceProvider),
    discoveryDataSource: ref.watch(discoveryRemoteDataSourceProvider),
  );
}

@riverpod
RecommendationRepository recommendationRepository(RecommendationRepositoryRef ref) {
  final remoteDataSource = ref.watch(aiRecommendationDataSourceProvider);
  return RecommendationRepositoryImpl(remoteDataSource);
}

@riverpod
Future<List<Recommendation>> aiMatchmaking(
  AiMatchmakingRef ref, {
  required String intent,
  required double latitude,
  required double longitude,
  double radius = 5000.0,
}) async {
  final repository = ref.watch(recommendationRepositoryProvider);
  final result = await repository.getAiRecommendations(
    intent: intent,
    latitude: latitude,
    longitude: longitude,
    radiusInMeters: radius,
  );
  
  return result.fold(
    (failure) => throw Exception(failure.message),
    (recommendations) => recommendations,
  );
}
