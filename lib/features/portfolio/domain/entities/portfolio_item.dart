import 'package:equatable/equatable.dart';

enum MediaType { image, video }

class PortfolioItem extends Equatable {
  final String id;
  final String businessId;
  final MediaType mediaType;
  final String mediaUrl;
  final String? thumbnailUrl; // For videos
  final String? caption;
  final double? price; // New field for sale items
  final String? productId; // Links back to the source product, if any
  final DateTime createdAt;

  const PortfolioItem({
    required this.id,
    required this.businessId,
    required this.mediaType,
    required this.mediaUrl,
    this.thumbnailUrl,
    this.caption,
    this.price,
    this.productId,
    required this.createdAt,
  });

  @override
  List<Object?> get props =>
      [id, businessId, mediaType, mediaUrl, thumbnailUrl, caption, price, productId, createdAt];

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
      price: json['price'] != null ? (json['price'] as num).toDouble() : null,
      productId: json['product_id'],
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
      'price': price,
      'product_id': productId,
    };
  }
}
