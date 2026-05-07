import 'package:discovaa/core/constants/app_constants.dart';
import 'package:discovaa/features/authentication/presentation/providers/registration_flow_provider.dart';
import 'package:discovaa/features/profile/presentation/providers/artisan_provider.dart';
import 'package:discovaa/features/profile/presentation/providers/user_profile_provider.dart';
import 'package:discovaa/features/home/presentation/providers/dashboard_provider.dart';
import 'package:discovaa/features/home/presentation/widgets/empty_state_card.dart';
import 'package:discovaa/features/home/presentation/widgets/section_header.dart';
import 'package:discovaa/shared/presentation/widgets/main_header.dart';
import 'package:discovaa/app/router/route_names.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:discovaa/features/profile/domain/entities/profile_enums.dart';
import 'package:discovaa/features/home/domain/entities/dashboard_entity.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  @override
  void initState() {
    super.initState();
    // Load dashboard data asynchronously without blocking initial render
    Future.microtask(() => _loadDashboardData());
  }

  void _loadDashboardData() {
    // Clear any previous errors before loading new data
    final currentState = ref.read(dashboardProvider);
    if (currentState.hasError) {
      ref.read(dashboardProvider.notifier).clearError();
    }

    final profileState = ref.read(userProfileProvider);
    final registrationState = ref.read(registrationFlowProvider);

    // Determine role: Profile role (source of truth) > Registration state (fallback)
    String roleName = 'client';
    if (profileState.profile != null) {
      roleName = profileState.profile!.isProvider ? 'provider' : 'client';
    } else {
      roleName = registrationState.selectedRole?.isProvider ?? false
          ? 'provider'
          : 'client';
    }

    final filter = ref.read(dashboardFilterProvider);
    ref
        .read(dashboardProvider.notifier)
        .loadDashboard(roleName, filter: filter);
  }

  Future<void> _refreshDashboard() async {
    final profileState = ref.read(userProfileProvider);
    final registrationState = ref.read(registrationFlowProvider);

    String roleName = 'client';
    if (profileState.profile != null) {
      roleName = profileState.profile!.isProvider ? 'provider' : 'client';
    } else {
      roleName = registrationState.selectedRole?.isProvider ?? false
          ? 'provider'
          : 'client';
    }

    final filter = ref.read(dashboardFilterProvider);
    await ref
        .read(dashboardProvider.notifier)
        .refresh(roleName, filter: filter);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(dashboardFilterProvider, (previous, next) {
      if (previous != next) {
        _loadDashboardData();
      }
    });

    final registrationState = ref.watch(registrationFlowProvider);
    final profileState = ref.watch(userProfileProvider);

    // Reactive role detection
    final isProvider = profileState.profile != null
        ? profileState.profile!.isProvider
        : (registrationState.selectedRole?.isProvider ?? false);
    final isISV = profileState.profile != null
        ? profileState.profile!.accountType == AccountType.provider
        : registrationState.selectedRole == UserRole.individualProvider;
    final dashboardState = ref.watch(dashboardProvider);
    final unreadCount = ref.watch(unreadMessagesProvider);
    final displayName =
        profileState.profile?.displayName?.trim().isNotEmpty == true
        ? profileState.profile!.displayName!.trim()
        : 'Welcome';

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Color(0xFFF8FBFF),
        body: RefreshIndicator(
          onRefresh: _refreshDashboard,
          color: AppColors.primary,
          child: Column(
            children: [
              MainHeader(),
              Expanded(
                child: SingleChildScrollView(
                  physics: AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.symmetric(
                    horizontal: 20.w,
                    vertical: 10.h,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Welcome Area
                      _DashboardWelcomeCard(
                        name: displayName,
                        onViewBookings: () => context.go(RouteNames.bookings),
                        onMessages: () => context.go(RouteNames.messages),
                        unreadCount: unreadCount,
                        isProvider: isProvider,
                      ),
                      SizedBox(height: 20.h),

                      // Search Area
                      _DashboardSearchField(),
                      SizedBox(height: 24.h),

                      // Loading State
                      if (dashboardState.isLoading) ...[
                        _DashboardSkeleton(),
                      ] else ...[
                        if (dashboardState.hasError) ...[
                          _DashboardError(
                            message: dashboardState.error!,
                            onRetry: _loadDashboardData,
                          ),
                          SizedBox(height: 20.h),
                        ],

                        // Spending Trend
                        _SpendingTrendCard(),
                        SizedBox(height: 20.h),

                        // Booking Mix
                        _BookingMixCard(),
                        SizedBox(height: 20.h),

                        // Appointments Section
                        _AppointmentsSection(
                          isProvider: isProvider,
                          isISV: isISV,
                        ),
                        SizedBox(height: 20.h),

                        // Upcoming Bookings & Active Requests
                        _UpcomingBookingsCard(),
                        SizedBox(height: 16.h),
                        if (isProvider) _ActiveRequestsCard(),
                        if (isProvider) SizedBox(height: 16.h),

                        // Total Spend & Messages
                        if (!isProvider) _TotalSpendCard(),
                        if (!isProvider) SizedBox(height: 16.h),
                        _MessagesCard(),
                        SizedBox(height: 16.h),

                        // Smart Insights
                        _SmartInsightsCard(),
                        SizedBox(height: 20.h),

                        // Performance Pulse (Provider only)
                        if (isProvider) _PerformancePulseCard(),
                        if (isProvider) SizedBox(height: 20.h),

                        // Recent Bookings
                        _RecentBookingsCard(isProvider: isProvider),
                        SizedBox(height: 16.h),

                        // Inbox Pulse
                        _InboxPulseCard(),
                        SizedBox(height: 30.h),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardWelcomeCard extends StatelessWidget {
  final String name;
  final VoidCallback onViewBookings;
  final VoidCallback onMessages;
  final int unreadCount;
  final bool isProvider;

  const _DashboardWelcomeCard({
    required this.name,
    required this.onViewBookings,
    required this.onMessages,
    this.unreadCount = 0,
    this.isProvider = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, AppColors.primary.withValues(alpha: 0.05)],
        ),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 20.r,
            offset: Offset(0, 10.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Welcome back",
            style: TextStyle(color: Colors.grey, fontSize: 12.sp),
          ),
          SizedBox(height: 4.h),
          Text(
            name,
            style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8.h),
          Text(
            "Here is your dream service at a glance — upcoming bookings, spending, and recommendations at a glance.",
            style: TextStyle(
              color: Colors.black54,
              fontSize: 13.sp,
              height: 1.4,
            ),
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              _ActionChip(
                icon: Icons.calendar_today,
                label: "View bookings",
                onTap: onViewBookings,
              ),
              SizedBox(width: 8.w),
              _ActionChip(
                icon: Icons.chat_bubble_outline,
                label: "Messages",
                onTap: onMessages,
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.star, color: Colors.white, size: 14.sp),
                SizedBox(width: 6.w),
                Text(
                  isProvider ? "For service providers" : "For end users",
                  style: TextStyle(color: Colors.white, fontSize: 12.sp),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardSearchField extends ConsumerWidget {
  const _DashboardSearchField();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TextEditingController searchController = TextEditingController();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15.r,
            offset: Offset(0, 5.h),
          ),
        ],
      ),
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: searchController,
        builder: (context, value, child) {
          return TextField(
            controller: searchController,
            onChanged: (val) {
              ref.read(artisanFilterProvider.notifier).setSearchQuery(val);
            },
            decoration: InputDecoration(
              hintText: "Search for services or artisans...",
              hintStyle: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 14.sp,
              ),
              prefixIcon: Icon(Icons.search, color: Colors.black),
              suffixIcon: value.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, color: Colors.grey),
                      onPressed: () {
                        searchController.clear();
                        ref
                            .read(artisanFilterProvider.notifier)
                            .setSearchQuery('');
                      },
                    )
                  : Container(
                      margin: EdgeInsets.all(8.w),
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Icon(Icons.tune, size: 18.sp, color: Colors.black),
                    ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 15.h),
            ),
          );
        },
      ),
    );
  }
}

class _ActionChip extends ConsumerWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14.sp),
            SizedBox(width: 6.w),
            Text(
              label,
              style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? child;
  final String? actionText;

  const _DashboardCard({
    required this.title,
    required this.subtitle,
    this.child,
    this.actionText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
              ),
              if (actionText != null)
                Text(
                  actionText!,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
            ],
          ),
          SizedBox(height: 6.h),
          Text(
            subtitle,
            style: TextStyle(color: Colors.black54, fontSize: 13.sp),
          ),
          if (child != null) ...[SizedBox(height: 20.h), child!],
        ],
      ),
    );
  }
}

