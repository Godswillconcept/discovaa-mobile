import 'dart:async';
import 'dart:math' as math;
import 'package:dio/dio.dart';
import 'package:discovaa/core/storage/secure_token_storage.dart';
import 'package:discovaa/core/constants/app_constants.dart';
import 'package:discovaa/core/constants/api_endpoints.dart';
import 'package:discovaa/core/errors/exceptions.dart';
import 'package:flutter/foundation.dart';

/// Logging interceptor for debugging API calls
class LoggingInterceptor extends Interceptor {
  String _endpointGroup(String path) {
    if (path.contains('/api/identity/')) return 'auth';
    if (path.contains('/api/message-threads/') ||
        path.contains('/api/messages/')) {
      return 'messaging';
    }
    if (path.contains('/api/payments/')) return 'payouts';
    if (path.contains('/api/providers/me/dashboard/') ||
        path.contains('/api/bookings/')) {
      return 'dashboard';
    }
    return 'api';
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (AppConstants.isDebugMode) {
      debugPrint('=== API Request ===');
      debugPrint('Group: ${_endpointGroup(options.path)}');
      debugPrint('Method: ${options.method}');
      debugPrint('URL: ${options.uri}');
      debugPrint('Headers: ${options.headers}');
      if (options.data != null) {
        debugPrint('Data: ${options.data}');
      }
      if (options.queryParameters.isNotEmpty) {
        debugPrint('Query Parameters: ${options.queryParameters}');
      }
      debugPrint('==================');
    }
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (AppConstants.isDebugMode) {
      debugPrint('=== API Response ===');
      debugPrint('Group: ${_endpointGroup(response.requestOptions.path)}');
      debugPrint('Method: ${response.requestOptions.method}');
      debugPrint('URL: ${response.requestOptions.uri}');
      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('Data: ${response.data}');
      debugPrint('===================');
    }
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (AppConstants.isDebugMode) {
      // Don't show scary error block for an expected 401 on logout
      final isExpectedLogout401 =
          err.response?.statusCode == 401 &&
          err.requestOptions.method == 'DELETE' &&
          err.requestOptions.path.contains('/auth/session');

      if (!isExpectedLogout401) {
        debugPrint('=== API Error ===');
        debugPrint('Group: ${_endpointGroup(err.requestOptions.path)}');
        debugPrint('Type: ${err.type}');
        debugPrint('Message: ${err.message}');
        debugPrint('Response: ${err.response}');
        debugPrint('================');
      }
    }
    super.onError(err, handler);
  }
}

/// Authentication interceptor for adding auth tokens
class AuthInterceptor extends Interceptor {
  final SecureTokenStorage _tokenStorage;
  static const String _retryAfterRefreshHeader = 'X-Retry-After-Refresh';

  // Static lock to prevent concurrent token refresh attempts
  static bool _isRefreshing = false;
  static Completer<_TokenRefreshResult>? _refreshCompleter;

  AuthInterceptor({required SecureTokenStorage tokenStorage})
    : _tokenStorage = tokenStorage;

  /// Check if the endpoint is an auth endpoint that doesn't require a token
  bool _isAuthEndpoint(String path) {
    // List of auth endpoints that don't require authentication (truly public endpoints)
    // Note: email/verify and resend require session_token, so they are NOT included here
    final authEndpoints = [
      '/api/identity/app/v1/auth/login',
      '/api/identity/app/v1/auth/signup',
      '/api/identity/app/v1/auth/password/request',
      '/api/identity/app/v1/auth/password/reset',
      '/api/identity/app/v1/tokens/refresh',
    ];
    return authEndpoints.any((endpoint) => path.contains(endpoint));
  }

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Skip auth header for authentication endpoints that don't require token
    if (_isAuthEndpoint(options.path)) {
      // Add device info only, no auth token
      options.headers['X-App-Version'] = AppConstants.appVersion;
      options.headers['X-Platform'] = AppConstants.platform;
      super.onRequest(options, handler);
      return;
    }

