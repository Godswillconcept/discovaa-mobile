import 'dart:math' as math;
import 'package:dio/dio.dart';
import 'package:discovaa/core/storage/hive_service.dart';
import 'package:discovaa/core/constants/app_constants.dart';
import 'package:discovaa/core/constants/api_endpoints.dart';
import 'package:discovaa/core/errors/exceptions.dart';
import 'package:flutter/foundation.dart';

/// Logging interceptor for debugging API calls
class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (AppConstants.isDebugMode) {
      debugPrint('=== API Request ===');
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
      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('Data: ${response.data}');
      debugPrint('Headers: ${response.headers}');
      debugPrint('===================');
    }
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (AppConstants.isDebugMode) {
      debugPrint('=== API Error ===');
      debugPrint('Type: ${err.type}');
      debugPrint('Message: ${err.message}');
      debugPrint('Response: ${err.response}');
      debugPrint('================');
    }
    super.onError(err, handler);
  }
}

/// Authentication interceptor for adding auth tokens
class AuthInterceptor extends Interceptor {
  final HiveService _hiveService;

  AuthInterceptor({required HiveService hiveService})
    : _hiveService = hiveService;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Respect opt-out: when 'X-Skip-Auth' is present, do not attach Authorization
    final skipAuthHeader = options.headers['X-Skip-Auth'];
    final skipAuth =
        skipAuthHeader == true ||
        skipAuthHeader == '1' ||
        skipAuthHeader == 'true';
    if (!skipAuth) {
      // Add auth token if available (OpenAPI uses access_token)
      var token = _hiveService.getString('access_token');
      var tokenType = 'access_token';
      // Fallback to session_token if access_token is not available
      if (token == null || token.isEmpty) {
        token = _hiveService.getString('session_token');
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
    // Handle token refresh on 401
    if (err.response?.statusCode == 401) {
      final originalRequest = err.requestOptions;
      final isRefreshRequest =
          originalRequest.path == ApiEndpoints.tokensRefresh;
      final alreadyRetried =
          originalRequest.headers['X-Retry-After-Refresh'] == true;

      if (isRefreshRequest || alreadyRetried) {
        debugPrint(
          '[AuthInterceptor] 401 on refresh/already retried request. Clearing auth state.',
        );
        await _clearAuthState();
        super.onError(err, handler);
        return;
      }

      debugPrint('[AuthInterceptor] Got 401, attempting token refresh...');
      try {
        // Attempt to refresh token using OpenAPI endpoint
        final newToken = await _refreshToken();
        if (newToken != null && newToken.isNotEmpty) {
          debugPrint(
            '[AuthInterceptor] Token refreshed successfully, retrying request...',
          );
          // Retry the original request with new token
          originalRequest.headers['Authorization'] = 'Bearer $newToken';
          originalRequest.headers['X-Retry-After-Refresh'] = true;

          final response = await Dio().fetch(originalRequest);
          handler.resolve(response);
          return;
        } else {
          debugPrint('[AuthInterceptor] Token refresh returned null');
          await _clearAuthState();
        }
      } catch (e) {
        debugPrint('[AuthInterceptor] Token refresh failed: $e');
        // Token refresh failed, clear tokens and auth state
        await _clearAuthState();
      }
    }

    super.onError(err, handler);
  }

  Future<String?> _refreshToken() async {
    try {
      final accessToken = _hiveService.getString('access_token');
      if (accessToken == null || accessToken.isEmpty) {
        return null;
      }

      final response = await Dio().post(
        '${ApiEndpoints.baseUrl}${ApiEndpoints.tokensRefresh}',
        data: {'token': accessToken},
      );

      if (response.statusCode == 200) {
        // Handle wrapped API response format: {success, data, meta, error}
        final responseData = response.data as Map<String, dynamic>?;
        final success = responseData?['success'] == true;

        if (!success) {
          return null;
        }

        final data = responseData?['data'] as Map<String, dynamic>?;
        final newToken = data?['access_token'] as String?;

        if (newToken != null && newToken.isNotEmpty) {
          await _hiveService.setString('access_token', newToken);
          return newToken;
        }
      }
    } catch (e) {
      // Handle refresh token error - let caller deal with it
    }
    return null;
  }

  /// Clear all authentication state when token refresh fails
  Future<void> _clearAuthState() async {
    await _hiveService.remove('access_token');
    await _hiveService.remove('session_token');
    await _hiveService.remove('user_data');
    // Auth state change will be detected by AuthInitializer on next app check
  }
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
      final seconds = int.tryParse(retryAfter[0]);
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

    if (retries < maxRetries && _shouldRetry(err)) {
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
