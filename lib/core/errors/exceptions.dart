/// Exception classes for typed error handling
library;

/// Network or Connectivity exceptions
class NetworkException implements Exception {
  final String message;
  NetworkException(this.message);

  @override
  String toString() => message;
}

/// Authentication specific exceptions (credentials, banned, etc)
class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}

/// Supabase / Database specific exceptions
class DatabaseException implements Exception {
  final String message;
  DatabaseException(this.message);

  @override
  String toString() => message;
}

/// Generic Server exceptions
class ServerException implements Exception {
  final String message;
  ServerException([this.message = 'An unexpected server error occurred']);

  @override
  String toString() => message;
}
