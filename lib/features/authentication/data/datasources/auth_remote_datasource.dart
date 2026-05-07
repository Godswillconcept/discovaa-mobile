import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:discovaa/core/constants/api_endpoints.dart';
import 'package:discovaa/core/errors/exceptions.dart';
import 'package:discovaa/core/network/dio_client.dart';
import 'package:discovaa/core/storage/secure_token_storage.dart';
import '../models/auth_models.dart';
import '../models/user_model.dart';
import '../models/registration_model.dart';
import '../../presentation/providers/registration_flow_provider.dart';

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

  /// Update user profile
  Future<UserModel> updateProfile({
    required String firstName,
    required String lastName,
    required String displayName,
    required String phone,
    required String address,
    required String? countryIso2,
    String? postalCode,
    String? businessName,
    String? businessDescription,
  });

  /// Fetch full user profile from accounts/me endpoint
  /// This returns the complete profile with is_profile_complete field
  Future<UserModel?> fetchFullProfile();

  /// Get auth configuration
  Future<Map<String, dynamic>?> fetchConfig();

  /// Upload ID document front
  Future<UserModel> uploadIdDocumentFront({
    required String idNumber,
    required File documentFront,
  });

  /// Upload ID document back
  Future<UserModel> uploadIdDocumentBack({
    required String idNumber,
    required File documentBack,
  });
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
  /// Note: This is a minimal mapping for the auth endpoint response.
  /// The full profile is fetched separately via fetchFullProfile() which contains
  /// the correct role field from accounts/me endpoint.
  UserModel _mapAuthUserToUserModel(AuthUser user) {
    return UserModel(
      id: user.id,
      email: user.email,
      displayName: user.display,
      phone: null,
      address: null,
      country: null,
      photoUrl: null,
      role: 'USER', // Default to USER, will be overridden by full profile fetch
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
      // Map role string to UserRole enum
      UserRole userRole;
      switch (registration.role.toLowerCase()) {
        case 'user':
          userRole = UserRole.user;
          break;
        case 'individual':
        case 'individual_provider':
          userRole = UserRole.individualProvider;
          break;
        case 'business':
        case 'business_provider':
          userRole = UserRole.businessProvider;
          break;
        default:
          userRole = UserRole.user;
      }

      final request = SignupRequest.fromUserRole(
        userRole,
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
    } on NetworkException catch (_) {
      rethrow;
    } on ServerException catch (_) {
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
      // Validate inputs
      if (email.isEmpty) {
        throw ServerException(
          message: 'Email is required for verification',
          code: 'MISSING_EMAIL',
        );
      }
      if (code.isEmpty) {
        throw ServerException(
          message: 'Verification code is required',
          code: 'MISSING_CODE',
        );
      }

      final sessionToken = await _tokenStorage.getSessionToken();
      final request = EmailVerifyRequest(key: code);

      debugPrint('[verifyEmail] Verifying email: $email with code: $code');
      debugPrint('[verifyEmail] Using Session Token: $sessionToken');

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
            ...sessionToken != null ? {'X-Session-Token': sessionToken} : {},
          },
          validateStatus: (status) =>
              status == 200 || status == 401 || status == 409,
        ),
      );

      final response = await dio.post(
        ApiEndpoints.authEmailVerify,
        data: request.toJson(),
      );

      debugPrint('VerifyEmail response status: ${response.statusCode}');
      debugPrint('VerifyEmail response data: ${response.data}');

      // 200 = verified and authenticated — extract and store tokens
      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData is Map<String, dynamic>) {
          if (responseData.containsKey('meta')) {
            final metaJson = Map<String, dynamic>.from(
              responseData['meta'] as Map,
            );
            final dataJson = responseData.containsKey('data')
                ? Map<String, dynamic>.from(responseData['data'] as Map)
                : <String, dynamic>{};
            final meta = AuthMeta.fromJsonWithFallback(metaJson, dataJson);
            await _storeTokens(meta, dataJson);
            debugPrint(
              '[verifyEmail] Tokens stored after successful verification.',
            );
          }
        }
        return true;
      }

      // 401 = email verified but auto-login is disabled server-side (ACCOUNT_LOGIN_ON_EMAIL_CONFIRMATION=False)
      // Per OpenAPI spec: "a 401 is returned when verifying as part of login/signup" — still a success
      if (response.statusCode == 401) {
        debugPrint(
          '[verifyEmail] 401: Email verified, auto-login not enabled.',
        );
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
    } on NetworkException catch (_) {
      rethrow;
    } on ServerException catch (_) {
      rethrow;
    } on ConflictException catch (_) {
      rethrow;
    } catch (e, stackTrace) {
      debugPrint('[verifyEmail] Unexpected error: $e');
      debugPrint('[verifyEmail] Stack trace: $stackTrace');
      throw UnknownException(
        message: 'Unexpected error during email verification: $e',
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
        options: Options(
          validateStatus: (status) => status == 200 || status == 401,
        ),
      );

      // Debug: print the actual response for debugging
      debugPrint('Login response status: ${response.statusCode}');
      debugPrint('Login response data: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 401) {
        final responseData = response.data;

        if (responseData is Map<String, dynamic>) {
          final normalizedData = Map<String, dynamic>.from(responseData);

          // Both 200 and 401 may contain meta with session_token
          if (normalizedData.containsKey('meta')) {
            final metaJson = Map<String, dynamic>.from(normalizedData['meta']);
            final meta = AuthMeta.fromJsonWithFallback(
              metaJson,
              normalizedData,
            );

            // Extract tokens and data for storage
            final dataJson = normalizedData.containsKey('data')
                ? Map<String, dynamic>.from(normalizedData['data'])
                : normalizedData;

            await _storeTokens(meta, dataJson);
          }

          // Case 1: Success (200)
          if (response.statusCode == 200) {
            if (normalizedData.containsKey('data')) {
              final authResponse = AuthenticatedResponse.fromJson(
                normalizedData,
              );
              return _mapAuthUserToUserModel(authResponse.user);
            } else if (normalizedData.containsKey('id')) {
              return UserModel.fromJson(normalizedData);
            }
          }

          // Case 2: Verification Pending (401)
          if (response.statusCode == 401) {
            final authResponse = AuthenticationResponse.fromJson(
              normalizedData,
            );

            if (authResponse.isFlowPending('verify_email')) {
              debugPrint(
                '[AuthRemoteDataSource] Login successful, pending email verification',
              );
              // Create minimal user model for email verification flow
              // Use email from the credentials we just sent
              final userModel = UserModel(
                id: '',
                email: email,
                displayName: '',
                role: 'user',
                isProfileComplete: false,
                isIdentityVerified: false,
              );
              return userModel;
            }
          }
        }
      }

      throw _handleError(response.data, 'Login failed');
    } on NetworkException catch (_) {
      rethrow;
    } on AuthenticationException catch (_) {
      rethrow;
    } on ServerException catch (_) {
      rethrow;
    } catch (e) {
      if (e is AuthenticationException) rethrow;
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
      // Call logout API with a short timeout.
      // We don't want to wait 30s for a logout to fail if the server is down.
      try {
        await _dioClient.delete(
          ApiEndpoints.authLogout,
          options: Options(
            sendTimeout: const Duration(seconds: 5),
            receiveTimeout: const Duration(seconds: 5),
            // We can add a custom header to hint the RetryInterceptor to skip retries
            extra: {'no-retry': true},
          ),
        );
      } catch (e) {
        // Ignore API errors during logout - we still want to clear local data
        debugPrint(
          '[AuthRemoteDataSource] Logout API call failed or timed out: $e',
        );
        debugPrint(
          '[AuthRemoteDataSource] Proceeding with local data clearance...',
        );
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
    } on NetworkException catch (_) {
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
        options: Options(
          validateStatus: (status) => status == 200 || status == 401,
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 401) {
        final responseData = response.data;
        if (responseData is Map<String, dynamic>) {
          final normalizedData = Map<String, dynamic>.from(responseData);

          // Store any tokens provided in meta (like session_token for the flow)
          if (normalizedData.containsKey('meta')) {
            final metaJson = Map<String, dynamic>.from(
              normalizedData['meta'] as Map,
            );
            final dataJson = normalizedData.containsKey('data')
                ? Map<String, dynamic>.from(normalizedData['data'] as Map)
                : <String, dynamic>{};
            final meta = AuthMeta.fromJsonWithFallback(metaJson, dataJson);
            await _storeTokens(meta, dataJson);
            debugPrint(
              '[sendPasswordResetEmail] Tokens stored for password reset flow.',
            );
          }

          // Case 1: Success (200)
          if (response.statusCode == 200) {
            return;
          }

          // Case 2: Flow Pending (401)
          if (response.statusCode == 401) {
            final authResponse = AuthenticationResponse.fromJson(
              normalizedData,
            );
            if (authResponse.isFlowPending('password_reset_by_code') ||
                authResponse.isFlowPending('password_reset_by_email')) {
              debugPrint(
                '[sendPasswordResetEmail] Password reset flow initiated successfully.',
              );
              return;
            }
          }
        }
      }

      throw _handleError(response.data, 'Failed to send reset email');
    } on NetworkException catch (_) {
      rethrow;
    } on ServerException catch (_) {
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
      debugPrint('[resetPassword] Starting password reset with key: $key');
      debugPrint('[resetPassword] New password length: ${newPassword.length}');

      final request = PasswordResetRequest(key: key, password: newPassword);
      debugPrint('[resetPassword] Request payload: ${request.toJson()}');

      // Retrieve session token stored during password reset flow
      final sessionToken = await _tokenStorage.getSessionToken();
      debugPrint(
        '[resetPassword] Session token: ${sessionToken != null ? "present" : "MISSING"}',
      );

      // Use direct Dio call to allow 409 status code (invalid/expired key)
      final dio = Dio(
        BaseOptions(
          baseUrl: ApiEndpoints.baseUrl,
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
          sendTimeout: const Duration(seconds: 30),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'X-Session-Token': ?sessionToken,
          },
          validateStatus: (status) => status == 200 || status == 409,
        ),
      );

      debugPrint(
        '[resetPassword] Making POST request to: ${ApiEndpoints.authPasswordReset}',
      );

      final response = await dio.post(
        ApiEndpoints.authPasswordReset,
        data: request.toJson(),
      );

      debugPrint('[resetPassword] Response status: ${response.statusCode}');
      debugPrint('[resetPassword] Response data: ${response.data}');

      // 200 = success
      if (response.statusCode == 200) {
        debugPrint('[resetPassword] Password reset successful');
        return;
      }

      // 409 = invalid/expired reset key
      if (response.statusCode == 409) {
        final responseData = response.data;
        String message =
            'Password reset link is invalid or has expired. Please request a new one.';
        if (responseData is Map<String, dynamic>) {
          message =
              responseData['message']?.toString() ??
              responseData['detail']?.toString() ??
              responseData['error']?.toString() ??
              message;
        }
        debugPrint('[resetPassword] 409 Conflict: $message');
        throw ConflictException(message: message, code: 'RESET_KEY_INVALID');
      }

      throw _handleError(response.data, 'Failed to reset password');
    } on NetworkException catch (_) {
      rethrow;
    } catch (e, stackTrace) {
      // Handle specific exceptions
      if (e is ConflictException) {
        rethrow;
      }
      if (e is ServerException) {
        rethrow;
      }
      debugPrint('[resetPassword] Unexpected error: $e');
      debugPrint('[resetPassword] Stack trace: $stackTrace');
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
      final sessionToken = await _tokenStorage.getSessionToken();

      final response = await _dioClient.post(
        ApiEndpoints.authEmailVerifyResend,
        options: Options(
          headers: {
            ...sessionToken != null ? {'X-Session-Token': sessionToken} : {},
          },
        ),
      );

      if (response.statusCode != 200) {
        throw _handleError(
          response.data,
          'Failed to resend verification email',
        );
      }
    } on NetworkException catch (_) {
      rethrow;
    } on ServerException catch (_) {
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
    } on NetworkException catch (_) {
      rethrow;
    } catch (e) {
      throw UnknownException(
        message: 'Unexpected error refreshing token',
        code: 'UNKNOWN_TOKEN_REFRESH_ERROR',
        details: e,
      );
    }
  }

  @override
  Future<UserModel> updateProfile({
    required String firstName,
    required String lastName,
    required String displayName,
    required String phone,
    required String address,
    required String? countryIso2,
    String? postalCode,
    String? businessName,
    String? businessDescription,
  }) async {
    try {
      final formData = FormData.fromMap({
        'first_name': firstName,
        'last_name': lastName,
        'display_name': displayName,
        'phone': phone,
        'address': address,
        ...countryIso2 != null ? {'country_iso2': countryIso2} : {},
        ...postalCode != null ? {'postal_code': postalCode} : {},
        ...businessName != null ? {'business_name': businessName} : {},
        ...businessDescription != null
            ? {'business_description': businessDescription}
            : {},
      });

      final response = await _dioClient.patch(
        ApiEndpoints.accountsMe,
        data: formData,
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData is Map<String, dynamic>) {
          if ((businessName?.trim().isNotEmpty ?? false) ||
              (businessDescription?.trim().isNotEmpty ?? false)) {
            await _updateProviderProfile(
              displayName: businessName?.trim().isNotEmpty == true
                  ? businessName!.trim()
                  : displayName,
              bio: businessDescription?.trim().isNotEmpty == true
                  ? businessDescription!.trim()
                  : null,
              phone: phone,
              countryIso2: countryIso2,
            );
          }

          // Check if response has the expected envelope format
          if (responseData.containsKey('data')) {
            final data = responseData['data'] as Map<String, dynamic>;
            return _mapAccountsMeToUserModel(data);
          }
          // Direct user object response
          else if (responseData.containsKey('id')) {
            return _mapAccountsMeToUserModel(responseData);
          }
        }
        throw ServerException(
          message: 'Invalid response format from server',
          code: 'INVALID_RESPONSE_FORMAT',
        );
      }

      throw _handleError(response.data, 'Failed to update profile');
    } on NetworkException catch (_) {
      rethrow;
    } on ServerException catch (_) {
      rethrow;
    } catch (e) {
      throw UnknownException(
        message: 'Unexpected error during profile update',
        code: 'UNKNOWN_PROFILE_UPDATE_ERROR',
        details: e,
      );
    }
  }

  Future<void> _updateProviderProfile({
    required String displayName,
    String? bio,
    required String phone,
    required String? countryIso2,
  }) async {
    await _dioClient.patch(
      ApiEndpoints.providersMeProfile,
      data: {
        'display_name': displayName,
        'bio': ?bio,
        'phone': phone,
        'country_iso2': ?countryIso2,
      },
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );
  }

  @override
  Future<UserModel?> fetchFullProfile() async {
    try {
      final response = await _dioClient.get(ApiEndpoints.accountsMe);

      debugPrint('FetchFullProfile response status: ${response.statusCode}');
      debugPrint('FetchFullProfile response data: ${response.data}');

      if (response.statusCode == 200) {
        final responseData = response.data;

        if (responseData is Map<String, dynamic>) {
          // Handle the accounts/me response format: {success, data, meta, error}
          if (responseData.containsKey('data')) {
            final data = responseData['data'] as Map<String, dynamic>;
            return _mapAccountsMeToUserModel(data);
          }
          // Direct user object response
          else if (responseData.containsKey('id')) {
            return _mapAccountsMeToUserModel(responseData);
          }
        }
      }

      return null;
    } on NetworkException catch (_) {
      return null;
    } on ServerException catch (_) {
      return null;
    } catch (e) {
      debugPrint('Error fetching full profile: $e');
      return null;
    }
  }

  /// Map accounts/me response to UserModel
  /// The accounts/me endpoint uses snake_case field names
  UserModel _mapAccountsMeToUserModel(Map<String, dynamic> data) {
    // Check if profile is complete based on required fields
    final displayName = data['display_name'] as String? ?? '';
    final phone = data['phone'] as String? ?? '';

    // Handle country field - it can be either a String or an object with iso2 field
    String? country;
    final countryData = data['country'];
    if (countryData is String) {
      country = countryData;
    } else if (countryData is Map<String, dynamic>) {
      country =
          countryData['iso2'] as String? ?? countryData['name'] as String?;
    }

    final verificationStatus = data['verification_status'] as String?;

    // Profile is considered complete if display_name and phone are filled
    final isProfileComplete = displayName.isNotEmpty && phone.isNotEmpty;

    // Map verification_status to isIdentityVerified
    // VERIFIED = identity verification complete
    // UNVERIFIED, PENDING, REJECTED = identity verification needed
    final isIdentityVerified = verificationStatus == 'VERIFIED';

    return UserModel(
      id: data['id'] as String,
      email: data['email'] as String,
      displayName: displayName,
      phone: phone,
      address: data['address'] as String?,
      country: country,
      postalCode: data['postal_code'] as String?,
      photoUrl: data['profile_photo'] as String?,
      role: _normalizeAccountRole(data),
      isEmailVerified: verificationStatus == 'VERIFIED',
      isIdentityVerified: isIdentityVerified,
      isProfileComplete: isProfileComplete,
      createdAt: null,
      updatedAt: null,
    );
  }

  String _normalizeAccountRole(Map<String, dynamic> data) {
    final rawRole = data['role']?.toString().trim().toUpperCase();
    final accountType = data['account_type']?.toString().trim().toLowerCase();
    final providerType = data['provider_type']?.toString().trim().toLowerCase();

    if (accountType == 'service_provider' || accountType == 'provider') {
      return providerType == 'business' ? 'BUSINESS' : 'INDIVIDUAL';
    }

    if (rawRole == 'INDIVIDUAL' || rawRole == 'BUSINESS' || rawRole == 'USER') {
      return rawRole!;
    }

    if (providerType == 'business') return 'BUSINESS';
    if (providerType == 'individual') return 'INDIVIDUAL';

    return 'USER';
  }

  @override
  Future<Map<String, dynamic>?> fetchConfig() async {
    try {
      final response = await _dioClient.get(ApiEndpoints.authConfig);

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData is Map<String, dynamic>) {
          // Handle the config response format: {status, data, meta}
          if (responseData.containsKey('data')) {
            return responseData['data'] as Map<String, dynamic>;
          }
          // Direct response
          return responseData;
        }
      }

      return null;
    } catch (e) {
      debugPrint('[AuthRemoteDataSource] Error fetching config: $e');
      return null;
    }
  }

  @override
  Future<UserModel> uploadIdDocumentFront({
    required String idNumber,
    required File documentFront,
  }) async {
    try {
      final formData = FormData.fromMap({
        'id_number': idNumber,
        'id_document_front': await MultipartFile.fromFile(documentFront.path),
      });

      final response = await _dioClient.patch(
        ApiEndpoints.accountsMe,
        data: formData,
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData is Map<String, dynamic>) {
          if (responseData.containsKey('data')) {
            final data = responseData['data'] as Map<String, dynamic>;
            return _mapAccountsMeToUserModel(data);
          } else if (responseData.containsKey('id')) {
            return _mapAccountsMeToUserModel(responseData);
          }
        }
      }

      throw ServerException(
        message: 'Failed to upload ID document front',
        code: 'ID_DOCUMENT_FRONT_UPLOAD_FAILED',
      );
    } on NetworkException catch (_) {
      rethrow;
    } on ServerException catch (_) {
      rethrow;
    } catch (e) {
      throw UnknownException(
        message: 'Unexpected error uploading ID document front',
        code: 'UNKNOWN_ID_FRONT_UPLOAD_ERROR',
        details: e,
      );
    }
  }

  @override
  Future<UserModel> uploadIdDocumentBack({
    required String idNumber,
    required File documentBack,
  }) async {
    try {
      final formData = FormData.fromMap({
        'id_number': idNumber,
        'id_document_back': await MultipartFile.fromFile(documentBack.path),
      });

      final response = await _dioClient.patch(
        ApiEndpoints.accountsMe,
        data: formData,
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData is Map<String, dynamic>) {
          if (responseData.containsKey('data')) {
            final data = responseData['data'] as Map<String, dynamic>;
            return _mapAccountsMeToUserModel(data);
          } else if (responseData.containsKey('id')) {
            return _mapAccountsMeToUserModel(responseData);
          }
        }
      }

      throw ServerException(
        message: 'Failed to upload ID document back',
        code: 'ID_DOCUMENT_BACK_UPLOAD_FAILED',
      );
    } on NetworkException catch (_) {
      rethrow;
    } on ServerException catch (_) {
      rethrow;
    } catch (e) {
      throw UnknownException(
        message: 'Unexpected error uploading ID document back',
        code: 'UNKNOWN_ID_BACK_UPLOAD_ERROR',
        details: e,
      );
    }
  }
}
