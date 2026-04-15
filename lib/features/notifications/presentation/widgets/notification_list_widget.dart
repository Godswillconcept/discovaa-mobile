import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/notification_entity.dart';
import '../providers/notifications_provider.dart';
import 'notification_list_item.dart';

class NotificationListWidget extends ConsumerWidget {
  final List<NotificationEntity> notifications;
  final ScrollController? scrollController;

  const NotificationListWidget({
    super.key,
    required this.notifications,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (notifications.isEmpty) {
      return const Center(child: Text('No notifications in this category'));
    }

    // Group by Latest and Previous (e.g., last 24 hours)
    final now = DateTime.now();
    final latest = notifications
        .where((n) => now.difference(n.timestamp).inHours < 24)
        .toList();
    final previous = notifications
        .where((n) => now.difference(n.timestamp).inHours >= 24)
        .toList();

    return ListView(
      controller: scrollController,
      children: [
        if (latest.isNotEmpty) ...[
          _buildHeader(context, 'LATEST', ref),
          ...latest.map(
            (n) => NotificationListItem(
              notification: n,
              onTap: () =>
                  ref.read(notificationsProvider.notifier).markAsRead(n.id),
            ),
          ),
        ],
        if (previous.isNotEmpty) ...[
          _buildHeader(context, 'PREVIOUS', null),
          ...previous.map(
            (n) => NotificationListItem(
              notification: n,
              onTap: () =>
                  ref.read(notificationsProvider.notifier).markAsRead(n.id),
            ),
          ),
        ],
        const SizedBox(height: 40),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            children: [
              Icon(Icons.error_outline, size: 32, color: Colors.grey),
              SizedBox(height: 8),
              Text(
                'That\'s all your notifications from the last 30 days.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, String title, WidgetRef? ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          if (ref != null)
            TextButton(
              onPressed: () =>
                  ref.read(notificationsProvider.notifier).markAllAsRead(),
              child: const Text(
                'Mark all as read',
                style: TextStyle(color: Colors.grey),
              ),
            ),
        ],
      ),
    );
  }
}