    // Respect opt-out: when 'X-Skip-Auth' is present, do not attach Authorization
    final skipAuthHeader = options.headers['X-Skip-Auth'];
    final skipAuth =
        skipAuthHeader == true ||
        skipAuthHeader == '1' ||
        skipAuthHeader == 'true';
    if (!skipAuth) {
      // Add auth token if available (OpenAPI uses access_token)
      var token = await _tokenStorage.getAccessToken();
      var tokenType = 'access_token';
      // Fallback to session_token if access_token is not available
      if (token == null || token.isEmpty) {
        token = await _tokenStorage.getSessionToken();
        tokenType = 'session_token';
      }
      debugPrint(
        '[AuthInterceptor] Token ($tokenType) for ${options.path}: ${token != null ? 'present' : 'MISSING'}',
      );
      if (token != null && token.isNotEmpty) {
        final authHeader = 'Bearer $token';
        options.headers['Authorization'] = authHeader;
        debugPrint(
          '[AuthInterceptor] Authorization: ${authHeader.substring(0, authHeader.length > 30 ? 30 : authHeader.length)}...',
        );
      } else {
        debugPrint(
          '[AuthInterceptor] No token found - request will be unauthenticated!',
        );
      }
    }

    // Add device info
    options.headers['X-App-Version'] = AppConstants.appVersion;
    options.headers['X-Platform'] = AppConstants.platform;

    super.onRequest(options, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Handle token refresh on 401 - but not for auth endpoints
    if (err.response?.statusCode == 401) {
      final originalRequest = err.requestOptions;

      // Skip token refresh for auth endpoints - they don't require authentication
      if (_isAuthEndpoint(originalRequest.path)) {
        super.onError(err, handler);
        return;
      }

      final isRefreshRequest =
          originalRequest.path == ApiEndpoints.tokensRefresh;
      final alreadyRetried =
          originalRequest.headers[_retryAfterRefreshHeader] == true;

      if (isRefreshRequest || alreadyRetried) {
        debugPrint(
          '[AuthInterceptor] 401 on refresh/already retried request. Clearing auth state.',
        );
        await _clearAuthState(reason: 'refresh_retry_limit');
        super.onError(err, handler);
        return;
      }

      // optimization: if we are trying to logout (DELETE session) and it fails with 401,
      // it means the session is already gone. Just clear local state and don't refresh.
      if (originalRequest.method == 'DELETE' &&
          originalRequest.path == ApiEndpoints.authLogout) {
        debugPrint(
          '[AuthInterceptor] Server session already expired (401). Completing local logout...',
        );
        await _clearAuthState(reason: 'logout_session_gone');
        super.onError(err, handler);
        return;
      }

      debugPrint('[AuthInterceptor] Got 401, attempting token refresh...');
      final refreshResult = await _refreshToken();
      if (refreshResult.status == _TokenRefreshStatus.success &&
          refreshResult.accessToken != null &&
          refreshResult.accessToken!.isNotEmpty) {
        debugPrint(
          '[AuthInterceptor] Token refreshed successfully, retrying request...',
        );
        originalRequest.headers['Authorization'] =
            'Bearer ${refreshResult.accessToken}';
        originalRequest.headers[_retryAfterRefreshHeader] = true;

        try {
          final response = await _retryRequest(originalRequest);
          handler.resolve(response);
          return;
        } catch (retryError) {
          // Retry failed with new token - this is not a refresh failure
          // The token was valid, but the request itself failed (e.g., validation error)
          debugPrint(
            '[AuthInterceptor] Request retry failed after successful token refresh: $retryError',
          );
          // Let the error propagate to the caller with proper error handling
          super.onError(err, handler);
          return;
        }
      }

      if (refreshResult.status == _TokenRefreshStatus.unauthorized) {
        // Only clear auth state if refresh token was present but rejected by server
        // This indicates the refresh token itself is invalid/expired
        await _clearAuthState(reason: 'refresh_token_rejected');
      } else if (refreshResult.status == _TokenRefreshStatus.failed) {
        // For other failures (network, server error, etc.), preserve auth state
        // to allow retry when connectivity is restored
        debugPrint(
          '[AuthInterceptor] Token refresh failed but preserving auth state for retry.',
        );
      } else if (refreshResult.status ==
          _TokenRefreshStatus.missingRefreshToken) {
        // Refresh token was never stored - this is a login flow bug, not a refresh failure
        // Don't clear auth state as it would be destructive
        debugPrint(
          '[AuthInterceptor] Refresh token missing from storage. '
          'This indicates the refresh token was not saved during login. '
          'Auth state preserved to avoid destructive clearing.',
        );
      }
    }

    super.onError(err, handler);
  }

