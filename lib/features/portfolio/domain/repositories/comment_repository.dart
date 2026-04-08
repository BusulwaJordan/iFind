import 'package:dartz/dartz.dart';
import 'package:ifind/core/errors/failures.dart';
import 'package:ifind/features/portfolio/domain/entities/comment.dart';

abstract class CommentRepository {
  Stream<Either<Failure, List<Comment>>> streamComments(String portfolioItemId);
  Future<Either<Failure, void>> addComment(String portfolioItemId, String comment);
  Future<Either<Failure, void>> deleteComment(String commentId);
  Future<Either<Failure, bool>> toggleLike(String portfolioItemId);
  Future<Either<Failure, bool>> isLikedByUser(String portfolioItemId, String userId);
}
