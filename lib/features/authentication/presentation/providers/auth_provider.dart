import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:discovaa/app/dependency_injection/service_locator.dart';
import 'package:discovaa/core/errors/exceptions.dart';
import 'package:discovaa/core/storage/hive_service.dart';
import 'package:discovaa/core/storage/secure_token_storage.dart';
import 'package:discovaa/features/authentication/domain/repositories/auth_repository.dart';
import 'package:discovaa/features/authentication/domain/entities/user_entity.dart';
import 'package:discovaa/features/authentication/domain/entities/registration_entity.dart';
import 'package:discovaa/features/authentication/presentation/providers/auth_state.dart';
import 'package:discovaa/features/authentication/presentation/providers/registration_flow_provider.dart';

/// Provider for AuthRepository
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return sl<AuthRepository>();
});

/// Provider for SecureTokenStorage
final tokenStorageProvider = Provider<SecureTokenStorage>((ref) {
  return sl<SecureTokenStorage>();
});

/// Notifier that GoRouter listens to for redirect re-evaluation.
/// Toggled automatically whenever authProvider state changes.
final authRefreshNotifier = ValueNotifier<bool>(false);

/// AuthNotifier using AsyncNotifier for better state management
class AuthNotifier extends AsyncNotifier<AuthState> {
  late final AuthRepository _repository;
  late final SecureTokenStorage _tokenStorage;

  @override
  FutureOr<AuthState> build() async {
    _repository = ref.watch(authRepositoryProvider);
    _tokenStorage = ref.watch(tokenStorageProvider);

    debugPrint('[AuthNotifier] build() called - checking existing session');
    // Check for existing session on app start
    final result = await _checkExistingSession();
    debugPrint('[AuthNotifier] build() completed with state: $result');
    return result;
  }

  @override
  set state(AsyncValue<AuthState> value) {
    super.state = value;
    // Notify GoRouter to re-evaluate redirects whenever auth state changes
    authRefreshNotifier.value = !authRefreshNotifier.value;
  }

  /// Read local identity verification status from Hive storage
  bool _getLocalIdentityVerified() {
    try {
      final data = HiveService.instance.getMap('identity_verification');
      return data?['isIdentityVerified'] == true;
    } catch (e) {
      return false;
    }
  }