  Future<Response<dynamic>> _retryRequest(
    RequestOptions originalRequest,
  ) async {
    final retryDio = Dio(
      BaseOptions(
        baseUrl: originalRequest.baseUrl,
        connectTimeout: originalRequest.connectTimeout,
        receiveTimeout: originalRequest.receiveTimeout,
        sendTimeout: originalRequest.sendTimeout,
        headers: Map<String, dynamic>.from(originalRequest.headers),
        responseType: originalRequest.responseType,
        contentType: originalRequest.contentType,
        validateStatus: originalRequest.validateStatus,
        receiveDataWhenStatusError: originalRequest.receiveDataWhenStatusError,
        followRedirects: originalRequest.followRedirects,
      ),
    );
    retryDio.interceptors.add(LoggingInterceptor());
    retryDio.interceptors.add(ErrorInterceptor());
    retryDio.interceptors.add(RetryInterceptor(dio: retryDio));
    return retryDio.fetch<dynamic>(originalRequest);
  }

  Future<_TokenRefreshResult> _refreshToken() async {
    // Implement locking mechanism to prevent concurrent refresh attempts
    if (_isRefreshing && _refreshCompleter != null) {
      debugPrint(
        '[AuthInterceptor] Token refresh already in progress, waiting for result...',
      );
      return _refreshCompleter!.future;
    }

    _isRefreshing = true;
    _refreshCompleter = Completer<_TokenRefreshResult>();

    try {
      final refreshToken = await _tokenStorage.getRefreshToken();
      final hasRefreshToken = refreshToken != null && refreshToken.isNotEmpty;
      debugPrint(
        '[AuthInterceptor][auth] Refresh token present for refresh: $hasRefreshToken',
      );
      if (!hasRefreshToken) {
        debugPrint(
          '[AuthInterceptor] AUTH DIAGNOSTIC: Refresh token missing from storage. '
          'Cannot attempt token refresh. Original 401 will be surfaced to caller.',
        );
        final result = const _TokenRefreshResult(
          status: _TokenRefreshStatus.missingRefreshToken,
        );
        _refreshCompleter!.complete(result);
        return result;
      }

      debugPrint(
        '[AuthInterceptor][auth] Attempting token refresh with payload key refresh_token',
      );

      // Create a dedicated Dio instance with proper configuration
      final dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'X-App-Version': AppConstants.appVersion,
            'X-Platform': AppConstants.platform,
          },
        ),
      );

      final response = await dio.post(
        '${ApiEndpoints.baseUrl}${ApiEndpoints.tokensRefresh}',
        data: {'refresh_token': refreshToken},
      );

      debugPrint(
        '[AuthInterceptor] Token refresh response status: ${response.statusCode}',
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = response.data as Map<String, dynamic>?;
        if (responseData == null) {
          debugPrint(
            '[AuthInterceptor] Token refresh failed: response data is null',
          );
          final result = const _TokenRefreshResult(
            status: _TokenRefreshStatus.failed,
          );
          _refreshCompleter!.complete(result);
          return result;
        }

        debugPrint(
          '[AuthInterceptor] Token refresh response data: $responseData',
        );

        // Extract tokens by checking multiple possible locations in the response
        // 1. Check data field (standard for this project's envelope)
        final data = responseData['data'] as Map<String, dynamic>?;
        // 2. Check meta field (tokens are often stored here)
        final meta = responseData['meta'] as Map<String, dynamic>?;

        String? newToken =
            data?['access_token']?.toString() ??
            meta?['access_token']?.toString() ??
            responseData['access_token']?.toString();

        String? newRefreshToken =
            data?['refresh_token']?.toString() ??
            meta?['refresh_token']?.toString() ??
            responseData['refresh_token']?.toString();

        // Check if authentication failed according to meta even though status is 200
        final isAuth = meta?['is_authenticated'] == true;
        if (meta != null && !isAuth && newToken == null) {
          debugPrint(
            '[AuthInterceptor] Token refresh failed: meta.is_authenticated is false',
          );
          final result = const _TokenRefreshResult(
            status: _TokenRefreshStatus.failed,
          );
          _refreshCompleter!.complete(result);
          return result;
        }

        if (newToken != null && newToken.isNotEmpty) {
          await _tokenStorage.saveTokens(
            accessToken: newToken,
            refreshToken: newRefreshToken ?? refreshToken,
          );
          debugPrint(
            '[AuthInterceptor] Token refreshed successfully: ${newToken.substring(0, newToken.length > 20 ? 20 : newToken.length)}...',
          );
          final result = _TokenRefreshResult(
            status: _TokenRefreshStatus.success,
            accessToken: newToken,
          );
          _refreshCompleter!.complete(result);
          return result;
        } else {
          debugPrint(
            '[AuthInterceptor] Token refresh failed: no access_token found anywhere in response',
          );
          final result = const _TokenRefreshResult(
            status: _TokenRefreshStatus.failed,
          );
          _refreshCompleter!.complete(result);
          return result;
        }
      } else {
        debugPrint(
          '[AuthInterceptor] Token refresh failed with status: ${response.statusCode}',
        );
        final result = const _TokenRefreshResult(
          status: _TokenRefreshStatus.failed,
        );
        _refreshCompleter!.complete(result);
        return result;
      }
    } on DioException catch (e) {
      debugPrint('[AuthInterceptor] Token refresh DioException: ${e.type}');
      debugPrint(
        '[AuthInterceptor] Response status: ${e.response?.statusCode}',
      );
      debugPrint('[AuthInterceptor] Response data: ${e.response?.data}');
      debugPrint('[AuthInterceptor] Error message: ${e.message}');
      final statusCode = e.response?.statusCode;
      // Any 4xx error from the token refresh endpoint means the refresh token
      // is invalid, expired, or malformed. All require re-authentication.
      if (statusCode != null && statusCode >= 400 && statusCode < 500) {
        debugPrint(
          '[AuthInterceptor] Token refresh returned $statusCode, treating as unauthorized',
        );
        final result = const _TokenRefreshResult(
          status: _TokenRefreshStatus.unauthorized,
        );
        _refreshCompleter!.complete(result);
        return result;
      }
      if (statusCode != null && statusCode >= 500) {
        final result = const _TokenRefreshResult(
          status: _TokenRefreshStatus.transientFailure,
        );
        _refreshCompleter!.complete(result);
        return result;
      }
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        final result = const _TokenRefreshResult(
          status: _TokenRefreshStatus.transientFailure,
        );
        _refreshCompleter!.complete(result);
        return result;
      }
      final result = const _TokenRefreshResult(
        status: _TokenRefreshStatus.failed,
      );
      _refreshCompleter!.complete(result);
      return result;
    } catch (e) {
      debugPrint('[AuthInterceptor] Token refresh unexpected error: $e');
      final result = const _TokenRefreshResult(
        status: _TokenRefreshStatus.failed,
      );
      _refreshCompleter!.complete(result);
      return result;
    } finally {
      // Reset the lock after completion
      _isRefreshing = false;
      _refreshCompleter = null;
    }
  }

  /// Clear all authentication state
  ///
  /// [reason] is logged for observability. Common reasons:
  /// - 'logout_session_gone': logout endpoint returned 401 (session already expired)
  /// - 'refresh_token_rejected': refresh token was rejected by server (401 on refresh)
  /// - 'refresh_retry_limit': already retried after refresh, still getting 401
  Future<void> _clearAuthState({String reason = 'unknown'}) async {
    await _tokenStorage.clearAllAuthData();
    debugPrint('[AuthInterceptor] Auth state cleared. Reason: $reason');
    // Auth state change will be detected by AuthInitializer on next app check
  }
}

