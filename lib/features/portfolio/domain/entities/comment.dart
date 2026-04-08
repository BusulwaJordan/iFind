import 'package:equatable/equatable.dart';

class Comment extends Equatable {
  final String id;
  final String portfolioItemId;
  final String userId;
  final String comment;
  final DateTime createdAt;
  final String? authorName;
  final String? authorAvatarUrl;

  const Comment({
    required this.id,
    required this.portfolioItemId,
    required this.userId,
    required this.comment,
    required this.createdAt,
    this.authorName,
    this.authorAvatarUrl,
  });

  @override
  List<Object?> get props => [id, portfolioItemId, userId, comment, createdAt, authorName, authorAvatarUrl];
}
