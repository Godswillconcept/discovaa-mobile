import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:discovaa/features/authentication/presentation/providers/session_provider.dart';
import 'package:discovaa/features/authentication/presentation/providers/signup_provider.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
  });

  group('SessionProvider - Role Management', () {
    test('initial state is correct', () {
      final state = container.read(sessionProvider);
      expect(state.role, UserRole.user);
      expect(state.isLoggedIn, false);
      expect(state.isInitialized, false);
      expect(state.isProvider, false);
    });

    test('signIn sets role and loggedIn state correctly', () {
      container.read(sessionProvider.notifier).signIn(UserRole.individualProvider);
      final state = container.read(sessionProvider);
      expect(state.role, UserRole.individualProvider);
      expect(state.isLoggedIn, true);
      expect(state.isInitialized, true);
      expect(state.isProvider, true);
    });

    test('completeRegistration sets role and loggedIn state correctly', () {
      container.read(sessionProvider.notifier).completeRegistration(UserRole.businessProvider);
      final state = container.read(sessionProvider);
      expect(state.role, UserRole.businessProvider);
      expect(state.isLoggedIn, true);
      expect(state.isInitialized, true);
      expect(state.isProvider, true);
    });

    test('signOut clears state', () {
      container.read(sessionProvider.notifier).signIn(UserRole.individualProvider);
      container.read(sessionProvider.notifier).signOut();
      final state = container.read(sessionProvider);
      expect(state.role, UserRole.user);
      expect(state.isLoggedIn, false);
      expect(state.isInitialized, false);
      expect(state.isProvider, false);
    });

    test('updateRole updates role only', () {
      container.read(sessionProvider.notifier).signIn(UserRole.user);
      container.read(sessionProvider.notifier).updateRole(UserRole.individualProvider);
      final state = container.read(sessionProvider);
      expect(state.role, UserRole.individualProvider);
      expect(state.isLoggedIn, true);
      expect(state.isInitialized, true);
    });

    test('restoreSession sets correct state', () {
      container.read(sessionProvider.notifier).restoreSession(UserRole.businessProvider);
      final state = container.read(sessionProvider);
      expect(state.role, UserRole.businessProvider);
      expect(state.isLoggedIn, true);
      expect(state.isInitialized, true);
      expect(state.isProvider, true);
    });

    test('markInitialized sets isInitialized without changing other fields', () {
      container.read(sessionProvider.notifier).restoreSession(UserRole.individualProvider);
      container.read(sessionProvider.notifier).markInitialized();
      final state = container.read(sessionProvider);
      expect(state.isInitialized, true);
      expect(state.role, UserRole.individualProvider);
      expect(state.isLoggedIn, true);
    });

    test('isProvider returns true only for provider roles', () {
      container.read(sessionProvider.notifier).signIn(UserRole.user);
      expect(container.read(sessionProvider).isProvider, false);

      container.read(sessionProvider.notifier).signIn(UserRole.individualProvider);
      expect(container.read(sessionProvider).isProvider, true);

      container.read(sessionProvider.notifier).signIn(UserRole.businessProvider);
      expect(container.read(sessionProvider).isProvider, true);
    });

    test('completeRegistration sets isLoggedIn and isInitialized correctly', () {
      container.read(sessionProvider.notifier).completeRegistration(UserRole.user);
      final state = container.read(sessionProvider);
      expect(state.isLoggedIn, true);
      expect(state.isInitialized, true);
    });
    
    test('copyWith preserves unchanged fields', () {
      final original = SessionState(role: UserRole.individualProvider, isLoggedIn: true, isInitialized: true);
      final updated = original.copyWith(role: UserRole.user);
      expect(updated.role, UserRole.user);
      expect(updated.isLoggedIn, true);
      expect(updated.isInitialized, true);
    });
  });
}
