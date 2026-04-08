import 'package:dartz/dartz.dart';
import 'package:ifind/core/errors/failures.dart';
import 'package:ifind/features/auth/domain/entities/user.dart';

/// Abstract auth repository - domain layer
/// Defines the contract for authentication operations
abstract class AuthRepository {
  /// Login with email and password
  Future<Either<Failure, User>> login({
    required String email,
    required String password,
  });

  /// Login with Google OAuth
  Future<Either<Failure, void>> loginWithGoogle();

  /// Register new user
  Future<Either<Failure, User>> register({
    required String email,
    required String password,
    required String fullName,
    required UserRole role,
    String? phone,
  });

  /// Logout current user
  Future<Either<Failure, void>> logout();

  /// Get current user
  Future<Either<Failure, User?>> getCurrentUser();

  /// Get user by ID
  Future<Either<Failure, User>> getUserById(String id);

  /// Update user profile
  Future<Either<Failure, User>> updateProfile({
    required String userId,
    String? fullName,
    String? phone,
  });

  /// Listen to auth state changes
  Stream<User?> get authStateChanges;
}
