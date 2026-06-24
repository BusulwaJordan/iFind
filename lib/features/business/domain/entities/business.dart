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

extension BusinessCategoryStorage on BusinessCategory {
  String get storageValue {
    switch (this) {
      case BusinessCategory.realEstate:
        return 'real_estate';
      default:
        return name;
    }
  }

  static BusinessCategory fromStorageValue(String? value) {
    final normalized = (value ?? '').trim().toLowerCase();

    // Keyword-based/substring fuzzy matching
    if (normalized.contains('beauty') || normalized.contains('wellness')) {
      return BusinessCategory.beauty;
    }
    if (normalized.contains('electronics')) {
      return BusinessCategory.electronics;
    }
    if (normalized.contains('fashion') || normalized.contains('clothing')) {
      return BusinessCategory.fashion;
    }
    if (normalized.contains('food') ||
        normalized.contains('restaurant') ||
        normalized.contains('beverage') ||
        normalized.contains('catering')) {
      return BusinessCategory.food;
    }
    if (normalized.contains('education') || normalized.contains('training')) {
      return BusinessCategory.education;
    }
    if (normalized.contains('health') ||
        normalized.contains('pharmacy') ||
        normalized.contains('medical') ||
        normalized.contains('hospital')) {
      return BusinessCategory.health;
    }
    if (normalized.contains('finance') || normalized.contains('financial')) {
      return BusinessCategory.finance;
    }
    if (normalized.contains('retail')) {
      return BusinessCategory.retail;
    }
    if (normalized.contains('service') ||
        normalized.contains('transport') ||
        normalized.contains('logistics') ||
        normalized.contains('it & software')) {
      return BusinessCategory.service;
    }
    if (normalized.contains('sports') || normalized.contains('fitness')) {
      return BusinessCategory.sports;
    }
    if (normalized.contains('kids') || normalized.contains('child')) {
      return BusinessCategory.kids;
    }
    if (normalized.contains('entertainment') || normalized.contains('event')) {
      return BusinessCategory.entertainment;
    }
    if (normalized.contains('arcade')) {
      return BusinessCategory.arcade;
    }
    if (normalized.contains('travel') || normalized.contains('flight')) {
      return BusinessCategory.travel;
    }
    if (normalized.contains('real_estate') ||
        normalized.contains('realestate') ||
        normalized.contains('properties') ||
        normalized.contains('apartment')) {
      return BusinessCategory.realEstate;
    }
    if (normalized.contains('pets') ||
        normalized.contains('dog') ||
        normalized.contains('cat')) {
      return BusinessCategory.pets;
    }
    if (normalized.contains('home')) {
      return BusinessCategory.home;
    }
    if (normalized.contains('automotive') || normalized.contains('car')) {
      return BusinessCategory.automotive;
    }

    switch (normalized) {
      case 'retail':
        return BusinessCategory.retail;
      case 'service':
      case 'services':
        return BusinessCategory.service;
      case 'food':
        return BusinessCategory.food;
      case 'fashion':
        return BusinessCategory.fashion;
      case 'electronics':
        return BusinessCategory.electronics;
      case 'home':
        return BusinessCategory.home;
      case 'beauty':
        return BusinessCategory.beauty;
      case 'automotive':
        return BusinessCategory.automotive;
      case 'health':
        return BusinessCategory.health;
      case 'sports':
        return BusinessCategory.sports;
      case 'kids':
        return BusinessCategory.kids;
      case 'education':
        return BusinessCategory.education;
      case 'entertainment':
      case 'events':
        return BusinessCategory.entertainment;
      case 'arcade':
        return BusinessCategory.arcade;
      case 'travel':
        return BusinessCategory.travel;
      case 'real_estate':
      case 'realestate':
      case 'properties':
        return BusinessCategory.realEstate;
      case 'pets':
        return BusinessCategory.pets;
      case 'finance':
        return BusinessCategory.finance;
      default:
        return BusinessCategory.other;
    }
  }
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
