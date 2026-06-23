import 'package:dartz/dartz.dart';
import 'package:ifind/core/errors/failures.dart';
import 'package:ifind/features/recommendations/domain/entities/recommendation.dart';

abstract class RecommendationRepository {
  /// Fetch personalized B2C recommendations for the given [userId].
  ///
  /// Returns an empty Right([]) for new users with no interaction history.
  Future<Either<Failure, List<Recommendation>>> getRecommendationsForUser({
    required String userId,
    int n = 5,
  });
}
