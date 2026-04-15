import 'package:flutter/material.dart';
import 'package:discovaa/core/constants/api_endpoints.dart';
import 'package:discovaa/core/network/api_helpers.dart';
import 'package:discovaa/core/network/dio_client.dart';
import '../models/dashboard_models.dart';

/// Remote data source for dashboard API calls
abstract class DashboardRemoteDataSource {
  /// Get provider dashboard data from API
  Future<DashboardDto> getProviderDashboard({DashboardFilterDto? filter});

  /// Get client dashboard data from API
  /// Note: Client dashboard is constructed from multiple endpoints
  Future<DashboardDto> getClientDashboard({DashboardFilterDto? filter});

  /// Get unread message count
  Future<int> getUnreadMessageCount();

  /// Get pending message count
  Future<int> getPendingMessageCount();

  /// Get upcoming appointments for provider
  Future<List<AppointmentDto>> getUpcomingAppointments({int limit = 5});

  /// Get recent bookings for user
  Future<List<RecentBookingDto>> getRecentBookings({int limit = 5});

  /// Get booking mix distribution
  Future<BookingMixDto> getBookingMix();

  /// Get spending trend data
  Future<SpendingTrendDto> getSpendingTrend({String range = '30d'});
}

/// Implementation of dashboard remote data source
class DashboardRemoteDataSourceImpl implements DashboardRemoteDataSource {
  final DioClient _dioClient;

  DashboardRemoteDataSourceImpl({required DioClient dioClient})
    : _dioClient = dioClient;

  @override
  Future<DashboardDto> getProviderDashboard({
    DashboardFilterDto? filter,
  }) async {
    final response = await _dioClient.get(
      ApiEndpoints.providersMeDashboard,
      queryParameters: filter?.toQueryParams(),
    );

    final envelope = decodeEnvelope(
      response,
      (raw) => _parseDashboardData(raw),
    );

    return DashboardDto.fromJson(envelope.data);
  }

  @override
  Future<DashboardDto> getClientDashboard({DashboardFilterDto? filter}) async {
    // For clients, we need to construct dashboard from multiple endpoints
    // since there's no dedicated client dashboard endpoint
    final results = await Future.wait([
      _getClientBookings(filter: filter),
      getRecentBookings(limit: 5),
      getUnreadMessageCount(),
      getPendingMessageCount(),
      getSpendingTrend(range: filter?.range ?? '30d'),
      getBookingMix(),
    ]);

    final bookingsData = results[0] as Map<String, dynamic>;
    final recentBookings = results[1] as List<RecentBookingDto>;
    final unreadCount = results[2] as int;
    final pendingCount = results[3] as int;
    final spendingTrend = results[4] as SpendingTrendDto;
    final bookingMix = results[5] as BookingMixDto;

    final upcomingCount =
        (bookingsData['upcoming_count'] as num?)?.toInt() ?? 0;
    final totalSpend = (bookingsData['total_spend'] as num?)?.toDouble() ?? 0.0;
    final completedCount =
        (bookingsData['completed_count'] as num?)?.toInt() ?? 0;
    final cancelledCount =
        (bookingsData['cancelled_count'] as num?)?.toInt() ?? 0;

    final kpis = DashboardKpiDto(
      totalSpend: totalSpend,
      completedBookings: completedCount,
      cancelledBookings: cancelledCount,
      upcomingCount: upcomingCount,
      unreadMessages: unreadCount,
      pendingMessages: pendingCount,
      currency: bookingsData['currency'] as String?,
    );

    final upcomingRaw =
        (bookingsData['upcoming'] as List<dynamic>? ?? const <dynamic>[])
            .whereType<Map<String, dynamic>>()
            .toList();

    final upcomingAppointments = upcomingRaw
        .map((e) => AppointmentDto.fromJson(e))
        .toList();

    return DashboardDto(
      spendingTrend: spendingTrend,
      bookingMix: bookingMix,
      kpis: kpis,
      recentBookings: recentBookings,
      upcomingAppointments: upcomingAppointments,
      role: 'client',
      generatedAt: DateTime.now(),
    );
  }

