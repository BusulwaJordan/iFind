import 'package:dartz/dartz.dart';
import 'package:ifind/core/errors/failures.dart';
import 'package:ifind/features/reviews/domain/entities/review.dart';

abstract class ReviewRepository {
  Future<Either<Failure, List<Review>>> getReviews(String businessId);
  Stream<Either<Failure, List<Review>>> streamReviews(String businessId);
  Future<Either<Failure, void>> addReview({
    required String businessId,
    required int rating,
    String? comment,
  });
}
