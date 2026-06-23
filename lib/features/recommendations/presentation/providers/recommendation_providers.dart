import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:ifind/core/providers/ai_providers.dart';
import 'package:ifind/features/recommendations/data/datasources/ai_recommendation_datasource.dart';
import 'package:ifind/features/recommendations/data/repositories/recommendation_repository_impl.dart';
import 'package:ifind/features/recommendations/domain/entities/recommendation.dart';
import 'package:ifind/features/recommendations/domain/repositories/recommendation_repository.dart';

part 'recommendation_providers.g.dart';

@riverpod
AiRecommendationDataSource aiRecommendationDataSource(Ref ref) {
  return AiRecommendationDataSourceImpl(
    recommendationService: ref.watch(recommendationServiceProvider),
  );
}

@riverpod
RecommendationRepository recommendationRepository(Ref ref) {
  final remoteDataSource = ref.watch(aiRecommendationDataSourceProvider);
  return RecommendationRepositoryImpl(remoteDataSource);
}

/// Fetches personalized B2C recommendations for [userId].
///
/// New users (no interactions yet) will get an empty list — the UI should
/// fall back to featured or popular businesses in that case.
@riverpod
Future<List<Recommendation>> userRecommendations(
  Ref ref, {
  required String userId,
  int n = 5,
}) async {
  final repository = ref.watch(recommendationRepositoryProvider);
  final result = await repository.getRecommendationsForUser(
    userId: userId,
    n: n,
  );

  return result.fold(
    (failure) => throw Exception(failure.message),
    (recommendations) => recommendations,
  );
}
