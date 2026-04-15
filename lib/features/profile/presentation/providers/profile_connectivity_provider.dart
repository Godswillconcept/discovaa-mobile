import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:discovaa/core/network/network_info.dart';

/// Connectivity state for profile operations
enum ProfileConnectivityState { connected, disconnected, checking, unknown }

/// Provider for profile-specific connectivity monitoring
final profileConnectivityProvider =
    StateNotifierProvider<
      ProfileConnectivityNotifier,
      ProfileConnectivityState
    >((ref) => ProfileConnectivityNotifier());

/// Notifier that monitors network connectivity for profile operations
class ProfileConnectivityNotifier
    extends StateNotifier<ProfileConnectivityState> {
  StreamSubscription<ConnectivityResult>? _subscription;
  NetworkInfo? _networkInfo;

  ProfileConnectivityNotifier() : super(ProfileConnectivityState.unknown) {
    _initConnectivity();
  }

  /// Initialize connectivity monitoring
  void _initConnectivity() async {
    state = ProfileConnectivityState.checking;

    try {
      _networkInfo = NetworkInfoImpl(connectivity: Connectivity());
      final isConnected = await _networkInfo!.isConnected;
      state = isConnected
          ? ProfileConnectivityState.connected
          : ProfileConnectivityState.disconnected;

      // Listen to connectivity changes
      _subscription = _networkInfo!.onConnectivityChanged.listen(
        _handleConnectivityChange,
        onError: (_) => state = ProfileConnectivityState.unknown,
      );
    } catch (e) {
      debugPrint('Error initializing connectivity: $e');
      state = ProfileConnectivityState.unknown;
    }
  }

  /// Handle connectivity changes
  void _handleConnectivityChange(ConnectivityResult result) {
    final hasConnection = result != ConnectivityResult.none;
    state = hasConnection
        ? ProfileConnectivityState.connected
        : ProfileConnectivityState.disconnected;
  }

  /// Check if currently connected
  Future<bool> checkConnection() async {
    state = ProfileConnectivityState.checking;
    try {
      if (_networkInfo != null) {
        final isConnected = await _networkInfo!.isConnected;
        state = isConnected
            ? ProfileConnectivityState.connected
            : ProfileConnectivityState.disconnected;
        return isConnected;
      }
      return false;
    } catch (e) {
      debugPrint('Error checking connectivity: $e');
      state = ProfileConnectivityState.unknown;
      return false;
    }
  }

  /// Show offline message helper
  String get offlineMessage {
    switch (state) {
      case ProfileConnectivityState.disconnected:
        return 'No internet connection. Changes will be saved locally and synced when online.';
      case ProfileConnectivityState.unknown:
        return 'Unable to check network status. Please try again.';
      default:
        return '';
    }
  }

  /// Check if can perform network operation
  bool get canProceed => state == ProfileConnectivityState.connected;

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

/// Widget to display connectivity status for profile
class ProfileConnectivityIndicator extends StatelessWidget {
  final ProfileConnectivityState state;
  final VoidCallback? onRetry;

  const ProfileConnectivityIndicator({
    super.key,
    required this.state,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (state == ProfileConnectivityState.connected ||
        state == ProfileConnectivityState.unknown) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: state == ProfileConnectivityState.disconnected
          ? Colors.red.shade50
          : Colors.orange.shade50,
      child: Row(
        children: [
          Icon(
            state == ProfileConnectivityState.disconnected
                ? Icons.wifi_off
                : Icons.pending,
            color: state == ProfileConnectivityState.disconnected
                ? Colors.red
                : Colors.orange,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              state == ProfileConnectivityState.disconnected
                  ? 'No internet connection'
                  : 'Checking connection...',
              style: TextStyle(
                color: state == ProfileConnectivityState.disconnected
                    ? Colors.red.shade800
                    : Colors.orange.shade800,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (onRetry != null && state == ProfileConnectivityState.disconnected)
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(0, 32),
              ),
              child: const Text('Retry'),
            ),
        ],
      ),
    );
  }
}
