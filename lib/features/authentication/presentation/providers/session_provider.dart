import 'package:discovaa/features/authentication/presentation/providers/signup_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Holds the authenticated session state for the currently logged-in user.
/// This is the single source of truth for role-gated UI after login/registration.
/// It is separate from [signupProvider] which is only a registration flow state machine.
class SessionState {
  final UserRole role;
  final bool isLoggedIn;

  const SessionState({
    this.role = UserRole.user,
    this.isLoggedIn = false,
  });

  bool get isProvider => role.isProvider;

  SessionState copyWith({UserRole? role, bool? isLoggedIn}) {
    return SessionState(
      role: role ?? this.role,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
    );
  }
}

class SessionNotifier extends StateNotifier<SessionState> {
  SessionNotifier() : super(const SessionState());

  /// Call this after a successful login. Sets the authenticated role.
  void signIn(UserRole role) {
    state = SessionState(role: role, isLoggedIn: true);
  }

  /// Call this after registration completes (OTP + profile).
  void completeRegistration(UserRole role) {
    state = SessionState(role: role, isLoggedIn: true);
  }

  /// Sign out — clears session.
  void signOut() {
    state = const SessionState();
  }
}

final sessionProvider =
    StateNotifierProvider<SessionNotifier, SessionState>(
  (ref) => SessionNotifier(),
);
