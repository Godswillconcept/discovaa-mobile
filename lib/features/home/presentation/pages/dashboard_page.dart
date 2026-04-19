import 'package:discovaa/core/constants/app_constants.dart';
import 'package:discovaa/features/authentication/presentation/providers/signup_provider.dart';
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
import 'package:go_router/go_router.dart';

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
    final signupState = ref.read(signupProvider);

    // Determine role: Profile role (source of truth) > Signup state (fallback)
    String roleName = 'client';
    if (profileState.profile != null) {
      roleName = profileState.profile!.isProvider ? 'provider' : 'client';
    } else {
      roleName = signupState.selectedRole.isProvider ? 'provider' : 'client';
    }

    final filter = ref.read(dashboardFilterProvider);
    ref.read(dashboardProvider.notifier).loadDashboard(roleName, filter: filter);
  }

  Future<void> _refreshDashboard() async {
    final profileState = ref.read(userProfileProvider);
    final signupState = ref.read(signupProvider);

    String roleName = 'client';
    if (profileState.profile != null) {
      roleName = profileState.profile!.isProvider ? 'provider' : 'client';
    } else {
      roleName = signupState.selectedRole.isProvider ? 'provider' : 'client';
    }

    final filter = ref.read(dashboardFilterProvider);
    await ref.read(dashboardProvider.notifier).refresh(roleName, filter: filter);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(dashboardFilterProvider, (previous, next) {
      if (previous != next) {
        _loadDashboardData();
      }
    });

    final signupState = ref.watch(signupProvider);
    final profileState = ref.watch(userProfileProvider);

    // Reactive role detection
    final isProvider = profileState.profile != null
        ? profileState.profile!.isProvider
        : signupState.selectedRole.isProvider;

    final isISV = profileState.profile != null
        ? profileState.profile!.accountType == AccountType.provider
        : signupState.selectedRole == UserRole.individualProvider;
    final dashboardState = ref.watch(dashboardProvider);
    final unreadCount = ref.watch(unreadMessagesProvider);
    final displayName =
        profileState.profile?.displayName?.trim().isNotEmpty == true
        ? profileState.profile!.displayName!.trim()
        : ((signupState.displayName?.trim().isNotEmpty == true)
              ? signupState.displayName!.trim()
              : 'Welcome');

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FBFF),
        body: RefreshIndicator(
          onRefresh: _refreshDashboard,
          color: AppColors.primary,
          child: Column(
            children: [
              const MainHeader(),
              Expanded(
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
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
                      ),
                      const SizedBox(height: 20),

                      // Search Area
                      const _DashboardSearchField(),
                      const SizedBox(height: 24),

                      // Loading State
                      if (dashboardState.isLoading) ...[
                        const _DashboardSkeleton(),
                      ] else ...[
                        if (dashboardState.hasError) ...[
                          _DashboardError(
                            message: dashboardState.error!,
                            onRetry: _loadDashboardData,
                          ),
                          const SizedBox(height: 20),
                        ],

                        // Spending Trend
                        const _SpendingTrendCard(),
                        const SizedBox(height: 20),

                        // Booking Mix
                        const _BookingMixCard(),
                        const SizedBox(height: 20),

                        // Appointments Section
                        _AppointmentsSection(
                          isProvider: isProvider,
                          isISV: isISV,
                        ),
                        const SizedBox(height: 20),

                        // Upcoming Bookings & Active Requests
                        const _UpcomingBookingsCard(),
                        const SizedBox(height: 16),
                        if (isProvider) const _ActiveRequestsCard(),
                        if (isProvider) const SizedBox(height: 16),

                        // Total Spend & Messages
                        if (!isProvider) const _TotalSpendCard(),
                        if (!isProvider) const SizedBox(height: 16),
                        const _MessagesCard(),
                        const SizedBox(height: 16),

                        // Smart Insights
                        const _SmartInsightsCard(),
                        const SizedBox(height: 20),

                        // Performance Pulse (Provider only)
                        if (isProvider) const _PerformancePulseCard(),
                        if (isProvider) const SizedBox(height: 20),

                        // Recent Bookings
                        const _RecentBookingsCard(),
                        const SizedBox(height: 16),

                        // Inbox Pulse
                        const _InboxPulseCard(),
                        const SizedBox(height: 30),
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

  const _DashboardWelcomeCard({
    required this.name,
    required this.onViewBookings,
    required this.onMessages,
    this.unreadCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, AppColors.primary.withValues(alpha: 0.05)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Welcome back",
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            name,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            "Here is your dream service at a glance — upcoming bookings, spending, and recommendations at a glance.",
            style: TextStyle(color: Colors.black54, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _ActionChip(
                icon: Icons.calendar_today,
                label: "View bookings",
                onTap: onViewBookings,
              ),
              const SizedBox(width: 8),
              _ActionChip(
                icon: Icons.chat_bubble_outline,
                label: "Messages",
                onTap: onMessages,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.star, color: Colors.white, size: 14),
                SizedBox(width: 6),
                Text(
                  "For service providers",
                  style: TextStyle(color: Colors.white, fontSize: 12),
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
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
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
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
              prefixIcon: const Icon(Icons.search, color: Colors.black),
              suffixIcon: value.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.grey),
                      onPressed: () {
                        searchController.clear();
                        ref
                            .read(artisanFilterProvider.notifier)
                            .setSearchQuery('');
                      },
                    )
                  : Container(
                      margin: const EdgeInsets.all(8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.tune,
                        size: 18,
                        color: Colors.black,
                      ),
                    ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 15),
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (actionText != null)
                Text(
                  actionText!,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.black54, fontSize: 13),
          ),
          if (child != null) ...[const SizedBox(height: 20), child!],
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (value != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    value!,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 12),
                  Container(height: 2, width: 20, color: Colors.black),
                ],
                const SizedBox(height: 12),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.black54, fontSize: 13),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
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
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
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
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(color: Colors.black54, fontSize: 13),
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
        _SkeletonCard(height: 200),
        const SizedBox(height: 20),
        _SkeletonCard(height: 180),
        const SizedBox(height: 20),
        _SkeletonCard(height: 120),
        const SizedBox(height: 20),
        _SkeletonCard(height: 100),
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
        borderRadius: BorderRadius.circular(20),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade400, size: 40),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.red.shade700),
          ),
          const SizedBox(height: 12),
          if (isAuthError) ...[
            ElevatedButton.icon(
              onPressed: () => context.push('/login'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade400,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.login),
              label: const Text('Log In'),
            ),
            const SizedBox(height: 8),
          ],
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: isAuthError
                  ? Colors.grey.shade400
                  : Colors.red.shade400,
              foregroundColor: Colors.white,
            ),
            child: const Text('Retry'),
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
      height: 150,
      child: Center(
        child: Text(
          "Start booking services to see your spending trend",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
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
    if (points.isEmpty) return const SizedBox.shrink();

    final spots = points.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.amount as double);
    }).toList();

    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final minY = 0.0;

    return SizedBox(
      height: 150,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                interval: (spots.length / 4).ceil().toDouble().clamp(
                  1,
                  double.infinity,
                ),
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= points.length) {
                    return const SizedBox.shrink();
                  }
                  final date = points[index].date as DateTime;
                  return Text(
                    '${date.day}/${date.month}',
                    style: const TextStyle(color: Colors.black54, fontSize: 10),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: (spots.length - 1).toDouble(),
          minY: minY,
          maxY: maxY > 0 ? maxY * 1.2 : 5,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: AppColors.primary,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.primary.withValues(alpha: 0.15),
              ),
            ),
          ],
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
      height: 140,
      child: Center(
        child: Text(
          "Your booking status distribution will appear here",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
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
    if (total == 0) return const SizedBox.shrink();

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
          height: 140,
          width: 140,
          child: PieChart(
            PieChartData(
              sectionsSpace: 0,
              centerSpaceRadius: 40,
              sections: sections,
            ),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            children: [
              _LegendItem(
                color: Colors.amber,
                label: "Requested",
                value:
                    "${data.requested} (${data.requestedPercentage.toStringAsFixed(0)}%)",
              ),
              const SizedBox(height: 8),
              _LegendItem(
                color: AppColors.success,
                label: "Confirmed",
                value:
                    "${data.confirmed} (${data.confirmedPercentage.toStringAsFixed(0)}%)",
              ),
              const SizedBox(height: 8),
              _LegendItem(
                color: Colors.black,
                label: "Completed",
                value:
                    "${data.completed} (${data.completedPercentage.toStringAsFixed(0)}%)",
              ),
              const SizedBox(height: 8),
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
        const SectionHeader(title: "Appointments"),
        if (appointments.isEmpty)
          Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: const Icon(
                      Icons.calendar_today_outlined,
                      size: 18,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isProvider
                          ? (isISV
                                ? "Your upcoming client appointments will appear here"
                                : "Scheduled business service appointments will appear here")
                          : "All appointments with artisans will appear here",
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              const EmptyStateCard(text: "There are no appointments yet."),
            ],
          )
        else
          Column(
            children: appointments.take(3).map((appointment) {
              return _AppointmentItem(appointment: appointment);
            }).toList(),
          ),
      ],
    );
  }
}