enum _TokenRefreshStatus {
  success,
  missingRefreshToken,
  unauthorized,
  transientFailure,
  failed,
}

class _TokenRefreshResult {
  final _TokenRefreshStatus status;
  final String? accessToken;

  const _TokenRefreshResult({required this.status, this.accessToken});
}

/// Error interceptor for handling common errors
class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Handle specific error cases
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        err = err.copyWith(
          error: const TimeoutException(
            message: 'Request timeout. Please check your internet connection.',
            code: 'TIMEOUT',
          ),
        );
        break;

      case DioExceptionType.connectionError:
        err = err.copyWith(
          error: const NetworkException(
            message: 'No internet connection. Please check your network.',
            code: 'NO_INTERNET',
          ),
        );
        break;

      case DioExceptionType.badResponse:
        // Handle specific HTTP status codes
        final statusCode = err.response?.statusCode;
        if (statusCode != null) {
          err = _handleHttpError(err, statusCode);
        }
        break;

      default:
        break;
    }

    super.onError(err, handler);
  }

  DioException _handleHttpError(DioException err, int statusCode) {
    final data = err.response?.data;
    String message = 'An error occurred';
    String code = 'HTTP_ERROR';

    if (data is Map<String, dynamic>) {
      message = data['message'] ?? message;
      code = data['code'] ?? code;
    }

    Exception exception;
    switch (statusCode) {
      case 400:
        exception = ValidationException(
          message: message,
          code: code,
          fieldErrors: data?['field_errors'],
        );
        break;

      case 401:
        exception = const AuthenticationException(
          message: 'You are not authenticated. Please login.',
          code: 'UNAUTHORIZED',
        );
        break;

      case 403:
        exception = const AuthorizationException(
          message: 'You do not have permission to perform this action.',
          code: 'FORBIDDEN',
        );
        break;

      case 404:
        exception = NotFoundException(message: message, code: code);
        break;

      case 409:
        exception = ConflictException(message: message, code: code);
        break;

      case 429:
        exception = RateLimitException(
          message: message,
          code: code,
          retryAfter: _parseRetryAfter(err.response?.headers),
        );
        break;

      case 500:
      case 502:
      case 503:
      case 504:
        exception = ServerException(
          message: 'Server error. Please try again later.',
          code: 'SERVER_ERROR',
        );
        break;

      default:
        exception = ServerException(message: message, code: code);
    }

    return err.copyWith(error: exception);
  }

  DateTime? _parseRetryAfter(Headers? headers) {
    if (headers == null) return null;

    final retryAfter = headers.value('retry-after');
    if (retryAfter != null && retryAfter.isNotEmpty) {
      final seconds = int.tryParse(retryAfter);
      if (seconds != null) {
        return DateTime.now().add(Duration(seconds: seconds));
      }
    }
    return null;
  }
}

