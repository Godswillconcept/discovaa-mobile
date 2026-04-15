import 'package:discovaa/features/messaging/domain/entities/conversation.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;

abstract class MessagingRepository {
  Future<List<Conversation>> listThreads();
  Future<List<types.Message>> listMessages(String threadId);
  Future<types.Message> sendMessage(String threadId, String text);
  Future<void> markAsRead(String threadId);
  bool get lastThreadsFromCache;
}
