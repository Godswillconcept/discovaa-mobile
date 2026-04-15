import 'package:discovaa/app/dependency_injection/service_locator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/repositories/notification_repository.dart';
import '../../data/repositories/remote_notification_repository.dart';
import '../controllers/notification_controller.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return RemoteNotificationRepository(dioClient: sl());
});

final notificationsProvider =
    AsyncNotifierProvider<NotificationsNotifier, List<NotificationEntity>>(() {
      return NotificationsNotifier();
    });

class NotificationsNotifier extends AsyncNotifier<List<NotificationEntity>> {
  @override
  Future<List<NotificationEntity>> build() async {
    return ref.watch(notificationRepositoryProvider).getNotifications();
  }

  Future<void> markAsRead(String id) async {
    await ref.read(notificationRepositoryProvider).markAsRead(id);
    state = AsyncData(
      state.value!
          .map((n) => n.id == id ? n.copyWith(isRead: true) : n)
          .toList(),
    );
  }

  Future<void> markAllAsRead() async {
    await ref.read(notificationRepositoryProvider).markAllAsRead();
    state = AsyncData(
      state.value!.map((n) => n.copyWith(isRead: true)).toList(),
    );
  }
}

final notificationTypeFilterProvider = StateProvider<NotificationType>(
  (ref) => NotificationType.newMessage,
);

// Filtered Notifications Provider
final filteredNotificationsProvider = Provider<List<NotificationEntity>>((ref) {
  final notificationsAsync = ref.watch(notificationsProvider);
  final filter = ref.watch(notificationTypeFilterProvider);

  // Only filter when we have actual data
  return notificationsAsync.when(
    data: (notifications) =>
        notifications.where((n) => n.type == filter).toList(),
    loading: () => [],
    error: (_, _) => [],
  );
});

// Unread Count Provider (computed from notifications)
final unreadNotificationsCountProvider = Provider<int>((ref) {
  final notificationsAsync = ref.watch(notificationsProvider);

  // Handle all async states properly
  return notificationsAsync.when(
    data: (notifications) => notifications.where((n) => !n.isRead).length,
    loading: () => 0,
    error: (_, _) => 0,
  );
});

// Check if there are any unread notifications
final hasUnreadNotificationsProvider = Provider<bool>((ref) {
  return ref.watch(unreadNotificationsCountProvider) > 0;
});

// Notification Controller Provider (for global state management)
final notificationControllerProvider =
    StateNotifierProvider<NotificationController, NotificationState>((ref) {
      final repository = ref.watch(notificationRepositoryProvider);
      return NotificationController(repository);
    });
