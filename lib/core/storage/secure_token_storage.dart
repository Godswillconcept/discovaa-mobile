import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:discovaa/core/storage/hive_service.dart';
import 'package:discovaa/features/authentication/data/models/user_model.dart';
import 'package:discovaa/features/authentication/domain/entities/user_entity.dart';

/// Service for securely storing and retrieving authentication-related data.
///
/// This service provides a centralized interface for managing:
/// - Access tokens
/// - Session tokens
/// - User data
/// - Authentication status
///
/// Sensitive tokens are stored using FlutterSecureStorage, while
/// non-sensitive data is stored using Hive.
class SecureTokenStorage {
  final HiveService _hiveService;
  final FlutterSecureStorage _secureStorage;

  // Storage keys
  static const String _accessTokenKey = 'access_token';
  static const String _sessionTokenKey = 'session_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userDataKey = 'user_data';
  static const String _isAuthenticatedKey = 'is_authenticated';
  static const String _hasCompletedOnboardingKey = 'has_completed_onboarding';

  SecureTokenStorage({
    required HiveService hiveService,
    required FlutterSecureStorage secureStorage,
  }) : _hiveService = hiveService,
       _secureStorage = secureStorage;

  // ==================== TOKEN MANAGEMENT ====================

  /// Save authentication tokens to secure storage.
  ///
  /// [accessToken] - The JWT access token for API authentication
  /// [sessionToken] - The session token for maintaining user session
  /// [refreshToken] - The refresh token for obtaining new access tokens
  Future<void> saveTokens({
    String? accessToken,
    String? sessionToken,
    String? refreshToken,
  }) async {
    try {
      if (accessToken != null && accessToken.isNotEmpty) {
        debugPrint('[SecureTokenStorage] Writing access_token...');
        await _secureStorage.write(key: _accessTokenKey, value: accessToken);
        debugPrint('[SecureTokenStorage] access_token written.');
      }
      if (sessionToken != null && sessionToken.isNotEmpty) {
        debugPrint('[SecureTokenStorage] Writing session_token...');
        await _secureStorage.write(key: _sessionTokenKey, value: sessionToken);
        debugPrint('[SecureTokenStorage] session_token written.');
      }
      if (refreshToken != null && refreshToken.isNotEmpty) {
        debugPrint('[SecureTokenStorage] Writing refresh_token...');
        await _secureStorage.write(key: _refreshTokenKey, value: refreshToken);
        debugPrint('[SecureTokenStorage] refresh_token written.');
      }
    } catch (e) {
      debugPrint('[SecureTokenStorage] ERROR during saveTokens: $e');
      rethrow;
    }
  }

  /// Retrieve the stored access token.
  ///
  /// Returns null if no token is stored.
  Future<String?> getAccessToken() async {
    return await _secureStorage.read(key: _accessTokenKey);
  }

  /// Retrieve the stored session token.
  ///
  /// Returns null if no token is stored.
  Future<String?> getSessionToken() async {
    return await _secureStorage.read(key: _sessionTokenKey);
  }

  /// Retrieve the stored refresh token.
  ///
  /// Returns null if no token is stored.
  Future<String?> getRefreshToken() async {
    return await _secureStorage.read(key: _refreshTokenKey);
  }

  /// Check if valid tokens exist in storage.
  ///
  /// Returns true if access token exists and is not empty.
  Future<bool> hasValidTokens() async {
    final accessToken = await getAccessToken();
    return accessToken != null && accessToken.isNotEmpty;
  }

  /// Clear all stored tokens.
  Future<void> clearTokens() async {
    await _secureStorage.delete(key: _accessTokenKey);
    await _secureStorage.delete(key: _sessionTokenKey);
    await _secureStorage.delete(key: _refreshTokenKey);
  }

  // ==================== USER DATA MANAGEMENT ====================

  /// Save user data to persistent storage.
  ///
  /// [user] - The user entity to store
  Future<void> saveUserData(UserEntity user) async {
    final userModel = UserModel.fromEntity(user);
    final userJson = jsonEncode(userModel.toJson());
    await _hiveService.setString(_userDataKey, userJson);
  }

  /// Retrieve stored user data.
  ///
  /// Returns null if no user data is stored or if parsing fails.
  UserEntity? getUserData() {
    try {
      final userJson = _hiveService.getString(_userDataKey);
      if (userJson == null || userJson.isEmpty) return null;

      final userMap = jsonDecode(userJson) as Map<String, dynamic>;
      final userModel = UserModel.fromJson(userMap);
      return userModel.toEntity();
    } catch (e) {
      // If parsing fails, clear the corrupted data
      clearUserData();
      return null;
    }
  }

  /// Clear stored user data.
  Future<void> clearUserData() async {
    await _hiveService.remove(_userDataKey);
  }

  // ==================== AUTHENTICATION STATUS ====================

  /// Set the authentication status.
  ///
  /// [isAuthenticated] - true if user is authenticated, false otherwise
  Future<void> setAuthenticated(bool isAuthenticated) async {
    await _hiveService.setBool(_isAuthenticatedKey, isAuthenticated);
  }

  /// Check if user is marked as authenticated.
  ///
  /// Returns false if no value is stored.
  bool isAuthenticated() {
    return _hiveService.getBool(_isAuthenticatedKey) ?? false;
  }

  // ==================== ONBOARDING STATUS ====================

  /// Mark onboarding as completed.
  ///
  /// This flag can be used to skip onboarding for returning users
  /// who haven't completed registration but have seen onboarding.
  Future<void> setOnboardingCompleted(bool completed) async {
    await _hiveService.setBool(_hasCompletedOnboardingKey, completed);
  }

  /// Check if user has completed onboarding.
  ///
  /// Returns false if no value is stored.
  bool hasCompletedOnboarding() {
    return _hiveService.getBool(_hasCompletedOnboardingKey) ?? false;
  }

  // ==================== COMPLETE CLEAR ====================

  /// Clear all authentication-related data.
  ///
  /// This should be called on logout to ensure no sensitive
  /// data remains in storage.
  Future<void> clearAllAuthData() async {
    await clearTokens();
    await clearUserData();
    await setAuthenticated(false);
    // Note: We keep onboarding status to avoid showing it again
  }

  /// Clear all data including onboarding status.
  ///
  /// Use this for a complete reset, like on account deletion.
  Future<void> clearAllData() async {
    await clearAllAuthData();
    await _hiveService.remove(_hasCompletedOnboardingKey);
  }
}
