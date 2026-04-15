import 'package:discovaa/features/notifications/domain/entities/notification_entity.dart';

class NotificationDto {
  final String id;
  final String type;
  final String title;
  final String? body;
  final bool isRead;
  final DateTime createdAt;
  final Map<String, dynamic>? data;

  const NotificationDto({
    required this.id,
    required this.type,
    required this.title,
    this.body,
    required this.isRead,
    required this.createdAt,
    this.data,
  });

  factory NotificationDto.fromJson(Map<String, dynamic> json) {
    final isReadRaw = json['is_read'];
    return NotificationDto(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? 'SYSTEM_UPDATE',
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString(),
      isRead: isReadRaw == true || isReadRaw?.toString().toLowerCase() == 'true',
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      data: json['data'] is Map<String, dynamic>
          ? json['data'] as Map<String, dynamic>
          : null,
    );
  }
}

NotificationEntity mapNotificationDto(NotificationDto dto) {
  return NotificationEntity(
    id: dto.id,
    type: _notificationType(dto.type),
    title: dto.title,
    subtitle: dto.body ?? '',
    timestamp: dto.createdAt,
    isRead: dto.isRead,
    extraData: dto.data,
  );
}

NotificationType _notificationType(String raw) {
  switch (raw.toUpperCase()) {
    case 'NEWS_UPDATE':
      return NotificationType.newsUpdate;
    case 'SYSTEM_UPDATE':
      return NotificationType.systemUpdate;
    default:
      return NotificationType.confirmedBooking;
  }
}
