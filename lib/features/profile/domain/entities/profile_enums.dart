/// Account type for user classification
enum AccountType {
  user,
  provider,
  business;

  String get displayName {
    switch (this) {
      case AccountType.user:
        return 'User';
      case AccountType.provider:
        return 'Provider';
      case AccountType.business:
        return 'Business';
    }
  }

  bool get isProvider => this != AccountType.user;
}

/// Verification status for identity and business verification
enum VerificationStatus {
  pending,
  verified,
  rejected,
  unverified;

  String get displayName {
    switch (this) {
      case VerificationStatus.pending:
        return 'Pending';
      case VerificationStatus.verified:
        return 'Verified';
      case VerificationStatus.rejected:
        return 'Rejected';
      case VerificationStatus.unverified:
        return 'Unverified';
    }
  }

  String get colorHex {
    switch (this) {
      case VerificationStatus.pending:
        return '#F59E0B'; // Amber
      case VerificationStatus.verified:
        return '#10B981'; // Emerald
      case VerificationStatus.rejected:
        return '#EF4444'; // Red
      case VerificationStatus.unverified:
        return '#6B7280'; // Gray
    }
  }
}

/// Days of the week for availability
enum DayOfWeek {
  monday,
  tuesday,
  wednesday,
  thursday,
  friday,
  saturday,
  sunday;

  String get displayName {
    switch (this) {
      case DayOfWeek.monday:
        return 'Monday';
      case DayOfWeek.tuesday:
        return 'Tuesday';
      case DayOfWeek.wednesday:
        return 'Wednesday';
      case DayOfWeek.thursday:
        return 'Thursday';
      case DayOfWeek.friday:
        return 'Friday';
      case DayOfWeek.saturday:
        return 'Saturday';
      case DayOfWeek.sunday:
        return 'Sunday';
    }
  }

  String get shortName {
    return displayName.substring(0, 3);
  }
}

/// Payout account connection status
enum PayoutStatus {
  notConnected,
  pending,
  connected,
  active,
  disabled;

  String get displayName {
    switch (this) {
      case PayoutStatus.notConnected:
        return 'Not Connected';
      case PayoutStatus.pending:
        return 'Pending';
      case PayoutStatus.connected:
        return 'Connected';
      case PayoutStatus.active:
        return 'Active';
      case PayoutStatus.disabled:
        return 'Disabled';
    }
  }
}

/// Provider payout lifecycle status
enum ProviderPayoutStatus {
  requested,
  processing,
  paid,
  failed,
  cancelled;

  String get displayName {
    switch (this) {
      case ProviderPayoutStatus.requested:
        return 'Requested';
      case ProviderPayoutStatus.processing:
        return 'Processing';
      case ProviderPayoutStatus.paid:
        return 'Paid';
      case ProviderPayoutStatus.failed:
        return 'Failed';
      case ProviderPayoutStatus.cancelled:
        return 'Cancelled';
    }
  }
}
