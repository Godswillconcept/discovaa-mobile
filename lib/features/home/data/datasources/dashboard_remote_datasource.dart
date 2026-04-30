import 'package:discovaa/core/constants/api_endpoints.dart';
import 'package:discovaa/core/constants/app_constants.dart';
import 'package:discovaa/core/network/api_helpers.dart';
import 'package:discovaa/core/network/dio_client.dart';
import '../models/dashboard_models.dart';
import 'package:flutter/material.dart';

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
  Future<int>? _unreadMessageCountInFlight;
  Future<int>? _pendingMessageCountInFlight;

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
    // Optimized: Consolidated bookings fetch + message counts (3 parallel calls instead of 6)
    // Add error handling to prevent one failure from blocking the entire dashboard load
    final results = await Future.wait([
      _getClientBookings(filter: filter).catchError((e) {
        debugPrint('[DashboardRemoteDataSource] Bookings fetch failed: $e');
        return _getEmptyBookingsData();
      }),
      getUnreadMessageCount().catchError((e) {
        debugPrint('[DashboardRemoteDataSource] Unread count fetch failed: $e');
        return 0;
      }),
      getPendingMessageCount().catchError((e) {
        debugPrint(
          '[DashboardRemoteDataSource] Pending count fetch failed: $e',
        );
        return 0;
      }),
    ]);

    final bookingsData = results[0] as Map<String, dynamic>;
    final unreadCount = results[1] as int;
    final pendingCount = results[2] as int;

    // Extract data from consolidated bookings response
    final upcomingCount =
        (bookingsData['upcoming_count'] as num?)?.toInt() ?? 0;
    final totalSpend = (bookingsData['total_spend'] as num?)?.toDouble() ?? 0.0;
    final completedCount =
        (bookingsData['completed_count'] as num?)?.toInt() ?? 0;
    final cancelledCount =
        (bookingsData['cancelled_count'] as num?)?.toInt() ?? 0;
    final spendingTrend = bookingsData['spending_trend'] as SpendingTrendDto;
    final bookingMix = bookingsData['booking_mix'] as BookingMixDto;
    final recentBookingsRaw = bookingsData['recent_bookings'] as List<dynamic>;
    final recentBookings = recentBookingsRaw
        .whereType<Map<String, dynamic>>()
        .map((e) => RecentBookingDto.fromJson(e))
        .toList();

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
        'expand':
            'items.service,provider', // Expand service and provider details
      },
    );

    final envelope = decodeListEnvelope(response, (item) => item);

    final bookings = envelope.data.whereType<Map<String, dynamic>>().toList();

    double totalSpend = 0.0;
    int upcomingCount = 0;
    int completedCount = 0;
    int cancelledCount = 0;
    int requestedCount = 0;
    int confirmedCount = 0;
    String? currency;
    final upcoming = <Map<String, dynamic>>[];

    // For spending trend
    final Map<String, double> dailyTotals = {};
    double totalAmount = 0.0;

    final now = DateTime.now();

    for (final booking in bookings) {
      final status = booking['status']?.toString() ?? '';
      final total = (booking['total'] as num?)?.toDouble() ?? 0.0;
      final scheduledStart = booking['scheduled_start']?.toString();
      final createdAt = booking['created_at']?.toString();

      if (currency == null && booking['currency'] != null) {
        currency = booking['currency']?.toString();
      }

      totalSpend += total;

      // Count by status
      final statusUpper = status.toUpperCase();
      if (statusUpper == 'REQUESTED') {
        requestedCount++;
      } else if (statusUpper == 'CONFIRMED') {
        confirmedCount++;
      } else if (statusUpper == 'COMPLETED') {
        completedCount++;
      } else if (statusUpper == 'CANCELLED') {
        cancelledCount++;
      }

      // Upcoming appointments
      if (statusUpper == 'CONFIRMED' || statusUpper == 'REQUESTED') {
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
      }

      // Spending trend data (only for completed/confirmed bookings)
      if (statusUpper == 'COMPLETED' || statusUpper == 'CONFIRMED') {
        totalAmount += total;

        if (createdAt != null) {
          final date = _tryParseDateTime(createdAt);
          if (date != null) {
            final dateKey =
                '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
            dailyTotals[dateKey] = (dailyTotals[dateKey] ?? 0.0) + total;
          }
        }
      }
    }

    // Calculate spending trend
    final sortedDates = dailyTotals.keys.toList()..sort();
    final spendingTrendPoints = sortedDates.map((dateStr) {
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
    if (spendingTrendPoints.isEmpty) {
      for (int i = 6; i >= 0; i--) {
        spendingTrendPoints.add(
          SpendingTrendDataPointDto(
            date: now.subtract(Duration(days: i)),
            amount: 0.0,
          ),
        );
      }
    }

    // Calculate percentage change
    double? percentageChange;
    if (spendingTrendPoints.length >= 2) {
      final firstHalf = spendingTrendPoints
          .take(spendingTrendPoints.length ~/ 2)
          .fold<double>(0.0, (sum, p) => sum + p.amount);
      final secondHalf = spendingTrendPoints
          .skip(spendingTrendPoints.length ~/ 2)
          .fold<double>(0.0, (sum, p) => sum + p.amount);

      if (firstHalf > 0) {
        percentageChange = ((secondHalf - firstHalf) / firstHalf) * 100;
      }
    }

    final spendingTrend = SpendingTrendDto(
      points: spendingTrendPoints,
      totalAmount: totalAmount,
      percentageChange: percentageChange,
      periodLabel: 'Last 30 days',
    );

    // Calculate booking mix
    final bookingMix = BookingMixDto(
      requested: requestedCount,
      confirmed: confirmedCount,
      completed: completedCount,
      cancelled: cancelledCount,
      total: requestedCount + confirmedCount + completedCount + cancelledCount,
    );

    // Get recent bookings (top 5 by creation date)
    final sortedByCreation = List<Map<String, dynamic>>.from(bookings)
      ..sort((a, b) {
        final aDate = _tryParseDateTime(a['created_at']?.toString());
        final bDate = _tryParseDateTime(b['created_at']?.toString());
        if (aDate == null || bDate == null) return 0;
        return bDate.compareTo(aDate);
      });

    final recentBookings = sortedByCreation.take(5).map((booking) {
      return _mapBookingToRecent(booking);
    }).toList();

    return {
      'total_spend': totalSpend,
      'upcoming_count': upcomingCount,
      'completed_count': completedCount,
      'cancelled_count': cancelledCount,
      'currency': currency ?? 'USD',
      'upcoming': upcoming.take(5).toList(),
      'spending_trend': spendingTrend,
      'booking_mix': bookingMix,
      'recent_bookings': recentBookings,
    };
  }

  String _extractServiceName(Map<String, dynamic> booking) {
    final items = booking['items'] as List<dynamic>?;
    if (items != null && items.isNotEmpty) {
      final firstItem = items.first;
      if (firstItem is Map<String, dynamic>) {
        final service = firstItem['service_snapshot'];
        if (service is Map<String, dynamic>) {
          return service['title']?.toString() ?? 'Service';
        }
        final itemService = firstItem['service'];
        if (itemService is Map<String, dynamic>) {
          return itemService['title']?.toString() ?? 'Service';
        }
      }
    }
    return 'Service';
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Future<int> getUnreadMessageCount() async {
    final inFlight = _unreadMessageCountInFlight;
    if (inFlight != null) {
      debugPrint(
        '[DashboardRemoteDataSource][dashboard] Reusing in-flight unread message count request',
      );
      return inFlight;
    }

    final request = () async {
      final response = await _dioClient.get(
        ApiEndpoints.messageThreads,
        queryParameters: {'unread': true},
      );

      final envelope = decodeListEnvelope(response, (item) => item);

      return envelope.data.length;
    }();

    _unreadMessageCountInFlight = request;
    try {
      return await request;
    } catch (e) {
      return 0;
    } finally {
      if (identical(_unreadMessageCountInFlight, request)) {
        _unreadMessageCountInFlight = null;
      }
    }
  }

  @override
  Future<int> getPendingMessageCount() async {
    final inFlight = _pendingMessageCountInFlight;
    if (inFlight != null) {
      debugPrint(
        '[DashboardRemoteDataSource][dashboard] Reusing in-flight pending message count request',
      );
      return inFlight;
    }

    final request = () async {
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
    }();

    _pendingMessageCountInFlight = request;
    try {
      return await request;
    } catch (e) {
      return 0;
    } finally {
      if (identical(_pendingMessageCountInFlight, request)) {
        _pendingMessageCountInFlight = null;
      }
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
        'expand': 'provider', // Expand provider details for display
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

    // Handle client field - it can be a Map or a String (UUID)
    final clientRaw = booking['client'];
    Map<String, dynamic>? client;
    if (clientRaw is Map<String, dynamic>) {
      client = clientRaw;
    }
    // If client is a String (UUID), we don't have client details available

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
      queryParameters: {
        'ordering': '-created_at',
        'limit': limit,
        'expand':
            'items.service,provider', // Expand service and provider details
      },
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
    String serviceId = '';

    if (items != null && items.isNotEmpty) {
      final firstItem = items.first;
      if (firstItem is Map<String, dynamic>) {
        // Try service_snapshot first, then fall back to service
        final serviceSnapshot = firstItem['service_snapshot'];
        final service = firstItem['service'];

        Map<String, dynamic>? serviceData;
        if (serviceSnapshot is Map<String, dynamic>) {
          serviceData = serviceSnapshot;
        } else if (service is Map<String, dynamic>) {
          serviceData = service;
        }

        if (serviceData != null) {
          serviceName = serviceData['title']?.toString() ?? 'Service';
          serviceId = serviceData['id']?.toString() ?? '';
          // Get first media item if available - validate it's a renderable URL
          final media = serviceData['media'];
          if (media is List<dynamic> && media.isNotEmpty) {
            final firstMedia = media.first;
            if (firstMedia is Map<String, dynamic>) {
              final fileUrl = firstMedia['file']?.toString();
              if (_isRenderableImagePath(fileUrl)) {
                serviceImage = fileUrl;
              }
            } else if (firstMedia is String) {
              // Handle case where media is just a string (UUID or URL)
              if (_isRenderableImagePath(firstMedia)) {
                serviceImage = firstMedia;
              }
            }
          }
        }
      }
    }

    // Fall back to placeholder if no valid image URL found
    serviceImage ??= AppAssets.servicePlaceholder(
      serviceId.isNotEmpty ? serviceId : 'booking',
    );

    // Handle provider field - it can be a Map or a String (UUID)
    final providerRaw = booking['provider'];
    Map<String, dynamic>? provider;
    if (providerRaw is Map<String, dynamic>) {
      provider = providerRaw;
    }
    // If provider is a String (UUID), we don't have provider details available

    return {
      'id': booking['id']?.toString() ?? '',
      'service_name': serviceName,
      'service_image': serviceImage,
      'provider_name':
          provider?['display_name']?.toString() ??
          provider?['business_name']?.toString() ??
          'Provider',
      'date': booking['created_at']?.toString(),
      'status': booking['status']?.toString() ?? 'unknown',
      'amount': (booking['total'] as num?)?.toDouble(),
      'currency': booking['currency']?.toString(),
    };
  }

  @override
  Future<BookingMixDto> getBookingMix() async {
    final response = await _dioClient.get(
      ApiEndpoints.bookings,
      queryParameters: {'expand': 'provider'}, // Expand provider details
    );

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
      queryParameters: {
        'limit': 100,
        'expand': 'provider', // Expand provider details
      },
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
    if (raw is! Map<String, dynamic>) {
      return {};
    }

    // Check if this is the nested provider dashboard structure
    final data = raw['data'];
    if (data is Map<String, dynamic>) {
      final kpis = data['kpis'];
      if (kpis is Map<String, dynamic>) {
        return _transformProviderKpis(kpis);
      }
    }

    // Return as-is for client dashboard or other structures
    return raw;
  }

  /// Transforms nested provider dashboard KPIs into flat structure
  /// expected by DashboardKpiDto
  Map<String, dynamic> _transformProviderKpis(Map<String, dynamic> kpis) {
    final bookings = kpis['bookings'] as Map<String, dynamic>?;
    final revenue = kpis['revenue'] as Map<String, dynamic>?;
    final reviews = kpis['reviews'] as Map<String, dynamic>?;
    final messaging = kpis['messaging'] as Map<String, dynamic>?;

    final byStatus = bookings?['by_status'] as Map<String, dynamic>?;

    final requestedCount = (byStatus?['REQUESTED'] as num?)?.toInt() ?? 0;
    final confirmedCount = (byStatus?['CONFIRMED'] as num?)?.toInt() ?? 0;

    return {
      'total_revenue': (revenue?['gross_captured'] as num?)?.toDouble() ?? 0.0,
      'total_spend': 0.0, // Providers don't have spend
      'completed_bookings': (byStatus?['COMPLETED'] as num?)?.toInt() ?? 0,
      'cancelled_bookings': (byStatus?['CANCELLED'] as num?)?.toInt() ?? 0,
      'upcoming_count': requestedCount + confirmedCount,
      'active_requests': requestedCount,
      'avg_rating': (reviews?['avg_rating'] as num?)?.toDouble() ?? 0.0,
      'review_count': (reviews?['count'] as num?)?.toInt() ?? 0,
      'unread_messages': 0, // Not in provider dashboard
      'pending_messages': 0, // Not in provider dashboard
      'currency': 'NGN', // Default currency
      // Provider-specific fields
      'gross_revenue': (revenue?['gross_captured'] as num?)?.toDouble() ?? 0.0,
      'net_payout':
          (revenue?['net_payout_captured'] as num?)?.toDouble() ?? 0.0,
      'threads_created': (messaging?['threads_created'] as num?)?.toInt() ?? 0,
      'messages_sent': (messaging?['messages_sent'] as num?)?.toInt() ?? 0,
      'unique_customers': (bookings?['unique_customers'] as num?)?.toInt() ?? 0,
    };
  }

  /// Returns empty bookings data structure for error fallback
  Map<String, dynamic> _getEmptyBookingsData() {
    final now = DateTime.now();
    final spendingTrendPoints = <SpendingTrendDataPointDto>[];
    for (int i = 6; i >= 0; i--) {
      spendingTrendPoints.add(
        SpendingTrendDataPointDto(
          date: now.subtract(Duration(days: i)),
          amount: 0.0,
        ),
      );
    }

    return {
      'total_spend': 0.0,
      'upcoming_count': 0,
      'completed_count': 0,
      'cancelled_count': 0,
      'currency': 'USD',
      'upcoming': <Map<String, dynamic>>[],
      'spending_trend': SpendingTrendDto(
        points: spendingTrendPoints,
        totalAmount: 0.0,
        percentageChange: null,
        periodLabel: 'Last 30 days',
      ),
      'booking_mix': BookingMixDto(
        requested: 0,
        confirmed: 0,
        completed: 0,
        cancelled: 0,
        total: 0,
      ),
      'recent_bookings': <Map<String, dynamic>>[],
    };
  }

  /// Validates that a string is a renderable image path (URL or asset path)
  /// Rejects UUIDs and other non-renderable strings
  bool _isRenderableImagePath(String? value) {
    if (value == null || value.isEmpty) {
      return false;
    }
    return value.startsWith('http://') ||
        value.startsWith('https://') ||
        value.startsWith('assets/');
  }
}