class _SmallDashboardCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final String? value;

  const _SmallDashboardCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.iconColor = Colors.black,
    this.iconBgColor = const Color(0xFFF5F5F5),
    this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (value != null) ...[
                  SizedBox(height: 8.h),
                  Text(
                    value!,
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ] else ...[
                  SizedBox(height: 12.h),
                  Container(height: 2.h, width: 20.w, color: Colors.black),
                ],
                SizedBox(height: 12.h),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.black54, fontSize: 13.sp),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20.sp),
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final String value;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10.w,
              height: 10.h,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            SizedBox(width: 8.w),
            Text(
              label,
              style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.bold,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }
}

class _PerformanceItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;

  const _PerformanceItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Icon(icon, color: iconColor, size: 24.sp),
        ),
        SizedBox(width: 16.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15.sp),
              ),
              SizedBox(height: 2.h),
              Text(
                subtitle,
                style: TextStyle(color: Colors.black54, fontSize: 13.sp),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// DATA-DRIVEN WIDGETS
// ============================================================================

class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SkeletonCard(height: 200.h),
        SizedBox(height: 20.h),
        _SkeletonCard(height: 180.h),
        SizedBox(height: 20.h),
        _SkeletonCard(height: 120.h),
        SizedBox(height: 20.h),
        _SkeletonCard(height: 100.h),
      ],
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  final double height;

  const _SkeletonCard({required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(20.r),
      ),
    );
  }
}

