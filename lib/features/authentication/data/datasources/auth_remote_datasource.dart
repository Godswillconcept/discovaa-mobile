import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:discovaa/core/constants/api_endpoints.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/storage/secure_token_storage.dart';
import '../models/auth_models.dart';
import '../models/user_model.dart';
import '../models/registration_model.dart';

/// Abstract remote data source for authentication using OpenAPI
abstract class AuthRemoteDataSource {
  /// Register a new user
  Future<UserModel> register(RegistrationModel registration);

  /// Verify email with code
  Future<bool> verifyEmail({required String email, required String code});

  /// Login with email and password
  Future<UserModel> login({required String email, required String password});

  /// Logout current user
  Future<void> logout();

  /// Get current authenticated user
  Future<UserModel?> getCurrentUser();

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email);

  /// Reset password with key
  Future<void> resetPassword({
    required String key,
    required String newPassword,
  });

  /// Resend email verification code
  Future<void> resendEmailVerification(String email);

  /// Refresh access token
  Future<String?> refreshToken();
}

/// Implementation using OpenAPI endpoints
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final DioClient _dioClient;
  final SecureTokenStorage _tokenStorage;

  AuthRemoteDataSourceImpl({
    required DioClient dioClient,
    required SecureTokenStorage tokenStorage,
  }) : _dioClient = dioClient,
       _tokenStorage = tokenStorage;

  /// Store auth tokens from OpenAPI response
  ///
  /// Extracts tokens from AuthMeta, supporting both meta and data envelope formats.
  /// [meta] - The AuthMeta parsed from response meta field
  /// [dataJson] - Optional data object for fallback refresh_token parsing
  Future<void> _storeTokens(
    AuthMeta meta, [
    Map<String, dynamic>? dataJson,
  ]) async {
    // Try to get refresh_token from meta, fall back to data if needed
    String? refreshTokenValue = meta.refreshToken;

    // Diagnostic logging to trace refresh token extraction
    debugPrint(
      '[AuthRemoteDataSource] meta.refreshToken: ${refreshTokenValue != null ? "present" : "MISSING"}',
    );
    if (dataJson != null) {
      debugPrint(
        '[AuthRemoteDataSource] data.refresh_token: ${dataJson['refresh_token'] != null ? "present" : "MISSING"}',
      );
    }

    if ((refreshTokenValue == null || refreshTokenValue.isEmpty) &&
        dataJson != null) {
      refreshTokenValue = dataJson['refresh_token']?.toString();
      debugPrint(
        '[AuthRemoteDataSource] Using refresh_token from data: ${refreshTokenValue != null ? "SUCCESS" : "STILL MISSING"}',
      );
    }

    // Use SecureTokenStorage for consistent token management
    await _tokenStorage.saveTokens(
      accessToken: meta.accessToken,
      sessionToken: meta.sessionToken,
      refreshToken: refreshTokenValue,
    );

    // Observability: Log which tokens were found and saved (without logging values)
    final hasAccess = meta.accessToken != null && meta.accessToken!.isNotEmpty;
    final hasSession =
        meta.sessionToken != null && meta.sessionToken!.isNotEmpty;
    final hasRefresh =
        refreshTokenValue != null && refreshTokenValue.isNotEmpty;
    debugPrint(
      '[AuthRemoteDataSource] Tokens saved: access=$hasAccess, session=$hasSession, refresh=$hasRefresh',
    );

    // Warning if refresh token is missing after login/session
    if (!hasRefresh) {
      debugPrint(
        '[AuthRemoteDataSource] WARNING: No refresh_token found in auth response. '
        'This may indicate a backend contract mismatch or parser issue.',
      );
    }
  }

  /// Clear all authentication-related data on logout
  Future<void> _clearAllAuthData() async {
    // Clear all auth data using SecureTokenStorage
    await _tokenStorage.clearAllAuthData();
  }

  /// Map User to UserModel
  UserModel _mapAuthUserToUserModel(AuthUser user) {
    return UserModel(
      id: user.id,
      email: user.email,
      displayName: user.display,
      phone: null,
      address: null,
      country: null,
      photoUrl: null,
      role: 'user',
      isEmailVerified: true, // OpenAPI handles this separately
      isProfileComplete: user.isProfileComplete,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Handle OpenAPI error response
  Exception _handleError(dynamic responseData, String defaultMessage) {
    if (responseData is Map<String, dynamic>) {
      final errorResponse = ErrorResponse.fromJson(responseData);
      if (errorResponse.errors.isNotEmpty) {
        final firstError = errorResponse.errors.first;
        return ServerException(
          message: firstError.message,
          code: firstError.code,
        );
      }
    }
    return ServerException(message: defaultMessage, code: 'UNKNOWN_ERROR');
  }

  @override
  Future<UserModel> register(RegistrationModel registration) async {
    try {
      // Generate username from email if not provided
      final username = registration.email.split('@').first;

      final request = SignupRequest(
        username: username,
        email: registration.email,
        password: registration.password,
      );

      // Use direct Dio call to allow 401 status code (pending verification)
      final dio = Dio(
        BaseOptions(
          baseUrl: ApiEndpoints.baseUrl,
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
          sendTimeout: const Duration(seconds: 30),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          validateStatus: (status) =>
              status == 200 || status == 401 || status == 409,
        ),
      );

      final response = await dio.post(
        ApiEndpoints.authSignup,
        data: request.toJson(),
      );

      // Debug: print the actual response for debugging
      debugPrint('Register response status: ${response.statusCode}');
      debugPrint('Register response data: ${response.data}');

      // Handle 200 (success), 401 (pending verification), and 409 (already exists)
      if (response.statusCode == 200 ||
          response.statusCode == 401 ||
          response.statusCode == 409) {
        final responseData = response.data;

        // Check if response has the expected envelope format
        if (responseData is Map<String, dynamic>) {
          // Normalize to Map<String, dynamic> to avoid type cast issues
          final normalizedData = Map<String, dynamic>.from(responseData);

          // Check if it's the envelope format: {status, data, meta}
          if (normalizedData.containsKey('data') &&
              normalizedData.containsKey('meta')) {
            final meta = AuthMeta.fromJson(
              normalizedData['meta'] as Map<String, dynamic>? ?? {},
            );
            final dataJson = normalizedData['data'] as Map<String, dynamic>?;

            // Store all tokens using _storeTokens for consistency
            await _storeTokens(meta, dataJson);

            // Check for pending verification flow on 401
            final data = responseData['data'] as Map<String, dynamic>?;
            final flows = data?['flows'] as List<dynamic>?;
            final hasPendingVerification =
                flows?.any(
                  (flow) =>
                      flow is Map<String, dynamic> &&
                      flow['id'] == 'verify_email' &&
                      flow['is_pending'] == true,
                ) ??
                false;

            // For 401 with pending verification, treat as success
            if (response.statusCode == 401 && hasPendingVerification) {
              debugPrint(
                '[AuthRemoteDataSource] Registration successful, pending email verification',
              );
              // Create minimal user model for the registration flow
              final userModel = UserModel(
                id: '',
                email: registration.email,
                displayName: registration.email.split('@').first,
                phone: null,
                address: null,
                country: null,
                photoUrl: null,
                role: registration.role,
                isEmailVerified: false,
                isProfileComplete: false,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              );
              return userModel;
            }

            // Normal 200 success path - store all tokens and return user
            if (response.statusCode == 200) {
              await _storeTokens(meta, normalizedData);
              final authResponse = AuthenticatedResponse.fromJson(
                normalizedData,
              );
              return _mapAuthUserToUserModel(authResponse.user);
            }
          }
          // Check if it's a direct user object (no envelope)
          else if (normalizedData.containsKey('id') &&
              normalizedData.containsKey('email')) {
            // Direct user response - create UserModel from it
            final user = UserModel.fromJson(normalizedData);
            // Try to get tokens from meta if available
            if (normalizedData.containsKey('meta')) {
              final metaJson = normalizedData['meta'] is Map
                  ? Map<String, dynamic>.from(normalizedData['meta'] as Map)
                  : <String, dynamic>{};
              // Use fromJsonWithFallback to parse refresh_token from both meta and root
              final meta = AuthMeta.fromJsonWithFallback(
                metaJson,
                normalizedData,
              );
              await _storeTokens(meta, normalizedData);
            }
            return user;
          }
        }

        // Handle 409 - email already registered
        if (response.statusCode == 409) {
          final responseData = response.data;
          String message = 'Email already registered';
          if (responseData is Map<String, dynamic>) {
            message =
                responseData['message']?.toString() ??
                responseData['detail']?.toString() ??
                'An account with this email already exists';
          }
          throw ConflictException(message: message, code: 'EMAIL_EXISTS');
        }

        throw ServerException(
          message: 'Unexpected response format from server',
          code: 'INVALID_RESPONSE_FORMAT',
        );
      }

      throw _handleError(response.data, 'Registration failed');
    } on NetworkException {
      rethrow;
    } on ServerException {
      rethrow;
    } catch (e) {
      throw UnknownException(
        message: 'Unexpected error during registration',
        code: 'UNKNOWN_REGISTRATION_ERROR',
        details: e,
      );
    }
  }

  @override
  Future<bool> verifyEmail({
    required String email,
    required String code,
  }) async {
    try {
      final request = EmailVerifyRequest(email: email, code: code);

      // Use direct Dio call to allow 409 status code (already verified)
      final dio = Dio(
        BaseOptions(
          baseUrl: ApiEndpoints.baseUrl,
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
          sendTimeout: const Duration(seconds: 30),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          validateStatus: (status) => status == 200 || status == 409,
        ),
      );

      final response = await dio.post(
        ApiEndpoints.authEmailVerify,
        data: request.toJson(),
      );

      debugPrint('VerifyEmail response status: ${response.statusCode}');
      debugPrint('VerifyEmail response data: ${response.data}');

      // 200 = verified successfully
      if (response.statusCode == 200) {
        return true;
      }

      // 409 = email already verified or code expired/invalid
      if (response.statusCode == 409) {
        final responseData = response.data;
        String message = 'Verification failed';
        if (responseData is Map<String, dynamic>) {
          message =
              responseData['message']?.toString() ??
              responseData['detail']?.toString() ??
              'This email may already be verified or the code is invalid';
        }
        throw ConflictException(
          message: message,
          code: 'VERIFICATION_CONFLICT',
        );
      }

      throw _handleError(response.data, 'Email verification failed');
    } on NetworkException {
      rethrow;
    } on ServerException {
      rethrow;
    } catch (e) {
      throw UnknownException(
        message: 'Unexpected error during email verification',
        code: 'UNKNOWN_EMAIL_VERIFICATION_ERROR',
        details: e,
      );
    }
  }

  /// NOTE: completeProfile is not needed in OpenAPI - signup includes profile
  /// Keeping for interface compatibility but redirecting to getCurrentUser
  Future<UserModel> completeProfile(dynamic profile) async {
    return await getCurrentUser() ??
        (throw ServerException(
          message: 'Failed to get current user after profile completion',
          code: 'PROFILE_COMPLETION_FAILED',
        ));
  }

  @override
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final request = LoginRequest(email: email, password: password);

      final response = await _dioClient.post(
        ApiEndpoints.authLogin,
        data: request.toJson(),
      );

      // Debug: print the actual response for debugging
      debugPrint('Login response status: ${response.statusCode}');
      debugPrint('Login response data: ${response.data}');

      if (response.statusCode == 200) {
        final responseData = response.data;

        // Check if response has the expected envelope format
        if (responseData is Map<String, dynamic>) {
          // Normalize to Map<String, dynamic> to avoid type cast issues
          final normalizedData = Map<String, dynamic>.from(responseData);

          // Check if it's the envelope format: {status, data, meta}
          if (normalizedData.containsKey('data') &&
              normalizedData.containsKey('meta')) {
            final authResponse = AuthenticatedResponse.fromJson(normalizedData);
            final dataJson = normalizedData['data'] as Map<String, dynamic>?;
            // Store tokens with fallback from data
            await _storeTokens(authResponse.meta, dataJson);
            return _mapAuthUserToUserModel(authResponse.user);
          }
          // Check if it's a direct user object (no envelope)
          else if (normalizedData.containsKey('id') &&
              normalizedData.containsKey('email')) {
            // Direct user response - create UserModel from it
            final user = UserModel.fromJson(normalizedData);
            // Try to get tokens from meta if available
            if (normalizedData.containsKey('meta')) {
              final metaJson = normalizedData['meta'] is Map
                  ? Map<String, dynamic>.from(normalizedData['meta'] as Map)
                  : <String, dynamic>{};
              // Use fromJsonWithFallback to parse refresh_token from both meta and root
              final meta = AuthMeta.fromJsonWithFallback(
                metaJson,
                normalizedData,
              );
              await _storeTokens(meta, normalizedData);
            }
            return user;
          }
        }

        throw ServerException(
          message: 'Unexpected response format from server',
          code: 'INVALID_RESPONSE_FORMAT',
        );
      }

      throw _handleError(response.data, 'Login failed');
    } on NetworkException {
      rethrow;
    } on ServerException {
      rethrow;
    } catch (e) {
      throw UnknownException(
        message: 'Unexpected error during login',
        code: 'UNKNOWN_LOGIN_ERROR',
        details: e,
      );
    }
  }

  @override
  Future<void> logout() async {
    try {
      // Call logout API if available
      try {
        await _dioClient.delete(ApiEndpoints.authLogout);
      } catch (e) {
        // Ignore API errors during logout - we still want to clear local data
        debugPrint('Logout API call failed: $e');
      }
      // Clear all auth data from local storage
      await _clearAllAuthData();
    } catch (e) {
      throw UnknownException(
        message: 'Unexpected error during logout',
        code: 'UNKNOWN_LOGOUT_ERROR',
        details: e,
      );
    }
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    try {
      final response = await _dioClient.get(ApiEndpoints.authCurrentUser);

      // Debug: print the actual response for debugging
      debugPrint('GetCurrentUser response status: ${response.statusCode}');
      debugPrint('GetCurrentUser response data: ${response.data}');

      if (response.statusCode == 200) {
        final responseData = response.data;

        if (responseData is Map<String, dynamic>) {
          // Check if it's the envelope format: {status, data, meta}
          if (responseData.containsKey('data') &&
              responseData.containsKey('meta')) {
            final sessionResponse = SessionResponse.fromJson(responseData);
            if (sessionResponse.isAuthenticated &&
                sessionResponse.user != null) {
              return _mapAuthUserToUserModel(sessionResponse.user!);
            }
          }
          // Check if it's a direct user object (no envelope)
          else if (responseData.containsKey('id') &&
              responseData.containsKey('email')) {
            return UserModel.fromJson(responseData);
          }
        }
      }

      return null;
    } on AuthenticationException {
      return null;
    } on NetworkException {
      rethrow;
    } catch (e) {
      throw UnknownException(
        message: 'Unexpected error getting current user',
        code: 'UNKNOWN_GET_USER_ERROR',
        details: e,
      );
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      final request = PasswordRequest(email: email);

      final response = await _dioClient.post(
        ApiEndpoints.authPasswordRequest,
        data: request.toJson(),
      );

      if (response.statusCode != 200) {
        throw _handleError(response.data, 'Failed to send reset email');
      }
    } on NetworkException {
      rethrow;
    } on ServerException {
      rethrow;
    } catch (e) {
      throw UnknownException(
        message: 'Unexpected error sending reset email',
        code: 'UNKNOWN_RESET_EMAIL_ERROR',
        details: e,
      );
    }
  }

  @override
  Future<void> resetPassword({
    required String key,
    required String newPassword,
  }) async {
    try {
      final request = PasswordResetRequest(key: key, password: newPassword);

      final response = await _dioClient.post(
        ApiEndpoints.authPasswordReset,
        data: request.toJson(),
      );

      if (response.statusCode != 200) {
        throw _handleError(response.data, 'Failed to reset password');
      }
    } on NetworkException {
      rethrow;
    } on ServerException {
      rethrow;
    } catch (e) {
      throw UnknownException(
        message: 'Unexpected error resetting password',
        code: 'UNKNOWN_PASSWORD_RESET_ERROR',
        details: e,
      );
    }
  }

  @override
  Future<void> resendEmailVerification(String email) async {
    try {
      final request = PasswordRequest(email: email);

      final response = await _dioClient.post(
        ApiEndpoints.authEmailVerifyResend,
        data: request.toJson(),
      );

      if (response.statusCode != 200) {
        throw _handleError(
          response.data,
          'Failed to resend verification email',
        );
      }
    } on NetworkException {
      rethrow;
    } on ServerException {
      rethrow;
    } catch (e) {
      throw UnknownException(
        message: 'Unexpected error resending verification email',
        code: 'UNKNOWN_RESEND_VERIFICATION_ERROR',
        details: e,
      );
    }
  }

  @override
  Future<String?> refreshToken() async {
    try {
      final refreshToken = await _tokenStorage.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        return null;
      }

      final request = TokenRefreshRequest(refreshToken: refreshToken);

      final response = await _dioClient.post(
        ApiEndpoints.tokensRefresh,
        data: request.toJson(),
      );

      if (response.statusCode == 200) {
        // Handle wrapped API response format: {success, data, meta, error}
        final responseData = response.data as Map<String, dynamic>?;
        final success = responseData?['success'] == true;

        if (!success) {
          return null;
        }

        final data = responseData?['data'] as Map<String, dynamic>?;
        if (data == null) {
          return null;
        }

        final refreshResponse = TokenRefreshResponse.fromJson(data);

        // Store new token using SecureTokenStorage
        await _tokenStorage.saveTokens(
          accessToken: refreshResponse.accessToken,
          refreshToken: refreshResponse.refreshToken,
        );

        return refreshResponse.accessToken;
      }

      return null;
    } on NetworkException {
      rethrow;
    } catch (e) {
      throw UnknownException(
        message: 'Unexpected error refreshing token',
        code: 'UNKNOWN_TOKEN_REFRESH_ERROR',
        details: e,
      );
    }
  }
}
