import 'package:flutter/foundation.dart';
import 'package:discovaa/core/constants/api_endpoints.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/storage/hive_service.dart';
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
  final HiveService _hiveService;

  AuthRemoteDataSourceImpl({
    required DioClient dioClient,
    required HiveService hiveService,
  }) : _dioClient = dioClient,
       _hiveService = hiveService;

  /// Store auth tokens from OpenAPI response
  Future<void> _storeTokens(AuthMeta meta) async {
    if (meta.accessToken != null && meta.accessToken!.isNotEmpty) {
      await _hiveService.setString('access_token', meta.accessToken!);
    }
    if (meta.sessionToken != null && meta.sessionToken!.isNotEmpty) {
      await _hiveService.setString('session_token', meta.sessionToken!);
    }
  }

  /// Clear stored tokens on logout
  Future<void> _clearTokens() async {
    await _hiveService.remove('access_token');
    await _hiveService.remove('session_token');
  }

  /// Clear all authentication-related data on logout
  Future<void> _clearAllAuthData() async {
    // Clear tokens
    await _clearTokens();
    // Clear user data
    await _hiveService.remove('user_data');
    // Clear authenticated flag
    await _hiveService.remove('is_authenticated');
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
      isProfileComplete: true,
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

      final response = await _dioClient.post(
        ApiEndpoints.authSignup,
        data: request.toJson(),
      );

      // Debug: print the actual response for debugging
      debugPrint('Register response status: ${response.statusCode}');
      debugPrint('Register response data: ${response.data}');

      if (response.statusCode == 200) {
        final responseData = response.data;

        // Check if response has the expected envelope format
        if (responseData is Map<String, dynamic>) {
          // Check if it's the envelope format: {status, data, meta}
          if (responseData.containsKey('data') &&
              responseData.containsKey('meta')) {
            final authResponse = AuthenticatedResponse.fromJson(responseData);
            // Store tokens
            await _storeTokens(authResponse.meta);
            return _mapAuthUserToUserModel(authResponse.user);
          }
          // Check if it's a direct user object (no envelope)
          else if (responseData.containsKey('id') &&
              responseData.containsKey('email')) {
            // Direct user response - create UserModel from it
            final user = UserModel.fromJson(responseData);
            // Try to get tokens from meta if available
            if (responseData.containsKey('meta')) {
              final meta = AuthMeta.fromJson(
                responseData['meta'] as Map<String, dynamic>? ?? {},
              );
              await _storeTokens(meta);
            }
            return user;
          }
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

      final response = await _dioClient.post(
        ApiEndpoints.authEmailVerify,
        data: request.toJson(),
      );

      if (response.statusCode == 200) {
        return true;
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
          // Check if it's the envelope format: {status, data, meta}
          if (responseData.containsKey('data') &&
              responseData.containsKey('meta')) {
            final authResponse = AuthenticatedResponse.fromJson(responseData);
            // Store tokens
            await _storeTokens(authResponse.meta);
            return _mapAuthUserToUserModel(authResponse.user);
          }
          // Check if it's a direct user object (no envelope)
          else if (responseData.containsKey('id') &&
              responseData.containsKey('email')) {
            // Direct user response - create UserModel from it
            final user = UserModel.fromJson(responseData);
            // Try to get tokens from meta if available
            if (responseData.containsKey('meta')) {
              final meta = AuthMeta.fromJson(
                responseData['meta'] as Map<String, dynamic>? ?? {},
              );
              await _storeTokens(meta);
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
      final accessToken = _hiveService.getString('access_token');
      if (accessToken == null || accessToken.isEmpty) {
        return null;
      }

      final request = TokenRefreshRequest(accessToken: accessToken);

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

        // Store new token
        await _hiveService.setString(
          'access_token',
          refreshResponse.accessToken,
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
