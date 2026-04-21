// OpenAPI Authentication Models
// Based on Headless API specification

import '../../presentation/providers/signup_provider.dart';

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
/// Uses account_type and provider_type to match web app API
class SignupRequest {
  final String email;
  final String password;
  final String accountType;
  final String? providerType;

  const SignupRequest({
    required this.email,
    required this.password,
    required this.accountType,
    this.providerType,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'email': email,
      'password': password,
      'account_type': accountType,
    };
    if (providerType != null) {
      json['provider_type'] = providerType;
    }
    return json;
  }

  /// Create from UserRole enum
  /// Maps UserRole to account_type and provider_type for API
  factory SignupRequest.fromUserRole(
    UserRole role, {
    required String email,
    required String password,
  }) {
    switch (role) {
      case UserRole.user:
        return SignupRequest(
          email: email,
          password: password,
          accountType: 'user',
          providerType: null,
        );
      case UserRole.individualProvider:
        return SignupRequest(
          email: email,
          password: password,
          accountType: 'service_provider',
          providerType: 'individual',
        );
      case UserRole.businessProvider:
        return SignupRequest(
          email: email,
          password: password,
          accountType: 'service_provider',
          providerType: 'business',
        );
    }
  }
}

/// Email verification request
class EmailVerifyRequest {
  final String key;

  const EmailVerifyRequest({required this.key});

