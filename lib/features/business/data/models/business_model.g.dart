// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'business_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$BusinessModelImpl _$$BusinessModelImplFromJson(Map<String, dynamic> json) =>
    _$BusinessModelImpl(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      category: $enumDecode(_$BusinessCategoryEnumMap, json['category']),
      subCategory: json['sub_category'] as String?,
      address: json['address'] as String?,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      phone: json['phone'] as String?,
      website: json['website'] as String?,
      email: json['email'] as String?,
      logoUrl: json['logo_url'] as String?,
      coverImageUrl: json['cover_image_url'] as String?,
      isVerified: json['is_verified'] as bool? ?? false,
      rating: (json['rating_average'] as num?)?.toDouble() ?? 0.0,
      reviewCount: (json['rating_count'] as num?)?.toInt() ?? 0,
      distance: (json['distance'] as num?)?.toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$$BusinessModelImplToJson(_$BusinessModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'owner_id': instance.ownerId,
      'name': instance.name,
      'description': instance.description,
      'category': _$BusinessCategoryEnumMap[instance.category]!,
      'sub_category': instance.subCategory,
      'address': instance.address,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'phone': instance.phone,
      'website': instance.website,
      'email': instance.email,
      'logo_url': instance.logoUrl,
      'cover_image_url': instance.coverImageUrl,
      'is_verified': instance.isVerified,
      'rating_average': instance.rating,
      'rating_count': instance.reviewCount,
      'distance': instance.distance,
      'created_at': instance.createdAt.toIso8601String(),
    };

const _$BusinessCategoryEnumMap = {
  BusinessCategory.retail: 'retail',
  BusinessCategory.service: 'service',
  BusinessCategory.food: 'food',
  BusinessCategory.fashion: 'fashion',
  BusinessCategory.footwear: 'footwear',
  BusinessCategory.electronics: 'electronics',
  BusinessCategory.home: 'home',
  BusinessCategory.beauty: 'beauty',
  BusinessCategory.automotive: 'automotive',
  BusinessCategory.health: 'health',
  BusinessCategory.sports: 'sports',
  BusinessCategory.kids: 'kids',
  BusinessCategory.education: 'education',
  BusinessCategory.entertainment: 'entertainment',
  BusinessCategory.arcade: 'arcade',
  BusinessCategory.travel: 'travel',
  BusinessCategory.realEstate: 'real_estate',
  BusinessCategory.pets: 'pets',
  BusinessCategory.finance: 'finance',
  BusinessCategory.agriculture: 'agriculture',
  BusinessCategory.wholesale: 'wholesale',
  BusinessCategory.manufacturing: 'manufacturing',
  BusinessCategory.construction: 'construction',
  BusinessCategory.other: 'other',
};
