import 'package:flutter/material.dart';
import '../../domain/entities/notification_entity.dart';

class NotificationTabSelector extends StatelessWidget {
  final NotificationType selectedType;
  final ValueChanged<NotificationType> onTypeChanged;

  const NotificationTabSelector({
    super.key,
    required this.selectedType,
    required this.onTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      padding: const EdgeInsets.all(8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: NotificationType.values.map((type) {
          final isSelected = selectedType == type;
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: InkWell(
              onTap: () => onTypeChanged(type),
              borderRadius: BorderRadius.circular(25),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.black : Colors.transparent,
                  borderRadius: BorderRadius.circular(25),
                  border: isSelected
                      ? null
                      : Border.all(color: Colors.grey.shade300),
                ),
                alignment: Alignment.center,
                child: Text(
                  _getTypeLabel(type),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _getTypeLabel(NotificationType type) {
    switch (type) {
      case NotificationType.newMessage:
        return 'ISV\nMessages';
      case NotificationType.confirmedBooking:
        return 'BSV\nBookings';
      case NotificationType.newsUpdate:
        return 'News\nUpdate';
      case NotificationType.systemUpdate:
        return 'System\nUpdate';
    }
  }
}
