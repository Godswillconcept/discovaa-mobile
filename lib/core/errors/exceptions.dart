/// Base exception class for all custom exceptions
abstract class AppException implements Exception {
  final String message;
  final String code;
  final dynamic details;

  const AppException({required this.message, required this.code, this.details});

  @override
  String toString() => 'AppException: $message (Code: $code)';
}

/// Server-related exceptions
class ServerException extends AppException {
  const ServerException({
    required super.message,
    required super.code,
    super.details,
  });
}

/// Network-related exceptions
class NetworkException extends AppException {
  const NetworkException({
    required super.message,
    required super.code,
    super.details,
  });
}

/// Authentication exceptions
class AuthenticationException extends AppException {
  const AuthenticationException({
    required super.message,
    required super.code,
    super.details,
  });
}

/// Authorization exceptions
class AuthorizationException extends AppException {
  const AuthorizationException({
    required super.message,
    required super.code,
    super.details,
  });
}

/// Validation exceptions
class ValidationException extends AppException {
  final Map<String, String>? fieldErrors;

  const ValidationException({
    required super.message,
    required super.code,
    this.fieldErrors,
    super.details,
  });
}

/// Cache exceptions
class CacheException extends AppException {
  const CacheException({
    required super.message,
    required super.code,
    super.details,
  });
}

/// File handling exceptions
class FileException extends AppException {
  const FileException({
    required super.message,
    required super.code,
    super.details,
  });
}

/// Parsing exceptions
class ParseException extends AppException {
  const ParseException({
    required super.message,
    required super.code,
    super.details,
  });
}

/// Timeout exceptions
class TimeoutException extends AppException {
  const TimeoutException({
    required super.message,
    required super.code,
    super.details,
  });
}

/// Rate limit exceptions
class RateLimitException extends AppException {
  final DateTime? retryAfter;

  const RateLimitException({
    required super.message,
    required super.code,
    this.retryAfter,
    super.details,
  });
}

/// Not found exceptions
class NotFoundException extends AppException {
  const NotFoundException({
    required super.message,
    required super.code,
    super.details,
  });
}

/// Conflict exceptions
class ConflictException extends AppException {
  const ConflictException({
    required super.message,
    required super.code,
    super.details,
  });
}

/// Unknown exceptions
class UnknownException extends AppException {
  const UnknownException({
    required super.message,
    required super.code,
    super.details,
  });
}
