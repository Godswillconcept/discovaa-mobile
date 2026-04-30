import 'package:connectivity_plus/connectivity_plus.dart';

/// Abstract interface for network connectivity information
abstract class NetworkInfo {
  /// Check if device has internet connection
  Future<bool> get isConnected;

  /// Get current connectivity result (v7 API returns List&lt;ConnectivityResult&gt;)
  Future<List<ConnectivityResult>> get connectivityResult;

  /// Stream of connectivity changes (v7 API returns List&lt;ConnectivityResult&gt;)
  Stream<List<ConnectivityResult>> get onConnectivityChanged;
}

/// Implementation of NetworkInfo using connectivity_plus package v5
class NetworkInfoImpl implements NetworkInfo {
  final Connectivity connectivity;

  NetworkInfoImpl({required this.connectivity});

  @override
  Future<bool> get isConnected async {
    final result = await connectivity.checkConnectivity();
    // v7 API returns List<ConnectivityResult>
    return !result.contains(ConnectivityResult.none);
  }

  @override
  Future<List<ConnectivityResult>> get connectivityResult async {
    return await connectivity.checkConnectivity();
  }

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged {
    return connectivity.onConnectivityChanged;
  }
}
