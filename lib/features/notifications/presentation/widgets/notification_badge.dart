import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/notifications_provider.dart';

/// A reactive badge widget that displays the unread notification count
/// Animates in/out based on count
class NotificationBadge extends ConsumerWidget {
  final Widget child;
  final double badgeSize;
  final Offset offset;

  const NotificationBadge({
    super.key,
    required this.child,
    this.badgeSize = 18,
    this.offset = const Offset(2, -2),
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(unreadNotificationsCountProvider);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        if (unreadCount > 0)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            top: offset.dy,
            right: offset.dx,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              height: badgeSize,
              width: unreadCount > 99 ? badgeSize + 10 : badgeSize,
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50), // Success green
                shape: unreadCount > 99 ? BoxShape.rectangle : BoxShape.circle,
                borderRadius: unreadCount > 99
                    ? BorderRadius.circular(badgeSize / 2)
                    : null,
                border: Border.all(color: Colors.black, width: 1.5),
              ),
              child: Center(
                child: Text(
                  unreadCount > 99 ? '99+' : unreadCount.toString(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: unreadCount > 99 ? 9 : 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// A specialized badge for the notification bell icon
class NotificationBellBadge extends ConsumerWidget {
  final VoidCallback onTap;
  final double iconSize;
  final Color iconColor;

  const NotificationBellBadge({
    super.key,
    required this.onTap,
    this.iconSize = 26,
    this.iconColor = Colors.white,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return NotificationBadge(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Icon(
            Icons.notifications_outlined,
            color: iconColor,
            size: iconSize,
          ),
        ),
      ),
    );
  }
}
