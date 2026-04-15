import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/notification_entity.dart';
import '../providers/notifications_provider.dart';
import 'notification_list_widget.dart';
import 'system_update_widget.dart';

/// A draggable bottom sheet for displaying notifications
/// Can be shown from anywhere in the app
class NotificationBottomSheet extends ConsumerStatefulWidget {
  final VoidCallback onClose;
  final ScrollController? scrollController;

  const NotificationBottomSheet({
    super.key,
    required this.onClose,
    this.scrollController,
  });

  /// Helper method to show the bottom sheet from anywhere
  static Future<void> show(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          NotificationBottomSheet(onClose: () => Navigator.of(context).pop()),
    );
  }

  @override
  ConsumerState<NotificationBottomSheet> createState() =>
      _NotificationBottomSheetState();
}

class _NotificationBottomSheetState
    extends ConsumerState<NotificationBottomSheet> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.scrollController ?? ScrollController();
  }

  @override
  void dispose() {
    if (widget.scrollController == null) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedType = ref.watch(notificationTypeFilterProvider);
    final notificationsAsync = ref.watch(notificationsProvider);
    final filteredNotifications = ref.watch(filteredNotificationsProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              _buildHeader(),
              // Filter tabs
              _buildFilterTabs(selectedType),
              const Divider(height: 1),
              // Content
              Expanded(
                child: notificationsAsync.when(
                  data: (_) =>
                      _buildContent(selectedType, filteredNotifications),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => _buildErrorWidget(error),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Notifications',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          IconButton(
            onPressed: widget.onClose,
            icon: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs(NotificationType selectedType) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildTab(
            'All',
            selectedType == NotificationType.newMessage,
            () => _onTabChanged(NotificationType.newMessage),
          ),
          _buildTab(
            'Booking',
            selectedType == NotificationType.confirmedBooking,
            () => _onTabChanged(NotificationType.confirmedBooking),
          ),
          _buildTab(
            'News Update',
            selectedType == NotificationType.newsUpdate,
            () => _onTabChanged(NotificationType.newsUpdate),
          ),
          _buildTab(
            'System Update',
            selectedType == NotificationType.systemUpdate,
            () => _onTabChanged(NotificationType.systemUpdate),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String label, bool isSelected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? Colors.black : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: isSelected ? null : Border.all(color: Colors.grey.shade300),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey.shade600,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  void _onTabChanged(NotificationType type) {
    ref.read(notificationTypeFilterProvider.notifier).state = type;
  }

  Widget _buildErrorWidget(Object error) {
    // Determine error type and show appropriate message
    final errorMessage = error.toString();
    final isConnectionError = errorMessage.contains('CONNECTION_ERROR') ||
        errorMessage.contains('connection') ||
        errorMessage.contains('Failed host lookup');

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isConnectionError ? Icons.wifi_off : Icons.error_outline,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              isConnectionError
                  ? 'No internet connection'
                  : 'Failed to load notifications',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              isConnectionError
                  ? 'Please check your internet connection and try again'
                  : 'Something went wrong. Please try again.',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () {
                ref.invalidate(notificationsProvider);
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: TextButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
    NotificationType selectedType,
    List<NotificationEntity> notifications,
  ) {
    if (selectedType == NotificationType.systemUpdate) {
      return const SystemUpdateWidget();
    }

    return NotificationListWidget(
      notifications: notifications,
      scrollController: _scrollController,
    );
  }
}
