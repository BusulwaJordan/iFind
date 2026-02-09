import 'package:equatable/equatable.dart';

/// User role enum
enum UserRole {
  customer,
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
class User extends Equatable {
  final String id;
  final String email;
  final UserRole role;
  final String fullName;
  final String? phone;
  final DateTime createdAt;
  final DateTime updatedAt;

  const User({
    required this.id,
    required this.email,
    required this.role,
    required this.fullName,
    this.phone,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        email,
        role,
        fullName,
        phone,
        createdAt,
        updatedAt,
      ];

  User copyWith({
    String? id,
    String? email,
    UserRole? role,
    String? fullName,
    String? phone,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      role: role ?? this.role,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
