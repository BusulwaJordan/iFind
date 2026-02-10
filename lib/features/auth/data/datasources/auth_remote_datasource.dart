import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:supabase_flutter/supabase_flutter.dart' as sb show User;
import 'package:ifind/core/constants/api_constants.dart';
import 'package:ifind/features/auth/data/models/user_model.dart';
import 'package:ifind/features/auth/domain/entities/user.dart';

/// Remote data source for authentication
/// Handles all Supabase authentication operations
class AuthRemoteDataSource {
  final SupabaseClient supabaseClient;

  AuthRemoteDataSource({required this.supabaseClient});

  /// Login with email and password
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await supabaseClient.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw Exception('Login failed: No user returned');
      }

      return await _mapSupabaseUserToModel(response.user!);
    } on AuthException catch (e) {
      // Return specific Supabase error message (e.g. "Email not confirmed")
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Login failed: ${e.toString()}');
    }
  }


  /// Register new user
  Future<UserModel> register({
    required String email,
    required String password,
    required String fullName,
    required UserRole role,
    String? phone,
  }) async {
    try {
      // Create auth user with metadata
      final response = await supabaseClient.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'role': _roleToString(role),
          'phone': phone,
        },
      );

      if (response.user == null) {
        throw Exception('Registration failed');
      }

      final now = DateTime.now();
      
      // Return user model based on input (profile creation handled by DB trigger)
      return UserModel(
        id: response.user!.id,
        email: email,
        fullName: fullName,
        role: role,
        phone: phone,
        createdAt: now,
        updatedAt: now,
      );


    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Registration failed: ${e.toString()}');
    }
  }

  /// Logout current user
  Future<void> logout() async {
    try {
      await supabaseClient.auth.signOut();
    } catch (e) {
      throw Exception('Logout failed: ${e.toString()}');
    }
  }

  /// Get current user
  Future<UserModel?> getCurrentUser() async {
    try {
      final currentUser = supabaseClient.auth.currentUser;
      if (currentUser == null) return null;

      return await _mapSupabaseUserToModel(currentUser);
    } catch (e) {
      return null;
    }
  }

  /// Get user by ID
  Future<UserModel> getUserById(String id) async {
    try {
      final response = await supabaseClient
          .from(ApiConstants.usersTable)
          .select()
          .eq('id', id)
          .single();

      return UserModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to fetch user: $e');
    }
  }

  /// Update user profile
  Future<UserModel> updateProfile({
    required String userId,
    String? fullName,
    String? phone,
  }) async {
    try {
      final updates = {
        'updated_at': DateTime.now().toIso8601String(),
        if (fullName != null) 'full_name': fullName,
        if (phone != null) 'phone': phone,
      };

      final response = await supabaseClient
          .from(ApiConstants.usersTable)
          .update(updates)
          .eq('id', userId)
          .select()
          .single();

      return UserModel.fromJson(response);
    } catch (e) {
      throw Exception('Profile update failed: ${e.toString()}');
    }
  }

  /// Listen to auth state changes
  Stream<UserModel?> get authStateChanges {
    return supabaseClient.auth.onAuthStateChange.asyncMap((state) async {
      final user = state.session?.user;
      if (user == null) return null;

      try {
        return await _mapSupabaseUserToModel(user);
      } catch (e) {
        return null;
      }
    });
  }

  /// Map Supabase auth User to iFind UserModel
  /// Attempts to fetch from database, falls back to user metadata
  Future<UserModel> _mapSupabaseUserToModel(sb.User user) async {
    try {
      final userProfile = await supabaseClient
          .from(ApiConstants.usersTable)
          .select()
          .eq('id', user.id)
          .single();

      return UserModel.fromJson(userProfile);
    } catch (e) {
      // Fallback: Use user metadata
      final metadata = user.userMetadata ?? {};
      final now = DateTime.now();

      return UserModel(
        id: user.id,
        email: user.email ?? '',
        fullName: metadata['full_name'] as String? ?? 'iFind User',
        role: _stringToRole(metadata['role'] as String? ?? 'customer'),
        phone: metadata['phone'] as String?,
        avatarUrl: metadata['avatar_url'] as String?,
        createdAt: DateTime.tryParse(user.createdAt) ?? now,
        updatedAt: now,
      );
    }
  }

  /// Helper to convert string to role enum
  UserRole _stringToRole(String role) {
    switch (role) {
      case 'business_owner':
        return UserRole.businessOwner;
      case 'manager':
        return UserRole.manager;
      default:
        return UserRole.customer;
    }
  }

  /// Helper to convert role enum to string
  String _roleToString(UserRole role) {
    switch (role) {
      case UserRole.customer:
        return 'customer';
      case UserRole.businessOwner:
        return 'business_owner';
      case UserRole.manager:
        return 'manager';
    }
  }
}
