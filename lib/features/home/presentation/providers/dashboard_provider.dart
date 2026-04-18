import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:discovaa/app/dependency_injection/service_locator.dart';
import 'package:discovaa/core/network/dio_client.dart';
import 'package:discovaa/core/network/network_info.dart';
import 'package:discovaa/core/storage/hive_service.dart';
import '../../data/datasources/dashboard_remote_datasource.dart';
import '../../data/repositories/dashboard_repository_impl.dart';
import '../../domain/entities/dashboard_entity.dart';
import '../../domain/repositories/dashboard_repository.dart';

// Repository Provider
final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  final dioClient = sl<DioClient>();
  final remoteDataSource = DashboardRemoteDataSourceImpl(dioClient: dioClient);
  return DashboardRepositoryImpl(
    remoteDataSource: remoteDataSource,
    hiveService: sl<HiveService>(),
    networkInfo: sl<NetworkInfo>(),
  );
});

// Dashboard State
class DashboardState {
  final bool isLoading;
  final DashboardEntity? data;
  final String? error;
  final bool isRefreshing;
  final String? loadedCacheKey;

  const DashboardState({
    this.isLoading = false,
    this.data,
    this.error,
    this.isRefreshing = false,
    this.loadedCacheKey,
  });

  DashboardState copyWith({
    bool? isLoading,
    DashboardEntity? data,
    String? error,
    bool? isRefreshing,
    String? loadedCacheKey,
  }) {
    return DashboardState(
      isLoading: isLoading ?? this.isLoading,
      data: data ?? this.data,
      error: error,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      loadedCacheKey: loadedCacheKey ?? this.loadedCacheKey,
    );
  }

  bool get hasData => data != null && !data!.isEmpty;
  bool get hasError => error != null;
  bool get isEmpty => data?.isEmpty ?? true;
}

// Dashboard Notifier
class DashboardNotifier extends StateNotifier<DashboardState> {
  final DashboardRepository _repository;

  DashboardNotifier(this._repository) : super(const DashboardState());

  String _cacheKey(String role, DashboardFilterEntity? filter) {
    final resolvedFilter = filter ?? const DashboardFilterEntity();
    return [
      role,
      resolvedFilter.range ?? '',
      resolvedFilter.from?.toIso8601String() ?? '',
      resolvedFilter.to?.toIso8601String() ?? '',
      resolvedFilter.role ?? '',
    ].join('|');
  }

  /// Load dashboard data based on user role
  Future<void> loadDashboard(
    String role, {
    DashboardFilterEntity? filter,
  }) async {
    final key = _cacheKey(role, filter);
    if (state.loadedCacheKey == key && state.data != null) {
      return;
    }

    final cached = _repository.getCachedDashboard(role, filter: filter);
    if (cached != null) {
      state = state.copyWith(isLoading: false, data: cached, loadedCacheKey: key);
    } else {
      state = state.copyWith(isLoading: true, error: null);
    }

    try {
      DashboardEntity data;
      if (role == 'provider') {
        data = await _repository.getProviderDashboard(filter: filter);
      } else {
        data = await _repository.getClientDashboard(filter: filter);
      }
      if (mounted) {
        state = state.copyWith(isLoading: false, data: data, loadedCacheKey: key);
      }
    } catch (e, stack) {
      if (!mounted) return;
      debugPrint('[DashboardNotifier] Error loading dashboard for role $role: $e');
      debugPrint('[DashboardNotifier] StackTrace: $stack');
      
      final hasCachedData = state.data != null;
      String errorMessage;
      
      if (e.toString().contains('401') ||
          e.toString().contains('Unauthorized')) {
        errorMessage = 'Authentication failed. Please log in again.';
      } else if (hasCachedData) {
        state = state.copyWith(isLoading: false);
        return;
      } else {
        errorMessage = 'Failed to load dashboard. Please try again.';
      }
      state = state.copyWith(isLoading: false, error: errorMessage);
    }
  }

  /// Refresh dashboard data
  Future<void> refresh(String role, {DashboardFilterEntity? filter}) async {
    if (state.isRefreshing) return;

    state = state.copyWith(isRefreshing: true);
    final key = _cacheKey(role, filter);

    try {
      final data = await _repository.refreshDashboard(role, filter: filter);
      state = state.copyWith(
        isRefreshing: false,
        data: data,
        loadedCacheKey: key,
        error: null, // Clear any previous errors on successful refresh
      );
    } catch (e) {
      // On refresh failure, keep showing existing data instead of showing error
      // This ensures smoother UX during network issues
      state = state.copyWith(
        isRefreshing: false,
        error: null, // Don't show error - we still have existing data
      );
    }
  }

