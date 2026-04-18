import '../entities/dashboard_entity.dart';

/// Repository interface for dashboard data
abstract class DashboardRepository {
  /// Get dashboard data from local cache instantly
  DashboardEntity? getCachedDashboard(String role, {DashboardFilterEntity? filter});

  /// Get provider dashboard data with KPIs and analytics
  /// 
  /// [filter] Optional filter for date range and other parameters
  /// Returns [DashboardEntity] containing all provider dashboard data
  Future<DashboardEntity> getProviderDashboard({DashboardFilterEntity? filter});

  /// Get client dashboard data with bookings and spending
  /// 
  /// [filter] Optional filter for date range and other parameters
  /// Returns [DashboardEntity] containing all client dashboard data
  Future<DashboardEntity> getClientDashboard({DashboardFilterEntity? filter});

  /// Get unread message count for the current user
  /// 
  /// Returns the number of unread messages
  Future<int> getUnreadMessageCount();

  /// Get pending message count for the current user
  /// 
  /// Returns the number of messages requiring attention
  Future<int> getPendingMessageCount();

  /// Refresh dashboard data
  /// 
  /// [role] The user role ('provider' or 'client')
  /// [filter] Optional filter parameters
  /// Returns refreshed [DashboardEntity]
  Future<DashboardEntity> refreshDashboard(String role, {DashboardFilterEntity? filter});
}
