import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:discovaa/core/network/websocket_client.dart';
import 'package:discovaa/core/storage/secure_token_storage.dart';

/// WebSocket service for managing real-time communication
///
/// Provides a higher-level API over WebSocketClient for:
/// - Auto-subscription to user inbox
/// - Event type filtering
/// - Connection lifecycle management
class WebSocketService {
  final SecureTokenStorage _tokenStorage;
  WebSocketClient? _client;

  // Stream subscriptions for internal use
  StreamSubscription? _messageSubscription;
  StreamSubscription? _connectionSubscription;

  // Event stream controllers by type
  final _bookingStatusController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _paymentStatusController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  final _typingController = StreamController<Map<String, dynamic>>.broadcast();
  final _threadController = StreamController<Map<String, dynamic>>.broadcast();
  final _readReceiptController =
      StreamController<Map<String, dynamic>>.broadcast();

  // Active thread subscriptions
  final Set<String> _subscribedThreads = {};

  // User ID for inbox subscription
  String? _currentUserId;

  // Public streams
  Stream<Map<String, dynamic>> get bookingStatusStream =>
      _bookingStatusController.stream;
  Stream<Map<String, dynamic>> get paymentStatusStream =>
      _paymentStatusController.stream;
  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;
  Stream<Map<String, dynamic>> get typingStream => _typingController.stream;
  Stream<Map<String, dynamic>> get threadStream => _threadController.stream;
  Stream<Map<String, dynamic>> get readReceiptStream =>
      _readReceiptController.stream;
  Stream<WebSocketConnectionState> get connectionStateStream =>
      _client?.connectionStateStream ?? Stream.empty();
  WebSocketConnectionState get connectionState =>
      _client?.connectionState ?? WebSocketConnectionState.disconnected;

  WebSocketService({required SecureTokenStorage tokenStorage})
    : _tokenStorage = tokenStorage;

  /// Initialize and connect to WebSocket
  Future<void> initialize(String userId) async {
    _currentUserId = userId;

    if (_client != null) {
      await disconnect();
    }

    _client = WebSocketClient(tokenStorage: _tokenStorage);

    // Subscribe to connection state changes
    _connectionSubscription = _client!.connectionStateStream.listen((state) {
      if (state == WebSocketConnectionState.connected) {
        _onConnected();
      }
    });

    // Subscribe to messages
    _messageSubscription = _client!.messageStream.listen(
      _onMessage,
      onError: (error) =>
          debugPrint('[WebSocketService] Message error: $error'),
    );

    // Connect
    await _client!.connect();
  }

  /// Disconnect and cleanup
  Future<void> disconnect() async {
    debugPrint('[WebSocketService] Disconnecting...');

    await _messageSubscription?.cancel();
    _messageSubscription = null;

    await _connectionSubscription?.cancel();
    _connectionSubscription = null;

    _subscribedThreads.clear();

    _client?.dispose();
    _client = null;

    _currentUserId = null;
  }

  /// Subscribe to a message thread
  void subscribeToThread(String threadId) {
    if (_subscribedThreads.contains(threadId)) return;

    _subscribedThreads.add(threadId);
    _client?.subscribeToThread(threadId);
    debugPrint('[WebSocketService] Subscribed to thread: $threadId');
  }

  /// Unsubscribe from a message thread
  void unsubscribeFromThread(String threadId) {
    _subscribedThreads.remove(threadId);
    _client?.unsubscribeFromThread(threadId);
    debugPrint('[WebSocketService] Unsubscribed from thread: $threadId');
  }

  /// Send a text message
  void sendMessage(String threadId, String text) {
    _client?.send({
      'type': 'send_message',
      'thread_id': threadId,
      'content': text,
    });
  }

  /// Send typing start indicator
  void sendTypingStart(String threadId) {
    _client?.sendTypingStart(threadId);
  }

  /// Send typing stop indicator
  void sendTypingStop(String threadId) {
    _client?.sendTypingStop(threadId);
  }

  /// Mark messages as read
  void markMessagesAsRead(String threadId, List<String> messageIds) {
    _client?.markAsRead(threadId, messageIds);
  }

  /// Handle connection established
  void _onConnected() {
    debugPrint('[WebSocketService] Connected, subscribing to user inbox');

    // Subscribe to user inbox for general notifications
    if (_currentUserId != null) {
      _client?.send({'type': 'subscribe_inbox', 'user_id': _currentUserId});
    }

    // Re-subscribe to all active threads
    for (final threadId in _subscribedThreads) {
      _client?.subscribeToThread(threadId);
    }
  }

  /// Handle incoming message
  void _onMessage(Map<String, dynamic> message) {
    // Check for server error payload
    if (message['error'] == true) {
      final detail = message['detail'] as String? ?? 'Unknown error occurred';
      debugPrint('[WebSocketService] Server error: $detail');
      // Error handling - could add a dedicated error stream here
      return;
    }

    final eventType = message['event_type'] as String?;

    if (eventType == null) {
      debugPrint(
        '[WebSocketService] Received message without event_type: $message',
      );
      return;
    }

    debugPrint('[WebSocketService] Received event: $eventType');

    switch (eventType) {
      // Booking events
      case 'booking_status_changed':
      case 'booking_requested':
      case 'booking_confirmed':
      case 'booking_cancelled':
      case 'booking_completed':
      case 'booking_ongoing':
        _bookingStatusController.add(message);
        break;

      // Payment events
      case 'payment_status_changed':
      case 'payment_requires_action':
      case 'payment_authorized':
      case 'payment_captured':
      case 'payment_failed':
      case 'payment_refunded':
        _paymentStatusController.add(message);
        break;

      // Message events
      case 'message_created':
      case 'message_received':
        _messageController.add(message);
        break;

      // Typing events
      case 'typing_start':
      case 'typing_stop':
        _typingController.add(message);
        break;

      // Thread events
      case 'thread_created':
      case 'thread_updated':
        _threadController.add(message);
        break;

      // Read receipt events
      case 'message_status_updated':
      case 'messages_read':
        _readReceiptController.add(message);
        break;

      // Heartbeat/keepalive
      case 'pong':
        // Ignore pong responses
        break;

      default:
        debugPrint('[WebSocketService] Unknown event type: $eventType');
    }
  }

  /// Dispose of all resources
  void dispose() {
    disconnect();
    _bookingStatusController.close();
    _paymentStatusController.close();
    _messageController.close();
    _typingController.close();
    _threadController.close();
    _readReceiptController.close();
  }
}

/// Global WebSocket service instance getter
WebSocketService get webSocketService => GetIt.instance<WebSocketService>();
