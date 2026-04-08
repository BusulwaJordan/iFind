import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ifind/core/errors/failures.dart';
import 'package:ifind/features/portfolio/domain/entities/comment.dart';
import 'package:ifind/features/portfolio/domain/repositories/comment_repository.dart';
import 'package:ifind/features/portfolio/data/models/comment_model.dart';

class CommentRepositoryImpl implements CommentRepository {
  final SupabaseClient supabaseClient;

  CommentRepositoryImpl(this.supabaseClient);

  @override
  Stream<Either<Failure, List<Comment>>> streamComments(
      String portfolioItemId) async* {
    try {
      final stream = supabaseClient
          .from('media_comments')
          .stream(primaryKey: ['id'])
          .eq('portfolio_item_id', portfolioItemId)
          .order('created_at', ascending: false);

      await for (final data in stream) {
        try {
          // Fetch user details for each comment
          final List<Comment> comments = [];
          for (final commentJson in data) {
            final userId = commentJson['user_id'];
            final userResponse = await supabaseClient
                .from('users')
                .select('full_name')
                .eq('id', userId)
                .maybeSingle();

            final commentWithUser = Map<String, dynamic>.from(commentJson);
            if (userResponse != null) {
              commentWithUser['users'] = userResponse;
            }

            comments.add(CommentModel.fromJson(commentWithUser));
          }
          yield Right(comments);
        } catch (e) {
          yield Left(ServerFailure(e.toString()));
        }
      }
    } catch (e) {
      yield Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> addComment(
      String portfolioItemId, String comment) async {
    try {
      final userId = supabaseClient.auth.currentUser?.id;
      if (userId == null) {
        return const Left(ServerFailure('User not authenticated'));
      }

      await supabaseClient.from('media_comments').insert({
        'portfolio_item_id': portfolioItemId,
        'user_id': userId,
        'comment': comment,
      });

      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteComment(String commentId) async {
    try {
      await supabaseClient.from('media_comments').delete().eq('id', commentId);

      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> toggleLike(String portfolioItemId) async {
    try {
      final userId = supabaseClient.auth.currentUser?.id;
      if (userId == null) {
        return const Left(ServerFailure('User not authenticated'));
      }

      // Check if already liked
      final existingLike = await supabaseClient
          .from('media_likes')
          .select()
          .eq('portfolio_item_id', portfolioItemId)
          .eq('user_id', userId)
          .maybeSingle();

      if (existingLike != null) {
        // Unlike
        await supabaseClient
            .from('media_likes')
            .delete()
            .eq('portfolio_item_id', portfolioItemId)
            .eq('user_id', userId);
        return const Right(false);
      } else {
        // Like
        await supabaseClient.from('media_likes').insert({
          'portfolio_item_id': portfolioItemId,
          'user_id': userId,
        });
        return const Right(true);
      }
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> isLikedByUser(
      String portfolioItemId, String userId) async {
    try {
      final like = await supabaseClient
          .from('media_likes')
          .select()
          .eq('portfolio_item_id', portfolioItemId)
          .eq('user_id', userId)
          .maybeSingle();

      return Right(like != null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
