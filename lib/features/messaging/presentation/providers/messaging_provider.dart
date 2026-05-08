import 'dart:async';
import 'package:discovaa/features/messaging/domain/entities/conversation.dart';
import 'package:discovaa/app/dependency_injection/service_locator.dart';
import 'package:discovaa/core/network/dio_client.dart';
import 'package:discovaa/core/network/network_info.dart';
import 'package:discovaa/core/network/websocket_client.dart';
import 'package:discovaa/core/network/websocket_service.dart';
import 'package:discovaa/core/storage/hive_service.dart';
import 'package:discovaa/features/messaging/data/repositories/messaging_repository_impl.dart';
import 'package:discovaa/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:discovaa/features/notifications/domain/entities/email_preferences.dart';
import 'package:discovaa/features/notifications/presentation/providers/email_preferences_provider.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final messagingRepositoryProvider = Provider<MessagingRepository>((ref) {
  return MessagingRepositoryImpl(
    dioClient: sl<DioClient>(),
    hiveService: sl<HiveService>(),
    networkInfo: sl<NetworkInfo>(),
  );
});

final messagingProvider =
    StateNotifierProvider<MessagingNotifier, MessagingState>((ref) {
      return MessagingNotifier(
        ref.watch(messagingRepositoryProvider),
        sl<WebSocketService>(),
        ref,
      );
    });

class MessagingState {
  final List<Conversation> conversations;
  final Map<String, List<types.Message>> messages; // Keyed by conversationId
  final bool isLoading;
  final String searchQuery;
  final String? error;
  final bool isStale;
  final WebSocketConnectionState connectionState;
  final Set<String> typingUsers; // User IDs currently typing
  final String? currentTypingThreadId; // Thread where user is typing

  MessagingState({
    this.conversations = const [],
    this.messages = const {},
    this.isLoading = false,
    this.searchQuery = '',
    this.error,
    this.isStale = false,
    this.connectionState = WebSocketConnectionState.disconnected,
    this.typingUsers = const {},
    this.currentTypingThreadId,
  });

  MessagingState copyWith({
    List<Conversation>? conversations,
    Map<String, List<types.Message>>? messages,
    bool? isLoading,
    String? searchQuery,
    String? error,
    bool? isStale,
    WebSocketConnectionState? connectionState,
    Set<String>? typingUsers,
    String? currentTypingThreadId,
  }) {
    return MessagingState(
      conversations: conversations ?? this.conversations,
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      searchQuery: searchQuery ?? this.searchQuery,
      error: error,
      isStale: isStale ?? this.isStale,
      connectionState: connectionState ?? this.connectionState,
      typingUsers: typingUsers ?? this.typingUsers,
      currentTypingThreadId:
          currentTypingThreadId ?? this.currentTypingThreadId,
    );
  }

  List<Conversation> get filteredConversations {
    if (searchQuery.isEmpty) return conversations;
    return conversations
        .where(
          (c) =>
              c.artisanName.toLowerCase().contains(searchQuery.toLowerCase()) ||
              c.lastMessage.toLowerCase().contains(searchQuery.toLowerCase()),
        )
        .toList();
  }
}

class MessagingNotifier extends StateNotifier<MessagingState> {
  MessagingNotifier(this._repository, this._webSocketService, this._ref)
    : super(MessagingState()) {
    _loadData();
    _initWebSocket();
  }

  final MessagingRepository _repository;
  final WebSocketService _webSocketService;
  final Ref _ref;
  StreamSubscription? _messageSubscription;
  StreamSubscription? _connectionSubscription;
  StreamSubscription? _typingSubscription;
  Timer? _typingDebounceTimer;

  /// Initialize WebSocket listeners
  void _initWebSocket() {
    // Listen to connection state changes
    _connectionSubscription = _webSocketService.connectionStateStream.listen((
      connState,
    ) {
      state = state.copyWith(connectionState: connState);
    });

    // Listen to incoming messages
    _messageSubscription = _webSocketService.messageStream.listen(
      _onWebSocketMessage,
    );

    // Listen to typing indicators
    _typingSubscription = _webSocketService.typingStream.listen(_onTypingEvent);
  }

