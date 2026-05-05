import 'package:discovaa/features/authentication/domain/entities/user_entity.dart';
import 'package:discovaa/features/authentication/presentation/providers/registration_flow_provider.dart';

/// Authentication status enum
enum AuthStatus {
  initial, // App just started, checking auth state
  unauthenticated, // No valid auth
  authenticated, // Fully authenticated with complete profile
  requiresProfile, // Authenticated but needs profile completion
  requiresVerification, // Provider needs ID verification
}

/// Unified authentication state
class AuthState {
  final AuthStatus status;
  final UserEntity? user;
  final String? errorMessage;
  final bool isLoading;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
    this.isLoading = false,
  });

  /// Helper getters
  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get needsProfile => status == AuthStatus.requiresProfile;
  bool get needsVerification => status == AuthStatus.requiresVerification;
  bool get isInitial => status == AuthStatus.initial;
  bool get isUnauthenticated => status == AuthStatus.unauthenticated;

  /// Get user role safely
  UserRole? get userRole {
    if (user == null) return null;
    final normalizedRole = user!.role.trim().toUpperCase();
    switch (normalizedRole) {
      case 'INDIVIDUAL':
        return UserRole.individualProvider;
      case 'BUSINESS':
        return UserRole.businessProvider;
      case 'USER':
        return UserRole.user;
      default:
        return null;
    }
  }

  /// Check if user is a provider (individual or business)
  bool get isProvider {
    final role = userRole;
    return role == UserRole.individualProvider ||
        role == UserRole.businessProvider;
  }

  AuthState copyWith({
    AuthStatus? status,
    UserEntity? user,
    String? errorMessage,
    bool? isLoading,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  String toString() {
    return 'AuthState(status: $status, user: ${user?.email}, isLoading: $isLoading)';
  }
}
