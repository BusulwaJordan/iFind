import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Simple DTO used while a user completes email confirmation
class PendingRegistration {
  final String email;
  final String password;

  const PendingRegistration({required this.email, required this.password});
}

/// Holds the pending registration (email + password) while awaiting
/// email confirmation. Set to `null` when there's no pending registration.
final pendingRegistrationProvider =
    StateProvider<PendingRegistration?>((ref) => null);