  /// Handle WebSocket message events
  void _onWebSocketMessage(Map<String, dynamic> message) {
    final eventType = message['event_type'] as String?;

    switch (eventType) {
      case 'message_created':
        _handleIncomingMessage(message);
        break;
      case 'thread_created':
        _handleNewThread(message);
        break;
      case 'message_status_updated':
        _handleMessageStatusUpdate(message);
        break;
    }
  }

  /// Handle incoming message from WebSocket
  void _handleIncomingMessage(Map<String, dynamic> message) {
    final threadId = message['thread_id'] as String?;
    final messageData = message['message'] as Map<String, dynamic>?;

    if (threadId == null || messageData == null) return;

    // Parse message and add to conversation
    final newMessage = types.TextMessage(
      id: messageData['id'] ?? DateTime.now().toIso8601String(),
      author: types.User(id: messageData['sender_id'] ?? 'other'),
      createdAt: messageData['created_at'] != null
          ? DateTime.parse(messageData['created_at']).millisecondsSinceEpoch
          : DateTime.now().millisecondsSinceEpoch,
      text: messageData['content'] ?? '',
    );

    final snippet = newMessage.text;
    final time = DateTime.fromMillisecondsSinceEpoch(newMessage.createdAt!);

    _addMessage(threadId, newMessage, snippet, time);

    // Send email alert for new message (if user prefers email notifications)
    try {
      final emailPrefs = _ref.read(emailPreferencesProvider).preferences;
      if (emailPrefs.isCategoryEnabled(EmailCategory.messaging)) {
        final emailRepo = _ref.read(emailRepositoryProvider);
        final content = messageData['content'] as String? ?? '';
        final preview = content.length > 50
            ? content.substring(0, 50)
            : content;
        emailRepo.sendTransactionalEmail(
          type: 'MESSAGE_RECEIVED',
          context: {
            'thread_id': threadId,
            'sender': messageData['sender_name'] ?? 'Unknown',
            'preview': preview,
          },
        );
      }
    } catch (e) {
      debugPrint('Failed to send message email: $e');
    }
  }

  /// Handle new thread creation
  void _handleNewThread(Map<String, dynamic> message) {
    final threadData = message['thread'] as Map<String, dynamic>?;
    if (threadData == null) return;

    final newConversation = Conversation(
      id: threadData['id'] ?? '',
      artisanId: threadData['other_user_id'] ?? '',
      artisanName: threadData['other_user_name'] ?? 'Unknown',
      artisanAvatar: threadData['other_user_avatar'] ?? '',
      lastMessage: threadData['last_message'] ?? 'New conversation',
      lastMessageTime: threadData['last_message_time'] != null
          ? DateTime.parse(threadData['last_message_time'])
          : DateTime.now(),
      unreadCount: 1,
    );

    // Add to conversations if not already present
    final existing = state.conversations
        .where((c) => c.id == newConversation.id)
        .toList();
    if (existing.isEmpty) {
      state = state.copyWith(
        conversations: [newConversation, ...state.conversations],
      );
    }
  }

  /// Handle message status updates (delivered/read)
  void _handleMessageStatusUpdate(Map<String, dynamic> data) {
    final threadId = data['thread'] as String?;
    final status = data['status'] as String?;
    final messageIds = data['message_ids'] as List<dynamic>?;

    if (threadId == null || status == null) return;

    final messages = state.messages[threadId];
    if (messages == null) return;

    // Map status string to types.Status
    types.Status? newStatus;
    switch (status) {
      case 'sent':
        newStatus = types.Status.sent;
        break;
      case 'delivered':
        newStatus = types.Status.delivered;
        break;
      case 'read':
        newStatus = types.Status.seen;
        break;
      default:
        return;
    }

    final newMessages = messages.map((msg) {
      if (messageIds?.contains(msg.id) == true) {
        return msg.copyWith(status: newStatus);
      }
      return msg;
    }).toList();

    state = state.copyWith(
      messages: {...state.messages, threadId: newMessages},
    );

    debugPrint(
      '[MessagingNotifier] Updated ${messageIds?.length ?? 0} messages to status: $status',
    );
  }

