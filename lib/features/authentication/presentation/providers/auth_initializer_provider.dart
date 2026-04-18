import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:discovaa/core/storage/hive_service.dart';
import 'package:discovaa/core/storage/secure_token_storage.dart';
import 'package:discovaa/features/authentication/domain/entities/user_entity.dart';
import 'package:discovaa/features/authentication/presentation/providers/session_provider.dart';
import 'package:discovaa/features/authentication/presentation/providers/signup_provider.dart';

/// Represents the authentication status of the user.
enum AuthStatus {
  /// User is authenticated with valid tokens.
  authenticated,

  /// User is not authenticated (no valid tokens).
  unauthenticated,

  /// Auth status is being determined.
  unknown,
}

/// Provider for SecureTokenStorage.
///
/// This provider lazily initializes the storage service using the
/// singleton HiveService instance.
final secureTokenStorageProvider = Provider<SecureTokenStorage>((ref) {
  return SecureTokenStorage(
    hiveService: HiveService.instance,
    secureStorage: const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    ),
  );
});

/// State class for auth initializer.
class AuthInitializerState {
  final AuthStatus status;
  final bool isLoading;

  const AuthInitializerState({
    this.status = AuthStatus.unknown,
    this.isLoading = true,
  });

  AuthInitializerState copyWith({AuthStatus? status, bool? isLoading}) {
    return AuthInitializerState(
      status: status ?? this.status,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// Notifier that handles authentication state initialization on app startup.
///
/// This notifier is responsible for:
/// 1. Checking if valid tokens exist in storage
/// 2. Loading user data if authenticated
/// 3. Restoring the session state
/// 4. Determining the initial auth status
class AuthInitializerNotifier extends StateNotifier<AuthInitializerState> {
  final Ref _ref;

  AuthInitializerNotifier(this._ref) : super(const AuthInitializerState()) {
    // Initialize auth status on creation
    _initialize();
  }

  /// Initialize the auth status by checking storage.
  Future<void> _initialize() async {
    try {
      // Wait a moment to ensure Hive is initialized
      await Future.delayed(const Duration(milliseconds: 100));

      final storage = _ref.read(secureTokenStorageProvider);

      // Check if user has valid tokens
      final hasTokens = await storage.hasValidTokens();
      final isAuthenticated = storage.isAuthenticated();

      if (!hasTokens || !isAuthenticated) {
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          isLoading: false,
        );
        return;
      }

      // Try to load user data
      final userData = storage.getUserData();
      if (userData == null) {
        // Tokens exist but no user data - treat as unauthenticated
        // This can happen if storage was partially cleared
        await storage.clearAllAuthData();
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          isLoading: false,
        );
        return;
      }

      // Restore session state
      _restoreSessionState(userData.role);

      state = state.copyWith(
        status: AuthStatus.authenticated,
        isLoading: false,
      );
    } catch (e) {
      // On error, treat as unauthenticated
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        isLoading: false,
      );
    }
  }

  /// Restore the session provider state based on stored user role.
  void _restoreSessionState(String role) {
    UserRole userRole;
    switch (role) {
      case 'provider':
        userRole = UserRole.individualProvider;
        break;
      case 'business':
        userRole = UserRole.businessProvider;
        break;
      default:
        userRole = UserRole.user;
    }

    // Update session provider
    _ref.read(sessionProvider.notifier).signIn(userRole);
  }

  /// Refresh the auth status.
  ///
  /// Call this when you want to re-check the authentication status,
  /// such as after a token refresh or when returning from background.
  Future<void> refresh() async {
    state = state.copyWith(isLoading: true);

    try {
      final storage = _ref.read(secureTokenStorageProvider);

      final hasTokens = await storage.hasValidTokens();
      final isAuthenticated = storage.isAuthenticated();

      if (!hasTokens || !isAuthenticated) {
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          isLoading: false,
        );
        return;
      }

      final userData = storage.getUserData();
      if (userData != null) {
        _restoreSessionState(userData.role);
        state = state.copyWith(
          status: AuthStatus.authenticated,
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          isLoading: false,
        );
      }
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        isLoading: false,
      );
    }
  }

  /// Mark user as authenticated with user data.
  ///
  /// Call this after successful login or registration.
  Future<void> setAuthenticated({
    required String accessToken,
    String? sessionToken,
    String? refreshToken,
    required String role,
    required UserEntity user,
  }) async {
    final storage = _ref.read(secureTokenStorageProvider);

    // Save tokens - all three if available
    await storage.saveTokens(
      accessToken: accessToken,
      sessionToken: sessionToken,
      refreshToken: refreshToken,
    );

    // Save user data
    await storage.saveUserData(user);

    // Set authenticated flag
    await storage.setAuthenticated(true);

    // Update session
    _restoreSessionState(role);

    // Log token summary for observability
    final hasAccess = accessToken.isNotEmpty;
    final hasSession = sessionToken != null && sessionToken.isNotEmpty;
    final hasRefresh = refreshToken != null && refreshToken.isNotEmpty;
    debugPrint(
      '[AuthInitializer] Tokens saved: access=$hasAccess, session=$hasSession, refresh=$hasRefresh',
    );

    // Update state
    state = state.copyWith(status: AuthStatus.authenticated, isLoading: false);
  }

  /// Mark user as unauthenticated and clear all auth data.
  ///
  /// Call this on logout.
  Future<void> setUnauthenticated() async {
    final storage = _ref.read(secureTokenStorageProvider);

    // Clear all auth data
    await storage.clearAllAuthData();

    // Reset session
    _ref.read(sessionProvider.notifier).signOut();

    // Update state
    state = state.copyWith(
      status: AuthStatus.unauthenticated,
      isLoading: false,
    );
  }
}

/// Main provider for auth initialization.
///
/// Usage:
/// ```dart
/// final authState = ref.watch(authInitializerProvider);
/// if (authState.status == AuthStatus.authenticated) {
///   // User is logged in
/// }
/// ```
final authInitializerProvider =
    StateNotifierProvider<AuthInitializerNotifier, AuthInitializerState>((ref) {
      return AuthInitializerNotifier(ref);
    });

/// Convenience provider to check if user is authenticated.
///
/// Returns true if auth status is authenticated.
final isUserAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authInitializerProvider);
  return authState.status == AuthStatus.authenticated;
});

/// Convenience provider to check if auth initialization is complete.
///
/// Returns true when the auth status is no longer loading.
final isAuthInitializedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authInitializerProvider);
  return !authState.isLoading;
});