class _DashboardError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _DashboardError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final isAuthError =
        message.contains('Authentication') || message.contains('log in');

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade400, size: 40.sp),
          SizedBox(height: 12.h),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.red.shade700),
          ),
          SizedBox(height: 12.h),
          if (isAuthError) ...[
            ElevatedButton.icon(
              onPressed: () => context.push('/login'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade400,
                foregroundColor: Colors.white,
              ),
              icon: Icon(Icons.login),
              label: Text('Log In'),
            ),
            SizedBox(height: 8.h),
          ],
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: isAuthError
                  ? Colors.grey.shade400
                  : Colors.red.shade400,
              foregroundColor: Colors.white,
            ),
            child: Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _SpendingTrendCard extends ConsumerWidget {
  const _SpendingTrendCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spendingTrend = ref.watch(spendingTrendProvider);

    if (spendingTrend == null || spendingTrend.isEmpty) {
      return _DashboardCard(
        title: "Spending trend",
        subtitle: "No spending data available yet.",
        child: _buildEmptyChart(),
      );
    }

    return _DashboardCard(
      title: "Spending trend",
      subtitle: spendingTrend.periodLabel,
      child: _SpendingTrendChart(data: spendingTrend),
    );
  }

  Widget _buildEmptyChart() {
    return SizedBox(
      height: 150.h,
      child: Center(
        child: Text(
          "Start booking services to see your spending trend",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade500, fontSize: 13.sp),
        ),
      ),
    );
  }
}

class _SpendingTrendChart extends StatelessWidget {
  final dynamic data;

  const _SpendingTrendChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final points = data.points as List<dynamic>;
    if (points.isEmpty) return SizedBox.shrink();

    final maxY = points
        .map((p) => p.amount as double)
        .fold(0.0, (max, val) => val > max ? val : max);

