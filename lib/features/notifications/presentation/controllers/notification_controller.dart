import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/repositories/notification_repository.dart';

/// State class for notification controller
class NotificationState {
  final bool isBottomSheetVisible;
  final bool isLoading;
  final String? errorMessage;
  final bool isOffline;
  final List<String> pendingActions;

  const NotificationState({
    this.isBottomSheetVisible = false,
    this.isLoading = false,
    this.errorMessage,
    this.isOffline = false,
    this.pendingActions = const [],
  });

  NotificationState copyWith({
    bool? isBottomSheetVisible,
    bool? isLoading,
    String? errorMessage,
    bool? isOffline,
    List<String>? pendingActions,
  }) {
    return NotificationState(
      isBottomSheetVisible: isBottomSheetVisible ?? this.isBottomSheetVisible,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      isOffline: isOffline ?? this.isOffline,
      pendingActions: pendingActions ?? this.pendingActions,
    );
  }
}

/// Global controller for managing notification bottom sheet state and actions
class NotificationController extends StateNotifier<NotificationState> {
  final NotificationRepository _repository;

  // Callback to show bottom sheet - set by UI
  VoidCallback? _showBottomSheetCallback;
  VoidCallback? _hideBottomSheetCallback;

  NotificationController(this._repository) : super(const NotificationState());

  /// Register callbacks for showing/hiding bottom sheet
  void registerCallbacks({
    required VoidCallback showCallback,
    required VoidCallback hideCallback,
  }) {
    _showBottomSheetCallback = showCallback;
    _hideBottomSheetCallback = hideCallback;
  }

  /// Show the notification bottom sheet
  void showBottomSheet() {
    _showBottomSheetCallback?.call();
    state = state.copyWith(isBottomSheetVisible: true);
  }

  /// Hide the notification bottom sheet
  void hideBottomSheet() {
    _hideBottomSheetCallback?.call();
    state = state.copyWith(isBottomSheetVisible: false);
  }

  /// Mark a single notification as read
  Future<void> markAsRead(String id) async {
    if (state.isOffline) {
      _queueAction('markAsRead:$id');
      return;
    }

    try {
      await _repository.markAsRead(id);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to mark as read');
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    if (state.isOffline) {
      _queueAction('markAllAsRead');
      return;
    }

    try {
      await _repository.markAllAsRead();
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to mark all as read');
    }
  }

  /// Handle connectivity changes
  void handleConnectivityChange(bool isConnected) {
    final wasOffline = state.isOffline;
    state = state.copyWith(isOffline: !isConnected);

    // If reconnected and was offline, process pending actions
    if (isConnected && wasOffline && state.pendingActions.isNotEmpty) {
      _processPendingActions();
    }
  }

  /// Queue an action for when connection is restored
  void _queueAction(String action) {
    final updatedPending = [...state.pendingActions, action];
    state = state.copyWith(pendingActions: updatedPending);
  }

  /// Process all pending actions
  Future<void> _processPendingActions() async {
    for (final action in state.pendingActions) {
      if (action.startsWith('markAsRead:')) {
        final id = action.split(':')[1];
        await markAsRead(id);
      } else if (action == 'markAllAsRead') {
        await markAllAsRead();
      }
    }
    state = state.copyWith(pendingActions: const []);
  }

  /// Clear any error message
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  /// Dispose callbacks
  @override
  void dispose() {
    _showBottomSheetCallback = null;
    _hideBottomSheetCallback = null;
    super.dispose();
  }
}