  /// Handle typing events
  void _onTypingEvent(Map<String, dynamic> event) {
    final eventType = event['event_type'] as String?;
    final userId = event['user_id'] as String?;
    final threadId = event['thread_id'] as String?;

    if (userId == null || threadId == null) return;

    final currentTyping = Set<String>.from(state.typingUsers);

    if (eventType == 'typing_start') {
      currentTyping.add(userId);
    } else if (eventType == 'typing_stop') {
      currentTyping.remove(userId);
    }

    state = state.copyWith(typingUsers: currentTyping);
  }

  /// Subscribe to a conversation thread
  void subscribeToConversation(String conversationId) {
    _webSocketService.subscribeToThread(conversationId);
  }

  /// Unsubscribe from a conversation thread
  void unsubscribeFromConversation(String conversationId) {
    _webSocketService.unsubscribeFromThread(conversationId);
  }

  /// Send typing start indicator (with debounce)
  void sendTypingStart(String conversationId) {
    if (state.currentTypingThreadId == conversationId) return;

    state = state.copyWith(currentTypingThreadId: conversationId);
    _webSocketService.sendTypingStart(conversationId);

    // Auto-stop typing after 3 seconds
    _typingDebounceTimer?.cancel();
    _typingDebounceTimer = Timer(const Duration(seconds: 3), () {
      sendTypingStop(conversationId);
    });
  }

  /// Send typing stop indicator
  void sendTypingStop(String conversationId) {
    _typingDebounceTimer?.cancel();
    state = state.copyWith(currentTypingThreadId: null);
    _webSocketService.sendTypingStop(conversationId);
  }

