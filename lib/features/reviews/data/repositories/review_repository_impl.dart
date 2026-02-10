import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ifind/core/errors/failures.dart';
import 'package:ifind/features/reviews/data/models/review_model.dart';
import 'package:ifind/features/reviews/domain/entities/review.dart';
import 'package:ifind/features/reviews/domain/repositories/review_repository.dart';

class ReviewRepositoryImpl implements ReviewRepository {
  final SupabaseClient _client;

  ReviewRepositoryImpl(this._client);

  @override
  Future<Either<Failure, List<Review>>> getReviews(String businessId) async {
    try {
      final response = await _client
          .from('reviews')
          .select('*, users(full_name, avatar_url)') // Join with users to get author info
          .eq('business_id', businessId)
          .order('created_at', ascending: false);

      final reviews = (response as List).map((json) => ReviewModel.fromJson(json)).toList();
      return Right(reviews);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Review>> addReview(Review review) async {
    try {
      final data = {
        'business_id': review.businessId,
        'customer_id': review.customerId,
        'rating': review.rating,
        'comment': review.comment,
      };

      final response = await _client
          .from('reviews')
          .insert(data)
          .select()
          .single();

      return Right(ReviewModel.fromJson(response));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
