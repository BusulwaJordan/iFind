import 'package:ifind/features/auth/domain/entities/user.dart';

/// User model - data layer
/// Handles JSON serialization/deserialization for Supabase
class UserModel extends User {
  const UserModel({
    required super.id,
    required super.email,
    required super.role,
    required super.fullName,
    super.phone,
    required super.createdAt,
    required super.updatedAt,
  });

  /// From JSON factory
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      role: _roleFromString(json['role'] as String),
      fullName: json['full_name'] as String,
      phone: json['phone'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// To JSON method
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'role': _roleToString(role),
      'full_name': fullName,
      'phone': phone,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Convert from domain entity
  factory UserModel.fromEntity(User user) {
    return UserModel(
      id: user.id,
      email: user.email,
      role: user.role,
      fullName: user.fullName,
      phone: user.phone,
      createdAt: user.createdAt,
      updatedAt: user.updatedAt,
    );
  }

  /// Helper to convert role enum to string
  static String _roleToString(UserRole role) {
    switch (role) {
      case UserRole.customer:
        return 'customer';
      case UserRole.businessOwner:
        return 'business_owner';
      case UserRole.manager:
        return 'manager';
    }
  }

  /// Helper to convert string to role enum
  static UserRole _roleFromString(String role) {
    switch (role) {
      case 'customer':
        return UserRole.customer;
      case 'business_owner':
        return UserRole.businessOwner;
      case 'manager':
        return UserRole.manager;
      default:
        return UserRole.customer;
    }
  }
}
