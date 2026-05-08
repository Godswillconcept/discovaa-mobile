import 'package:discovaa/features/notifications/domain/entities/email_preferences.dart';

/// Repository for managing email notifications and preferences
abstract class EmailRepository {
  /// Get user's email preferences
  Future<EmailPreferences> getEmailPreferences();

  /// Update user's email preferences
  Future<EmailPreferences> updateEmailPreferences(EmailPreferences preferences);

  /// Send a transactional email triggered by booking/payment/messaging events
  Future<void> sendTransactionalEmail({
    required String type,
    required Map<String, dynamic> context,
  });

  /// Get email delivery status for a specific notification
  Future<EmailDeliveryStatus> getEmailDeliveryStatus(String notificationId);

  /// Subscribe/unsubscribe from email notifications
  Future<void> setEmailSubscription({
    required bool subscribed,
    String? category, // If null, applies to all emails
  });

  /// Get email history (sent emails)
  Future<List<EmailHistoryItem>> getEmailHistory({
    int page = 1,
    int pageSize = 20,
    String? category,
  });
}

/// Email delivery status
enum EmailDeliveryStatus {
  pending,
  sent,
  delivered,
  opened,
  clicked,
  bounced,
  failed,
}

/// Email history item
class EmailHistoryItem {
  final String id;
  final String subject;
  final String category;
  final DateTime sentAt;
  final EmailDeliveryStatus status;
  final bool opened;
  final DateTime? openedAt;
  final bool clicked;
  final DateTime? clickedAt;

  EmailHistoryItem({
    required this.id,
    required this.subject,
    required this.category,
    required this.sentAt,
    required this.status,
    this.opened = false,
    this.openedAt,
    this.clicked = false,
    this.clickedAt,
  });
}
