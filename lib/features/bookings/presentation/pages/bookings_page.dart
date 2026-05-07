import 'package:discovaa/core/constants/app_constants.dart';
import 'package:discovaa/features/authentication/presentation/providers/auth_provider.dart';
import 'package:discovaa/features/bookings/data/models/booking_api_models.dart';
import 'package:discovaa/features/bookings/data/models/booking_model.dart';
import 'package:discovaa/features/bookings/presentation/pages/booking_detail_page.dart';
import 'package:discovaa/features/bookings/presentation/providers/bookings_provider.dart';
import 'package:discovaa/shared/presentation/widgets/main_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// ---------------------------------------------------------------------------
// BookingsPage — root
// ---------------------------------------------------------------------------

class BookingsPage extends ConsumerStatefulWidget {
  const BookingsPage({super.key});

  @override
  ConsumerState<BookingsPage> createState() => _BookingsPageState();
}

class _BookingsPageState extends ConsumerState<BookingsPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(bookingsProvider.notifier).loadBookings();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final userRole = authState.value?.user?.role;
    final isProvider = isProviderRole(userRole);
    final pageTitle = isProvider ? 'My Bookings' : 'Booking History';

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: DefaultTabController(
        length: 5,
        child: Scaffold(
          backgroundColor: const Color(0xFFF8FBFF),
          body: Column(
            children: [
              const MainHeader(),
              Container(
                color: Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              pageTitle,
                              style: TextStyle(
                                fontSize: 24.sp,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),
                          // Active bookings badge
                          Consumer(
                            builder: (ctx, ref, _) {
                              final count = ref.watch(
                                activeBookingCountProvider,
                              );
                              if (count == 0) return const SizedBox.shrink();
                              return Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 10.w,
                                  vertical: 4.h,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(20.r),
                                ),
                                child: Text(
                                  '$count active',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 10.h),
                      child: _SearchField(
                        onChanged: ref
                            .read(bookingsProvider.notifier)
                            .updateSearch,
                      ),
                    ),
                    TabBar(
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      indicatorColor: AppColors.primaryRed,
                      labelColor: Colors.black,
                      unselectedLabelColor: Colors.grey,
                      dividerColor: Colors.transparent,
                      indicatorSize: TabBarIndicatorSize.label,
                      indicatorWeight: 3,
                      labelStyle: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13.sp,
                      ),
                      unselectedLabelStyle: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 13.sp,
                      ),
                      tabs: const [
                        Tab(text: 'Requested'),
                        Tab(text: 'Confirmed'),
                        Tab(text: 'Ongoing'),
                        Tab(text: 'Completed'),
                        Tab(text: 'Cancelled'),
                      ],
                    ),
                    SizedBox(height: 10.h),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _BookingsTab(status: BookingStatus.requested),
                    _BookingsTab(status: BookingStatus.confirmed),
                    _BookingsTab(status: BookingStatus.ongoing),
                    _BookingsTab(status: BookingStatus.completed),
                    _BookingsTab(status: BookingStatus.cancelled),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Search field
// ---------------------------------------------------------------------------

class _SearchField extends StatelessWidget {
  final ValueChanged<String> onChanged;
  const _SearchField({required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: TextField(
        onChanged: onChanged,
        style: TextStyle(color: Colors.white, fontSize: 13.sp),
        decoration: InputDecoration(
          hintText: 'Search your bookings…',
          hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13.sp),
          prefixIcon: Icon(
            Icons.search,
            size: 20.sp,
            color: Colors.grey.shade500,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 12.h),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bookings tab — filtered by status
// ---------------------------------------------------------------------------

class _BookingsTab extends ConsumerWidget {
  final BookingStatus status;
  const _BookingsTab({required this.status});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsState = ref.watch(bookingsProvider);

    if (bookingsState.status == BookingsLoadStatus.loading) {
      return const _BookingsListSkeleton();
    }

    if (bookingsState.status == BookingsLoadStatus.failure) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded, size: 48.sp, color: Colors.grey),
            SizedBox(height: 12.h),
            Text(
              bookingsState.errorMessage ?? 'Something went wrong.',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            SizedBox(height: 12.h),
            ElevatedButton(
              onPressed: () =>
                  ref.read(bookingsProvider.notifier).loadBookings(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50.r),
                ),
              ),
              child: const Text('Retry', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    final bookings = bookingsState.byStatus(status);

    if (bookings.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => ref.read(bookingsProvider.notifier).refreshBookings(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: _EmptyState(status: status),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(bookingsProvider.notifier).refreshBookings(),
      child: ListView.separated(
        padding: EdgeInsets.all(20.w),
        itemCount: bookings.length,
        separatorBuilder: (context, index) => SizedBox(height: 14.h),
        itemBuilder: (context, i) => _BookingCard(booking: bookings[i]),
      ),
    );
  }
}

class _BookingsListSkeleton extends StatelessWidget {
  const _BookingsListSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: EdgeInsets.all(20.w),
      itemCount: 4,
      separatorBuilder: (context, index) => SizedBox(height: 14.h),
      itemBuilder: (context, index) {
        return Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 120.w,
                height: 14.h,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              SizedBox(height: 12.h),
              Container(
                width: double.infinity,
                height: 18.h,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              SizedBox(height: 10.h),
              Container(
                width: 180.w,
                height: 14.h,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Booking card
// ---------------------------------------------------------------------------

class _BookingCard extends ConsumerWidget {
  final BookingModel booking;
  const _BookingCard({required this.booking});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = booking.status;

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => BookingDetailPage(booking: booking)),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8.r,
              offset: Offset(0, 3.h),
            ),
          ],
        ),
        child: Column(
          children: [
            // ── Header ────────────────────────────────────────────────
            Padding(
              padding: EdgeInsets.all(14.w),
              child: Row(
                children: [
                  // Service cover thumbnail
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10.r),
                    child: booking.service.imagePath != null
                        ? _buildServiceImage(booking.service.imagePath!)
                        : _ThumbFallback(),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          booking.service.category,
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          booking.service.title,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          booking.service.formattedPrice,
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Status badge
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 9.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: status.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Text(
                      status.displayName,
                      style: TextStyle(
                        color: status.color,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Divider(height: 1, color: Colors.white.withValues(alpha: 0.1)),

            // ── Schedule row ──────────────────────────────────────────
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
              child: Row(
                children: [
                  _MetaIcon(
                    icon: Icons.calendar_today_outlined,
                    label: booking.scheduledDisplayDate,
                  ),
                  SizedBox(width: 16.w),
                  _MetaIcon(
                    icon: Icons.access_time_rounded,
                    label: booking.scheduledDisplayTime,
                  ),
                  if (booking.service.durationMinutes != null) ...[
                    SizedBox(width: 16.w),
                    _MetaIcon(
                      icon: Icons.timer_outlined,
                      label: _fmtDuration(booking.service.durationMinutes!),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmtDuration(int minutes) {
    if (minutes < 60) return '$minutes min';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '$h hr' : '$h hr $m min';
  }

  /// Builds service image widget, handling both network URLs and local assets
  Widget _buildServiceImage(String imagePath) {
    final isNetworkUrl =
        imagePath.startsWith('http://') || imagePath.startsWith('https://');
    if (isNetworkUrl) {
      return Image.network(
        imagePath,
        width: 52.w,
        height: 52.h,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stack) => _ThumbFallback(),
      );
    }
    return Image.asset(
      imagePath,
      width: 52.w,
      height: 52.h,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stack) => _ThumbFallback(),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  final BookingStatus status;
  const _EmptyState({required this.status});

  @override
  Widget build(BuildContext context) {
    final icons = {
      BookingStatus.requested: Icons.hourglass_empty_rounded,
      BookingStatus.confirmed: Icons.calendar_today_outlined,
      BookingStatus.ongoing: Icons.handyman_outlined,
      BookingStatus.completed: Icons.check_circle_outline_rounded,
      BookingStatus.cancelled: Icons.cancel_outlined,
    };

    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icons[status] ?? Icons.inbox_outlined,
              size: 56.sp,
              color: Colors.grey.shade300,
            ),
            SizedBox(height: 16.h),
            Text(
              'No ${status.displayName.toLowerCase()} bookings',
              style: TextStyle(
                fontSize: 17.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white70,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Your ${status.displayName.toLowerCase()} bookings will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13.sp, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Local helpers
// ---------------------------------------------------------------------------

class _ThumbFallback extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52.w,
      height: 52.h,
      color: const Color(0xFFF0F0F0),
      child: Icon(
        Icons.home_repair_service_rounded,
        size: 24.sp,
        color: Colors.black26,
      ),
    );
  }
}

class _MetaIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MetaIcon({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13.sp, color: Colors.grey.shade500),
        SizedBox(width: 4.w),
        Text(
          label,
          style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade500),
        ),
      ],
    );
  }
}
