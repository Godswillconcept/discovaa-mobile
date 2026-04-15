import 'package:discovaa/features/messaging/domain/entities/conversation.dart';
import 'package:discovaa/app/dependency_injection/service_locator.dart';
import 'package:discovaa/core/network/dio_client.dart';
import 'package:discovaa/core/network/network_info.dart';
import 'package:discovaa/core/storage/hive_service.dart';
import 'package:discovaa/features/messaging/data/repositories/messaging_repository_impl.dart';
import 'package:discovaa/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
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
      return MessagingNotifier(ref.watch(messagingRepositoryProvider));
    });

class MessagingState {
  final List<Conversation> conversations;
  final Map<String, List<types.Message>> messages; // Keyed by conversationId
  final bool isLoading;
  final String searchQuery;
  final String? error;
  final bool isStale;

  MessagingState({
    this.conversations = const [],
    this.messages = const {},
    this.isLoading = false,
    this.searchQuery = '',
    this.error,
    this.isStale = false,
  });

  MessagingState copyWith({
    List<Conversation>? conversations,
    Map<String, List<types.Message>>? messages,
    bool? isLoading,
    String? searchQuery,
    String? error,
    bool? isStale,
  }) {
    return MessagingState(
      conversations: conversations ?? this.conversations,
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      searchQuery: searchQuery ?? this.searchQuery,
      error: error,
      isStale: isStale ?? this.isStale,
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
  MessagingNotifier(this._repository) : super(MessagingState()) {
    _loadData();
  }

  final MessagingRepository _repository;

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
    await _repository.markAsRead(conversationId);
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
}
