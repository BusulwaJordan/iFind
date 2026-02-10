import 'package:equatable/equatable.dart';

class Review extends Equatable {
  final String id;
  final String businessId;
  final String customerId;
  final int rating;
  final String? comment;
  final DateTime createdAt;
  // Optional: Author name/avatar if joined
  final String? authorName;
  final String? authorAvatarUrl;

  const Review({
    required this.id,
    required this.businessId,
    required this.customerId,
    required this.rating,
    this.comment,
    required this.createdAt,
    this.authorName,
    this.authorAvatarUrl,
  });

  @override
  List<Object?> get props => [
        id,
        businessId,
        customerId,
        rating,
        comment,
        createdAt,
        authorName,
        authorAvatarUrl,
      ];
}
