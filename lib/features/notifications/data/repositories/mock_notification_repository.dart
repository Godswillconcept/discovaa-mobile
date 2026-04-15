import '../../domain/entities/notification_entity.dart';
import '../../domain/repositories/notification_repository.dart';

class MockNotificationRepository implements NotificationRepository {
  final List<NotificationEntity> _notifications = [
    // New Messages
    NotificationEntity(
      id: '1',
      type: NotificationType.newMessage,
      title: 'Jason Doe sent a message',
      subtitle:
          'Yes, I\'ll be available. Please send your address and contact details. I\'ll be expecting',
      timestamp: DateTime.now().subtract(const Duration(hours: 1)),
      imageUrl: 'assets/images/placeholders/artisan_01.png',
      extraData: {'conversationId': 'conv1'},
    ),
    NotificationEntity(
      id: '2',
      type: NotificationType.newMessage,
      title: 'Plum Plum... sent a message',
      subtitle:
          'Yes, I\'ll be available. Please send your address and contact details. I\'ll be expecting',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      imageUrl: 'assets/images/placeholders/artisan_02.png',
      extraData: {'conversationId': 'conv1'},
    ),
    NotificationEntity(
      id: '3',
      type: NotificationType.newMessage,
      title: 'Amber\'s Phot... sent a message',
      subtitle:
          'Yes, I\'ll be available. Please send your address and contact details. I\'ll be expecting',
      timestamp: DateTime.now().subtract(const Duration(hours: 12)),
      imageUrl: 'assets/images/placeholders/artisan_03.png',
      extraData: {'conversationId': 'conv1'},
    ),

    // Confirmed Bookings
    NotificationEntity(
      id: '4',
      type: NotificationType.confirmedBooking,
      title: 'Jason Doe confirmed booking for:',
      subtitle: 'Car Maintenance\nDate: 2nd February 2024\nTime: 8AM',
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      imageUrl: 'assets/images/placeholders/artisan_04.png',
    ),
    NotificationEntity(
      id: '5',
      type: NotificationType.confirmedBooking,
      title: 'Plum Plumbing Services... confirmed booking for:',
      subtitle: 'Plumbing\nDate: 2nd February 2024\nTime: 8AM',
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      imageUrl: 'assets/images/placeholders/artisan_05.png',
    ),

    // News Updates
    NotificationEntity(
      id: '6',
      type: NotificationType.newsUpdate,
      title: 'Jason Doe confirmed booking for:',
      subtitle: 'Car Maintenance\nDate: 2nd February 2024\nTime: 8AM',
      timestamp: DateTime.now().subtract(const Duration(days: 2)),
      imageUrl: 'assets/images/placeholders/artisan_06.png',
    ),

    // System Update
    NotificationEntity(
      id: '7',
      type: NotificationType.systemUpdate,
      title: 'System Update',
      subtitle: 'This update provides bug fixes for your system including...',
      timestamp: DateTime.now().subtract(const Duration(days: 3)),
      extraData: {
        'automaticUpdates': false,
        'downloadInProgress': true,
        'installOnceDownloaded': false,
      },
    ),
  ];

  @override
  Future<List<NotificationEntity>> getNotifications() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _notifications;
  }

  @override
  Future<void> markAsRead(String id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
    }
  }

  @override
  Future<void> markAllAsRead() async {
    for (var i = 0; i < _notifications.length; i++) {
      _notifications[i] = _notifications[i].copyWith(isRead: true);
    }
  }
}
