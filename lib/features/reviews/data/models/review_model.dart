import 'package:ifind/features/reviews/domain/entities/review.dart';

class ReviewModel extends Review {
  const ReviewModel({
    required super.id,
    required super.businessId,
    required super.customerId,
    required super.rating,
    super.comment,
    required super.createdAt,
    super.authorName,
    super.authorAvatarUrl,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    // Check if 'users' relation is included for author details
    final authorData = json['users'] as Map<String, dynamic>?;

    return ReviewModel(
      id: json['id'] as String,
      businessId: json['business_id'] as String,
      customerId: json['customer_id'] as String,
      rating: json['rating'] as int,
      comment: json['comment'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      authorName: authorData?['full_name'] as String?,
      authorAvatarUrl: authorData?['avatar_url'] as String?, // Note: Schema might need check if avatar_url is in public.users or metadata
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'business_id': businessId,
      'customer_id': customerId,
      'rating': rating,
      'comment': comment,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
