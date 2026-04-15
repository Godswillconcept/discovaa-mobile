import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:discovaa/app/dependency_injection/service_locator.dart';
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
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(state: AuthOperationState.loading, errorMessage: null);

    final result = await _repository.login(
      email: email,
      password: password,
    );

    if (result.isSuccess && result.data != null) {
      state = state.copyWith(
        state: AuthOperationState.success,
        user: result.data,
        isAuthenticated: true,
      );
      return true;
    } else {
      state = state.copyWith(
        state: AuthOperationState.error,
        errorMessage: result.failure?.message ?? 'Login failed',
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
    state = state.copyWith(state: AuthOperationState.loading, errorMessage: null);

    final registration = RegistrationEntity(
      email: email,
      password: password,
      role: role.name,
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
    state = state.copyWith(state: AuthOperationState.loading, errorMessage: null);

    final result = await _repository.verifyOtp(
      email: email,
      otpCode: otpCode,
    );

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
    state = state.copyWith(state: AuthOperationState.loading, errorMessage: null);

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
    state = state.copyWith(state: AuthOperationState.loading, errorMessage: null);

    final result = await _repository.logout();

    if (result.isSuccess) {
      state = const AuthState(); // Reset to initial state
      return true;
    } else {
      state = state.copyWith(
        state: AuthOperationState.error,
        errorMessage: result.failure?.message ?? 'Logout failed',
      );
      return false;
    }
  }

  /// Get current user
  Future<void> getCurrentUser() async {
    state = state.copyWith(state: AuthOperationState.loading, errorMessage: null);

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
    state = state.copyWith(state: AuthOperationState.loading, errorMessage: null);

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
    state = state.copyWith(state: AuthOperationState.loading, errorMessage: null);

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

  /// Clear error state
  void clearError() {
    state = state.copyWith(state: AuthOperationState.idle, errorMessage: null);
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
