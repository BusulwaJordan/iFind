import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ifind/features/portfolio/domain/entities/comment.dart';
import 'package:ifind/features/portfolio/domain/repositories/comment_repository.dart';
import 'package:ifind/features/portfolio/data/repositories/comment_repository_impl.dart';

// Repository Provider
final commentRepositoryProvider = Provider<CommentRepository>((ref) {
  return CommentRepositoryImpl(Supabase.instance.client);
});

// Stream comments for a portfolio item
final commentsStreamProvider = StreamProvider.family<List<Comment>, String>((ref, portfolioItemId) {
  final repository = ref.watch(commentRepositoryProvider);
  return repository.streamComments(portfolioItemId).asyncMap((either) {
    return either.fold(
      (failure) => throw Exception(failure.toString()),
      (comments) => comments,
    );
  });
});

// Like count for a portfolio item
final likeCountProvider = FutureProvider.family<int, String>((ref, portfolioItemId) async {
  try {
    final response = await Supabase.instance.client
        .from('media_likes')
        .select('id')
        .eq('portfolio_item_id', portfolioItemId);
    
    return (response as List).length;
  } catch (e) {
    return 0;
  }
});

// Check if current user liked an item
final userLikeStatusProvider = FutureProvider.family<bool, String>((ref, portfolioItemId) async {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return false;

  final repository = ref.watch(commentRepositoryProvider);
  final result = await repository.isLikedByUser(portfolioItemId, userId);
  
  return result.fold(
    (failure) => false,
    (isLiked) => isLiked,
  );
});

// Comment count for a portfolio item
final commentCountProvider = StreamProvider.family<int, String>((ref, portfolioItemId) {
  return Supabase.instance.client
      .from('media_comments')
      .stream(primaryKey: ['id'])
      .eq('portfolio_item_id', portfolioItemId)
      .map((data) => data.length);
});

// Toggle Like Provider
final toggleLikeProvider = FutureProvider.family<bool, String>((ref, portfolioItemId) async {
  final repository = ref.watch(commentRepositoryProvider);
  final result = await repository.toggleLike(portfolioItemId);
  
  return result.fold(
    (failure) => throw Exception(failure.toString()),
    (isLiked) {
      // Invalidate related providers to trigger UI update
      ref.invalidate(likeCountProvider(portfolioItemId));
      ref.invalidate(userLikeStatusProvider(portfolioItemId));
      return isLiked;
    },
  );
});
