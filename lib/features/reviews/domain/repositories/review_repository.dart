import 'package:dartz/dartz.dart';
import 'package:ifind/core/errors/failures.dart';
import 'package:ifind/features/reviews/domain/entities/review.dart';

abstract class ReviewRepository {
  Future<Either<Failure, List<Review>>> getReviews(String businessId);
  Future<Either<Failure, Review>> addReview(Review review);
}
