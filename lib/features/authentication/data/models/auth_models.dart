// OpenAPI Authentication Models
// Based on Headless API specification

// ============================================================================
// Request DTOs
// ============================================================================

/// Login request
/// Supports login by email or username
class LoginRequest {
  final String? email;
  final String? username;
  final String password;

  const LoginRequest({this.email, this.username, required this.password})
    : assert(
        email != null || username != null,
        'Either email or username is required',
      );

  Map<String, dynamic> toJson() {
    return {
      if (email != null) 'email': email,
      if (username != null) 'username': username,
      'password': password,
    };
  }
}

/// Signup request
class SignupRequest {
  final String username;
  final String email;
  final String password;

  const SignupRequest({
    required this.username,
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {'username': username, 'email': email, 'password': password};
  }
}

/// Email verification request
class EmailVerifyRequest {
  final String email;
  final String code;

  const EmailVerifyRequest({required this.email, required this.code});

  Map<String, dynamic> toJson() {
    return {'email': email, 'code': code};
  }
}

/// Password reset request (send email)
class PasswordRequest {
  final String email;

  const PasswordRequest({required this.email});

  Map<String, dynamic> toJson() {
    return {'email': email};
  }
}

/// Password reset confirmation
class PasswordResetRequest {
  final String key;
  final String password;

  const PasswordResetRequest({required this.key, required this.password});

  Map<String, dynamic> toJson() {
    return {'key': key, 'password': password};
  }
}

/// Token refresh request
class TokenRefreshRequest {
  final String accessToken;

  const TokenRefreshRequest({required this.accessToken});

  Map<String, dynamic> toJson() {
    return {'token': accessToken};
  }
}

/// ============================================================================
/// Response DTOs
/// ============================================================================

/// User data in response
class AuthUser {
  final String id;
  final String display;
  final String email;
  final String username;
  final bool hasUsablePassword;

  const AuthUser({
    required this.id,
    required this.display,
    required this.email,
    required this.username,
    required this.hasUsablePassword,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id']?.toString() ?? '',
      display: json['display']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      hasUsablePassword: json['has_usable_password'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'display': display,
      'email': email,
      'username': username,
      'has_usable_password': hasUsablePassword,
    };
  }
}

/// Authentication method used
class AuthMethod {
  final String method;
  final int at; // timestamp
  final Map<String, dynamic>? extraData;

  const AuthMethod({required this.method, required this.at, this.extraData});

  factory AuthMethod.fromJson(dynamic json) {
    // Handle case where methods item might be a string instead of object
    if (json is String) {
      return AuthMethod(
        method: json,
        at: DateTime.now().millisecondsSinceEpoch,
        extraData: null,
      );
    }
    // Handle proper object format
    if (json is Map<String, dynamic>) {
      // Handle 'at' field that might be String instead of int
      final atValue = json['at'];
      int atTimestamp;
      if (atValue is int) {
        atTimestamp = atValue;
      } else if (atValue is String) {
        atTimestamp =
            int.tryParse(atValue) ?? DateTime.now().millisecondsSinceEpoch;
      } else {
        atTimestamp = DateTime.now().millisecondsSinceEpoch;
      }

      return AuthMethod(
        method: json['method']?.toString() ?? 'password',
        at: atTimestamp,
        extraData: json,
      );
    }
    // Fallback for unexpected format
    return AuthMethod(
      method: 'password',
      at: DateTime.now().millisecondsSinceEpoch,
      extraData: null,
    );
  }
}

/// Data inside authenticated response
class AuthenticatedData {
  final AuthUser user;
  final List<AuthMethod> methods;

  const AuthenticatedData({required this.user, required this.methods});

  factory AuthenticatedData.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'] as Map<String, dynamic>?;
    final methodsList = json['methods'] as List<dynamic>?;

