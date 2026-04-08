import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ifind/core/errors/failures.dart';
import 'package:ifind/features/reviews/data/models/review_model.dart';
import 'package:ifind/features/reviews/domain/entities/review.dart';
import 'package:ifind/features/reviews/domain/repositories/review_repository.dart';
import 'package:ifind/features/business/domain/repositories/business_repository.dart';

class ReviewRepositoryImpl implements ReviewRepository {
  final SupabaseClient _client;
  final BusinessRepository _businessRepository;

  ReviewRepositoryImpl(this._client, this._businessRepository);

  @override
  Future<Either<Failure, List<Review>>> getReviews(String businessId) async {
    try {
      final response = await _client
          .from('reviews')
          .select('*, users(full_name)')
          .eq('business_id', businessId)
          .order('created_at', ascending: false);

      final reviews =
          (response as List).map((json) => ReviewModel.fromJson(json)).toList();
      return Right(reviews);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Stream<Either<Failure, List<Review>>> streamReviews(
      String businessId) async* {
    try {
      final stream = _client
          .from('reviews')
          .stream(primaryKey: ['id'])
          .eq('business_id', businessId)
          .order('created_at', ascending: false);

      await for (final data in stream) {
        try {
          final List<Review> reviews = [];
          for (final reviewJson in data) {
            final userId = reviewJson['customer_id'];
            final userResponse = await _client
                .from('users')
                .select('full_name')
                .eq('id', userId)
                .maybeSingle();

            final reviewWithUser = Map<String, dynamic>.from(reviewJson);
            if (userResponse != null) {
              reviewWithUser['users'] = userResponse;
            }

            reviews.add(ReviewModel.fromJson(reviewWithUser));
          }
          yield Right(reviews);
        } catch (e) {
          yield Left(ServerFailure(e.toString()));
        }
      }
    } catch (e) {
      yield Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> addReview({
    required String businessId,
    required int rating,
    String? comment,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        return const Left(ServerFailure('User not authenticated'));
      }

      final data = {
        'business_id': businessId,
        'customer_id': userId,
        'rating': rating,
        'comment': comment,
      };

      await _client.from('reviews').insert(data);

      // Manually trigger rating update to ensure immediate consistency
      await _businessRepository.updateBusinessRating(businessId);

      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
