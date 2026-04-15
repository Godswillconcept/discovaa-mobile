import 'package:flutter/material.dart';
import 'package:discovaa/core/network/network_info.dart';
import 'package:discovaa/core/storage/hive_service.dart';
import '../../domain/entities/dashboard_entity.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../datasources/dashboard_remote_datasource.dart';
import '../models/dashboard_models.dart';

/// Implementation of dashboard repository
class DashboardRepositoryImpl implements DashboardRepository {
  final DashboardRemoteDataSource _remoteDataSource;
  final HiveService _hiveService;
  final NetworkInfo _networkInfo;

  DashboardRepositoryImpl({
    required DashboardRemoteDataSource remoteDataSource,
    required HiveService hiveService,
    required NetworkInfo networkInfo,
  }) : _remoteDataSource = remoteDataSource,
       _hiveService = hiveService,
       _networkInfo = networkInfo;

  @override
  Future<DashboardEntity> getProviderDashboard({
    DashboardFilterEntity? filter,
  }) async {
    final filterDto = filter != null
        ? DashboardFilterDto(
            range: filter.range,
            from: filter.from,
            to: filter.to,
            role: filter.role,
          )
        : null;

    return _getDashboard(
      cacheKey: _cacheKey('provider', filterDto),
      loader: () => _remoteDataSource.getProviderDashboard(filter: filterDto),
    );
  }

  @override
  Future<DashboardEntity> getClientDashboard({
    DashboardFilterEntity? filter,
  }) async {
    final filterDto = filter != null
        ? DashboardFilterDto(
            range: filter.range,
            from: filter.from,
            to: filter.to,
            role: filter.role,
          )
        : null;

    return _getDashboard(
      cacheKey: _cacheKey('client', filterDto),
      loader: () => _remoteDataSource.getClientDashboard(filter: filterDto),
    );
  }

  @override
  Future<int> getUnreadMessageCount() async {
    return _remoteDataSource.getUnreadMessageCount();
  }

  @override
  Future<int> getPendingMessageCount() async {
    return _remoteDataSource.getPendingMessageCount();
  }

  @override
  Future<DashboardEntity> refreshDashboard(
    String role, {
    DashboardFilterEntity? filter,
  }) async {
    if (role == 'provider') {
      return getProviderDashboard(filter: filter);
    } else {
      return getClientDashboard(filter: filter);
    }
  }

  Future<DashboardEntity> _getDashboard({
    required String cacheKey,
    required Future<DashboardDto> Function() loader,
  }) async {
    try {
      if (!await _networkInfo.isConnected) {
        final cached = _readCachedDashboard(cacheKey);
        if (cached != null) {
          return _mapDtoToEntity(cached);
        }
      }
      final dto = await loader();
      await _hiveService.setMap(cacheKey, dto.toJson());
      return _mapDtoToEntity(dto);
    } catch (_) {
      final cached = _readCachedDashboard(cacheKey);
      if (cached != null) {
        return _mapDtoToEntity(cached);
      }
      rethrow;
    }
  }

  DashboardDto? _readCachedDashboard(String cacheKey) {
    final cached = _hiveService.getMap(cacheKey);
    if (cached == null || cached.isEmpty) {
      return null;
    }
    return DashboardDto.fromJson(cached);
  }

  String _cacheKey(String role, DashboardFilterDto? filter) {
    final range = filter?.range ?? 'all';
    final from = filter?.from?.toIso8601String() ?? 'none';
    final to = filter?.to?.toIso8601String() ?? 'none';
    return 'dashboard.cache.$role.$range.$from.$to';
  }

  /// Map DTO to Entity
  DashboardEntity _mapDtoToEntity(DashboardDto dto) {
    return DashboardEntity(
      spendingTrend: dto.spendingTrend != null
          ? SpendingTrendEntity(
              points: dto.spendingTrend!.points
                  .map(
                    (p) =>
                        SpendingTrendDataPoint(date: p.date, amount: p.amount),
                  )
                  .toList(),
              totalAmount: dto.spendingTrend!.totalAmount,
              percentageChange: dto.spendingTrend!.percentageChange,
              periodLabel: dto.spendingTrend!.periodLabel,
            )
          : null,
      bookingMix: dto.bookingMix != null
          ? BookingMixEntity(
              requested: dto.bookingMix!.requested,
              confirmed: dto.bookingMix!.confirmed,
              completed: dto.bookingMix!.completed,
              cancelled: dto.bookingMix!.cancelled,
              total: dto.bookingMix!.total,
            )
          : null,
      kpis: dto.kpis != null
          ? DashboardKpiEntity(
              totalRevenue: dto.kpis!.totalRevenue,
              totalSpend: dto.kpis!.totalSpend,
              completedBookings: dto.kpis!.completedBookings,
              cancelledBookings: dto.kpis!.cancelledBookings,
              upcomingCount: dto.kpis!.upcomingCount,
              activeRequests: dto.kpis!.activeRequests,
              avgRating: dto.kpis!.avgRating,
              reviewCount: dto.kpis!.reviewCount,
              unreadMessages: dto.kpis!.unreadMessages,
              pendingMessages: dto.kpis!.pendingMessages,
              currency: dto.kpis!.currency,
            )
          : null,
      insights: dto.insights
          .map(
            (i) => InsightEntity(
              id: i.id,
              title: i.title,
              description: i.description,
              actionLabel: i.actionLabel,
              actionRoute: i.actionRoute,
              icon: _mapIconNameToIconData(i.iconName),
              type: i.type,
            ),
          )
          .toList(),
      recentBookings: dto.recentBookings
          .map(
            (b) => RecentBookingEntity(
              id: b.id,
              serviceName: b.serviceName,
              serviceImage: b.serviceImage,
              providerName: b.providerName,
              date: b.date,
              status: b.status,
              amount: b.amount,
              currency: b.currency,
            ),
          )
          .toList(),
      upcomingAppointments: dto.upcomingAppointments
          .map(
            (a) => AppointmentEntity(
              id: a.id,
              serviceName: a.serviceName,
              clientName: a.clientName,
              clientAvatar: a.clientAvatar,
              scheduledDate: a.scheduledDate,
              scheduledTime: a.scheduledTime,
              status: a.status,
              location: a.location,
              notes: a.notes,
            ),
          )
          .toList(),
      role: dto.role,
      generatedAt: dto.generatedAt,
    );
  }

  /// Map icon name to IconData
  IconData? _mapIconNameToIconData(String? iconName) {
    switch (iconName?.toLowerCase()) {
      case 'calendar':
        return Icons.calendar_today;
      case 'star':
        return Icons.star;
      case 'message':
        return Icons.message;
      case 'notification':
        return Icons.notifications;
      case 'check':
        return Icons.check_circle;
      case 'warning':
        return Icons.warning;
      case 'info':
        return Icons.info;
      case 'search':
        return Icons.search;
      case 'trending_up':
        return Icons.trending_up;
      case 'trending_down':
        return Icons.trending_down;
      case 'money':
        return Icons.attach_money;
      case 'person':
        return Icons.person;
      case 'schedule':
        return Icons.schedule;
      case 'location':
        return Icons.location_on;
      default:
        return null;
    }
  }
}
