import 'package:freezed_annotation/freezed_annotation.dart';

part 'business.freezed.dart';


enum BusinessCategory {
  retail,
  service,
  food,
  fashion,
  electronics,
  home,
  beauty,
  automotive,
  health,
  sports,
  kids,
  education,
  entertainment,
  arcade,
  travel,
  @JsonValue('real_estate')
  realEstate,
  pets,
  finance,
  other,
}


@freezed
class Business with _$Business {
  const factory Business({
    required String id,
    required String ownerId,
    required String name,
    required String description,
    required BusinessCategory category,
    String? subCategory,
    String? address,
    required double latitude,
    required double longitude,
    String? phone,
    String? website,
    String? email,
    String? logoUrl,
    String? coverImageUrl,
    @Default(false) bool isVerified,
    @Default(0.0) double rating,
    @Default(0) int reviewCount,
    double? distance,
    required DateTime createdAt,
  }) = _Business;
}

