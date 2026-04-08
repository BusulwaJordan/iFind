import 'package:dartz/dartz.dart';
import 'package:ifind/core/errors/failures.dart';
import 'package:ifind/features/recommendations/domain/entities/recommendation.dart';

abstract class RecommendationRepository {
  Future<Either<Failure, List<Recommendation>>> getAiRecommendations({
    required String intent,
    required double latitude,
    required double longitude,
    double radiusInMeters = 5000.0,
  });
}
