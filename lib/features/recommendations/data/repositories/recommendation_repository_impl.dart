import 'package:dartz/dartz.dart';
import 'package:ifind/core/errors/exceptions.dart';
import 'package:ifind/core/errors/failures.dart';
import 'package:ifind/features/recommendations/data/datasources/ai_recommendation_datasource.dart';
import 'package:ifind/features/recommendations/domain/entities/recommendation.dart';
import 'package:ifind/features/recommendations/domain/repositories/recommendation_repository.dart';

class RecommendationRepositoryImpl implements RecommendationRepository {
  final AiRecommendationDataSource remoteDataSource;

  RecommendationRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, List<Recommendation>>> getAiRecommendations({
    required String intent,
    required double latitude,
    required double longitude,
    double radiusInMeters = 5000.0,
  }) async {
    try {
      final models = await remoteDataSource.getAiRecommendations(
        intent: intent,
        latitude: latitude,
        longitude: longitude,
        radiusInMeters: radiusInMeters,
      );
      final recommendations = models.map((model) => model.toEntity()).toList();
      return Right(recommendations);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return const Left(ServerFailure('An unexpected error occurred during AI matchmaking'));
    }
  }
}
