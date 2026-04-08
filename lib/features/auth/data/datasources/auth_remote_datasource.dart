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
  Future<User> login({
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

      final model = await _mapSupabaseUserToModel(response.user!);
      return model.toEntity();
    } on AuthException {
      rethrow;
    } catch (e) {
      throw Exception('Login failed: ${e.toString()}');
    }
  }

  /// Register new user
  Future<User> register({
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
        emailRedirectTo: 'ifind://auth/verify', // Deep link for mobile
        data: {
          'full_name': fullName,
          'role': role == UserRole.businessOwner ? 'business_owner' : role.name,
          'phone': phone,
        },
      );

      if (response.user == null) {
        throw Exception('Registration failed');
      }

      final now = DateTime.now();

      // Return user entity directly
      return User(
        id: response.user!.id,
        email: email,
        fullName: fullName,
        role: role,
        phone: phone,
        createdAt: now,
        updatedAt: now,
      );
    } on AuthException {
      rethrow;
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

  /// Login with Google
  Future<void> loginWithGoogle() async {
    try {
      await supabaseClient.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.supabase.ifind://login-callback/',
      );
    } catch (e) {
      throw Exception('Google Sign-In failed: ${e.toString()}');
    }
  }

  /// Get current user
  Future<User?> getCurrentUser() async {
    try {
      final currentUser = supabaseClient.auth.currentUser;
      if (currentUser == null) return null;

      final model = await _mapSupabaseUserToModel(currentUser);
      return model.toEntity();
    } catch (e) {
      return null;
    }
  }

  /// Get user by ID
  Future<User> getUserById(String id) async {
    try {
      final response = await supabaseClient
          .from(ApiConstants.usersTable)
          .select()
          .eq('id', id)
          .single();

      final model = UserModel.fromJson(response);
      return model.toEntity();
    } catch (e) {
      throw Exception('Failed to fetch user: $e');
    }
  }

  /// Update user profile
  Future<User> updateProfile({
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

      final model = UserModel.fromJson(response);
      return model.toEntity();
    } catch (e) {
      throw Exception('Profile update failed: ${e.toString()}');
    }
  }

  /// Listen to auth state changes
  Stream<User?> get authStateChanges {
    return supabaseClient.auth.onAuthStateChange.asyncMap((state) async {
      final user = state.session?.user;
      if (user == null) return null;

      try {
        final model = await _mapSupabaseUserToModel(user);
        return model.toEntity();
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

      final roleStr = metadata['role'] as String? ?? 'customer';
      final parsedRole = roleStr == 'business_owner' 
          ? UserRole.businessOwner 
          : (roleStr == 'manager' ? UserRole.manager : UserRole.customer);

      return UserModel(
        id: user.id,
        email: user.email ?? '',
        fullName: metadata['full_name'] as String? ?? 'iFind User',
        role: parsedRole,
        phone: metadata['phone'] as String?,
        avatarUrl: metadata['avatar_url'] as String?,
        createdAt: DateTime.tryParse(user.createdAt) ?? now,
        updatedAt: now,
      );
    }
  }
}
