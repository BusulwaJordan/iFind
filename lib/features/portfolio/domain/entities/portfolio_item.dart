import 'package:equatable/equatable.dart';

enum MediaType { image, video }

class PortfolioItem extends Equatable {
  final String id;
  final String businessId;
  final MediaType mediaType;
  final String mediaUrl;
  final String? thumbnailUrl; // For videos
  final String? caption;
  final DateTime createdAt;

  const PortfolioItem({
    required this.id,
    required this.businessId,
    required this.mediaType,
    required this.mediaUrl,
    this.thumbnailUrl,
    this.caption,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, businessId, mediaType, mediaUrl, thumbnailUrl, caption, createdAt];

  factory PortfolioItem.fromJson(Map<String, dynamic> json) {
    return PortfolioItem(
      id: json['id'],
      businessId: json['business_id'],
      mediaType: MediaType.values.firstWhere(
        (e) => e.name == json['media_type'],
        orElse: () => MediaType.image,
      ),
      mediaUrl: json['media_url'],
      thumbnailUrl: json['thumbnail_url'],
      caption: json['caption'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'business_id': businessId,
      'media_type': mediaType.name,
      'media_url': mediaUrl,
      'thumbnail_url': thumbnailUrl,
      'caption': caption,
    };
  }
}
