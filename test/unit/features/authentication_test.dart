import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:dio/dio.dart';
import 'package:discovaa/features/authentication/data/datasources/auth_remote_datasource.dart';
import 'package:discovaa/core/storage/secure_token_storage.dart';
import 'package:discovaa/core/network/dio_client.dart';

// Mock classes for testing
class MockDioClient extends Mock implements DioClient {
  @override
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return Future.value(
      Response<T>(
        data: {'detail': 'Not found'} as T,
        statusCode: 404,
        requestOptions: RequestOptions(path: path),
      ),
    );
  }

  @override
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    // Mock successful login response with tokens
    if (path.contains('/login')) {
      return Future.value(
        Response<T>(
          data:
              {
                    'status': 200,
                    'data': {
                      'id': 'test-user-id',
                      'email': 'test@example.com',
                      'displayName': 'Test User',
                      'username': 'testuser',
                      'hasUsablePassword': true,
                      'isProfileComplete': true,
                    },
                    'meta': {
                      'is_authenticated': true,
                      'access_token': 'test-access-token',
                      'session_token': 'test-session-token',
                      'refresh_token': 'test-refresh-token',
                    },
                  }
                  as T,
          statusCode: 200,
          requestOptions: RequestOptions(path: path),
        ),
      );
    }

    // Mock token refresh response
    if (path.contains('/tokens/refresh')) {
      return Future.value(
        Response<T>(
          data:
              {
                    'access_token': 'new-test-access-token',
                    'refresh_token': 'new-test-refresh-token',
                  }
                  as T,
          statusCode: 200,
          requestOptions: RequestOptions(path: path),
        ),
      );
    }

    // Mock 401 response for testing token refresh
    if (path.contains('/protected-endpoint')) {
      return Future.value(
        Response<T>(
          data: {'detail': 'Token expired'} as T,
          statusCode: 401,
          requestOptions: RequestOptions(path: path),
        ),
      );
    }

    return Future.value(
      Response<T>(
        data: {'detail': 'Not found'} as T,
        statusCode: 404,
        requestOptions: RequestOptions(path: path),
      ),
    );
  }

  @override
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return Future.value(
      Response<T>(statusCode: 204, requestOptions: RequestOptions(path: path)),
    );
  }

  @override
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return Future.value(
      Response<T>(
        data: {'detail': 'Not found'} as T,
        statusCode: 404,
        requestOptions: RequestOptions(path: path),
      ),
    );
  }
}

class MockSecureTokenStorage extends Mock implements SecureTokenStorage {
  String? _accessToken;
  String? _sessionToken;
  String? _refreshToken;

  @override
  Future<void> saveTokens({
    String? accessToken,
    String? sessionToken,
    String? refreshToken,
  }) async {
    _accessToken = accessToken;
    _sessionToken = sessionToken;
    _refreshToken = refreshToken;
  }

  @override
  Future<String?> getAccessToken() async => _accessToken;
  @override
  Future<String?> getSessionToken() async => _sessionToken;
  @override
  Future<String?> getRefreshToken() async => _refreshToken;

  @override
  Future<void> clearTokens() async {
    _accessToken = null;
    _sessionToken = null;
    _refreshToken = null;
  }

  @override
  Future<void> clearAllAuthData() async {
    await clearTokens();
  }

  @override
  Future<bool> hasValidTokens() async {
    return _accessToken != null && _accessToken!.isNotEmpty;
  }
}

void main() {
  group('Authentication Remote DataSource Tests', () {
    late AuthRemoteDataSourceImpl authDataSource;
    late MockSecureTokenStorage mockStorage;
    late MockDioClient mockDioClient;

    setUp(() {
      mockStorage = MockSecureTokenStorage();
      mockDioClient = MockDioClient();
      authDataSource = AuthRemoteDataSourceImpl(
        dioClient: mockDioClient,
        tokenStorage: mockStorage,
      );
    });

    test('should return UserModel on successful login', () async {
      // Perform login
      final result = await authDataSource.login(
        email: 'test@example.com',
        password: 'password',
      );

      // Verify result is a UserModel with correct data
      expect(result, isNotNull);
      expect(result.email, 'test@example.com');
      expect(result.id, 'test-user-id');
      expect(result.displayName, 'Test User');
    });

    test('should store tokens after successful login', () async {
      // Perform login
      await authDataSource.login(
        email: 'test@example.com',
        password: 'password',
      );

      // Verify tokens were stored
      final storedAccessToken = await mockStorage.getAccessToken();
      final storedSessionToken = await mockStorage.getSessionToken();
      final storedRefreshToken = await mockStorage.getRefreshToken();

      expect(storedAccessToken, 'test-access-token');
      expect(storedSessionToken, 'test-session-token');
      expect(storedRefreshToken, 'test-refresh-token');
    });

    test('should refresh token successfully', () async {
      // Setup initial tokens
      await mockStorage.saveTokens(
        accessToken: 'old-access-token',
        sessionToken: 'old-session-token',
        refreshToken: 'old-refresh-token',
      );

      // Perform token refresh
      final newToken = await authDataSource.refreshToken();

      // Verify new token was returned and stored
      expect(newToken, 'new-test-access-token');

      final storedAccessToken = await mockStorage.getAccessToken();
      expect(storedAccessToken, 'new-test-access-token');
    });

    test('should return null when refresh token is missing', () async {
      // Setup storage with no refresh token
      await mockStorage.saveTokens(
        accessToken: 'test-access-token',
        sessionToken: 'test-session-token',
        refreshToken: null,
      );

      // Try to refresh token (should return null due to missing refresh token)
      final result = await authDataSource.refreshToken();

      expect(result, isNull);
    });

    test('should get current user', () async {
      // Mock the getCurrentUser response
      when(
        mockDioClient.get<Map<String, dynamic>>(
          '/api/identity/app/v1/accounts/me',
          queryParameters: anyNamed('queryParameters'),
          options: anyNamed('options'),
        ),
      ).thenAnswer(
        (_) => Future.value(
          Response<Map<String, dynamic>>(
            data: {
              'id': 'test-user-id',
              'email': 'test@example.com',
              'displayName': 'Test User',
              'role': 'user',
              'isEmailVerified': true,
              'isIdentityVerified': false,
              'isProfileComplete': true,
            },
            statusCode: 200,
            requestOptions: RequestOptions(
              path: '/api/identity/app/v1/accounts/me',
            ),
          ),
        ),
      );

      final result = await authDataSource.getCurrentUser();

      expect(result, isNotNull);
      expect(result?.email, 'test@example.com');
      expect(result?.displayName, 'Test User');
    });
  });
}
