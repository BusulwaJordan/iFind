import 'package:ifind/features/auth/domain/entities/user.dart';

/// Outcome of a registration attempt.
class RegistrationResult {
  final User user;
  final bool requiresEmailConfirmation;

  const RegistrationResult({
    required this.user,
    required this.requiresEmailConfirmation,
  });
}