    return AuthenticatedData(
      user: userJson != null
          ? AuthUser.fromJson(userJson)
          : const AuthUser(
              id: '',
              display: '',
              email: '',
              username: '',
              hasUsablePassword: false,
            ),
      methods: methodsList?.map((e) => AuthMethod.fromJson(e)).toList() ?? [],
    );
  }
}

/// Meta information in auth response
class AuthMeta {
  final bool isAuthenticated;
  final String? sessionToken;
  final String? accessToken;

  const AuthMeta({
    required this.isAuthenticated,
    this.sessionToken,
    this.accessToken,
  });

  factory AuthMeta.fromJson(Map<String, dynamic> json) {
    return AuthMeta(
      isAuthenticated: json['is_authenticated'] == true,
      sessionToken: json['session_token']?.toString(),
      accessToken: json['access_token']?.toString(),
    );
  }
}

/// Authenticated response (login/signup success)
class AuthenticatedResponse {
  final int status;
  final AuthenticatedData data;
  final AuthMeta meta;

  const AuthenticatedResponse({
    required this.status,
    required this.data,
    required this.meta,
  });

  factory AuthenticatedResponse.fromJson(Map<String, dynamic> json) {
    return AuthenticatedResponse(
      status: json['status'] as int? ?? 200,
      data: AuthenticatedData.fromJson(
        json['data'] as Map<String, dynamic>? ?? {},
      ),
      meta: AuthMeta.fromJson(json['meta'] as Map<String, dynamic>? ?? {}),
    );
  }

  /// Convenience getter for the user
  AuthUser get user => data.user;
}

/// Error item in error response
class ErrorItem {
  final String? param;
  final String code;
  final String message;

  const ErrorItem({this.param, required this.code, required this.message});

  factory ErrorItem.fromJson(Map<String, dynamic> json) {
    return ErrorItem(
      param: json['param']?.toString(),
      code: json['code']?.toString() ?? 'unknown_error',
      message: json['message']?.toString() ?? 'An error occurred',
    );
  }
}

/// Error response
class ErrorResponse {
  final int status;
  final List<ErrorItem> errors;

  const ErrorResponse({required this.status, required this.errors});

  factory ErrorResponse.fromJson(Map<String, dynamic> json) {
    final errorsList = json['errors'] as List<dynamic>?;
    return ErrorResponse(
      status: json['status'] as int? ?? 400,
      errors:
          errorsList
              ?.map((e) => ErrorItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  /// Get the first error message
  String get firstErrorMessage =>
      errors.isNotEmpty ? errors.first.message : 'An error occurred';

  /// Get errors for a specific field
  List<ErrorItem> errorsForField(String field) {
    return errors.where((e) => e.param == field).toList();
  }
}

/// ============================================================================
/// Session Response (for GET /auth/session)
/// ============================================================================

class SessionResponse {
  final int status;
  final AuthenticatedData? data;
  final AuthMeta meta;

  const SessionResponse({required this.status, this.data, required this.meta});

  factory SessionResponse.fromJson(Map<String, dynamic> json) {
    final dataJson = json['data'] as Map<String, dynamic>?;
    return SessionResponse(
      status: json['status'] as int? ?? 200,
      data: dataJson != null ? AuthenticatedData.fromJson(dataJson) : null,
      meta: AuthMeta.fromJson(json['meta'] as Map<String, dynamic>? ?? {}),
    );
  }

  bool get isAuthenticated => meta.isAuthenticated;
  AuthUser? get user => data?.user;
}

/// ============================================================================
/// Token Refresh Response
/// ============================================================================

class TokenRefreshResponse {
  final String accessToken;
  final String? refreshToken;
  final int? expiresIn;

  const TokenRefreshResponse({
    required this.accessToken,
    this.refreshToken,
    this.expiresIn,
  });

  factory TokenRefreshResponse.fromJson(Map<String, dynamic> json) {
    return TokenRefreshResponse(
      accessToken: json['access_token']?.toString() ?? '',
      refreshToken: json['refresh_token']?.toString(),
      expiresIn: json['expires_in'] as int?,
    );
  }
}