  Future<void> _loadData() async {
    state = state.copyWith(isLoading: true, error: null, isStale: false);
    try {
      final conversations = await _repository.listThreads();
      state = state.copyWith(
        conversations: conversations,
        isLoading: false,
        error: null,
        isStale: _repository.lastThreadsFromCache,
      );
      for (final conversation in conversations.take(1)) {
        final messages = await _repository.listMessages(conversation.id);
        state = state.copyWith(
          messages: {...state.messages, conversation.id: messages},
        );
      }
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load messages. Please try again.',
        isStale: false,
      );
    }
  }

  Future<void> refresh() async {
    await _loadData();
  }

  Future<void> sendMessage(String conversationId, String text) async {
    // Send via WebSocket if connected, otherwise fall back to REST API
    if (state.connectionState == WebSocketConnectionState.connected) {
      _webSocketService.sendMessage(conversationId, text);

      // Optimistically add message to UI
      final user = const types.User(id: 'user1');
      final now = DateTime.now();
      final optimisticMessage = types.TextMessage(
        id: 'temp_${now.millisecondsSinceEpoch}',
        author: user,
        createdAt: now.millisecondsSinceEpoch,
        text: text,
        status: types.Status.sending,
      );

      _addMessage(conversationId, optimisticMessage, text, now);

      // Stop typing indicator
      sendTypingStop(conversationId);
    } else {
      // Fall back to REST API
      final sent = await _repository.sendMessage(conversationId, text);
      final snippet = sent is types.TextMessage ? sent.text : text;
      _addMessage(
        conversationId,
        sent,
        snippet,
        DateTime.fromMillisecondsSinceEpoch(
          sent.createdAt ?? DateTime.now().millisecondsSinceEpoch,
        ),
      );
    }
  }

  void sendImageMessage(
    String conversationId,
    String imagePath,
    String imageName,
    int size, {
    double? width,
    double? height,
  }) {
    final user = const types.User(id: 'user1');
    final now = DateTime.now();
    final newMessage = types.ImageMessage(
      author: user,
      createdAt: now.millisecondsSinceEpoch,
      id: now.toIso8601String(),
      name: imageName,
      size: size,
      uri: imagePath,
      width: width,
      height: height,
    );

    _addMessage(conversationId, newMessage, '📸 Photo', now);
  }

  void sendFileMessage(
    String conversationId,
    String filePath,
    String fileName,
    int size, {
    String? mimeType,
  }) {
    final user = const types.User(id: 'user1');
    final now = DateTime.now();
    final newMessage = types.FileMessage(
      author: user,
      createdAt: now.millisecondsSinceEpoch,
      id: now.toIso8601String(),
      name: fileName,
      size: size,
      uri: filePath,
      mimeType: mimeType,
    );

    _addMessage(conversationId, newMessage, '📄 File: $fileName', now);
  }

  void _addMessage(
    String conversationId,
    types.Message message,
    String snippet,
    DateTime time,
  ) {
    final currentMessages = List<types.Message>.from(
      state.messages[conversationId] ?? [],
    );
    currentMessages.insert(0, message);

    final newMessagesMap = Map<String, List<types.Message>>.from(
      state.messages,
    );
    newMessagesMap[conversationId] = currentMessages;

    // Update conversation last message info
    final updatedConversations = state.conversations.map((c) {
      if (c.id == conversationId) {
        return c.copyWith(lastMessage: snippet, lastMessageTime: time);
      }
      return c;
    }).toList();

    state = state.copyWith(
      messages: newMessagesMap,
      conversations: updatedConversations,
    );
  }

  Future<void> markAsRead(String conversationId) async {
    // Use WebSocket if connected, otherwise fall back to REST API
    if (state.connectionState == WebSocketConnectionState.connected) {
      // Get message IDs that need to be marked as read
      final messages = state.messages[conversationId] ?? [];
      final unreadMessageIds = messages
          .where((m) => m.author.id != 'user1') // Not from current user
          .map((m) => m.id)
          .toList();

      if (unreadMessageIds.isNotEmpty) {
        _webSocketService.markMessagesAsRead(conversationId, unreadMessageIds);
      }
    } else {
      await _repository.markAsRead(conversationId);
    }

    final updatedConversations = state.conversations.map((c) {
      if (c.id == conversationId) {
        return c.copyWith(unreadCount: 0);
      }
      return c;
    }).toList();
    state = state.copyWith(conversations: updatedConversations);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void markAllAsRead() {
    final updatedConversations = state.conversations
        .map((c) => c.copyWith(unreadCount: 0))
        .toList();
    state = state.copyWith(conversations: updatedConversations);
  }

  /// Finds an existing conversation for [artisanId] or creates a new stub
  /// entry and returns it. Safe to call from UI before navigating to ChatPage.
  Conversation findOrCreateConversation({
    required String artisanId,
    required String artisanName,
    required String artisanAvatar,
  }) {
    final existing = state.conversations
        .where((c) => c.artisanId == artisanId)
        .toList();
    if (existing.isNotEmpty) return existing.first;

    final newConv = Conversation(
      id: 'conv_${artisanId}_${DateTime.now().millisecondsSinceEpoch}',
      artisanId: artisanId,
      artisanName: artisanName,
      artisanAvatar: artisanAvatar,
      lastMessage: 'Say hello!',
      lastMessageTime: DateTime.now(),
    );

    state = state.copyWith(conversations: [newConv, ...state.conversations]);
    return newConv;
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    _connectionSubscription?.cancel();
    _typingSubscription?.cancel();
    _typingDebounceTimer?.cancel();
    // Unsubscribe from all threads
    for (final conversation in state.conversations) {
      _webSocketService.unsubscribeFromThread(conversation.id);
    }
    super.dispose();
  }
}
