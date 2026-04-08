import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';

/// User role enum
enum UserRole {
  customer,
  @JsonValue('business_owner')
  businessOwner,
  manager;

  String get displayName {
    switch (this) {
      case UserRole.customer:
        return 'Customer';
      case UserRole.businessOwner:
        return 'Business Owner';
      case UserRole.manager:
        return 'Manager';
    }
  }
}

/// User entity - domain layer
@freezed
class User with _$User {
  const factory User({
    required String id,
    required String email,
    required UserRole role,
    required String fullName,
    String? phone,
    String? avatarUrl,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _User;
}