  Future<Map<String, dynamic>> _getClientBookings({
    DashboardFilterDto? filter,
  }) async {
    // Get bookings with different statuses to build dashboard
    final params = filter?.toQueryParams() ?? {};

    final response = await _dioClient.get(
      ApiEndpoints.bookings,
      queryParameters: {
        ...params,
        'limit': 100, // Get enough data to calculate stats
      },
    );

    final envelope = decodeListEnvelope(response, (item) => item);

    final bookings = envelope.data.whereType<Map<String, dynamic>>().toList();

    double totalSpend = 0.0;
    int upcomingCount = 0;
    int completedCount = 0;
    int cancelledCount = 0;
    String? currency;
    final upcoming = <Map<String, dynamic>>[];

    final now = DateTime.now();

    for (final booking in bookings) {
      final status = booking['status']?.toString() ?? '';
      final total = (booking['total'] as num?)?.toDouble() ?? 0.0;
      final scheduledStart = booking['scheduled_start']?.toString();

      if (currency == null && booking['currency'] != null) {
        currency = booking['currency']?.toString();
      }

      totalSpend += total;

      if (status.toUpperCase() == 'CONFIRMED' ||
          status.toUpperCase() == 'REQUESTED') {
        upcomingCount++;
        if (scheduledStart != null) {
          final date = _tryParseDateTime(scheduledStart);
          if (date == null) {
            continue;
          }
          if (date.isAfter(now) || _isSameDay(date, now)) {
            upcoming.add({
              'id': booking['id']?.toString() ?? '',
              'service_name': _extractServiceName(booking),
              'client_name': 'You',
              'scheduled_date': scheduledStart,
              'status': status,
            });
          }
        }
      } else if (status.toUpperCase() == 'COMPLETED') {
        completedCount++;
      } else if (status.toUpperCase() == 'CANCELLED') {
        cancelledCount++;
      }
    }

    return {
      'total_spend': totalSpend,
      'upcoming_count': upcomingCount,
      'completed_count': completedCount,
      'cancelled_count': cancelledCount,
      'currency': currency ?? 'USD',
      'upcoming': upcoming.take(5).toList(),
    };
  }

