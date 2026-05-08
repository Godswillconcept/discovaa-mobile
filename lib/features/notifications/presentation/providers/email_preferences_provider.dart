import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:discovaa/app/dependency_injection/service_locator.dart';
import 'package:discovaa/features/notifications/data/repositories/email_repository_impl.dart';
import 'package:discovaa/features/notifications/domain/entities/email_preferences.dart';
import 'package:discovaa/features/notifications/domain/repositories/email_repository.dart';

// ---------------------------------------------------------------------------
// Email preferences state
// ---------------------------------------------------------------------------

enum EmailPreferencesLoadStatus { idle, loading, success, failure }

class EmailPreferencesState {
  final EmailPreferences preferences;
  final EmailPreferencesLoadStatus status;
  final String? errorMessage;

  EmailPreferencesState({
    required this.preferences,
    this.status = EmailPreferencesLoadStatus.idle,
    this.errorMessage,
  });

  EmailPreferencesState copyWith({
    EmailPreferences? preferences,
    EmailPreferencesLoadStatus? status,
    String? errorMessage,
  }) {
    return EmailPreferencesState(
      preferences: preferences ?? this.preferences,
      status: status ?? this.status,
      errorMessage: errorMessage,
    );
  }
}

// ---------------------------------------------------------------------------
// Email preferences notifier
// ---------------------------------------------------------------------------

class EmailPreferencesNotifier extends StateNotifier<EmailPreferencesState> {
  EmailPreferencesNotifier(this._repository)
    : super(EmailPreferencesState(preferences: EmailPreferences()));

  final EmailRepository _repository;

  /// Load email preferences from repository
  Future<void> loadPreferences() async {
    state = state.copyWith(status: EmailPreferencesLoadStatus.loading);

    try {
      final preferences = await _repository.getEmailPreferences();
      state = state.copyWith(
        preferences: preferences,
        status: EmailPreferencesLoadStatus.success,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        status: EmailPreferencesLoadStatus.failure,
        errorMessage: e.toString(),
      );
    }
  }

  /// Update email preferences
  Future<void> updatePreferences(EmailPreferences newPreferences) async {
    // Optimistic update
    state = state.copyWith(preferences: newPreferences);

    try {
      final updatedPreferences = await _repository.updateEmailPreferences(
        newPreferences,
      );
      state = state.copyWith(
        preferences: updatedPreferences,
        status: EmailPreferencesLoadStatus.success,
        errorMessage: null,
      );
    } catch (e) {
      // Revert on error
      state = state.copyWith(
        status: EmailPreferencesLoadStatus.failure,
        errorMessage: e.toString(),
      );
    }
  }

  /// Toggle master email switch
  Future<void> toggleMasterSwitch() async {
    final newPreferences = state.preferences.toggleAllEmails();
    await updatePreferences(newPreferences);
  }

  /// Toggle category preference
  Future<void> toggleCategory(EmailCategory category) async {
    final newPreferences = state.preferences.toggleCategory(category);
    await updatePreferences(newPreferences);
  }

  /// Update frequency
  Future<void> updateFrequency(EmailFrequency frequency) async {
    final newPreferences = state.preferences.copyWith(frequency: frequency);
    await updatePreferences(newPreferences);
  }

  /// Enable all categories
  Future<void> enableAllCategories() async {
    final newPreferences = state.preferences.enableAllCategories();
    await updatePreferences(newPreferences);
  }

  /// Disable all categories
  Future<void> disableAllCategories() async {
    final newPreferences = state.preferences.disableAllCategories();
    await updatePreferences(newPreferences);
  }

  /// Retry loading preferences
  Future<void> retry() async {
    await loadPreferences();
  }
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

/// Email repository provider
final emailRepositoryProvider = Provider<EmailRepository>((ref) {
  return EmailRepositoryImpl(dioClient: sl(), hiveService: sl());
});

/// Email preferences provider
final emailPreferencesProvider =
    StateNotifierProvider<EmailPreferencesNotifier, EmailPreferencesState>((
      ref,
    ) {
      return EmailPreferencesNotifier(ref.watch(emailRepositoryProvider));
    });

/// Convenience provider for just the preferences object
final emailPreferencesObjectProvider = Provider<EmailPreferences>((ref) {
  return ref.watch(emailPreferencesProvider).preferences;
});

/// Convenience provider for loading status
final emailPreferencesStatusProvider = Provider<EmailPreferencesLoadStatus>((
  ref,
) {
  return ref.watch(emailPreferencesProvider).status;
});
