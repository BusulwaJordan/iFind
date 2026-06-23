import 'package:dartz/dartz.dart';
import 'package:ifind/core/errors/failures.dart';
import 'package:ifind/features/auth/domain/entities/registration_result.dart';
import 'package:ifind/features/auth/domain/entities/user.dart';
import 'package:ifind/features/auth/domain/repositories/auth_repository.dart';

/// Register use case
class Register {
  final AuthRepository repository;

  Register(this.repository);

  Future<Either<Failure, RegistrationResult>> call({
    required String email,
    required String password,
    required String fullName,
    required UserRole role,
    String? phone,
  }) async {
    return await repository.register(
      email: email,
      password: password,
      fullName: fullName,
      role: role,
      phone: phone,
    );
  }
}