  Map<String, dynamic> toJson() {
    return {'key': key};
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
  final String refreshToken;

  const TokenRefreshRequest({required this.refreshToken});

  Map<String, dynamic> toJson() {
    return {'refresh_token': refreshToken};
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
  final bool isProfileComplete;

  const AuthUser({
    required this.id,
    required this.display,
    required this.email,
    required this.username,
    required this.hasUsablePassword,
    this.isProfileComplete = true,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    final String display = json['display']?.toString() ?? '';
    final String username = json['username']?.toString() ?? '';
    final String email = json['email']?.toString() ?? '';

    // Detect incomplete profile:
    // 1. Backend explicitly sends is_profile_complete: false
    // 2. OR display equals username (auto-generated display name from registration)
    final bool? explicitProfileComplete =
        json['is_profile_complete'] as bool? ??
        json['profile_complete'] as bool?;

    final bool isProfileComplete =
        explicitProfileComplete ??
        // If backend explicitly sends is_profile_complete, use it
        // Otherwise, consider profile complete if display is set and doesn't look auto-generated
        (display.isNotEmpty &&
            !display.contains('@') &&
            display.toLowerCase() != email.toLowerCase());

    return AuthUser(
      id: json['id']?.toString() ?? '',
      display: display,
      email: json['email']?.toString() ?? '',
      username: username,
      hasUsablePassword: json['has_usable_password'] == true,
      isProfileComplete: isProfileComplete,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'display': display,
      'email': email,
      'username': username,
      'has_usable_password': hasUsablePassword,
      'is_profile_complete': isProfileComplete,
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
///
/// Parses refresh_token from multiple locations:
/// 1. meta.refresh_token (preferred)
/// 2. data.refresh_token (fallback for some endpoints)
class AuthMeta {
  final bool isAuthenticated;
  final String? sessionToken;
  final String? accessToken;
  final String? refreshToken;

  const AuthMeta({
    required this.isAuthenticated,
    this.sessionToken,
    this.accessToken,
    this.refreshToken,
  });

  /// Factory that parses tokens from meta and optionally from data envelope.
  ///
  /// [metaJson] - The meta object from response envelope
  /// [dataJson] - Optional data object for fallback refresh_token parsing
  factory AuthMeta.fromJsonWithFallback(
    Map<String, dynamic> metaJson, [
    Map<String, dynamic>? dataJson,
  ]) {
    // Primary parse from meta
    final refreshFromMeta = metaJson['refresh_token']?.toString();

    // Fallback: check data.refresh_token if not in meta
    final refreshFromData = dataJson?['refresh_token']?.toString();

    return AuthMeta(
      isAuthenticated: metaJson['is_authenticated'] == true,
      sessionToken: metaJson['session_token']?.toString(),
      accessToken: metaJson['access_token']?.toString(),
      refreshToken: refreshFromMeta ?? refreshFromData,
    );
  }

  factory AuthMeta.fromJson(Map<String, dynamic> json) {
    return AuthMeta(
      isAuthenticated: json['is_authenticated'] == true,
      sessionToken: json['session_token']?.toString(),
      accessToken: json['access_token']?.toString(),
      refreshToken: json['refresh_token']?.toString(),
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
    // Normalize data to handle potential dynamic Map casting issues
    final dataJson = json['data'] is Map
        ? Map<String, dynamic>.from(json['data'] as Map)
        : <String, dynamic>{};
    final metaJson = json['meta'] is Map
        ? Map<String, dynamic>.from(json['meta'] as Map)
        : <String, dynamic>{};

    return AuthenticatedResponse(
      status: json['status'] as int? ?? 200,
      data: AuthenticatedData.fromJson(dataJson),
      // Use fromJsonWithFallback to parse refresh_token from both meta and data
      meta: AuthMeta.fromJsonWithFallback(metaJson, dataJson),
    );
  }

  /// Convenience getter for the user
  AuthUser get user => data.user;
}

/// Represents a flow in the authentication process
class AuthFlow {
  final String id;
  final bool isPending;
  final Map<String, dynamic>? provider;
  final List<String>? types;

  const AuthFlow({
    required this.id,
    this.isPending = false,
    this.provider,
    this.types,
  });

  factory AuthFlow.fromJson(Map<String, dynamic> json) {
    return AuthFlow(
      id: json['id']?.toString() ?? '',
      isPending: json['is_pending'] == true,
      provider: json['provider'] is Map
          ? Map<String, dynamic>.from(json['provider'] as Map)
          : null,
      types: (json['types'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
    );
  }
}

/// Represents an unauthenticated response, often containing pending flows (401)
class AuthenticationResponse {
  final int status;
  final List<AuthFlow> flows;
  final AuthMeta meta;
  final AuthUser? user; // Only present in reauthentication responses

  const AuthenticationResponse({
    required this.status,
    required this.flows,
    required this.meta,
    this.user,
  });

  factory AuthenticationResponse.fromJson(Map<String, dynamic> json) {
    final dataJson = json['data'] is Map
        ? Map<String, dynamic>.from(json['data'] as Map)
        : <String, dynamic>{};
    final flowsList = dataJson['flows'] as List<dynamic>?;
    final userJson = dataJson['user'] as Map<String, dynamic>?;
    final metaJson = json['meta'] is Map
        ? Map<String, dynamic>.from(json['meta'] as Map)
        : <String, dynamic>{};

    return AuthenticationResponse(
      status: json['status'] as int? ?? 401,
      flows:
          flowsList
              ?.map((e) => AuthFlow.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      meta: AuthMeta.fromJson(metaJson),
      user: userJson != null ? AuthUser.fromJson(userJson) : null,
    );
  }

  /// Check if a specific flow is pending
  bool isFlowPending(String flowId) {
    return flows.any((flow) => flow.id == flowId && flow.isPending);
  }
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
    // Normalize data to handle potential dynamic Map casting issues
    final dataJson = json['data'] is Map
        ? Map<String, dynamic>.from(json['data'] as Map)
        : null;
    final metaJson = json['meta'] is Map
        ? Map<String, dynamic>.from(json['meta'] as Map)
        : <String, dynamic>{};

    return SessionResponse(
      status: json['status'] as int? ?? 200,
      data: dataJson != null ? AuthenticatedData.fromJson(dataJson) : null,
      // Use fromJsonWithFallback to parse refresh_token from both meta and data
      meta: AuthMeta.fromJsonWithFallback(metaJson, dataJson),
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
