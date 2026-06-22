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
  Future<Either<Failure, List<Recommendation>>> getRecommendationsForUser({
    required String userId,
    int n = 5,
  }) async {
    try {
      final models = await remoteDataSource.getRecommendationsForUser(
        userId: userId,
        n: n,
      );
      final recommendations = models.map((model) => model.toEntity()).toList();
      return Right(recommendations);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return const Left(
          ServerFailure('Failed to load personalized recommendations.'));
    }
  }
}