    return SizedBox(
      height: 150.h,
      child: BarChart(
        BarChartData(
          gridData: FlGridData(show: false),
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => Colors.black.withValues(alpha: 0.8),
              // tooltipRoundedRadius: 8,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final date = points[group.x].date as DateTime;
                final dateStr = DateFormat('MMM dd').format(date);
                return BarTooltipItem(
                  '$dateStr\n',
                  TextStyle(
                    color: Colors.white70,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w500,
                  ),
                  children: [
                    TextSpan(
                      text: '₦${rod.toY.toInt()}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 25.sp,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= points.length) {
                    return SizedBox.shrink();
                  }

                  // Show labels for every 2nd or 3rd point to avoid crowding
                  if (points.length > 7 &&
                      index % (points.length > 15 ? 4 : 2) != 0) {
                    return SizedBox.shrink();
                  }

                  final date = points[index].date as DateTime;
                  return Padding(
                    padding: EdgeInsets.only(top: 8.0),
                    child: Text(
                      DateFormat('dd/MM').format(date),
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: points.asMap().entries.map((entry) {
            return BarChartGroupData(
              x: entry.key,
              barRods: [
                BarChartRodData(
                  toY: entry.value.amount as double,
                  color: AppColors.primary,
                  width: points.length > 15 ? 6 : 10,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(4),
                    bottom: Radius.circular(1),
                  ),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: maxY > 0 ? maxY * 1.1 : 10,
                    color: AppColors.primary.withValues(alpha: 0.05),
                  ),
                ),
              ],
            );
          }).toList(),
          maxY: maxY > 0 ? maxY * 1.1 : 10,
        ),
      ),
    );
  }
}

class _BookingMixCard extends ConsumerWidget {
  const _BookingMixCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingMix = ref.watch(bookingMixProvider);

    if (bookingMix == null || bookingMix.isEmpty) {
      return _DashboardCard(
        title: "Booking mix",
        subtitle: "No booking data available yet.",
        child: _buildEmptyMix(),
      );
    }

    return _DashboardCard(
      title: "Booking mix",
      subtitle: "Status distribution across your bookings.",
      actionText: "See all",
      child: _BookingMixChart(data: bookingMix),
    );
  }

  Widget _buildEmptyMix() {
    return SizedBox(
      height: 140.h,
      child: Center(
        child: Text(
          "Your booking status distribution will appear here",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade500, fontSize: 13.sp),
        ),
      ),
    );
  }
}

class _BookingMixChart extends StatelessWidget {
  final dynamic data;

  const _BookingMixChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final total = data.total as int;
    if (total == 0) return SizedBox.shrink();

    final sections = [
      PieChartSectionData(
        color: Colors.amber,
        value: data.requestedPercentage,
        title: '',
        radius: 12,
      ),
      PieChartSectionData(
        color: AppColors.success,
        value: data.confirmedPercentage,
        title: '',
        radius: 12,
      ),
      PieChartSectionData(
        color: Colors.black,
        value: data.completedPercentage,
        title: '',
        radius: 12,
      ),
      PieChartSectionData(
        color: Colors.red.shade200,
        value: data.cancelledPercentage,
        title: '',
        radius: 12,
      ),
    ];

