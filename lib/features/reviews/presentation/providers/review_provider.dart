import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ifind/features/reviews/data/repositories/review_repository_impl.dart';
import 'package:ifind/features/reviews/domain/entities/review.dart';
import 'package:ifind/features/reviews/domain/repositories/review_repository.dart';
import 'package:ifind/features/business/presentation/providers/business_provider.dart';

final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  return ReviewRepositoryImpl(
    Supabase.instance.client,
    ref.watch(businessRepositoryProvider),
  );
});

final businessReviewsProvider = StreamProvider.family<List<Review>, String>((ref, businessId) {
  final repository = ref.watch(reviewRepositoryProvider);
  return repository.streamReviews(businessId).asyncMap((either) {
    return either.fold(
      (failure) => throw Exception(failure.message),
      (reviews) => reviews,
    );
  });
});