class _AppointmentItem extends StatelessWidget {
  final dynamic appointment;

  const _AppointmentItem({required this.appointment});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.calendar_today, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appointment.serviceName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${appointment.formattedDate} • ${appointment.formattedTime}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              appointment.status.toString().toUpperCase(),
              style: const TextStyle(
                color: AppColors.success,
                fontSize: 10,
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
      iconBgColor: const Color(0xFFFFF3E0),
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
      iconBgColor: const Color(0xFFE8F5E9),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Plan your next service",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                SizedBox(height: 4),
                Text(
                  "Discover top-rated providers for your needs.",
                  style: TextStyle(color: Colors.black54, fontSize: 12),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {},
            child: const Text(
              "Explore\nservices",
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, size: 20),
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
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          if (insight.icon != null) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                insight.icon as IconData,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  insight.description,
                  style: const TextStyle(color: Colors.black54, fontSize: 12),
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
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, size: 20),
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
          const SizedBox(height: 16),
          _PerformanceItem(
            icon: Icons.warning_amber_rounded,
            iconColor: Colors.orange,
            title: "${metrics['cancelled']} cancelled",
            subtitle: "Bookings cancelled requests",
          ),
          const SizedBox(height: 16),
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
  const _RecentBookingsCard();

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
          return _RecentBookingItem(booking: booking);
        }).toList(),
      ),
    );
  }
}

class _RecentBookingItem extends StatelessWidget {
  final dynamic booking;

  const _RecentBookingItem({required this.booking});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          if (booking.serviceImage != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                booking.serviceImage,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 48,
                  height: 48,
                  color: Colors.grey.shade300,
                  child: const Icon(Icons.image_not_supported, size: 20),
                ),
              ),
            )
          else
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.home_repair_service, size: 20),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.serviceName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  booking.providerName,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  booking.formattedDate,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                ),
              ],
            ),
          ),
          if (booking.formattedAmount != null)
            Text(
              booking.formattedAmount,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
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