    return Row(
      children: [
        SizedBox(
          height: 140.h,
          width: 140.w,
          child: PieChart(
            PieChartData(
              sectionsSpace: 0,
              centerSpaceRadius: 40,
              sections: sections,
            ),
          ),
        ),
        SizedBox(width: 20.w),
        Expanded(
          child: Column(
            children: [
              _LegendItem(
                color: Colors.amber,
                label: "Requested",
                value:
                    "${data.requested} (${data.requestedPercentage.toStringAsFixed(0)}%)",
              ),
              SizedBox(height: 8.h),
              _LegendItem(
                color: AppColors.success,
                label: "Confirmed",
                value:
                    "${data.confirmed} (${data.confirmedPercentage.toStringAsFixed(0)}%)",
              ),
              SizedBox(height: 8.h),
              _LegendItem(
                color: Colors.black,
                label: "Completed",
                value:
                    "${data.completed} (${data.completedPercentage.toStringAsFixed(0)}%)",
              ),
              SizedBox(height: 8.h),
              _LegendItem(
                color: Colors.red.shade200,
                label: "Cancelled",
                value:
                    "${data.cancelled} (${data.cancelledPercentage.toStringAsFixed(0)}%)",
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AppointmentsSection extends ConsumerWidget {
  final bool isProvider;
  final bool isISV;

  const _AppointmentsSection({required this.isProvider, required this.isISV});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appointments = ref.watch(upcomingAppointmentsProvider);

    return Column(
      children: [
        SectionHeader(title: "Appointments"),
        if (appointments.isEmpty)
          Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Icon(
                      Icons.calendar_today_outlined,
                      size: 18.sp,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      isProvider
                          ? (isISV
                                ? "Your upcoming client appointments will appear here"
                                : "Scheduled business service appointments will appear here")
                          : "All appointments with artisans will appear here",
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 15.h),
              EmptyStateCard(text: "There are no appointments yet."),
            ],
          )
        else
          Column(
            children: appointments.take(3).map((appointment) {
              return _AppointmentItem(
                appointment: appointment,
                isProvider: isProvider,
              );
            }).toList(),
          ),
      ],
    );
  }
}

class _AppointmentItem extends StatelessWidget {
  final dynamic appointment;
  final bool isProvider;

  const _AppointmentItem({required this.appointment, required this.isProvider});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 48.w,
            height: 48.h,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.calendar_today, color: AppColors.primary),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appointment.serviceName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14.sp,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2.h),
                Text(
                  isProvider
                      ? "Client: ${appointment.clientName}"
                      : "Artisan: ${appointment.providerName}",
                  style: TextStyle(
                    color: Colors.black.withValues(alpha: 0.7),
                    fontSize: 13.sp,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (isProvider) ...[
                  SizedBox(height: 2.h),
                  Text(
                    "Service by: ${appointment.providerName}",
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 11.sp,
                    ),
                  ),
                ],
                SizedBox(height: 2.h),
                Text(
                  '${appointment.formattedDate} • ${appointment.formattedTime}',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12.sp,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Text(
              appointment.status.toString().toUpperCase(),
              style: TextStyle(
                color: AppColors.success,
                fontSize: 10.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UpcomingBookingsCard extends ConsumerWidget {
  const _UpcomingBookingsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(upcomingCountProvider);

    return _SmallDashboardCard(
      title: "Upcoming bookings",
      subtitle: count > 0
          ? "$count appointments set up ahead"
          : "Appointments set up ahead.",
      icon: Icons.calendar_month,
      value: count > 0 ? count.toString() : null,
    );
  }
}

class _ActiveRequestsCard extends ConsumerWidget {
  const _ActiveRequestsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(activeRequestsProvider);

    return _SmallDashboardCard(
      title: "Active requests",
      subtitle: count > 0
          ? "$count pending service requests"
          : "Looking for pending requests?",
      icon: Icons.flash_on,
      iconColor: Colors.orange,
      iconBgColor: Color(0xFFFFF3E0),
      value: count > 0 ? count.toString() : null,
    );
  }
}

class _TotalSpendCard extends ConsumerWidget {
  const _TotalSpendCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kpi = ref.watch(totalSpendProvider);

    String subtitle = "Overall booking value.";
    if (kpi != null && kpi.totalSpend > 0) {
      subtitle = "Total spend: ${kpi.formattedTotalSpend}";
    }

    return _SmallDashboardCard(
      title: "Total spend",
      subtitle: subtitle,
      icon: Icons.trending_up,
      iconColor: Colors.green,
      iconBgColor: Color(0xFFE8F5E9),
      value: kpi?.totalSpend != null && kpi!.totalSpend > 0
          ? kpi.formattedTotalSpend
          : null,
    );
  }
}

class _MessagesCard extends ConsumerWidget {
  const _MessagesCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(unreadMessagesProvider);

    return _SmallDashboardCard(
      title: "Messages",
      subtitle: count > 0
          ? "$count unread conversations"
          : "No unread conversations",
      icon: Icons.chat_bubble_outline,
      value: count > 0 ? count.toString() : null,
    );
  }
}

class _SmartInsightsCard extends ConsumerWidget {
  const _SmartInsightsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insights = ref.watch(insightsProvider);

    if (insights.isEmpty) {
      return _DashboardCard(
        title: "Smart insights",
        subtitle: "Actionable guidance powered by your recent activity",
        child: _buildEmptyInsight(),
      );
    }

    return _DashboardCard(
      title: "Smart insights",
      subtitle: "Actionable guidance powered by your recent activity",
      child: Column(
        children: insights.take(2).map((insight) {
          return _InsightItem(insight: insight);
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyInsight() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Plan your next service",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13.sp,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  "Discover top-rated providers for your needs.",
                  style: TextStyle(color: Colors.black54, fontSize: 13.sp),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {},
            child: Text(
              "Explore\nservices",
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(width: 8.w),
          Icon(Icons.chevron_right, size: 20.sp),
        ],
      ),
    );
  }
}

class _InsightItem extends StatelessWidget {
  final dynamic insight;

  const _InsightItem({required this.insight});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          if (insight.icon != null) ...[
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                insight.icon as IconData,
                color: AppColors.primary,
                size: 20.sp,
              ),
            ),
            SizedBox(width: 12.w),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight.title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13.sp,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  insight.description,
                  style: TextStyle(color: Colors.black54, fontSize: 13.sp),
                ),
              ],
            ),
          ),
          if (insight.actionLabel != null) ...[
            GestureDetector(
              onTap: () {
                if (insight.actionRoute != null) {
                  // Navigate to route
                }
              },
              child: Text(
                insight.actionLabel,
                textAlign: TextAlign.right,
                style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(width: 8.w),
            Icon(Icons.chevron_right, size: 20.sp),
          ],
        ],
      ),
    );
  }
}