  /// Check for existing session
  Future<AuthState> _checkExistingSession() async {
    try {
      debugPrint('[AuthNotifier] _checkExistingSession() started');
      final hasTokens = await _tokenStorage.hasValidTokens();
      if (!hasTokens) {
        debugPrint(
          '[AuthNotifier] No valid tokens found, returning unauthenticated',
        );
        return const AuthState(status: AuthStatus.unauthenticated);
      }

      debugPrint('[AuthNotifier] Valid tokens found, fetching current user...');
      final userResult = await _repository.getCurrentUser();
      if (userResult.isSuccess && userResult.data != null) {
        debugPrint(
          '[AuthNotifier] Got current user: ${userResult.data!.email}',
        );
        // The auth session endpoint returns minimal user data without reliable
        // is_profile_complete or role fields. Fetch full profile for accuracy.
        final fullProfileResult = await _repository.fetchFullProfile();
        final user =
            fullProfileResult.isSuccess && fullProfileResult.data != null
            ? fullProfileResult.data!
            : userResult.data!;

        debugPrint(
          '[AuthNotifier] Full profile fetched: isIdentityVerified=${user.isIdentityVerified}, isProfileComplete=${user.isProfileComplete}',
        );

        // Supplement with locally persisted identity verification status
        final identityVerified = _getLocalIdentityVerified();
        debugPrint('[AuthNotifier] Local identity verified: $identityVerified');
        final effectiveUser = user.copyWith(
          isIdentityVerified: user.isIdentityVerified || identityVerified,
        );

        // Check if profile is complete
        if (!effectiveUser.isProfileComplete) {
          debugPrint(
            '[AuthNotifier] Profile incomplete, returning requiresProfile',
          );
          return AuthState(
            status: AuthStatus.requiresProfile,
            user: effectiveUser,
          );
        }

        // Check if identity verification is needed (ALL users, not just providers)
        if (!effectiveUser.isIdentityVerified) {
          debugPrint(
            '[AuthNotifier] Identity not verified, returning requiresVerification',
          );
          return AuthState(
            status: AuthStatus.requiresVerification,
            user: effectiveUser,
          );
        }

        debugPrint(
          '[AuthNotifier] User fully authenticated, returning authenticated',
        );
        return AuthState(status: AuthStatus.authenticated, user: effectiveUser);
      }

      debugPrint(
        '[AuthNotifier] Failed to get current user, returning unauthenticated',
      );
      return const AuthState(status: AuthStatus.unauthenticated);
    } catch (e) {
      debugPrint('[AuthNotifier] Error in _checkExistingSession: $e');
      return AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: e.toString(),
      );
    }
  }

  /// Login with email and password
  Future<void> login({required String email, required String password}) async {
    state = const AsyncData(AuthState(isLoading: true));

    final result = await _repository.login(email: email, password: password);

    if (result.isSuccess && result.data != null) {
      // Check if this is a pending verification user (empty ID indicates pending email verification)
      final isPendingVerification = result.data!.id.isEmpty;

      UserEntity user;
      if (isPendingVerification) {
        // For pending verification users, skip profile fetch (not yet fully authenticated)
        // Use the minimal user data returned from login
        user = result.data!;
      } else {
        // For authenticated users, fetch full profile for accurate data
        final fullProfileResult = await _repository.fetchFullProfile();
        user = fullProfileResult.isSuccess && fullProfileResult.data != null
            ? fullProfileResult.data!
            : result.data!;
      }

      // Supplement with locally persisted identity verification status
      final identityVerified = _getLocalIdentityVerified();
      final effectiveUser = user.copyWith(
        isIdentityVerified: user.isIdentityVerified || identityVerified,
      );

      // Persist user and session so _checkExistingSession() can restore on restart
      await _tokenStorage.saveUserData(effectiveUser);
      await _tokenStorage.setAuthenticated(true);

      if (!effectiveUser.isProfileComplete) {
        state = AsyncData(
          AuthState(status: AuthStatus.requiresProfile, user: effectiveUser),
        );
      } else if (!effectiveUser.isIdentityVerified) {
        state = AsyncData(
          AuthState(
            status: AuthStatus.requiresVerification,
            user: effectiveUser,
          ),
        );
      } else {
        state = AsyncData(
          AuthState(status: AuthStatus.authenticated, user: effectiveUser),
        );
      }
    } else {
      state = AsyncData(
        AuthState(
          status: AuthStatus.unauthenticated,
          errorMessage: result.failure?.message ?? 'Login failed',
        ),
      );
    }
  }

  /// Register a new user
  Future<bool> register({
    required String email,
    required String password,
    required UserRole role,
  }) async {
    state = const AsyncData(AuthState(isLoading: true));

    // Map UserRole to accountType and providerType
    String accountType;
    String? providerType;
    switch (role) {
      case UserRole.user:
        accountType = 'user';
        providerType = null;
        break;
      case UserRole.individualProvider:
        accountType = 'service_provider';
        providerType = 'individual';
        break;
      case UserRole.businessProvider:
        accountType = 'service_provider';
        providerType = 'business';
        break;
    }

    final registration = RegistrationEntity(
      email: email,
      password: password,
      accountType: accountType,
      providerType: providerType,
    );

    final result = await _repository.register(registration);

    if (result.isSuccess && result.data != null) {
      state = AsyncData(
        AuthState(status: AuthStatus.requiresProfile, user: result.data),
      );
      return true;
    } else {
      state = AsyncData(
        AuthState(
          status: AuthStatus.unauthenticated,
          errorMessage: result.failure?.message ?? 'Registration failed',
        ),
      );
      return false;
    }
  }

  /// Verify OTP code
  Future<bool> verifyOtp({
    required String email,
    required String otpCode,
  }) async {
    state = state.whenData((authState) => authState.copyWith(isLoading: true));

    final result = await _repository.verifyOtp(email: email, otpCode: otpCode);

    if (result.isSuccess && result.data == true) {
      state = state.whenData(
        (authState) => authState.copyWith(isLoading: false, errorMessage: null),
      );
      return true;
    } else {
      state = state.whenData(
        (authState) => authState.copyWith(
          isLoading: false,
          errorMessage: result.failure?.message ?? 'Verification failed',
        ),
      );
      return false;
    }
  }

  /// Resend OTP code
  Future<bool> resendOtp(String email) async {
    state = state.whenData((authState) => authState.copyWith(isLoading: true));

    final result = await _repository.resendOtp(email);

    if (result.isSuccess) {
      state = state.whenData(
        (authState) => authState.copyWith(isLoading: false, errorMessage: null),
      );
      return true;
    } else {
      state = state.whenData(
        (authState) => authState.copyWith(
          isLoading: false,
          errorMessage: result.failure?.message ?? 'Failed to resend code',
        ),
      );
      return false;
    }
  }

  /// Logout current user
  Future<void> logout() async {
    try {
      // Attempt to call the repository to logout from server
      await _repository.logout();
    } catch (e) {
      // Log the error but don't block local cleanup
      debugPrint('[AuthNotifier] Logout API call failed: $e');
    } finally {
      // Always clear all auth data regardless of API success/failure
      await _tokenStorage.clearAllAuthData();

      // Clear all cached user data from Hive
      await _clearAllCachedData();

      // Update state to unauthenticated
      state = const AsyncData(AuthState(status: AuthStatus.unauthenticated));
    }
  }

  /// Clear all cached user data from Hive storage
  Future<void> _clearAllCachedData() async {
    try {
      final hiveService = HiveService.instance;

      // Clear profile cache
      await hiveService.remove('profile.cache.me');
      await hiveService.remove('profile.cache.me.timestamp');

      // Clear identity verification status
      await hiveService.remove('identity_verification');

      // Clear favorite artisans
      await hiveService.remove('favorite_artisans');

      // Clear artisan detail caches (if stored with pattern)
      final keys = hiveService.getKeys().toList();
      for (final key in keys) {
        if (key is String &&
            (key.startsWith('artisan_detail.') ||
                key.startsWith('profile.cache.') ||
                key.startsWith('favorite_'))) {
          await hiveService.remove(key);
        }
      }

      debugPrint('[AuthNotifier] All cached data cleared successfully');
    } catch (e) {
      debugPrint('[AuthNotifier] Error clearing cached data: $e');
    }
  }

  /// Get current user
  Future<void> getCurrentUser() async {
    state = state.whenData((authState) => authState.copyWith(isLoading: true));

    final result = await _repository.getCurrentUser();

    if (result.isSuccess && result.data != null) {
      final user = result.data!;
      final identityVerified = _getLocalIdentityVerified();
      final effectiveUser = user.copyWith(
        isIdentityVerified: user.isIdentityVerified || identityVerified,
      );
      state = AsyncData(
        AuthState(
          status: effectiveUser.isProfileComplete
              ? !effectiveUser.isIdentityVerified
                    ? AuthStatus.requiresVerification
                    : AuthStatus.authenticated
              : AuthStatus.requiresProfile,
          user: effectiveUser,
        ),
      );
    } else {
      state = const AsyncData(
        AuthState(status: AuthStatus.unauthenticated, isLoading: false),
      );
    }
  }

  /// Send password reset email
  Future<bool> sendPasswordResetEmail(String email) async {
    state = state.whenData((authState) => authState.copyWith(isLoading: true));

    final result = await _repository.sendPasswordResetEmail(email);

    if (result.isSuccess) {
      state = state.whenData(
        (authState) => authState.copyWith(isLoading: false, errorMessage: null),
      );
      return true;
    } else {
      state = state.whenData(
        (authState) => authState.copyWith(
          isLoading: false,
          errorMessage: result.failure?.message ?? 'Failed to send reset email',
        ),
      );
      return false;
    }
  }

  /// Reset password with token
  Future<bool> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    state = state.whenData((authState) => authState.copyWith(isLoading: true));

    debugPrint('[authProvider] resetPassword called with token: $token');

    final result = await _repository.resetPassword(
      token: token,
      newPassword: newPassword,
    );

    debugPrint(
      '[authProvider] resetPassword result: isSuccess=${result.isSuccess}, failure=${result.failure?.message}',
    );

    if (result.isSuccess) {
      state = state.whenData(
        (authState) => authState.copyWith(isLoading: false, errorMessage: null),
      );
      return true;
    } else {
      state = state.whenData(
        (authState) => authState.copyWith(
          isLoading: false,
          errorMessage: result.failure?.message ?? 'Failed to reset password',
        ),
      );
      return false;
    }
  }

  /// Update user profile
  Future<bool> updateProfile({
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
    state = state.whenData((authState) => authState.copyWith(isLoading: true));

    try {
      final result = await _repository.updateProfile(
        firstName: firstName,
        lastName: lastName,
        displayName: displayName,
        phone: phone,
        address: address,
        countryIso2: countryIso2,
        postalCode: postalCode,
        businessName: businessName,
        businessDescription: businessDescription,
      );

      if (result.isSuccess && result.data != null) {
        final user = result.data!;
        final identityVerified = _getLocalIdentityVerified();
        final effectiveUser = user.copyWith(
          isIdentityVerified: user.isIdentityVerified || identityVerified,
        );
        state = AsyncData(
          AuthState(
            status: !effectiveUser.isIdentityVerified
                ? AuthStatus.requiresVerification
                : AuthStatus.authenticated,
            user: effectiveUser,
          ),
        );
        return true;
      } else {
        state = state.whenData(
          (authState) => authState.copyWith(
            isLoading: false,
            errorMessage: result.failure?.message ?? 'Failed to update profile',
          ),
        );
        return false;
      }
    } on NetworkException catch (e) {
      state = state.whenData(
        (authState) =>
            authState.copyWith(isLoading: false, errorMessage: e.message),
      );
      return false;
    } on ServerException catch (e) {
      state = state.whenData(
        (authState) =>
            authState.copyWith(isLoading: false, errorMessage: e.message),
      );
      return false;
    } catch (e) {
      state = state.whenData(
        (authState) => authState.copyWith(
          isLoading: false,
          errorMessage: 'Unexpected error during profile update',
        ),
      );
      return false;
    }
  }

  /// Upload ID document front
  Future<bool> uploadIdDocumentFront({
    required String idNumber,
    required File documentFront,
  }) async {
    state = state.whenData((authState) => authState.copyWith(isLoading: true));

    try {
      final result = await _repository.uploadIdDocumentFront(
        idNumber: idNumber,
        documentFront: documentFront,
      );

      if (result.isSuccess) {
        state = state.whenData(
          (authState) =>
              authState.copyWith(isLoading: false, errorMessage: null),
        );
        return true;
      } else {
        state = state.whenData(
          (authState) => authState.copyWith(
            isLoading: false,
            errorMessage:
                result.failure?.message ?? 'Failed to upload document',
          ),
        );
        return false;
      }
    } catch (e) {
      state = state.whenData(
        (authState) => authState.copyWith(
          isLoading: false,
          errorMessage: 'Failed to upload document: $e',
        ),
      );
      return false;
    }
  }

  /// Upload ID document back
  Future<bool> uploadIdDocumentBack({
    required String idNumber,
    required File documentBack,
  }) async {
    state = state.whenData((authState) => authState.copyWith(isLoading: true));

    try {
      final result = await _repository.uploadIdDocumentBack(
        idNumber: idNumber,
        documentBack: documentBack,
      );

      if (result.isSuccess) {
        state = state.whenData(
          (authState) =>
              authState.copyWith(isLoading: false, errorMessage: null),
        );
        return true;
      } else {
        state = state.whenData(
          (authState) => authState.copyWith(
            isLoading: false,
            errorMessage:
                result.failure?.message ?? 'Failed to upload document',
          ),
        );
        return false;
      }
    } catch (e) {
      state = state.whenData(
        (authState) => authState.copyWith(
          isLoading: false,
          errorMessage: 'Failed to upload document: $e',
        ),
      );
      return false;
    }
  }

  /// Mark identity verification as complete and transition to authenticated
  void markIdentityVerified() {
    state = state.whenData((authState) {
      final user = authState.user;
      if (user == null) return authState;
      return AuthState(
        status: AuthStatus.authenticated,
        user: user.copyWith(isIdentityVerified: true),
      );
    });
  }

  /// Skip identity verification and transition to authenticated
  /// Called when user clicks 'Skip for now' on IdentificationPage
  void skipVerification() {
    state = state.whenData((authState) {
      final user = authState.user;
      if (user == null) {
        debugPrint(
          '[AuthNotifier] skipVerification() - no user found, returning current state',
        );
        return authState;
      }
      debugPrint(
        '[AuthNotifier] skipVerification() called - transitioning to authenticated (verification skipped)',
      );
      return AuthState(
        status: AuthStatus.authenticated,
        user: user.copyWith(isIdentityVerified: false),
      );
    });
  }

  /// Skip profile completion and transition to next step
  /// Called when user clicks 'Skip' on CompleteProfilePage
  void skipProfile() {
    state = state.whenData((authState) {
      final user = authState.user;
      if (user == null) {
        debugPrint(
          '[AuthNotifier] skipProfile() - no user found, returning current state',
        );
        return authState;
      }
      debugPrint(
        '[AuthNotifier] skipProfile() called - transitioning from requiresProfile',
      );
      // If identity is already verified, go to authenticated
      // Otherwise, go to requiresVerification
      if (user.isIdentityVerified) {
        debugPrint(
          '[AuthNotifier] skipProfile() - identity verified, transitioning to authenticated',
        );
        return AuthState(
          status: AuthStatus.authenticated,
          user: user.copyWith(isProfileComplete: true),
        );
      } else {
        debugPrint(
          '[AuthNotifier] skipProfile() - identity not verified, transitioning to requiresVerification',
        );
        return AuthState(
          status: AuthStatus.requiresVerification,
          user: user.copyWith(isProfileComplete: true),
        );
      }
    });
  }

  /// Clear error state
  void clearError() {
    state = state.whenData(
      (authState) => authState.copyWith(errorMessage: null, isLoading: false),
    );
  }

  /// Register device token for push notifications
  Future<bool> registerDeviceToken({required String token}) async {
    try {
      final result = await _repository.registerDeviceToken(token: token);
      return result.isSuccess;
    } catch (e) {
      return false;
    }
  }
}

/// Main auth provider using AsyncNotifier
final authProvider = AsyncNotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});

/// Convenience provider to check if user is authenticated
final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authProvider);
  return authState.when(
    data: (state) => state.isAuthenticated,
    loading: () => false,
    error: (_, _) => false,
  );
});

/// Convenience provider to get current user
final currentUserProvider = Provider<UserEntity?>((ref) {
  final authState = ref.watch(authProvider);
  return authState.when(
    data: (state) => state.user,
    loading: () => null,
    error: (_, _) => null,
  );
});

/// Convenience provider to get auth loading state
final isAuthLoadingProvider = Provider<bool>((ref) {
  final authState = ref.watch(authProvider);
  return authState.when(
    data: (state) => state.isLoading,
    loading: () => true,
    error: (_, _) => false,
  );
});

/// Convenience provider to get auth error
final authErrorProvider = Provider<String?>((ref) {
  final authState = ref.watch(authProvider);
  return authState.when(
    data: (state) => state.errorMessage,
    loading: () => null,
    error: (error, _) => error.toString(),
  );
});