/// Retry interceptor for automatic retries on failures
class RetryInterceptor extends Interceptor {
  final Dio dio;
  final int maxRetries;
  final int baseDelayMs;
  final int maxDelayMs;
  final bool respectRetryAfter;

  RetryInterceptor({
    required this.dio,
    this.maxRetries = 3,
    this.baseDelayMs = 800,
    this.maxDelayMs = 4000,
    this.respectRetryAfter = true,
  });

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final extra = err.requestOptions.extra;
    final retries = (extra['retries'] ?? 0) as int;
    final noRetry = (extra['no-retry'] ?? false) as bool;

    if (!noRetry && retries < maxRetries && _shouldRetry(err)) {
      final attempt = retries + 1;
      extra['retries'] = attempt;

      final delay = _computeBackoff(err, attempt);
      await Future.delayed(delay);

      try {
        final response = await dio.fetch(err.requestOptions);
        handler.resolve(response);
        return;
      } catch (e) {
        // Retry failed, continue with error
      }
    }

    super.onError(err, handler);
  }

  bool _shouldRetry(DioException err) {
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return true;

      case DioExceptionType.badResponse:
        final statusCode = err.response?.statusCode;
        return statusCode != null && (statusCode >= 500 || statusCode == 429);

      default:
        return false;
    }
  }

  Duration _computeBackoff(DioException err, int attempt) {
    if (respectRetryAfter) {
      final retryAfter = err.response?.headers.value('retry-after');
      if (retryAfter != null && retryAfter.isNotEmpty) {
        final seconds = int.tryParse(retryAfter.trim());
        if (seconds != null && seconds > 0) {
          return Duration(seconds: seconds);
        }
      }
    }

    final exp = 1 << (attempt - 1);
    final base = (baseDelayMs * exp).clamp(baseDelayMs, maxDelayMs).toInt();
    final jitterBound = (base * 0.2).toInt().clamp(50, 800);
    final jitter = jitterBound > 0 ? math.Random().nextInt(jitterBound) : 0;
    final delayMs = (base + jitter).clamp(baseDelayMs, maxDelayMs);
    return Duration(milliseconds: delayMs);
  }
}


