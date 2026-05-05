import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:discovaa/core/storage/hive_service.dart';

/// State for identity verification reminder
class IdentityVerificationReminderState {
  final bool showReminder;
  final bool isVerified;
  final bool wasSkipped;
  final String? idType;
  final DateTime? skippedAt;

  const IdentityVerificationReminderState({
    this.showReminder = false,
    this.isVerified = false,
    this.wasSkipped = false,
    this.idType,
    this.skippedAt,
  });

  IdentityVerificationReminderState copyWith({
    bool? showReminder,
    bool? isVerified,
    bool? wasSkipped,
    String? idType,
    DateTime? skippedAt,
  }) {
    return IdentityVerificationReminderState(
      showReminder: showReminder ?? this.showReminder,
      isVerified: isVerified ?? this.isVerified,
      wasSkipped: wasSkipped ?? this.wasSkipped,
      idType: idType ?? this.idType,
      skippedAt: skippedAt ?? this.skippedAt,
    );
  }
}

/// Notifier to manage identity verification reminder state
class IdentityVerificationReminderNotifier
    extends StateNotifier<IdentityVerificationReminderState> {
  IdentityVerificationReminderNotifier()
    : super(const IdentityVerificationReminderState());

  Timer? _debounceTimer;
  static const Duration _debounceTime = Duration(milliseconds: 300);

  /// Check verification status and update reminder state
  /// Call this after user logs in
  Future<void> checkVerificationStatus() async {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceTime, () async {
      try {
        final hiveService = HiveService.instance;
        final data = hiveService.getMap('identity_verification');

        if (data != null) {
          final isVerified = data['isIdentityVerified'] as bool? ?? false;
          final wasSkipped = data['skippedVerification'] as bool? ?? false;
          final skippedAt = data['skippedAt'] != null
              ? DateTime.tryParse(data['skippedAt'] as String)
              : null;
          final idType = data['idType'] as String?;

          // Show reminder if not verified and not permanently skipped
          final showReminder = !isVerified && !wasSkipped;

          state = state.copyWith(
            showReminder: showReminder,
            isVerified: isVerified,
            wasSkipped: wasSkipped,
            idType: idType,
            skippedAt: skippedAt,
          );
        } else {
          // No verification data - show reminder for new users
          state = state.copyWith(showReminder: true);
        }
      } catch (error) {
        // Default to showing reminder if check fails
        state = state.copyWith(showReminder: true);
      } finally {
        _debounceTimer = null;
      }
    });
  }

  /// Mark reminder as dismissed (temporary)
  void dismissReminder() {
    state = state.copyWith(showReminder: false);
  }

  /// Permanently hide reminder (user doesn't want to see it again)
  Future<void> permanentlyDismiss() async {
    try {
      final hiveService = HiveService.instance;
      final data = hiveService.getMap('identity_verification') ?? {};

      await hiveService.setMap('identity_verification', {
        ...data,
        'skippedVerification': true,
        'skippedAt': DateTime.now().toIso8601String(),
      });

      state = state.copyWith(
        showReminder: false,
        wasSkipped: true,
        skippedAt: DateTime.now(),
      );
    } catch (e) {
      // Log error but don't crash the app
      debugPrint('Error saving reminder preference: $e');
      // Show user feedback that something went wrong
      state = state.copyWith(showReminder: false);
    }
  }

  /// Reset state (e.g., on logout)
  void reset() {
    _debounceTimer?.cancel();
    _debounceTimer = null;
    state = const IdentityVerificationReminderState();
  }

  /// Clean up resources
  @override
  void dispose() {
    _debounceTimer?.cancel();
    _debounceTimer = null;
    super.dispose();
  }
}

/// Provider for identity verification reminder
final identityVerificationReminderProvider =
    StateNotifierProvider<
      IdentityVerificationReminderNotifier,
      IdentityVerificationReminderState
    >((ref) => IdentityVerificationReminderNotifier());

/// Convenience provider to check if reminder should be shown
final showIdentityVerificationReminderProvider = Provider<bool>((ref) {
  return ref.watch(identityVerificationReminderProvider).showReminder;
});
