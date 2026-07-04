import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ifind/core/errors/failures.dart';
import 'package:ifind/features/reviews/data/models/review_model.dart';
import 'package:ifind/features/reviews/domain/entities/review.dart';
import 'package:ifind/features/reviews/domain/repositories/review_repository.dart';

class ReviewRepositoryImpl implements ReviewRepository {
  final SupabaseClient _client;

  ReviewRepositoryImpl(this._client);

  /// `reviews.business_id` is the UUID primary key on `businesses`, but
  /// callers pass the custom text business id (e.g. "BIZ0122") used
  /// everywhere else in the app. Resolve the UUID before querying/writing.
  Future<String?> _resolveBusinessUuid(String businessId) async {
    final row = await _client
        .from('businesses')
        .select('id')
        .eq('business_id', businessId)
        .maybeSingle();
    return row?['id'] as String?;
  }

  @override
  Future<Either<Failure, List<Review>>> getReviews(String businessId) async {
    try {
      final resolvedId = await _resolveBusinessUuid(businessId) ?? businessId;
      List<dynamic> response;
      try {
        // Try with user join (requires FK constraint in Supabase)
        response = await _client
            .from('reviews')
            .select('*, users(full_name, avatar_url)')
            .eq('business_id', resolvedId)
            .order('created_at', ascending: false);
      } catch (_) {
        // FK not set up — fall back to plain reviews; authorName shows as Anonymous
        response = await _client
            .from('reviews')
            .select()
            .eq('business_id', resolvedId)
            .order('created_at', ascending: false);
      }

      final reviews =
          response.map((json) => ReviewModel.fromJson(json)).toList();
      return Right(reviews);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Stream<Either<Failure, List<Review>>> streamReviews(
      String businessId) async* {
    try {
      final resolvedId = await _resolveBusinessUuid(businessId) ?? businessId;
      final stream = _client
          .from('reviews')
          .stream(primaryKey: ['id'])
          .eq('business_id', resolvedId)
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

      final resolvedId = await _resolveBusinessUuid(businessId);
      if (resolvedId == null) {
        return const Left(ServerFailure('Business not found'));
      }

      final data = {
        'business_id': resolvedId,
        'customer_id': userId,
        'rating': rating,
        'comment': comment,
      };

      // Upsert: a customer can only have one review per business
      // (reviews_business_id_customer_id_key), so a repeat rating updates
      // their existing review instead of failing on the unique constraint.
      await _client
          .from('reviews')
          .upsert(data, onConflict: 'business_id,customer_id');

      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> addReply({
    required String reviewId,
    required String reply,
  }) async {
    try {
      await _client.from('reviews').update({
        'owner_reply': reply,
        'replied_at': DateTime.now().toIso8601String(),
      }).eq('id', reviewId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
