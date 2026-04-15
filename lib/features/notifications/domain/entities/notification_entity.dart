enum NotificationType {
  newMessage, // ISV
  confirmedBooking, // BSV
  newsUpdate,
  systemUpdate,
}

class NotificationEntity {
  final String id;
  final NotificationType type;
  final String title;
  final String subtitle;
  final DateTime timestamp;
  final bool isRead;
  final String? imageUrl;
  final Map<String, dynamic>? extraData;

  NotificationEntity({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.timestamp,
    this.isRead = false,
    this.imageUrl,
    this.extraData,
  });

  NotificationEntity copyWith({bool? isRead}) {
    return NotificationEntity(
      id: id,
      type: type,
      title: title,
      subtitle: subtitle,
      timestamp: timestamp,
      isRead: isRead ?? this.isRead,
      imageUrl: imageUrl,
      extraData: extraData,
    );
  }
}
