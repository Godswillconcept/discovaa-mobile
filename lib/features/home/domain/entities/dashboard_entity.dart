import 'package:flutter/material.dart';

/// Spending trend data point entity
class SpendingTrendDataPoint {
  final DateTime date;
  final double amount;

  const SpendingTrendDataPoint({required this.date, required this.amount});
}

/// Spending trend entity
class SpendingTrendEntity {
  final List<SpendingTrendDataPoint> points;
  final double totalAmount;
  final double? percentageChange;
  final String periodLabel;

  const SpendingTrendEntity({
    required this.points,
    required this.totalAmount,
    this.percentageChange,
    required this.periodLabel,
  });

  bool get isEmpty => points.isEmpty;
  bool get hasData => points.isNotEmpty;
}

/// Booking status mix entity
class BookingMixEntity {
  final int requested;
  final int confirmed;
  final int completed;
  final int cancelled;
  final int total;

  const BookingMixEntity({
    required this.requested,
    required this.confirmed,
    required this.completed,
    required this.cancelled,
    required this.total,
  });

  double get requestedPercentage => total > 0 ? (requested / total) * 100 : 0;
  double get confirmedPercentage => total > 0 ? (confirmed / total) * 100 : 0;
  double get completedPercentage => total > 0 ? (completed / total) * 100 : 0;
  double get cancelledPercentage => total > 0 ? (cancelled / total) * 100 : 0;

  bool get isEmpty => total == 0;
  bool get hasData => total > 0;
}

/// Dashboard KPI entity
class DashboardKpiEntity {
  final double totalRevenue;
  final double totalSpend;
  final int completedBookings;
  final int cancelledBookings;
  final int upcomingCount;
  final int activeRequests;
  final double avgRating;
  final int reviewCount;
  final int unreadMessages;
  final int pendingMessages;
  final String? currency;

  const DashboardKpiEntity({
    this.totalRevenue = 0.0,
    this.totalSpend = 0.0,
    this.completedBookings = 0,
    this.cancelledBookings = 0,
    this.upcomingCount = 0,
    this.activeRequests = 0,
    this.avgRating = 0.0,
    this.reviewCount = 0,
    this.unreadMessages = 0,
    this.pendingMessages = 0,
    this.currency,
  });

  String get formattedAvgRating => avgRating.toStringAsFixed(1);
  String get formattedTotalRevenue => _formatCurrency(totalRevenue);
  String get formattedTotalSpend => _formatCurrency(totalSpend);

  String _formatCurrency(double amount) {
    final symbol = currency == 'USD' ? '\$' : (currency ?? '\$');
    return '$symbol${amount.toStringAsFixed(2)}';
  }
}

/// Smart insight entity
class InsightEntity {
  final String id;
  final String title;
  final String description;
  final String? actionLabel;
  final String? actionRoute;
  final IconData? icon;
  final String type;

  const InsightEntity({
    required this.id,
    required this.title,
    required this.description,
    this.actionLabel,
    this.actionRoute,
    this.icon,
    this.type = 'info',
  });
}

/// Recent booking entity
class RecentBookingEntity {
  final String id;
  final String serviceName;
  final String? serviceImage;
  final String providerName;
  final String? clientName;
  final String? clientAvatar;
  final DateTime date;
  final String status;
  final double? amount;
  final String? currency;

  const RecentBookingEntity({
    required this.id,
    required this.serviceName,
    this.serviceImage,
    required this.providerName,
    this.clientName,
    this.clientAvatar,
    required this.date,
    required this.status,
    this.amount,
    this.currency,
  });

  String get formattedDate {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} weeks ago';

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String? get formattedAmount {
    if (amount == null) return null;
    final symbol = currency == 'USD' ? '\$' : (currency ?? '\$');
    return '$symbol${amount!.toStringAsFixed(2)}';
  }
}

/// Appointment entity
class AppointmentEntity {
  final String id;
  final String serviceName;
  final String providerName;
  final String clientName;
  final String? clientAvatar;
  final DateTime scheduledDate;
  final TimeOfDay? scheduledTime;
  final String status;
  final String? location;
  final String? notes;

