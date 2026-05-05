import 'package:discovaa/features/authentication/presentation/providers/auth_provider.dart';
import 'package:discovaa/features/authentication/presentation/providers/registration_flow_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Holds the authenticated session state for the currently logged-in user.
/// This is the single source of truth for role-gated UI after login/registration.
/// It is separate from [registrationFlowProvider] which is only a registration flow state machine.
class SessionState {
  final UserRole role;
  final bool isLoggedIn;
  final bool isInitialized;

  const SessionState({
    this.role = UserRole.user,
    this.isLoggedIn = false,
    this.isInitialized = false,
  });

  bool get isProvider => role.isProvider;

  SessionState copyWith({
    UserRole? role,
    bool? isLoggedIn,
    bool? isInitialized,
  }) {
    return SessionState(
      role: role ?? this.role,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }
}

class SessionNotifier extends StateNotifier<SessionState> {
  SessionNotifier() : super(const SessionState());

  /// Call this after a successful login. Sets the authenticated role.
  void signIn(UserRole role) {
    state = SessionState(role: role, isLoggedIn: true, isInitialized: true);
  }

  /// Call this after registration completes (OTP + profile).
  void completeRegistration(UserRole role) {
    state = SessionState(role: role, isLoggedIn: true, isInitialized: true);
  }

  /// Update role dynamically (e.g., after profile fetch completes)
  void updateRole(UserRole role) {
    state = state.copyWith(role: role, isInitialized: true);
  }

  /// Mark session as initialized with a known role
  /// Used when restoring session from persistent storage
  void restoreSession(UserRole role) {
    state = SessionState(role: role, isLoggedIn: true, isInitialized: true);
  }

  /// Sign out — clears session.
  void signOut() {
    state = const SessionState();
  }

  /// Mark initialization as complete without changing auth state
  void markInitialized() {
    state = state.copyWith(isInitialized: true);
  }
}

final sessionProvider = StateNotifierProvider<SessionNotifier, SessionState>(
  (ref) => SessionNotifier(),
);

/// Unified provider that resolves the effective user role.
///
/// This provider ensures the user's role is consistently derived from either:
/// 1. The session state (if already initialized, e.g., from storage)
/// 2. The current user entity from auth state (if available)
/// 3. Defaults to UserRole.user
///
/// This prevents race conditions and ensures UI elements like the bottom nav bar
/// and header avatar always display the correct role-based options.
final effectiveUserRoleProvider = Provider<UserRole>((ref) {
  final sessionState = ref.watch(sessionProvider);
  final authState = ref.watch(authProvider);

  // If session is initialized, trust its role (comes from persisted state)
  if (sessionState.isInitialized && sessionState.isLoggedIn) {
    return sessionState.role;
  }

  // Otherwise, derive from current user entity if available
  final user = authState.value?.user;
  if (user != null) {
    final roleStr = user.role.trim().toUpperCase();
    switch (roleStr) {
      case 'INDIVIDUAL':
        return UserRole.individualProvider;
      case 'BUSINESS':
        return UserRole.businessProvider;
      case 'ADMIN':
        return UserRole.user; // ADMIN treated as user for UI purposes
      default:
        return UserRole.user;
    }
  }

  // Fallback: session's role (which defaults to user)
  return sessionState.role;
});

/// Convenience provider to check if user is any kind of Service Provider
/// Both individual and business providers get the Services tab.
final isServiceProvider = Provider<bool>((ref) {
  final role = ref.watch(effectiveUserRoleProvider);
  return role == UserRole.individualProvider ||
      role == UserRole.businessProvider;
});

/// Convenience provider to check if user is specifically an Individual Service Provider
final isIndividualServiceProvider = Provider<bool>((ref) {
  final role = ref.watch(effectiveUserRoleProvider);
  return role == UserRole.individualProvider;
});

/// Convenience provider to check if user is specifically a Business Service Provider
final isBusinessServiceProvider = Provider<bool>((ref) {
  final role = ref.watch(effectiveUserRoleProvider);
  return role == UserRole.businessProvider;
});

/// Convenience provider to check if user is an ordinary user
final isOrdinaryUserProvider = Provider<bool>((ref) {
  final role = ref.watch(effectiveUserRoleProvider);
  return role == UserRole.user;
});
