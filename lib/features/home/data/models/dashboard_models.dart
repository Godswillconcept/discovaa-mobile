import 'package:flutter/material.dart';

/// Spending trend data point for charts
class SpendingTrendDataPointDto {
  final DateTime date;
  final double amount;

  const SpendingTrendDataPointDto({required this.date, required this.amount});

  factory SpendingTrendDataPointDto.fromJson(Map<String, dynamic> json) {
    return SpendingTrendDataPointDto(
      date: DateTime.parse(json['date'] as String),
      amount: (json['amount'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'amount': amount,
  };
}

/// Spending trend data containing time-series points
class SpendingTrendDto {
  final List<SpendingTrendDataPointDto> points;
  final double totalAmount;
  final double? percentageChange;
  final String periodLabel;

  const SpendingTrendDto({
    required this.points,
    required this.totalAmount,
    this.percentageChange,
    required this.periodLabel,
  });

  factory SpendingTrendDto.fromJson(Map<String, dynamic> json) {
    final pointsList = (json['points'] as List<dynamic>? ?? []);
    final points = <SpendingTrendDataPointDto>[];
    for (final e in pointsList) {
      if (e is Map<String, dynamic>) {
        try {
          points.add(SpendingTrendDataPointDto.fromJson(e));
        } catch (_) {
          // Skip malformed data points
        }
      }
    }
    return SpendingTrendDto(
      points: points,
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      percentageChange: (json['percentage_change'] as num?)?.toDouble(),
      periodLabel: json['period_label'] as String? ?? 'Last 30 days',
    );
  }

  Map<String, dynamic> toJson() => {
    'points': points.map((e) => e.toJson()).toList(),
    'total_amount': totalAmount,
    'percentage_change': percentageChange,
    'period_label': periodLabel,
  };
}

/// Booking status distribution for pie chart
class BookingMixDto {
  final int requested;
  final int confirmed;
  final int completed;
  final int cancelled;
  final int total;

  const BookingMixDto({
    required this.requested,
    required this.confirmed,
    required this.completed,
    required this.cancelled,
    required this.total,
  });

  factory BookingMixDto.fromJson(Map<String, dynamic> json) {
    final requested = (json['requested'] as num?)?.toInt() ?? 0;
    final confirmed = (json['confirmed'] as num?)?.toInt() ?? 0;
    final completed = (json['completed'] as num?)?.toInt() ?? 0;
    final cancelled = (json['cancelled'] as num?)?.toInt() ?? 0;

    return BookingMixDto(
      requested: requested,
      confirmed: confirmed,
      completed: completed,
      cancelled: cancelled,
      total: requested + confirmed + completed + cancelled,
    );
  }

  Map<String, dynamic> toJson() => {
    'requested': requested,
    'confirmed': confirmed,
    'completed': completed,
    'cancelled': cancelled,
    'total': total,
  };

  double get requestedPercentage => total > 0 ? (requested / total) * 100 : 0;
  double get confirmedPercentage => total > 0 ? (confirmed / total) * 100 : 0;
  double get completedPercentage => total > 0 ? (completed / total) * 100 : 0;
  double get cancelledPercentage => total > 0 ? (cancelled / total) * 100 : 0;
}

/// Key performance indicators for dashboard
class DashboardKpiDto {
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
  // Provider-specific fields
  final double grossRevenue;
  final double netPayout;
  final int threadsCreated;
  final int messagesSent;
  final int uniqueCustomers;

  const DashboardKpiDto({
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
    this.grossRevenue = 0.0,
    this.netPayout = 0.0,
    this.threadsCreated = 0,
    this.messagesSent = 0,
    this.uniqueCustomers = 0,
  });

  factory DashboardKpiDto.fromJson(Map<String, dynamic> json) {
    return DashboardKpiDto(
      totalRevenue: (json['total_revenue'] as num?)?.toDouble() ?? 0.0,
      totalSpend: (json['total_spend'] as num?)?.toDouble() ?? 0.0,
      completedBookings: (json['completed_bookings'] as num?)?.toInt() ?? 0,
      cancelledBookings: (json['cancelled_bookings'] as num?)?.toInt() ?? 0,
      upcomingCount: (json['upcoming_count'] as num?)?.toInt() ?? 0,
      activeRequests: (json['active_requests'] as num?)?.toInt() ?? 0,
      avgRating: (json['avg_rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: (json['review_count'] as num?)?.toInt() ?? 0,
      unreadMessages: (json['unread_messages'] as num?)?.toInt() ?? 0,
      pendingMessages: (json['pending_messages'] as num?)?.toInt() ?? 0,
      currency: json['currency'] as String?,
      // Provider-specific fields
      grossRevenue: (json['gross_revenue'] as num?)?.toDouble() ?? 0.0,
      netPayout: (json['net_payout'] as num?)?.toDouble() ?? 0.0,
      threadsCreated: (json['threads_created'] as num?)?.toInt() ?? 0,
      messagesSent: (json['messages_sent'] as num?)?.toInt() ?? 0,
      uniqueCustomers: (json['unique_customers'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'total_revenue': totalRevenue,
    'total_spend': totalSpend,
    'completed_bookings': completedBookings,
    'cancelled_bookings': cancelledBookings,
    'upcoming_count': upcomingCount,
    'active_requests': activeRequests,
    'avg_rating': avgRating,
    'review_count': reviewCount,
    'unread_messages': unreadMessages,
    'pending_messages': pendingMessages,
    'currency': currency,
    // Provider-specific fields
    'gross_revenue': grossRevenue,
    'net_payout': netPayout,
    'threads_created': threadsCreated,
    'messages_sent': messagesSent,
    'unique_customers': uniqueCustomers,
  };
}

/// Smart insight item
class InsightDto {
  final String id;
  final String title;
  final String description;
  final String? actionLabel;
  final String? actionRoute;
  final IconData? icon;
  final String? iconName;
  final String type;

  const InsightDto({
    required this.id,
    required this.title,
    required this.description,
    this.actionLabel,
    this.actionRoute,
    this.icon,
    this.iconName,
    this.type = 'info',
  });

  factory InsightDto.fromJson(Map<String, dynamic> json) {
    return InsightDto(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      actionLabel: json['action_label'] as String?,
      actionRoute: json['action_route'] as String?,
      iconName: json['icon'] as String?,
      type: json['type'] as String? ?? 'info',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'action_label': actionLabel,
    'action_route': actionRoute,
    'icon': iconName,
    'type': type,
  };
}

/// Recent booking summary for dashboard
class RecentBookingDto {
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

  const RecentBookingDto({
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

  factory RecentBookingDto.fromJson(Map<String, dynamic> json) {
    return RecentBookingDto(
      id: json['id'] as String? ?? '',
      serviceName: json['service_name'] as String? ?? '',
      serviceImage: json['service_image'] as String?,
      providerName: json['provider_name'] as String? ?? '',
      clientName: json['client_name'] as String?,
      clientAvatar: json['client_avatar'] as String?,
      date: json['date'] != null
          ? DateTime.parse(json['date'] as String)
          : DateTime.now(),
      status: json['status'] as String? ?? 'unknown',
      amount: (json['amount'] as num?)?.toDouble(),
      currency: json['currency'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'service_name': serviceName,
    'service_image': serviceImage,
    'provider_name': providerName,
    'client_name': clientName,
    'client_avatar': clientAvatar,
    'date': date.toIso8601String(),
    'status': status,
    'amount': amount,
    'currency': currency,
  };
}

/// Appointment item for upcoming appointments section
class AppointmentDto {
  final String id;
  final String serviceName;
  final String clientName;
  final String providerName;
  final String? clientAvatar;
  final DateTime scheduledDate;
  final TimeOfDay? scheduledTime;
  final String status;
  final String? location;
  final String? notes;

  const AppointmentDto({
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

  factory AppointmentDto.fromJson(Map<String, dynamic> json) {
    TimeOfDay? time;
    if (json['scheduled_time'] != null) {
      final timeStr = json['scheduled_time'] as String;
      final parts = timeStr.split(':');
      if (parts.length >= 2) {
        time = TimeOfDay(
          hour: int.tryParse(parts[0]) ?? 0,
          minute: int.tryParse(parts[1]) ?? 0,
        );
      }
    }

    return AppointmentDto(
      id: json['id'] as String? ?? '',
      serviceName: json['service_name'] as String? ?? '',
      clientName: json['client_name'] as String? ?? '',
      providerName: json['provider_name'] as String? ?? '',
      clientAvatar: json['client_avatar'] as String?,
      scheduledDate: json['scheduled_date'] != null
          ? DateTime.parse(json['scheduled_date'] as String)
          : DateTime.now(),
      scheduledTime: time,
      status: json['status'] as String? ?? 'unknown',
      location: json['location'] as String?,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'service_name': serviceName,
    'client_name': clientName,
    'provider_name': providerName,
    'client_avatar': clientAvatar,
    'scheduled_date': scheduledDate.toIso8601String(),
    'scheduled_time': scheduledTime != null
        ? '${scheduledTime!.hour.toString().padLeft(2, '0')}:${scheduledTime!.minute.toString().padLeft(2, '0')}'
        : null,
    'status': status,
    'location': location,
    'notes': notes,
  };
}

/// Main dashboard response DTO
class DashboardDto {
  final SpendingTrendDto? spendingTrend;
  final BookingMixDto? bookingMix;
  final DashboardKpiDto? kpis;
  final List<InsightDto> insights;
  final List<RecentBookingDto> recentBookings;
  final List<AppointmentDto> upcomingAppointments;
  final String? role;
  final DateTime? generatedAt;

  const DashboardDto({
    this.spendingTrend,
    this.bookingMix,
    this.kpis,
    this.insights = const [],
    this.recentBookings = const [],
    this.upcomingAppointments = const [],
    this.role,
    this.generatedAt,
  });

  factory DashboardDto.fromJson(Map<String, dynamic> json) {
    return DashboardDto(
      spendingTrend: json['spending_trend'] != null
          ? SpendingTrendDto.fromJson(
              (json['spending_trend'] as Map).cast<String, dynamic>(),
            )
          : null,
      bookingMix: json['booking_mix'] != null
          ? BookingMixDto.fromJson(
              (json['booking_mix'] as Map).cast<String, dynamic>(),
            )
          : null,
      kpis: json['kpis'] != null
          ? DashboardKpiDto.fromJson(
              (json['kpis'] as Map).cast<String, dynamic>(),
            )
          : null,
      insights: (json['insights'] as List<dynamic>? ?? [])
          .map((e) => InsightDto.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
      recentBookings: (json['recent_bookings'] as List<dynamic>? ?? [])
          .map(
            (e) =>
                RecentBookingDto.fromJson((e as Map).cast<String, dynamic>()),
          )
          .toList(),
      upcomingAppointments:
          (json['upcoming_appointments'] as List<dynamic>? ?? [])
              .map(
                (e) =>
                    AppointmentDto.fromJson((e as Map).cast<String, dynamic>()),
              )
              .toList(),
      role: json['role'] as String?,
      generatedAt: json['generated_at'] != null
          ? DateTime.parse(json['generated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'spending_trend': spendingTrend?.toJson(),
    'booking_mix': bookingMix?.toJson(),
    'kpis': kpis?.toJson(),
    'insights': insights.map((e) => e.toJson()).toList(),
    'recent_bookings': recentBookings.map((e) => e.toJson()).toList(),
    'upcoming_appointments': upcomingAppointments
        .map((e) => e.toJson())
        .toList(),
    'role': role,
    'generated_at': generatedAt?.toIso8601String(),
  };
}

/// Dashboard filter parameters
class DashboardFilterDto {
  final String? range;
  final DateTime? from;
  final DateTime? to;
  final String? role;

  const DashboardFilterDto({this.range, this.from, this.to, this.role});

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