  String _extractServiceName(Map<String, dynamic> booking) {
    final items = booking['items'] as List<dynamic>?;
    if (items != null && items.isNotEmpty) {
      final firstItem = items.first as Map<String, dynamic>?;
      final service = firstItem?['service_snapshot'] as Map<String, dynamic>?;
      if (service != null) {
        return service['title']?.toString() ?? 'Service';
      }
      final itemService = firstItem?['service'] as Map<String, dynamic>?;
      if (itemService != null) {
        return itemService['title']?.toString() ?? 'Service';
      }
    }
    return 'Service';
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Future<int> getUnreadMessageCount() async {
    try {
      final response = await _dioClient.get(
        ApiEndpoints.messageThreads,
        queryParameters: {'unread': true},
      );

      final envelope = decodeListEnvelope(response, (item) => item);

      return envelope.data.length;
    } catch (e) {
      return 0;
    }
  }

  @override
  Future<int> getPendingMessageCount() async {
    try {
      final response = await _dioClient.get(
        ApiEndpoints.messageThreads,
        queryParameters: {'has_history': true},
      );

      final envelope = decodeListEnvelope(response, (item) => item);

      // Count threads where the other party sent the last message
      int pendingCount = 0;
      for (final thread in envelope.data.whereType<Map<String, dynamic>>()) {
        final lastMessage = thread['last_message'] as Map<String, dynamic>?;
        if (lastMessage != null) {
          final isRead = lastMessage['is_read'] ?? true;
          final sender = lastMessage['sender'] as Map<String, dynamic>?;
          final isMe = sender?['is_me'] ?? false;

          if (!isRead && !isMe) {
            pendingCount++;
          }
        }
      }

      return pendingCount;
    } catch (e) {
      return 0;
    }
  }

  @override
  Future<List<AppointmentDto>> getUpcomingAppointments({int limit = 5}) async {
    final response = await _dioClient.get(
      ApiEndpoints.bookings,
      queryParameters: {
        'status': 'CONFIRMED',
        'ordering': 'scheduled_start',
        'limit': limit,
      },
    );

    final envelope = decodeListEnvelope(
      response,
      (item) => _mapBookingToAppointment(item),
    );

    return envelope.data.map((e) => AppointmentDto.fromJson(e)).toList();
  }

  Map<String, dynamic> _mapBookingToAppointment(Map<String, dynamic> booking) {
    final scheduledStart = booking['scheduled_start']?.toString();
    DateTime? date;
    TimeOfDay? time;

    if (scheduledStart != null) {
      date = _tryParseDateTime(scheduledStart);
      if (date != null) {
        time = TimeOfDay(hour: date.hour, minute: date.minute);
      }
    }

    final client = booking['client'] as Map<String, dynamic>?;
    final items = booking['items'] as List<dynamic>?;
    String serviceName = 'Service';

    if (items != null && items.isNotEmpty) {
      final firstItem = items.first as Map<String, dynamic>?;
      final serviceSnapshot =
          firstItem?['service_snapshot'] as Map<String, dynamic>?;
      if (serviceSnapshot != null) {
        serviceName = serviceSnapshot['title']?.toString() ?? 'Service';
      }
    }

    return {
      'id': booking['id']?.toString() ?? '',
      'service_name': serviceName,
      'client_name': client?['display_name']?.toString() ?? 'Client',
      'client_avatar': client?['profile_photo']?.toString(),
      'scheduled_date': date?.toIso8601String(),
      'scheduled_time': time != null
          ? '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}'
          : null,
      'status': booking['status']?.toString() ?? 'unknown',
      'location': booking['location_display']?.toString(),
      'notes': booking['notes']?.toString(),
    };
  }

  @override
  Future<List<RecentBookingDto>> getRecentBookings({int limit = 5}) async {
    final response = await _dioClient.get(
      ApiEndpoints.bookings,
      queryParameters: {'ordering': '-created_at', 'limit': limit},
    );

    final envelope = decodeListEnvelope(
      response,
      (item) => _mapBookingToRecent(item),
    );

    return envelope.data.map((e) => RecentBookingDto.fromJson(e)).toList();
  }

  Map<String, dynamic> _mapBookingToRecent(Map<String, dynamic> booking) {
    final items = booking['items'] as List<dynamic>?;
    String serviceName = 'Service';
    String? serviceImage;

    if (items != null && items.isNotEmpty) {
      final firstItem = items.first as Map<String, dynamic>;
      final serviceSnapshot =
          firstItem['service_snapshot'] as Map<String, dynamic>?;
      if (serviceSnapshot != null) {
        serviceName = serviceSnapshot['title']?.toString() ?? 'Service';
        // Get first media item if available
        final media = serviceSnapshot['media'] as List<dynamic>?;
        if (media != null && media.isNotEmpty) {
          serviceImage = (media.first as Map<String, dynamic>)['file']
              ?.toString();
        }
      }
    }

    final provider = booking['provider'] as Map<String, dynamic>?;

    return {
      'id': booking['id']?.toString() ?? '',
      'service_name': serviceName,
      'service_image': serviceImage,
      'provider_name': provider?['display_name']?.toString() ?? 'Provider',
      'date': booking['created_at']?.toString(),
      'status': booking['status']?.toString() ?? 'unknown',
      'amount': (booking['total'] as num?)?.toDouble(),
      'currency': booking['currency']?.toString(),
    };
  }

  @override
  Future<BookingMixDto> getBookingMix() async {
    final response = await _dioClient.get(ApiEndpoints.bookings);

    final envelope = decodeListEnvelope(response, (item) => item);

    int requested = 0;
    int confirmed = 0;
    int completed = 0;
    int cancelled = 0;

    for (final booking in envelope.data.whereType<Map<String, dynamic>>()) {
      final status = (booking['status']?.toString() ?? '').toUpperCase();
      switch (status) {
        case 'REQUESTED':
          requested++;
          break;
        case 'CONFIRMED':
          confirmed++;
          break;
        case 'COMPLETED':
          completed++;
          break;
        case 'CANCELLED':
          cancelled++;
          break;
      }
    }

    return BookingMixDto(
      requested: requested,
      confirmed: confirmed,
      completed: completed,
      cancelled: cancelled,
      total: requested + confirmed + completed + cancelled,
    );
  }

  @override
  Future<SpendingTrendDto> getSpendingTrend({String range = '30d'}) async {
    // Get bookings for spending trend calculation
    final response = await _dioClient.get(
      ApiEndpoints.bookings,
      queryParameters: {'limit': 100},
    );

    final envelope = decodeListEnvelope(response, (item) => item);

    // Group bookings by date and sum totals
    final Map<String, double> dailyTotals = {};
    double totalAmount = 0.0;
    String? currency;

    for (final booking in envelope.data.whereType<Map<String, dynamic>>()) {
      final status = (booking['status']?.toString() ?? '').toUpperCase();
      if (status != 'COMPLETED' && status != 'CONFIRMED') {
        continue;
      }

      final total = (booking['total'] as num?)?.toDouble() ?? 0.0;
      final createdAt = booking['created_at']?.toString();

      if (currency == null && booking['currency'] != null) {
        currency = booking['currency']?.toString();
      }

      if (createdAt != null) {
        final date = _tryParseDateTime(createdAt);
        if (date == null) {
          continue;
        }
        final dateKey =
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

        dailyTotals[dateKey] = (dailyTotals[dateKey] ?? 0.0) + total;
        totalAmount += total;
      }
    }

    // Sort dates and create data points
    final sortedDates = dailyTotals.keys.toList()..sort();
    final points = sortedDates.map((dateStr) {
      final parts = dateStr.split('-');
      return SpendingTrendDataPointDto(
        date: DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        ),
        amount: dailyTotals[dateStr]!,
      );
    }).toList();

    // If no data points, generate empty trend for last 7 days
    if (points.isEmpty) {
      final now = DateTime.now();
      for (int i = 6; i >= 0; i--) {
        points.add(
          SpendingTrendDataPointDto(
            date: now.subtract(Duration(days: i)),
            amount: 0.0,
          ),
        );
      }
    }

    // Calculate percentage change
    double? percentageChange;
    if (points.length >= 2) {
      final firstHalf = points
          .take(points.length ~/ 2)
          .fold<double>(0.0, (sum, p) => sum + p.amount);
      final secondHalf = points
          .skip(points.length ~/ 2)
          .fold<double>(0.0, (sum, p) => sum + p.amount);

      if (firstHalf > 0) {
        percentageChange = ((secondHalf - firstHalf) / firstHalf) * 100;
      }
    }

    return SpendingTrendDto(
      points: points,
      totalAmount: totalAmount,
      percentageChange: percentageChange,
      periodLabel: _getPeriodLabel(range),
    );
  }

  String _getPeriodLabel(String range) {
    switch (range) {
      case '7d':
        return 'Last 7 days';
      case '30d':
        return 'Last 30 days';
      case '90d':
        return 'Last 3 months';
      default:
        return 'Last 30 days';
    }
  }

  DateTime? _tryParseDateTime(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    return DateTime.tryParse(value);
  }

  Map<String, dynamic> _parseDashboardData(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      return raw;
    }
    return {};
  }
}
