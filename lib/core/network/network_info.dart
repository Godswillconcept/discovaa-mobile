import 'package:connectivity_plus/connectivity_plus.dart';

/// Abstract interface for network connectivity information
abstract class NetworkInfo {
  /// Check if device has internet connection
  Future<bool> get isConnected;

  /// Get current connectivity result (v5 API returns single ConnectivityResult)
  Future<ConnectivityResult> get connectivityResult;

  /// Stream of connectivity changes (v5 API returns single ConnectivityResult)
  Stream<ConnectivityResult> get onConnectivityChanged;
}

/// Implementation of NetworkInfo using connectivity_plus package v5
class NetworkInfoImpl implements NetworkInfo {
  final Connectivity connectivity;

  NetworkInfoImpl({required this.connectivity});

  @override
  Future<bool> get isConnected async {
    final result = await connectivity.checkConnectivity();
    // v5 API returns single ConnectivityResult
    return result != ConnectivityResult.none;
  }

  @override
  Future<ConnectivityResult> get connectivityResult async {
    return await connectivity.checkConnectivity();
  }

  @override
  Stream<ConnectivityResult> get onConnectivityChanged {
    return connectivity.onConnectivityChanged;
  }
}
