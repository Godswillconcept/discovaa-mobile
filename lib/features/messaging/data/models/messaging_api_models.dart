import 'package:discovaa/features/messaging/domain/entities/conversation.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;

class MessageThreadDto {
  final String id;
  final String title;
  final String? latestMessageContent;
  final DateTime? latestMessageCreatedAt;
  final int unreadCount;

  const MessageThreadDto({
    required this.id,
    required this.title,
    this.latestMessageContent,
    this.latestMessageCreatedAt,
    this.unreadCount = 0,
  });

  factory MessageThreadDto.fromJson(Map<String, dynamic> json) {
    return MessageThreadDto(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Conversation',
      latestMessageContent: json['latest_message_content']?.toString(),
      latestMessageCreatedAt:
          DateTime.tryParse(json['latest_message_created_at']?.toString() ?? ''),
      unreadCount: json['unread_count'] as int? ?? 0,
    );
  }
}

class MessageDto {
  final String id;
  final String threadId;
  final String? senderId;
  final String kind;
  final String content;
  final DateTime createdAt;

  const MessageDto({
    required this.id,
    required this.threadId,
    this.senderId,
    required this.kind,
    required this.content,
    required this.createdAt,
  });

  factory MessageDto.fromJson(Map<String, dynamic> json) {
    return MessageDto(
      id: json['id']?.toString() ?? '',
      threadId: json['thread']?.toString() ?? '',
      senderId: json['sender']?.toString(),
      kind: json['kind']?.toString() ?? 'TEXT',
      content: json['content']?.toString() ?? '',
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

Conversation mapThreadDto(MessageThreadDto dto) {
  return Conversation(
    id: dto.id,
    artisanId: dto.id,
    artisanName: dto.title,
    artisanAvatar: 'assets/images/placeholders/user_avatar.png',
    lastMessage: dto.latestMessageContent ?? 'No messages yet',
    lastMessageTime: dto.latestMessageCreatedAt ?? DateTime.now(),
    unreadCount: dto.unreadCount,
  );
}

types.Message mapMessageDto(MessageDto dto) {
  return types.TextMessage(
    author: types.User(id: dto.senderId ?? 'unknown'),
    createdAt: dto.createdAt.millisecondsSinceEpoch,
    id: dto.id,
    text: dto.content,
  );
}
