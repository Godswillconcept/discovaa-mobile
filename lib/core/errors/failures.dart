import 'package:equatable/equatable.dart';

/// Base failure class for all business logic failures
abstract class Failure extends Equatable {
  final String message;
  final String code;
  final dynamic details;

  const Failure({required this.message, required this.code, this.details});

  @override
  List<Object?> get props => [message, code, details];

  @override
  String toString() => 'Failure: $message (Code: $code)';
}

/// Server failures
class ServerFailure extends Failure {
  const ServerFailure({
    required super.message,
    required super.code,
    super.details,
  });
}

/// Network failures
class NetworkFailure extends Failure {
  const NetworkFailure({
    required super.message,
    required super.code,
    super.details,
  });
}

/// Authentication failures
class AuthenticationFailure extends Failure {
  const AuthenticationFailure({
    required super.message,
    required super.code,
    super.details,
  });
}

/// Authorization failures
class AuthorizationFailure extends Failure {
  const AuthorizationFailure({
    required super.message,
    required super.code,
    super.details,
  });
}

/// Validation failures
class ValidationFailure extends Failure {
  final Map<String, String>? fieldErrors;

  const ValidationFailure({
    required super.message,
    required super.code,
    this.fieldErrors,
    super.details,
  });

  @override
  List<Object?> get props => [message, code, details, fieldErrors];
}

/// Cache failures
class CacheFailure extends Failure {
  const CacheFailure({
    required super.message,
    required super.code,
    super.details,
  });
}

/// File handling failures
class FileFailure extends Failure {
  const FileFailure({
    required super.message,
    required super.code,
    super.details,
  });
}

/// Parsing failures
class ParsingFailure extends Failure {
  const ParsingFailure({
    required super.message,
    required super.code,
    super.details,
  });
}

/// Timeout failures
class TimeoutFailure extends Failure {
  const TimeoutFailure({
    required super.message,
    required super.code,
    super.details,
  });
}

/// Rate limit failures
class RateLimitFailure extends Failure {
  final DateTime? retryAfter;

  const RateLimitFailure({
    required super.message,
    required super.code,
    this.retryAfter,
    super.details,
  });

  @override
  List<Object?> get props => [message, code, details, retryAfter];
}

/// Not found failures
class NotFoundFailure extends Failure {
  const NotFoundFailure({
    required super.message,
    required super.code,
    super.details,
  });
}

/// Conflict failures
class ConflictFailure extends Failure {
  const ConflictFailure({
    required super.message,
    required super.code,
    super.details,
  });
}

/// Unknown failures
class UnknownFailure extends Failure {
  const UnknownFailure({
    required super.message,
    required super.code,
    super.details,
  });
}