class _PerformancePulseCard extends ConsumerWidget {
  const _PerformancePulseCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metrics = ref.watch(performanceMetricsProvider);

    return _DashboardCard(
      title: "Performance pulse",
      subtitle: "A snapshot of your reliability and trust.",
      child: Column(
        children: [
          _PerformanceItem(
            icon: Icons.check_circle_outline,
            iconColor: Colors.green,
            title: "${metrics['completed']} completed",
            subtitle: "Out of total generated requests",
          ),
          SizedBox(height: 16.h),
          _PerformanceItem(
            icon: Icons.warning_amber_rounded,
            iconColor: Colors.orange,
            title: "${metrics['cancelled']} cancelled",
            subtitle: "Bookings cancelled requests",
          ),
          SizedBox(height: 16.h),
          _PerformanceItem(
            icon: Icons.star_border,
            iconColor: Colors.black,
            title:
                "${metrics['rating'] > 0 ? metrics['rating'].toStringAsFixed(1) : '--'} rating",
            subtitle: "Customer feedback",
          ),
        ],
      ),
    );
  }
}

class _RecentBookingsCard extends ConsumerWidget {
  final bool isProvider;

  const _RecentBookingsCard({required this.isProvider});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookings = ref.watch(recentBookingsProvider);
    final completedCount = ref.watch(completedBookingsProvider);

    if (bookings.isEmpty) {
      return _DashboardCard(
        title: "Recent bookings",
        subtitle:
            "Past and already concluded bookings.\n$completedCount booking total",
        actionText: "View all",
      );
    }

    return _DashboardCard(
      title: "Recent bookings",
      subtitle:
          "Past and already concluded bookings.\n$completedCount booking total",
      actionText: "View all",
      child: Column(
        children: bookings.take(3).map((booking) {
          return _RecentBookingItem(booking: booking, isProvider: isProvider);
        }).toList(),
      ),
    );
  }
}

class _RecentBookingItem extends StatelessWidget {
  final RecentBookingEntity booking;
  final bool isProvider;

  const _RecentBookingItem({required this.booking, required this.isProvider});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child:
                booking.serviceImage != null &&
                    booking.serviceImage!.startsWith('http')
                ? Image.network(
                    booking.serviceImage!,
                    width: 48.w,
                    height: 48.h,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Image.asset(
                      AppAssets.servicePlaceholder(booking.id),
                      width: 48.w,
                      height: 48.h,
                      fit: BoxFit.cover,
                    ),
                  )
                : Image.asset(
                    AppAssets.servicePlaceholder(booking.id),
                    width: 48.w,
                    height: 48.h,
                    fit: BoxFit.cover,
                  ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.serviceName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13.sp,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4.h),
                Text(
                  "Provider: ${booking.providerName}",
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12.sp,
                  ),
                ),
                if (isProvider && booking.clientName != null) ...[
                  SizedBox(height: 2.h),
                  Text(
                    "Client: ${booking.clientName}",
                    style: TextStyle(
                      color: AppColors.primary.withValues(alpha: 0.8),
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                SizedBox(height: 2.h),
                Text(
                  booking.formattedDate,
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 11.sp,
                  ),
                ),
              ],
            ),
          ),
          if (booking.formattedAmount != null)
            Text(
              booking.formattedAmount!,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.sp),
            ),
        ],
      ),
    );
  }
}

class _InboxPulseCard extends ConsumerWidget {
  const _InboxPulseCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(pendingMessagesProvider);

    return _DashboardCard(
      title: "Inbox pulse",
      subtitle: "Messages that need your attention.\n$count pending messages",
      actionText: "Read now",
    );
  }
}
