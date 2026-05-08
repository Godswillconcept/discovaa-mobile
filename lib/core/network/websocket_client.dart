import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'package:discovaa/core/constants/api_endpoints.dart';
import 'package:discovaa/core/storage/secure_token_storage.dart';

/// Connection state for WebSocket
enum WebSocketConnectionState {
  disconnected,
  connecting,
  connected,
  reconnecting,
  error,
}

/// WebSocket client for real-time communication
///
/// Handles connection management, authentication, reconnection with
/// exponential backoff, and message dispatching.
class WebSocketClient {
  final SecureTokenStorage _tokenStorage;

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _reconnectTimer;
  Timer? _heartbeatTimer;

  // Connection state
  WebSocketConnectionState _connectionState =
      WebSocketConnectionState.disconnected;
  WebSocketConnectionState get connectionState => _connectionState;

  // Reconnection configuration
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 10;
  static const Duration _initialReconnectDelay = Duration(seconds: 1);
  static const Duration _maxReconnectDelay = Duration(seconds: 30);
  static const Duration _heartbeatInterval = Duration(seconds: 30);

  // Message queue for offline buffering
  final List<Map<String, dynamic>> _messageQueue = [];
  bool _isProcessingQueue = false;

  // Stream controllers for events
  final _connectionStateController =
      StreamController<WebSocketConnectionState>.broadcast();
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  final _errorController = StreamController<Exception>.broadcast();

  // Public streams
  Stream<WebSocketConnectionState> get connectionStateStream =>
      _connectionStateController.stream;
  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;
  Stream<Exception> get errorStream => _errorController.stream;

  // Base URL for WebSocket (convert HTTPS to WSS)
  String get _webSocketBaseUrl {
    final baseUrl = ApiEndpoints.baseUrl;
    if (baseUrl.startsWith('https://')) {
      return baseUrl.replaceFirst('https://', 'wss://');
    }
    return baseUrl.replaceFirst('http://', 'ws://');
  }

  WebSocketClient({required SecureTokenStorage tokenStorage})
    : _tokenStorage = tokenStorage;