  const AppointmentEntity({
    required this.id,
    required this.serviceName,
    required this.clientName,
    required this.providerName,
    this.clientAvatar,
    required this.scheduledDate,
    this.scheduledTime,
    required this.status,
    this.location,
    this.notes,
  });

  String get formattedDate {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final appointmentDate = DateTime(
      scheduledDate.year,
      scheduledDate.month,
      scheduledDate.day,
    );

    if (appointmentDate == today) return 'Today';
    if (appointmentDate == today.add(const Duration(days: 1)))
      return 'Tomorrow';

    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${days[scheduledDate.weekday - 1]}, ${months[scheduledDate.month - 1]} ${scheduledDate.day}';
  }

  String get formattedTime {
    if (scheduledTime == null) return '';
    final h = scheduledTime!.hourOfPeriod == 0
        ? 12
        : scheduledTime!.hourOfPeriod;
    final m = scheduledTime!.minute.toString().padLeft(2, '0');
    final p = scheduledTime!.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$m $p';
  }

  bool get isUpcoming {
    final now = DateTime.now();
    return scheduledDate.isAfter(now) ||
        (scheduledDate.year == now.year &&
            scheduledDate.month == now.month &&
            scheduledDate.day == now.day);
  }
}

/// Main dashboard entity
class DashboardEntity {
  final SpendingTrendEntity? spendingTrend;
  final BookingMixEntity? bookingMix;
  final DashboardKpiEntity? kpis;
  final List<InsightEntity> insights;
  final List<RecentBookingEntity> recentBookings;
  final List<AppointmentEntity> upcomingAppointments;
  final String? role;
  final DateTime? generatedAt;

  const DashboardEntity({
    this.spendingTrend,
    this.bookingMix,
    this.kpis,
    this.insights = const [],
    this.recentBookings = const [],
    this.upcomingAppointments = const [],
    this.role,
    this.generatedAt,
  });

  bool get hasData {
    return spendingTrend != null ||
        bookingMix != null ||
        kpis != null ||
        insights.isNotEmpty ||
        recentBookings.isNotEmpty ||
        upcomingAppointments.isNotEmpty;
  }

  bool get isEmpty => !hasData;

  DashboardEntity copyWith({
    SpendingTrendEntity? spendingTrend,
    BookingMixEntity? bookingMix,
    DashboardKpiEntity? kpis,
    List<InsightEntity>? insights,
    List<RecentBookingEntity>? recentBookings,
    List<AppointmentEntity>? upcomingAppointments,
    String? role,
    DateTime? generatedAt,
  }) {
    return DashboardEntity(
      spendingTrend: spendingTrend ?? this.spendingTrend,
      bookingMix: bookingMix ?? this.bookingMix,
      kpis: kpis ?? this.kpis,
      insights: insights ?? this.insights,
      recentBookings: recentBookings ?? this.recentBookings,
      upcomingAppointments: upcomingAppointments ?? this.upcomingAppointments,
      role: role ?? this.role,
      generatedAt: generatedAt ?? this.generatedAt,
    );
  }
}

/// Dashboard filter entity
class DashboardFilterEntity {
  final String? range;
  final DateTime? from;
  final DateTime? to;
  final String? role;

  const DashboardFilterEntity({this.range, this.from, this.to, this.role});

  DashboardFilterEntity copyWith({
    String? range,
    DateTime? from,
    DateTime? to,
    String? role,
  }) {
    return DashboardFilterEntity(
      range: range ?? this.range,
      from: from ?? this.from,
      to: to ?? this.to,
      role: role ?? this.role,
    );
  }

  Map<String, dynamic> toQueryParams() {
    final params = <String, dynamic>{};
    if (range != null) params['range'] = range;
    if (from != null) params['from'] = _formatDate(from!);
    if (to != null) params['to'] = _formatDate(to!);
    return params;
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
