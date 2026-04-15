import 'package:discovaa/shared/presentation/widgets/main_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/notification_entity.dart';
import '../providers/notifications_provider.dart';
import '../widgets/notification_tab_selector.dart';
import '../widgets/notification_list_widget.dart';
import '../widgets/system_update_widget.dart';

class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedType = ref.watch(notificationTypeFilterProvider);
    final filteredNotifications = ref.watch(filteredNotificationsProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          const MainHeader(),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Notifications',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                GestureDetector(
                  onTap: () {},
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.more_horiz,
                      color: Colors.black,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          NotificationTabSelector(
            selectedType: selectedType,
            onTypeChanged: (type) =>
                ref.read(notificationTypeFilterProvider.notifier).state = type,
          ),
          const Divider(height: 1),
          Expanded(
            child: selectedType == NotificationType.systemUpdate
                ? const SystemUpdateWidget()
                : NotificationListWidget(notifications: filteredNotifications),
          ),
        ],
      ),
    );
  }
}
