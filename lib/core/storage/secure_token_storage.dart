import 'dart:convert';

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
/// All data is stored using Hive for persistence across app restarts.
class SecureTokenStorage {
  final HiveService _hiveService;

  // Storage keys
  static const String _accessTokenKey = 'access_token';
  static const String _sessionTokenKey = 'session_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userDataKey = 'user_data';
  static const String _isAuthenticatedKey = 'is_authenticated';
  static const String _hasCompletedOnboardingKey = 'has_completed_onboarding';

  SecureTokenStorage({required HiveService hiveService})
    : _hiveService = hiveService;

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
    if (accessToken != null && accessToken.isNotEmpty) {
      await _hiveService.setString(_accessTokenKey, accessToken);
    }
    if (sessionToken != null && sessionToken.isNotEmpty) {
      await _hiveService.setString(_sessionTokenKey, sessionToken);
    }
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await _hiveService.setString(_refreshTokenKey, refreshToken);
    }
  }

  /// Retrieve the stored access token.
  ///
  /// Returns null if no token is stored.
  String? getAccessToken() {
    return _hiveService.getString(_accessTokenKey);
  }

  /// Retrieve the stored session token.
  ///
  /// Returns null if no token is stored.
  String? getSessionToken() {
    return _hiveService.getString(_sessionTokenKey);
  }

  /// Retrieve the stored refresh token.
  ///
  /// Returns null if no token is stored.
  String? getRefreshToken() {
    return _hiveService.getString(_refreshTokenKey);
  }

  /// Check if valid tokens exist in storage.
  ///
  /// Returns true if access token exists and is not empty.
  bool hasValidTokens() {
    final accessToken = getAccessToken();
    return accessToken != null && accessToken.isNotEmpty;
  }

  /// Clear all stored tokens.
  Future<void> clearTokens() async {
    await _hiveService.remove(_accessTokenKey);
    await _hiveService.remove(_sessionTokenKey);
    await _hiveService.remove(_refreshTokenKey);
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
