import 'package:dio/dio.dart';
import 'package:discovaa/core/constants/api_endpoints.dart';
import 'package:discovaa/core/constants/app_constants.dart';
import 'package:discovaa/core/network/interceptors.dart';
import 'package:discovaa/core/network/api_models.dart';
import 'package:discovaa/core/network/network_info.dart';
import 'package:discovaa/core/errors/exceptions.dart';
import 'package:discovaa/core/storage/secure_token_storage.dart';

class DioClient {
  late final Dio _dio;
  final NetworkInfo _networkInfo;
  final SecureTokenStorage _tokenStorage;

  DioClient({
    required NetworkInfo networkInfo,
    required SecureTokenStorage tokenStorage,
  }) : _networkInfo = networkInfo,
       _tokenStorage = tokenStorage {
    _dio = Dio(_createBaseOptions());
    _dio.interceptors.addAll(_createInterceptors());
  }

  Dio get dio => _dio;

  BaseOptions _createBaseOptions() {
    return BaseOptions(
      baseUrl: ApiEndpoints.baseUrl,
      connectTimeout: Duration(milliseconds: AppConstants.apiConnectTimeout),
      receiveTimeout: Duration(milliseconds: AppConstants.apiTimeout),
      sendTimeout: Duration(milliseconds: AppConstants.apiTimeout),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );
  }

  List<Interceptor> _createInterceptors() {
    return [
      AuthInterceptor(tokenStorage: _tokenStorage),
      LoggingInterceptor(),
      ErrorInterceptor(),
      RetryInterceptor(dio: _dio),
    ];
  }

  /// GET request
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    if (!await _networkInfo.isConnected) {
      throw const NetworkException(
        message: 'No internet connection',
        code: 'NO_INTERNET',
      );
    }

    try {
      return await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  /// POST request
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    if (!await _networkInfo.isConnected) {
      throw const NetworkException(
        message: 'No internet connection',
        code: 'NO_INTERNET',
      );
    }

    try {
      return await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  /// PUT request
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    if (!await _networkInfo.isConnected) {
      throw const NetworkException(
        message: 'No internet connection',
        code: 'NO_INTERNET',
      );
    }

    try {
      return await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  /// PATCH request
  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    if (!await _networkInfo.isConnected) {
      throw const NetworkException(
        message: 'No internet connection',
        code: 'NO_INTERNET',
      );
    }

    try {
      return await _dio.patch<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  /// DELETE request
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    if (!await _networkInfo.isConnected) {
      throw const NetworkException(
        message: 'No internet connection',
        code: 'NO_INTERNET',
      );
    }

    try {
      return await _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  /// Upload file
  Future<Response<T>> upload<T>(
    String path, {
    required String filePath,
    Map<String, dynamic>? data,
    ProgressCallback? onSendProgress,
    Options? options,
  }) async {
    if (!await _networkInfo.isConnected) {
      throw const NetworkException(
        message: 'No internet connection',
        code: 'NO_INTERNET',
      );
    }

    try {
      final formData = FormData.fromMap({
        ...?data,
        'file': await MultipartFile.fromFile(filePath),
      });

      return await _dio.post<T>(
        path,
        data: formData,
        onSendProgress: onSendProgress,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  /// Download file
  Future<Response> download(
    String urlPath,
    String savePath, {
    ProgressCallback? onReceiveProgress,
    Options? options,
  }) async {
    if (!await _networkInfo.isConnected) {
      throw const NetworkException(
        message: 'No internet connection',
        code: 'NO_INTERNET',
      );
    }

    try {
      return await _dio.download(
        urlPath,
        savePath,
        onReceiveProgress: onReceiveProgress,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  Exception _handleDioException(DioException e) {
    // If ErrorInterceptor already transformed the error into one of our custom exceptions
    if (e.error is Exception && e.error is! DioException) {
      return e.error as Exception;
    }

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const TimeoutException(
          message: 'Request timeout',
          code: 'TIMEOUT',
        );

      case DioExceptionType.badResponse:
        return _handleHttpError(e.response!);

      case DioExceptionType.cancel:
        return const NetworkException(
          message: 'Request cancelled',
          code: 'CANCELLED',
        );

      case DioExceptionType.connectionError:
        return const NetworkException(
          message: 'Connection error',
          code: 'CONNECTION_ERROR',
        );

      case DioExceptionType.badCertificate:
        return const NetworkException(
          message: 'Invalid SSL certificate',
          code: 'BAD_CERTIFICATE',
        );

      case DioExceptionType.unknown:
        if (e.error is Exception) return e.error as Exception;
        return UnknownException(
          message: e.message ?? 'Unknown error occurred',
          code: 'UNKNOWN',
          details: e.error,
        );
    }
  }

  Exception _handleHttpError(Response response) {
    final statusCode = response.statusCode;
    final data = response.data;

    String message = 'Request failed';
    String code = 'HTTP_ERROR';
    Map<String, dynamic>? details;

    if (data is Map<String, dynamic>) {
      final errorPayload = data['error'] is Map<String, dynamic>
          ? ApiErrorPayload.fromJson(data['error'] as Map<String, dynamic>)
          : null;
      message =
          errorPayload?.message ??
          data['message']?.toString() ??
          data['detail']?.toString() ??
          message;
      code = errorPayload?.code ?? data['code']?.toString() ?? code;
      details = data;
    }

    switch (statusCode) {
      case 400:
        return ValidationException(
          message: message,
          code: code,
          details: details,
        );

      case 401:
        return const AuthenticationException(
          message: 'Unauthorized',
          code: 'UNAUTHORIZED',
        );

      case 403:
        return const AuthorizationException(
          message: 'Forbidden',
          code: 'FORBIDDEN',
        );

      case 404:
        return NotFoundException(
          message: message,
          code: code,
          details: details,
        );

      case 409:
        return ConflictException(
          message: message,
          code: code,
          details: details,
        );

      case 429:
        return RateLimitException(
          message: message,
          code: code,
          retryAfter: _parseRetryAfter(response.headers),
          details: details,
        );

      case 500:
      case 502:
      case 503:
      case 504:
        return ServerException(message: message, code: code, details: details);
    }

    // This should never be reached, but added for safety
    return ServerException(message: message, code: code, details: details);
  }

  DateTime? _parseRetryAfter(Headers headers) {
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
