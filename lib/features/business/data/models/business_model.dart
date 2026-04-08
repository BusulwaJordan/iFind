import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ifind/features/business/domain/entities/business.dart';

part 'business_model.freezed.dart';
part 'business_model.g.dart';

@freezed
class BusinessModel with _$BusinessModel {
  const factory BusinessModel({
    required String id,
    @JsonKey(name: 'owner_id') required String ownerId,
    required String name,
    required String description,
    required BusinessCategory category,
    @JsonKey(name: 'sub_category') String? subCategory,
    String? address,
    required double latitude,
    required double longitude,
    String? phone,
    String? website,
    String? email,
    @JsonKey(name: 'logo_url') String? logoUrl,
    @JsonKey(name: 'cover_image_url') String? coverImageUrl,
    @JsonKey(name: 'is_verified') @Default(false) bool isVerified,
    @JsonKey(name: 'rating_average') @Default(0.0) double rating,
    @JsonKey(name: 'rating_count') @Default(0) int reviewCount,
    double? distance,
    @JsonKey(name: 'created_at') required DateTime createdAt,
  }) = _BusinessModel;

  factory BusinessModel.fromJson(Map<String, dynamic> json) =>
      _$BusinessModelFromJson(_preprocess(json));

  static Map<String, dynamic> _preprocess(Map<String, dynamic> json) {
    final Map<String, dynamic> data = Map<String, dynamic>.from(json);

    double lat = (data['latitude'] as num?)?.toDouble() ?? 0.0;
    double lng = (data['longitude'] as num?)?.toDouble() ?? 0.0;

    // Fallback parser for PostGIS 'POINT(lng lat)' format
    if (lat == 0.0 && lng == 0.0 && data['location'] != null) {
      try {
        final loc = data['location'] as String;
        final coords =
            loc.replaceAll('POINT(', '').replaceAll(')', '').split(' ');
        if (coords.length == 2) {
          lng = double.parse(coords[0]);
          lat = double.parse(coords[1]);
        }
      } catch (_) {}
    }

    data['latitude'] = lat;
    data['longitude'] = lng;
    return data;
  }

  const BusinessModel._();

  Business toEntity() => Business(
        id: id,
        ownerId: ownerId,
        name: name,
        description: description,
        category: category,
        subCategory: subCategory,
        address: address,
        latitude: latitude,
        longitude: longitude,
        phone: phone,
        website: website,
        email: email,
        logoUrl: logoUrl,
        coverImageUrl: coverImageUrl,
        isVerified: isVerified,
        rating: rating,
        reviewCount: reviewCount,
        distance: distance,
        createdAt: createdAt,
      );
}