  /// Clear dashboard data
  void clear() {
    state = const DashboardState();
  }

  /// Clear error state only, keeping the current data
  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Main Dashboard Provider
final dashboardProvider =
    StateNotifierProvider<DashboardNotifier, DashboardState>((ref) {
      final repository = ref.watch(dashboardRepositoryProvider);
      return DashboardNotifier(repository);
    });

// Dashboard Filter Provider
final dashboardFilterProvider = StateProvider<DashboardFilterEntity>((ref) {
  return const DashboardFilterEntity(range: '30d');
});

// Dashboard Data Selectors

/// Spending trend data selector
final spendingTrendProvider = Provider<SpendingTrendEntity?>((ref) {
  final dashboardState = ref.watch(dashboardProvider);
  return dashboardState.data?.spendingTrend;
});

/// Booking mix data selector
final bookingMixProvider = Provider<BookingMixEntity?>((ref) {
  final dashboardState = ref.watch(dashboardProvider);
  return dashboardState.data?.bookingMix;
});

/// KPI data selector
final dashboardKpiProvider = Provider<DashboardKpiEntity?>((ref) {
  final dashboardState = ref.watch(dashboardProvider);
  return dashboardState.data?.kpis;
});

/// Unread Messages Count Provider
final unreadMessagesProvider = Provider<int>((ref) {
  final kpis = ref.watch(dashboardKpiProvider);
  return kpis?.unreadMessages ?? 0;
});

/// Pending Messages Count Provider
final pendingMessagesProvider = Provider<int>((ref) {
  final kpis = ref.watch(dashboardKpiProvider);
  return kpis?.pendingMessages ?? 0;
});

/// Insights list selector
final insightsProvider = Provider<List<InsightEntity>>((ref) {
  final dashboardState = ref.watch(dashboardProvider);
  return dashboardState.data?.insights ?? [];
});

/// Recent bookings selector
final recentBookingsProvider = Provider<List<RecentBookingEntity>>((ref) {
  final dashboardState = ref.watch(dashboardProvider);
  return dashboardState.data?.recentBookings ?? [];
});

/// Upcoming appointments selector
final upcomingAppointmentsProvider = Provider<List<AppointmentEntity>>((ref) {
  final dashboardState = ref.watch(dashboardProvider);
  return dashboardState.data?.upcomingAppointments ?? [];
});

/// Upcoming bookings count selector
final upcomingCountProvider = Provider<int>((ref) {
  final kpis = ref.watch(dashboardKpiProvider);
  return kpis?.upcomingCount ?? 0;
});

/// Active requests count selector (for providers)
final activeRequestsProvider = Provider<int>((ref) {
  final kpis = ref.watch(dashboardKpiProvider);
  return kpis?.activeRequests ?? 0;
});

/// Total spend selector (for clients)
final totalSpendProvider = Provider<DashboardKpiEntity?>((ref) {
  final kpis = ref.watch(dashboardKpiProvider);
  return kpis;
});

/// Total revenue selector (for providers)
final totalRevenueProvider = Provider<DashboardKpiEntity?>((ref) {
  final kpis = ref.watch(dashboardKpiProvider);
  return kpis;
});

/// Completed bookings count selector
final completedBookingsProvider = Provider<int>((ref) {
  final kpis = ref.watch(dashboardKpiProvider);
  return kpis?.completedBookings ?? 0;
});

/// Cancelled bookings count selector
final cancelledBookingsProvider = Provider<int>((ref) {
  final kpis = ref.watch(dashboardKpiProvider);
  return kpis?.cancelledBookings ?? 0;
});

/// Average rating selector
final avgRatingProvider = Provider<double>((ref) {
  final kpis = ref.watch(dashboardKpiProvider);
  return kpis?.avgRating ?? 0.0;
});

/// Performance metrics provider (for providers)
final performanceMetricsProvider = Provider<Map<String, dynamic>>((ref) {
  final kpis = ref.watch(dashboardKpiProvider);
  return {
    'completed': kpis?.completedBookings ?? 0,
    'cancelled': kpis?.cancelledBookings ?? 0,
    'rating': kpis?.avgRating ?? 0.0,
    'reviewCount': kpis?.reviewCount ?? 0,
  };
});
