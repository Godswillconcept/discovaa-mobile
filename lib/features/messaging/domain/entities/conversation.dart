import 'package:equatable/equatable.dart';

class Conversation extends Equatable {
  final String id;
  final String artisanId;
  final String artisanName;
  final String artisanAvatar;
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;
  final bool isOnline;
  final int yearsInBusiness;
  final int hiresCount;

  const Conversation({
    required this.id,
    required this.artisanId,
    required this.artisanName,
    required this.artisanAvatar,
    required this.lastMessage,
    required this.lastMessageTime,
    this.unreadCount = 0,
    this.isOnline = false,
    this.yearsInBusiness = 0,
    this.hiresCount = 0,
  });

  @override
  List<Object?> get props => [
        id,
        artisanId,
        artisanName,
        artisanAvatar,
        lastMessage,
        lastMessageTime,
        unreadCount,
        isOnline,
        yearsInBusiness,
        hiresCount,
      ];

  Conversation copyWith({
    String? id,
    String? artisanId,
    String? artisanName,
    String? artisanAvatar,
    String? lastMessage,
    DateTime? lastMessageTime,
    int? unreadCount,
    bool? isOnline,
    int? yearsInBusiness,
    int? hiresCount,
  }) {
    return Conversation(
      id: id ?? this.id,
      artisanId: artisanId ?? this.artisanId,
      artisanName: artisanName ?? this.artisanName,
      artisanAvatar: artisanAvatar ?? this.artisanAvatar,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadCount: unreadCount ?? this.unreadCount,
      isOnline: isOnline ?? this.isOnline,
      yearsInBusiness: yearsInBusiness ?? this.yearsInBusiness,
      hiresCount: hiresCount ?? this.hiresCount,
    );
  }
}
