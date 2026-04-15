import 'package:discovaa/core/constants/api_endpoints.dart';
import 'package:discovaa/core/network/api_helpers.dart';
import 'package:discovaa/core/network/dio_client.dart';
import 'package:discovaa/core/network/network_info.dart';
import 'package:discovaa/core/storage/hive_service.dart';
import 'package:discovaa/features/messaging/data/models/messaging_api_models.dart';
import 'package:discovaa/features/messaging/domain/entities/conversation.dart';
import 'package:discovaa/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;

class MessagingRepositoryImpl implements MessagingRepository {
  final DioClient _dioClient;
  final HiveService _hiveService;
  final NetworkInfo _networkInfo;
  bool _lastThreadsFromCache = false;

  MessagingRepositoryImpl({
    required DioClient dioClient,
    required HiveService hiveService,
    required NetworkInfo networkInfo,
  }) : _dioClient = dioClient,
       _hiveService = hiveService,
       _networkInfo = networkInfo;

  static const _threadsCacheKey = 'messaging.cache.threads';

  @override
  Future<List<Conversation>> listThreads() async {
    try {
      if (!await _networkInfo.isConnected) {
        final cached = _readCachedThreads();
        if (cached.isNotEmpty) {
          _lastThreadsFromCache = true;
          return cached;
        }
      }
      final response = await _dioClient.get(ApiEndpoints.messageThreads);
      final envelope = decodeListEnvelope(
        response,
        (item) => MessageThreadDto.fromJson(item),
      );
      final threads = envelope.data.map(mapThreadDto).toList(growable: false);
      await _hiveService.setList(
        _threadsCacheKey,
        threads
            .map((thread) => _conversationToJson(thread))
            .toList(growable: false),
      );
      _lastThreadsFromCache = false;
      return threads;
    } catch (_) {
      final cached = _readCachedThreads();
      if (cached.isNotEmpty) {
        _lastThreadsFromCache = true;
        return cached;
      }
      rethrow;
    }
  }

  @override
  Future<List<types.Message>> listMessages(String threadId) async {
    final cacheKey = '$_threadsCacheKey.messages.$threadId';
    try {
      if (!await _networkInfo.isConnected) {
        final cached = _readCachedMessages(cacheKey);
        if (cached.isNotEmpty) {
          return cached;
        }
      }
      final response = await _dioClient.get(
        ApiEndpoints.messagesV1,
        queryParameters: {'thread': threadId},
      );
      final envelope = decodeListEnvelope(
        response,
        (item) => MessageDto.fromJson(item),
      );
      final messages = envelope.data.map(mapMessageDto).toList(growable: false);
      await _hiveService.setList(
        cacheKey,
        messages
            .map((message) => _messageToJson(message, threadId))
            .toList(growable: false),
      );
      return messages;
    } catch (_) {
      final cached = _readCachedMessages(cacheKey);
      if (cached.isNotEmpty) {
        return cached;
      }
      rethrow;
    }
  }

  @override
  Future<types.Message> sendMessage(String threadId, String text) async {
    final response = await _dioClient.post(
      ApiEndpoints.messagesV1,
      data: {'thread': threadId, 'kind': 'TEXT', 'content': text},
    );
    final dto = decodeEnvelope(
      response,
      (raw) => MessageDto.fromJson(asMap(raw)),
    ).data;
    return mapMessageDto(dto);
  }

  @override
  Future<void> markAsRead(String threadId) async {
    await _dioClient.post(ApiEndpoints.threadMarkRead(threadId));
  }

  List<Conversation> _readCachedThreads() {
    final cached = _hiveService.getList<dynamic>(_threadsCacheKey) ?? const [];
    return cached
        .whereType<Map>()
        .map((item) => _conversationFromJson(item.cast<String, dynamic>()))
        .toList(growable: false);
  }

  List<types.Message> _readCachedMessages(String cacheKey) {
    final cached = _hiveService.getList<dynamic>(cacheKey) ?? const [];
    return cached
        .whereType<Map>()
        .map((item) => _messageFromJson(item.cast<String, dynamic>()))
        .toList(growable: false);
  }

  @override
  bool get lastThreadsFromCache => _lastThreadsFromCache;

  Map<String, dynamic> _conversationToJson(Conversation conversation) {
    return {
      'id': conversation.id,
      'artisanId': conversation.artisanId,
      'artisanName': conversation.artisanName,
      'artisanAvatar': conversation.artisanAvatar,
      'lastMessage': conversation.lastMessage,
      'lastMessageTime': conversation.lastMessageTime.toIso8601String(),
      'unreadCount': conversation.unreadCount,
      'isOnline': conversation.isOnline,
      'yearsInBusiness': conversation.yearsInBusiness,
      'hiresCount': conversation.hiresCount,
    };
  }

  Conversation _conversationFromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id']?.toString() ?? '',
      artisanId: json['artisanId']?.toString() ?? '',
      artisanName: json['artisanName']?.toString() ?? 'Conversation',
      artisanAvatar:
          json['artisanAvatar']?.toString() ??
          'assets/images/placeholders/user_avatar.png',
      lastMessage: json['lastMessage']?.toString() ?? 'No messages yet',
      lastMessageTime:
          DateTime.tryParse(json['lastMessageTime']?.toString() ?? '') ??
          DateTime.now(),
      unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
      isOnline: json['isOnline'] as bool? ?? false,
      yearsInBusiness: (json['yearsInBusiness'] as num?)?.toInt() ?? 0,
      hiresCount: (json['hiresCount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> _messageToJson(types.Message message, String threadId) {
    final text = message is types.TextMessage ? message.text : '';
    return {
      'id': message.id,
      'threadId': threadId,
      'senderId': message.author.id,
      'kind': 'TEXT',
      'content': text,
      'createdAt': DateTime.fromMillisecondsSinceEpoch(
        message.createdAt ?? DateTime.now().millisecondsSinceEpoch,
      ).toIso8601String(),
    };
  }

  types.Message _messageFromJson(Map<String, dynamic> json) {
    return types.TextMessage(
      author: types.User(id: json['senderId']?.toString() ?? 'unknown'),
      createdAt: DateTime.tryParse(
        json['createdAt']?.toString() ?? '',
      )?.millisecondsSinceEpoch,
      id: json['id']?.toString() ?? '',
      text: json['content']?.toString() ?? '',
    );
  }
}
