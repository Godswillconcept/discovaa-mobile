/// User email preferences for different notification types
class EmailPreferences {
  final bool enabled;
  final Map<EmailCategory, bool> categoryPreferences;
  final EmailFrequency frequency;
  final DateTime? lastUpdated;

  EmailPreferences({
    this.enabled = true,
    Map<EmailCategory, bool>? categoryPreferences,
    this.frequency = EmailFrequency.immediate,
    this.lastUpdated,
  }) : categoryPreferences = categoryPreferences ?? {
    for (final category in EmailCategory.values) category: true,
  };

  EmailPreferences copyWith({
    bool? enabled,
    Map<EmailCategory, bool>? categoryPreferences,
    EmailFrequency? frequency,
    DateTime? lastUpdated,
  }) {
    return EmailPreferences(
      enabled: enabled ?? this.enabled,
      categoryPreferences: categoryPreferences ?? this.categoryPreferences,
      frequency: frequency ?? this.frequency,
      lastUpdated: lastUpdated ?? DateTime.now(),
    );
  }

  /// Check if emails are enabled for a specific category
  bool isCategoryEnabled(EmailCategory category) {
    return enabled && (categoryPreferences[category] ?? true);
  }

  /// Toggle email for a specific category
  EmailPreferences toggleCategory(EmailCategory category) {
    final newPreferences = Map<EmailCategory, bool>.from(categoryPreferences);
    newPreferences[category] = !(newPreferences[category] ?? true);
    return copyWith(categoryPreferences: newPreferences);
  }

  /// Enable/disable all emails
  EmailPreferences toggleAllEmails() {
    return copyWith(enabled: !enabled);
  }

  /// Enable all categories
  EmailPreferences enableAllCategories() {
    return copyWith(
      enabled: true,
      categoryPreferences: {
        for (final category in EmailCategory.values) category: true,
      },
    );
  }

  /// Disable all categories
  EmailPreferences disableAllCategories() {
    return copyWith(
      categoryPreferences: {
        for (final category in EmailCategory.values) category: false,
      },
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EmailPreferences &&
        other.enabled == enabled &&
        other.frequency == frequency &&
        _mapEquals(other.categoryPreferences, categoryPreferences);
  }

  @override
  int get hashCode {
    return enabled.hashCode ^
        frequency.hashCode ^
        categoryPreferences.hashCode;
  }

  @override
  String toString() {
    return 'EmailPreferences('
        'enabled: $enabled, '
        'frequency: $frequency, '
        'categories: $categoryPreferences'
        ')';
  }

  /// Helper method to compare maps
  bool _mapEquals<T, U>(Map<T, U> a, Map<T, U> b) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (a[key] != b[key]) return false;
    }
    return true;
  }
}

/// Email notification categories
enum EmailCategory {
  bookingUpdates,
  paymentUpdates,
  messaging,
  promotions,
  account,
  reviews,
  system,
}

/// Email frequency preferences
enum EmailFrequency {
  immediate,
  daily,
  weekly,
  never,
}

/// Extension methods for EmailCategory
extension EmailCategoryExtension on EmailCategory {
  String get displayName {
    switch (this) {
      case EmailCategory.bookingUpdates:
        return 'Booking Updates';
      case EmailCategory.paymentUpdates:
        return 'Payment Updates';
      case EmailCategory.messaging:
        return 'New Messages';
      case EmailCategory.promotions:
        return 'Promotions & Offers';
      case EmailCategory.account:
        return 'Account Updates';
      case EmailCategory.reviews:
        return 'Reviews & Feedback';
      case EmailCategory.system:
        return 'System Notifications';
    }
  }

  String get description {
    switch (this) {
      case EmailCategory.bookingUpdates:
        return 'Get notified about booking status changes, confirmations, and cancellations';
      case EmailCategory.paymentUpdates:
        return 'Receive payment confirmations, receipts, and transaction updates';
      case EmailCategory.messaging:
        return 'Email notifications for new messages from clients or providers';
      case EmailCategory.promotions:
        return 'Special offers, discounts, and promotional content';
      case EmailCategory.account:
        return 'Important account security and profile updates';
      case EmailCategory.reviews:
        return 'New reviews and feedback notifications';
      case EmailCategory.system:
        return 'System maintenance, updates, and important announcements';
    }
  }

  String get icon {
    switch (this) {
      case EmailCategory.bookingUpdates:
        return '📅';
      case EmailCategory.paymentUpdates:
        return '💳';
      case EmailCategory.messaging:
        return '💬';
      case EmailCategory.promotions:
        return '🎉';
      case EmailCategory.account:
        return '👤';
      case EmailCategory.reviews:
        return '⭐';
      case EmailCategory.system:
        return '🔔';
    }
  }
}

/// Extension methods for EmailFrequency
extension EmailFrequencyExtension on EmailFrequency {
  String get displayName {
    switch (this) {
      case EmailFrequency.immediate:
        return 'Immediately';
      case EmailFrequency.daily:
        return 'Daily Digest';
      case EmailFrequency.weekly:
        return 'Weekly Summary';
      case EmailFrequency.never:
        return 'Never';
    }
  }

  String get description {
    switch (this) {
      case EmailFrequency.immediate:
        return 'Receive emails as soon as events happen';
      case EmailFrequency.daily:
        return 'Get a daily summary of all notifications';
      case EmailFrequency.weekly:
        return 'Get a weekly summary of all notifications';
      case EmailFrequency.never:
        return 'No email notifications';
    }
  }
}
