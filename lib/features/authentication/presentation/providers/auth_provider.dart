import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:discovaa/app/dependency_injection/service_locator.dart';
import 'package:discovaa/core/errors/exceptions.dart';
import 'package:discovaa/features/authentication/domain/repositories/auth_repository.dart';
import 'package:discovaa/features/authentication/domain/entities/user_entity.dart';
import 'package:discovaa/features/authentication/domain/entities/registration_entity.dart';
import 'package:discovaa/features/authentication/presentation/providers/signup_provider.dart';

/// Auth operation state
enum AuthOperationState { idle, loading, success, error }

/// Auth state that holds user and operation status
class AuthState {
  final UserEntity? user;
  final AuthOperationState state;
  final String? errorMessage;
  final bool isAuthenticated;

  const AuthState({
    this.user,
    this.state = AuthOperationState.idle,
    this.errorMessage,
    this.isAuthenticated = false,
  });

  AuthState copyWith({
    UserEntity? user,
    AuthOperationState? state,
    String? errorMessage,
    bool? isAuthenticated,
  }) {
    return AuthState(
      user: user ?? this.user,
      state: state ?? this.state,
      errorMessage: errorMessage,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }
}

/// Provider for AuthRepository
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return sl<AuthRepository>();
});

/// Notifier that connects UI to AuthRepository
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(const AuthState());

  /// Login with email and password
  Future<bool> login({required String email, required String password}) async {
    state = state.copyWith(
      state: AuthOperationState.loading,
      errorMessage: null,
    );

    final result = await _repository.login(email: email, password: password);

    if (result.isSuccess && result.data != null) {
      state = state.copyWith(
        state: AuthOperationState.success,
        user: result.data,
        isAuthenticated: true,
      );
      return true;
    } else {
      final failure = result.failure;
      state = state.copyWith(
        state: AuthOperationState.error,
        errorMessage: failure?.code == 'VERIFICATION_PENDING'
            ? 'VERIFICATION_PENDING'
            : (failure?.message ?? 'Login failed'),
      );
      return false;
    }
  }

  /// Register a new user
  Future<bool> register({
    required String email,
    required String password,
    required UserRole role,
  }) async {
    state = state.copyWith(
      state: AuthOperationState.loading,
      errorMessage: null,
    );

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
      state = state.copyWith(
        state: AuthOperationState.success,
        user: result.data,
      );
      return true;
    } else {
      state = state.copyWith(
        state: AuthOperationState.error,
        errorMessage: result.failure?.message ?? 'Registration failed',
      );
      return false;
    }
  }

  /// Verify OTP code
  Future<bool> verifyOtp({
    required String email,
    required String otpCode,
  }) async {
    state = state.copyWith(
      state: AuthOperationState.loading,
      errorMessage: null,
    );

    final result = await _repository.verifyOtp(email: email, otpCode: otpCode);

    if (result.isSuccess && result.data == true) {
      state = state.copyWith(state: AuthOperationState.success);
      return true;
    } else {
      state = state.copyWith(
        state: AuthOperationState.error,
        errorMessage: result.failure?.message ?? 'Verification failed',
      );
      return false;
    }
  }

  /// Resend OTP code
  Future<bool> resendOtp(String email) async {
    state = state.copyWith(
      state: AuthOperationState.loading,
      errorMessage: null,
    );

    final result = await _repository.resendOtp(email);

    if (result.isSuccess) {
      state = state.copyWith(state: AuthOperationState.success);
      return true;
    } else {
      state = state.copyWith(
        state: AuthOperationState.error,
        errorMessage: result.failure?.message ?? 'Failed to resend code',
      );
      return false;
    }
  }

  /// Logout current user
  Future<bool> logout() async {
    state = state.copyWith(
      state: AuthOperationState.loading,
      errorMessage: null,
    );

    // Call the repository to logout from server.
    // The repository implementation now has a short timeout and ignores failures.
    await _repository.logout();

    // REGARDLESS of whether the API call succeeded or failed,
    // we MUST clear the local authentication state.
    state = const AuthState(
      user: null,
      isAuthenticated: false,
      state: AuthOperationState.success,
    );
    return true;
  }

  /// Get current user
  Future<void> getCurrentUser() async {
    state = state.copyWith(
      state: AuthOperationState.loading,
      errorMessage: null,
    );

    final result = await _repository.getCurrentUser();

    if (result.isSuccess && result.data != null) {
      state = state.copyWith(
        state: AuthOperationState.success,
        user: result.data,
        isAuthenticated: true,
      );
    } else {
      state = state.copyWith(
        state: AuthOperationState.error,
        isAuthenticated: false,
      );
    }
  }

  /// Send password reset email
  Future<bool> sendPasswordResetEmail(String email) async {
    state = state.copyWith(
      state: AuthOperationState.loading,
      errorMessage: null,
    );

    final result = await _repository.sendPasswordResetEmail(email);

    if (result.isSuccess) {
      state = state.copyWith(state: AuthOperationState.success);
      return true;
    } else {
      state = state.copyWith(
        state: AuthOperationState.error,
        errorMessage: result.failure?.message ?? 'Failed to send reset email',
      );
      return false;
    }
  }

  /// Reset password with token
  Future<bool> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    state = state.copyWith(
      state: AuthOperationState.loading,
      errorMessage: null,
    );

    final result = await _repository.resetPassword(
      token: token,
      newPassword: newPassword,
    );

    if (result.isSuccess) {
      state = state.copyWith(state: AuthOperationState.success);
      return true;
    } else {
      state = state.copyWith(
        state: AuthOperationState.error,
        errorMessage: result.failure?.message ?? 'Failed to reset password',
      );
      return false;
    }
  }

  /// Register device token for push notifications
  /// This is a best-effort operation - failures don't affect auth state
  Future<bool> registerDeviceToken({required String token}) async {
    try {
      final result = await _repository.registerDeviceToken(token: token);

      if (result.isSuccess) {
        return true;
      }
      return false;
    } catch (e) {
      // Device registration is best-effort, don't affect auth state
      return false;
    }
  }

  /// Update user profile
  Future<bool> updateProfile({
    required String firstName,
    required String lastName,
    required String displayName,
    required String phone,
    required String? countryIso2,
    String? businessName,
    String? businessDescription,
  }) async {
    state = state.copyWith(
      state: AuthOperationState.loading,
      errorMessage: null,
    );

    try {
      final result = await _repository.updateProfile(
        firstName: firstName,
        lastName: lastName,
        displayName: displayName,
        phone: phone,
        countryIso2: countryIso2,
        businessName: businessName,
        businessDescription: businessDescription,
      );

      if (result.isSuccess && result.data != null) {
        return true;
      } else {
        state = state.copyWith(
          state: AuthOperationState.error,
          errorMessage: result.failure?.message ?? 'Failed to update profile',
        );
        return false;
      }
    } on NetworkException catch (e) {
      state = state.copyWith(
        state: AuthOperationState.error,
        errorMessage: e.message,
      );
      return false;
    } on ServerException catch (e) {
      state = state.copyWith(
        state: AuthOperationState.error,
        errorMessage: e.message,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        state: AuthOperationState.error,
        errorMessage: 'Unexpected error during profile update',
      );
      return false;
    }
  }

  /// Clear error state
  void clearError() {
    state = state.copyWith(state: AuthOperationState.idle, errorMessage: null);
  }

  /// Fetch full user profile from accounts/me endpoint
  /// This returns the complete profile with is_profile_complete field
  Future<bool> fetchFullProfile() async {
    state = state.copyWith(
      state: AuthOperationState.loading,
      errorMessage: null,
    );

    final result = await _repository.fetchFullProfile();

    if (result.isSuccess) {
      if (result.data != null) {
        state = state.copyWith(
          state: AuthOperationState.success,
          user: result.data,
          isAuthenticated: true,
        );
      }
      return true;
    } else {
      state = state.copyWith(
        state: AuthOperationState.error,
        errorMessage: result.failure?.message ?? 'Failed to fetch profile',
      );
      return false;
    }
  }

  /// Upload ID document front
  Future<bool> uploadIdDocumentFront({
    required String idNumber,
    required File documentFront,
  }) async {
    state = state.copyWith(
      state: AuthOperationState.loading,
      errorMessage: null,
    );

    try {
      final result = await _repository.uploadIdDocumentFront(
        idNumber: idNumber,
        documentFront: documentFront,
      );

      if (result.isSuccess && result.data != null) {
        state = state.copyWith(
          state: AuthOperationState.success,
          user: result.data,
        );
        return true;
      } else {
        state = state.copyWith(
          state: AuthOperationState.error,
          errorMessage:
              result.failure?.message ?? 'Failed to upload ID document',
        );
        return false;
      }
    } on NetworkException catch (e) {
      state = state.copyWith(
        state: AuthOperationState.error,
        errorMessage: e.message,
      );
      return false;
    } on ServerException catch (e) {
      state = state.copyWith(
        state: AuthOperationState.error,
        errorMessage: e.message,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        state: AuthOperationState.error,
        errorMessage: 'Unexpected error during ID document upload',
      );
      return false;
    }
  }

  /// Upload ID document back
  Future<bool> uploadIdDocumentBack({
    required String idNumber,
    required File documentBack,
  }) async {
    state = state.copyWith(
      state: AuthOperationState.loading,
      errorMessage: null,
    );

    try {
      final result = await _repository.uploadIdDocumentBack(
        idNumber: idNumber,
        documentBack: documentBack,
      );

      if (result.isSuccess && result.data != null) {
        state = state.copyWith(
          state: AuthOperationState.success,
          user: result.data,
        );
        return true;
      } else {
        state = state.copyWith(
          state: AuthOperationState.error,
          errorMessage:
              result.failure?.message ?? 'Failed to upload ID document',
        );
        return false;
      }
    } on NetworkException catch (e) {
      state = state.copyWith(
        state: AuthOperationState.error,
        errorMessage: e.message,
      );
      return false;
    } on ServerException catch (e) {
      state = state.copyWith(
        state: AuthOperationState.error,
        errorMessage: e.message,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        state: AuthOperationState.error,
        errorMessage: 'Unexpected error during ID document upload',
      );
      return false;
    }
  }

  /// Fetch auth configuration
  Future<Map<String, dynamic>?> fetchConfig() async {
    final result = await _repository.fetchConfig();
    return result.isSuccess ? result.data : null;
  }
}

/// Main auth provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider));
});

/// Convenience provider to check if user is authenticated
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isAuthenticated;
});

/// Convenience provider to get current user
final currentUserProvider = Provider<UserEntity?>((ref) {
  return ref.watch(authProvider).user;
});

/// Convenience provider to get auth loading state
final isAuthLoadingProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).state == AuthOperationState.loading;
});

/// Convenience provider to get auth error
final authErrorProvider = Provider<String?>((ref) {
  return ref.watch(authProvider).errorMessage;
});
