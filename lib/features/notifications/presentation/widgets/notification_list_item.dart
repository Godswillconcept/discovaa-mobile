import 'package:go_router/go_router.dart';
import 'package:discovaa/app/router/route_names.dart';
import 'package:discovaa/features/messaging/presentation/providers/messaging_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../domain/entities/notification_entity.dart';
import 'package:timeago/timeago.dart' as timeago;

class NotificationListItem extends ConsumerWidget {
  final NotificationEntity notification;
  final VoidCallback onTap;

  const NotificationListItem({
    super.key,
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: () {
        onTap(); // Mark as read
        _handleNavigation(context, ref);
      },
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.w),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 28.r,
              backgroundImage: notification.imageUrl != null
                  ? AssetImage(notification.imageUrl!)
                  : null,
              child: notification.imageUrl == null
                  ? const Icon(Icons.person)
                  : null,
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: TextStyle(color: Colors.black, fontSize: 16.sp),
                      children: [
                        TextSpan(
                          text: notification.title.split(' ')[0],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                          text:
                              ' ${notification.title.substring(notification.title.indexOf(' ') + 1)}',
                        ),
                        WidgetSpan(child: SizedBox(width: 8.w)),
                        TextSpan(
                          text: timeago.format(notification.timestamp),
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 14.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    notification.subtitle,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14.sp,
                      height: 1.3,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (!notification.isRead)
              Container(
                margin: EdgeInsets.only(top: 10.h, left: 8.w),
                width: 10.w,
                height: 10.w,
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _handleNavigation(BuildContext context, WidgetRef ref) {
    switch (notification.type) {
      case NotificationType.newMessage:
        // Navigate to ISV Messages Transcript (ChatPage)
        final conversationId =
            notification.extraData?['conversationId'] as String?;
        if (conversationId != null) {
          final messagingState = ref.read(messagingProvider);
          final conversation = messagingState.conversations.firstWhere(
            (c) => c.id == conversationId,
            orElse: () => messagingState.conversations.first,
          );
          context.push('${RouteNames.messages}/chat', extra: conversation);
        } else {
          context.push(RouteNames.messages);
        }
        break;
      case NotificationType.confirmedBooking:
        // Navigate to BSV context (Favorites)
        context.push(RouteNames.favorites);
        break;
      case NotificationType.newsUpdate:
      case NotificationType.systemUpdate:
        // Already on NotificationsPage, maybe show detail or do nothing
        break;
    }
  }
}