  /// Connect to the WebSocket server
  Future<void> connect() async {
    if (_connectionState == WebSocketConnectionState.connecting ||
        _connectionState == WebSocketConnectionState.connected) {
      debugPrint('[WebSocketClient] Already connecting or connected');
      return;
    }

    _updateConnectionState(WebSocketConnectionState.connecting);

    try {
      final token = await _tokenStorage.getAccessToken();
      if (token == null || token.isEmpty) {
        throw Exception('No access token available for WebSocket connection');
      }

      final wsUrl = '$_webSocketBaseUrl/ws/chat/?access_token=$token';
      debugPrint('[WebSocketClient] Connecting to $wsUrl');

      // Create WebSocket connection
      if (kIsWeb) {
        _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      } else {
        _channel = IOWebSocketChannel.connect(
          Uri.parse(wsUrl),
          pingInterval: _heartbeatInterval,
        );
      }

      // Listen to messages
      _subscription = _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDisconnected,
        cancelOnError: false,
      );

      _updateConnectionState(WebSocketConnectionState.connected);
      _reconnectAttempts = 0;

      // Start heartbeat for web platform
      if (kIsWeb) {
        _startHeartbeat();
      }

      // Process any queued messages
      _processMessageQueue();

      debugPrint('[WebSocketClient] Connected successfully');
    } catch (e) {
      debugPrint('[WebSocketClient] Connection error: $e');
      _updateConnectionState(WebSocketConnectionState.error);
      _scheduleReconnect();
    }
  }

  /// Disconnect from the WebSocket server
  Future<void> disconnect() async {
    debugPrint('[WebSocketClient] Disconnecting...');

    _reconnectTimer?.cancel();
    _heartbeatTimer?.cancel();

    await _subscription?.cancel();
    _subscription = null;

    await _channel?.sink.close();
    _channel = null;

    _updateConnectionState(WebSocketConnectionState.disconnected);
    debugPrint('[WebSocketClient] Disconnected');
  }

  /// Send a message through the WebSocket
  void send(Map<String, dynamic> message) {
    if (_connectionState == WebSocketConnectionState.connected &&
        _channel != null) {
      try {
        final jsonMessage = jsonEncode(message);
        _channel!.sink.add(jsonMessage);
        debugPrint('[WebSocketClient] Message sent: $jsonMessage');
      } catch (e) {
        debugPrint('[WebSocketClient] Error sending message: $e');
        // Queue message for retry
        _messageQueue.add(message);
      }
    } else {
      // Queue message for later
      debugPrint('[WebSocketClient] Connection not available, queuing message');
      _messageQueue.add(message);
    }
  }

  /// Subscribe to a specific thread/channel
  void subscribeToThread(String threadId) {
    send({'type': 'subscribe', 'thread_id': threadId});
  }

  /// Unsubscribe from a specific thread/channel
  void unsubscribeFromThread(String threadId) {
    send({'type': 'unsubscribe', 'thread_id': threadId});
  }

  /// Send typing indicator
  void sendTypingStart(String threadId) {
    send({'type': 'typing_start', 'thread_id': threadId});
  }

  /// Send typing stop indicator
  void sendTypingStop(String threadId) {
    send({'type': 'typing_stop', 'thread_id': threadId});
  }

  /// Send message status update (delivered/read)
  void sendMessageStatusUpdate(
    String threadId,
    String status,
    List<String> messageIds,
  ) {
    send({
      'type': 'update_message_status',
      'thread': threadId,
      'status': status,
      'message_ids': messageIds,
    });
  }

  /// Mark messages as read (legacy - use sendMessageStatusUpdate instead)
  void markAsRead(String threadId, List<String> messageIds) {
    sendMessageStatusUpdate(threadId, 'read', messageIds);
  }

  /// Handle incoming message
  void _onMessage(dynamic data) {
    try {
      final message = jsonDecode(data as String) as Map<String, dynamic>;
      debugPrint('[WebSocketClient] Received: $message');
      _messageController.add(message);
    } catch (e) {
      debugPrint('[WebSocketClient] Error parsing message: $e');
    }
  }

  /// Handle connection error
  void _onError(dynamic error) {
    debugPrint('[WebSocketClient] Error: $error');
    if (error is Exception) {
      _errorController.add(error);
    } else {
      _errorController.add(Exception(error.toString()));
    }
    _updateConnectionState(WebSocketConnectionState.error);
    _scheduleReconnect();
  }

  /// Handle disconnection
  void _onDisconnected() {
    debugPrint('[WebSocketClient] Connection closed');
    if (_connectionState != WebSocketConnectionState.disconnected) {
      _updateConnectionState(WebSocketConnectionState.disconnected);
      _scheduleReconnect();
    }
  }

  /// Schedule reconnection with exponential backoff
  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      debugPrint('[WebSocketClient] Max reconnection attempts reached');
      return;
    }

    _reconnectAttempts++;
    final delay = Duration(
      milliseconds:
          (_initialReconnectDelay.inMilliseconds *
                  (1 << (_reconnectAttempts - 1)))
              .clamp(
                _initialReconnectDelay.inMilliseconds,
                _maxReconnectDelay.inMilliseconds,
              ),
    );

    debugPrint(
      '[WebSocketClient] Scheduling reconnect in ${delay.inSeconds}s (attempt $_reconnectAttempts/$_maxReconnectAttempts)',
    );

    _updateConnectionState(WebSocketConnectionState.reconnecting);

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () {
      if (_connectionState != WebSocketConnectionState.connected) {
        connect();
      }
    });
  }

  /// Start heartbeat for web platform
  /// Start heartbeat for web platform
  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (timer) {
      if (_connectionState == WebSocketConnectionState.connected) {
        send({'type': 'ping'});
      }
    });
  }

  /// Process queued messages
  void _processMessageQueue() async {
    if (_isProcessingQueue || _messageQueue.isEmpty) return;

    _isProcessingQueue = true;

    while (_messageQueue.isNotEmpty &&
        _connectionState == WebSocketConnectionState.connected) {
      final message = _messageQueue.removeAt(0);
      send(message);
      await Future.delayed(const Duration(milliseconds: 100));
    }

    _isProcessingQueue = false;
  }

  /// Update connection state and notify listeners
  void _updateConnectionState(WebSocketConnectionState state) {
    if (_connectionState != state) {
      _connectionState = state;
      _connectionStateController.add(state);
      debugPrint('[WebSocketClient] State changed to: $state');
    }
  }

  /// Dispose of resources
  void dispose() {
    disconnect();
    _connectionStateController.close();
    _messageController.close();
    _errorController.close();
  }
}
