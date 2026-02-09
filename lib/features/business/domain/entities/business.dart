import 'package:equatable/equatable.dart';

enum BusinessCategory {
  retail,
  service,
  food,
  entertainment,
  arcade,
  other,
}

class Business extends Equatable {
  final String id;
  final String ownerId;
  final String name;
  final String description;
  final BusinessCategory category;
  final String? subCategory;
  final String? address;
  final double latitude;
  final double longitude;
  final String? phone;
  final String? website;
  final String? email;
  final String? logoUrl;
  final String? coverImageUrl;
  final bool isVerified;
  final double rating;
  final int reviewCount;
  final double? distance; // Calculated distance from user
  final DateTime createdAt;

  const Business({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.description,
    required this.category,
    this.subCategory,
    this.address,
    required this.latitude,
    required this.longitude,
    this.phone,
    this.website,
    this.email,
    this.logoUrl,
    this.coverImageUrl,
    this.isVerified = false,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.distance,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        ownerId,
        name,
        category,
        latitude,
        longitude,
        isVerified,
        rating,
        distance,
      ];
}
