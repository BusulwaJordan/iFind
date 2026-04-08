import 'package:ifind/features/portfolio/domain/entities/comment.dart';

class CommentModel extends Comment {
  const CommentModel({
    required super.id,
    required super.portfolioItemId,
    required super.userId,
    required super.comment,
    required super.createdAt,
    super.authorName,
    super.authorAvatarUrl,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: json['id'],
      portfolioItemId: json['portfolio_item_id'],
      userId: json['user_id'],
      comment: json['comment'],
      createdAt: DateTime.parse(json['created_at']),
      authorName: json['users']?['full_name'],
      authorAvatarUrl: null, // Can be added if avatar URLs are stored
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'portfolio_item_id': portfolioItemId,
      'user_id': userId,
      'comment': comment,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
