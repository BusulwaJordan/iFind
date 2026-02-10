import 'package:ifind/features/business/domain/entities/business.dart';

class BusinessModel extends Business {
  const BusinessModel({
    required super.id,
    required super.ownerId,
    required super.name,
    required super.description,
    required super.category,
    super.subCategory,
    super.address,
    required super.latitude,
    required super.longitude,
    super.phone,
    super.website,
    super.email,
    super.logoUrl,
    super.coverImageUrl,
    super.isVerified,
    super.rating,
    super.reviewCount,
    super.distance,
    required super.createdAt,
  });

  factory BusinessModel.fromJson(Map<String, dynamic> json) {
    double lat = (json['latitude'] as num?)?.toDouble() ?? 0.0;
    double lng = (json['longitude'] as num?)?.toDouble() ?? 0.0;
    
    // Fallback parser for PostGIS 'POINT(lng lat)' format if individual columns are null
    if (lat == 0.0 && lng == 0.0 && json['location'] != null) {
      try {
        final loc = json['location'] as String;
        final coords = loc.replaceAll('POINT(', '').replaceAll(')', '').split(' ');
        if (coords.length == 2) {
          lng = double.parse(coords[0]);
          lat = double.parse(coords[1]);
        }
      } catch (_) {}
    }

    return BusinessModel(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      category: _parseCategory(json['category'] as String),
      subCategory: json['sub_category'] as String?,
      address: json['address'] as String?,
      latitude: lat,
      longitude: lng,
      phone: json['phone'] as String?,
      website: json['website'] as String?,
      email: json['email'] as String?,
      logoUrl: json['logo_url'] as String?,
      coverImageUrl: json['cover_image_url'] as String?,
      isVerified: json['is_verified'] as bool? ?? false,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: json['review_count'] as int? ?? 0,
      distance: (json['distance'] as num?)?.toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'owner_id': ownerId,
      'name': name,
      'description': description,
      'category': category.name,
      'sub_category': subCategory,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'phone': phone,
      'website': website,
      'email': email,
      'logo_url': logoUrl,
      'cover_image_url': coverImageUrl,
      'is_verified': isVerified,
      'rating': rating,
      'review_count': reviewCount,
      'created_at': createdAt.toIso8601String(),
    };
  }

  static BusinessCategory _parseCategory(String category) {
    return BusinessCategory.values.firstWhere(
      (e) => e.name == category,
      orElse: () => BusinessCategory.other,
    );
  }
}
