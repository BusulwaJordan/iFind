import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ifind/features/reviews/data/repositories/review_repository_impl.dart';
import 'package:ifind/features/reviews/domain/entities/review.dart';
import 'package:ifind/features/reviews/domain/repositories/review_repository.dart';

final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  return ReviewRepositoryImpl(Supabase.instance.client);
});

final businessReviewsProvider = FutureProvider.family<List<Review>, String>((ref, businessId) async {
  final repository = ref.watch(reviewRepositoryProvider);
  final result = await repository.getReviews(businessId);
  return result.fold(
    (failure) => [],
    (reviews) => reviews,
  );
});
