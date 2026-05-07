import 'package:discovaa/app/router/route_names.dart';
import 'package:discovaa/core/constants/app_constants.dart';
import 'package:discovaa/features/authentication/presentation/providers/auth_provider.dart';
import 'package:discovaa/features/bookings/data/models/booking_model.dart';
import 'package:discovaa/features/bookings/presentation/providers/bookings_provider.dart';
import 'package:discovaa/features/services/data/models/service_model.dart';
import 'package:discovaa/features/messaging/presentation/providers/messaging_provider.dart';
import 'package:discovaa/features/profile/presentation/providers/user_profile_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Utility Functions
// ─────────────────────────────────────────────────────────────────────────────

/// Represents the current user's role in a specific booking
enum BookingUserRole { client, provider }

/// Determines the current user's role in a specific booking
BookingUserRole? resolveBookingUserRole({
  required String? currentUserId,
  required String? currentUserProviderId,
  required BookingModel booking,
}) {
  // Check if current user is the CLIENT for this booking
  if (currentUserId != null && currentUserId == booking.clientId) {
    return BookingUserRole.client;
  }

  // Check if current user is the PROVIDER for this booking
  if (currentUserProviderId != null &&
      currentUserProviderId == booking.providerId) {
    return BookingUserRole.provider;
  }

  return null; // User is not part of this booking
}

/// Formats a DateTime to a readable string like "4/29/2026, 3:30 PM"
String formatBookingDate(DateTime date) {
  final hour = date.hour > 12
      ? date.hour - 12
      : (date.hour == 0 ? 12 : date.hour);
  final minute = date.minute.toString().padLeft(2, '0');
  final period = date.hour >= 12 ? 'PM' : 'AM';
  return '${date.month}/${date.day}/${date.year}, $hour:$minute $period';
}

/// Extracts numeric price from a formatted price string (e.g., "NGN 5,000" -> "5000")
String extractNumericPrice(String formattedPrice) {
  return formattedPrice.replaceAll(RegExp(r'[^0-9.]'), '');
}

/// Converts payment status from API (e.g., "REQUIRES_ACTION") to readable format ("Requires action")
String formatPaymentStatus(String? status) {
  if (status == null || status.isEmpty) return 'Unknown';

  // Handle snake_case or UPPER_CASE
  final readable = status
      .toLowerCase()
      .replaceAll('_', ' ')
      .split(' ')
      .map(
        (word) => word.isNotEmpty
            ? '${word[0].toUpperCase()}${word.substring(1)}'
            : '',
      )
      .join(' ');

  return readable;
}

/// Checks if payment has been successfully completed (captured or authorized)
bool isPaymentSuccessful(String? paymentStatus) {
  if (paymentStatus == null) return false;
  return paymentStatus == 'CAPTURED' || paymentStatus == 'AUTHORIZED';
}

// ─────────────────────────────────────────────────────────────────────────────
// Extracted Widgets
// ─────────────────────────────────────────────────────────────────────────────

class _TitleSection extends StatelessWidget {
  final BookingModel booking;
  final bool isProvider;

  const _TitleSection({required this.booking, required this.isProvider});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Booking details',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                isProvider
                    ? 'Booking for ${booking.userDisplayName ?? booking.clientName}'
                    : 'Booking with ${booking.providerName ?? 'Provider'}',
                style: TextStyle(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: 16.w),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
                side: BorderSide(color: Colors.grey.shade300),
              ),
              child: const Text(
                'Back',
                style: TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (!isProvider) ...[
              SizedBox(width: 8.w),
              _MessageButton(booking: booking),
            ],
          ],
        ),
      ],
    );
  }
}

class _MessageButton extends ConsumerWidget {
  final BookingModel booking;

  const _MessageButton({required this.booking});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      onPressed: () {
        final displayName = booking.providerName ?? 'Provider';
        final avatarPath = booking.providerAvatarPath;
        final conversation = ref
            .read(messagingProvider.notifier)
            .findOrCreateConversation(
              artisanId: booking.id,
              artisanName: displayName,
              artisanAvatar:
                  avatarPath ?? 'assets/images/placeholders/user_avatar.png',
            );
        context.push('${RouteNames.messages}/chat', extra: conversation);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.black,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
        elevation: 0,
      ),
      child: const Text(
        'Message',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// Full-screen detail view for a single [BookingModel].
class BookingDetailPage extends ConsumerStatefulWidget {
  final BookingModel booking;
  const BookingDetailPage({super.key, required this.booking});

  @override
  ConsumerState<BookingDetailPage> createState() => _BookingDetailPageState();
}

class _BookingDetailPageState extends ConsumerState<BookingDetailPage> {
  /// Always use the live booking from the provider so status changes propagate.
  /// Uses select() to only rebuild when the specific booking changes.
  BookingModel get _booking {
    final bookings = ref.watch(
      bookingsProvider.select((state) => state.bookings),
    );
    final live = bookings.where((b) => b.id == widget.booking.id).toList();
    return live.isNotEmpty ? live.first : widget.booking;
  }

  @override
  Widget build(BuildContext context) {
    final booking = _booking;
    final status = booking.status;

    // Get current user info for role resolution
    final authState = ref.watch(authProvider);
    final currentUserId = authState.value?.user?.id;
    final currentUserProviderId = ref.watch(
      userProfileProvider.select((state) => state.profile?.providerId),
    );

    // Resolve user's role in THIS booking
    final userRoleInBooking = resolveBookingUserRole(
      currentUserId: currentUserId,
      currentUserProviderId: currentUserProviderId,
      booking: booking,
    );

    final isBookingProvider = userRoleInBooking == BookingUserRole.provider;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: RefreshIndicator(
          onRefresh: () async {
            await ref
                .read(bookingsProvider.notifier)
                .retrieveBooking(widget.booking.id);
          },
          child: Stack(
            children: [
              CustomScrollView(
                slivers: [
                  // ── Hero image ─────────────────────────────────────────
                  SliverAppBar(
                    automaticallyImplyLeading: false,
                    expandedHeight: 240.h,
                    pinned: false,
                    backgroundColor: Colors.transparent,
                    flexibleSpace: FlexibleSpaceBar(
                      background: Stack(
                        fit: StackFit.expand,
                        children: [
                          booking.service.imagePath != null
                              ? _buildHeroImage(
                                  booking.service.imagePath!,
                                  booking.service.category,
                                )
                              : _HeroFallback(
                                  category: booking.service.category,
                                ),
                          const DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Colors.transparent, Colors.white],
                                stops: [0.5, 1.0],
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 16.h,
                            left: 20.w,
                            child: _StatusBadge(status: status),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(20.w, 4.h, 20.w, 100.h),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title Row
                          _TitleSection(
                            booking: booking,
                            isProvider: isBookingProvider,
                          ),
                          SizedBox(height: 24.h),

                          // Header Card (User/Provider details)
                          _HeaderCard(
                            booking: booking,
                            isProvider: isBookingProvider,
                          ),
                          SizedBox(height: 16.h),

                          // Items Card
                          _SectionLabel('Items'),
                          SizedBox(height: 8.h),
                          _ItemsCard(
                            booking: booking,
                            isProvider: isBookingProvider,
                          ),
                          SizedBox(height: 16.h),

                          // Booking info Card
                          _SectionLabel('Booking info'),
                          SizedBox(height: 8.h),
                          _BookingInfoCard(booking: booking),
                          SizedBox(height: 16.h),

                          // Adjust time Card - only allow before booking is confirmed
                          if (isBookingProvider &&
                              booking.status == BookingStatus.requested) ...[
                            _SectionLabel('Adjust time'),
                            SizedBox(height: 8.h),
                            _AdjustTimeCard(booking: booking),
                            SizedBox(height: 16.h),
                          ],

                          // Payment Action (User only)
                          if (!isBookingProvider &&
                              booking.paymentStatus == 'REQUIRES_ACTION') ...[
                            _PaymentActionSection(booking: booking),
                            SizedBox(height: 16.h),
                          ],

                          // Actions Card
                          _SectionLabel('Actions'),
                          SizedBox(height: 8.h),
                          _ActionsCard(
                            booking: booking,
                            isProvider: isBookingProvider,
                          ),
                          SizedBox(height: 16.h),

                          // Variable price warning
                          if (isBookingProvider &&
                              booking.service.priceType ==
                                  PriceType.variable) ...[
                            _VariablePriceWarning(),
                            SizedBox(height: 16.h),
                          ],

                          // Review
                          if (status == BookingStatus.completed) ...[
                            _SectionLabel('Review'),
                            SizedBox(height: 8.h),
                            _ReviewSection(booking: booking),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // ── Floating back button ────────────────────────────────────
              SafeArea(
                child: Padding(
                  padding: EdgeInsets.all(16.w),
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: EdgeInsets.all(10.w),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8.r,
                            offset: Offset(0, 2.h),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 18.sp,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds hero image widget, handling both network URLs and local assets
  Widget _buildHeroImage(String imagePath, String category) {
    final isNetworkUrl =
        imagePath.startsWith('http://') || imagePath.startsWith('https://');
    if (isNetworkUrl) {
      return Image.network(
        imagePath,
        fit: BoxFit.cover,
        errorBuilder: (ctx, e, st) => _HeroFallback(category: category),
      );
    }
    return Image.asset(
      imagePath,
      fit: BoxFit.cover,
      errorBuilder: (ctx, e, st) => _HeroFallback(category: category),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Review section
// ─────────────────────────────────────────────────────────────────────────────

class _ReviewSection extends ConsumerStatefulWidget {
  final BookingModel booking;
  const _ReviewSection({required this.booking});

  @override
  ConsumerState<_ReviewSection> createState() => _ReviewSectionState();
}

class _ReviewSectionState extends ConsumerState<_ReviewSection> {
  late int _rating;
  final _ctrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _rating = widget.booking.rating ?? 0;
    _ctrl.text = widget.booking.review ?? '';
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasExisting = widget.booking.rating != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lightBlueBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Star row
          Row(
            children: List.generate(5, (i) {
              return GestureDetector(
                onTap: hasExisting
                    ? null
                    : () => setState(() => _rating = i + 1),
                child: Icon(
                  i < _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                  size: 28.sp,
                  color: i < _rating ? AppColors.warning : Colors.grey.shade300,
                ),
              );
            }),
          ),
          if (!hasExisting) ...[
            SizedBox(height: 10.h),
            TextField(
              controller: _ctrl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Write a review (optional)…',
                hintStyle: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 13.sp,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.r),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.r),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                contentPadding: EdgeInsets.all(12.w),
              ),
            ),
            SizedBox(height: 10.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _rating == 0
                    ? null
                    : () {
                        ref
                            .read(bookingsProvider.notifier)
                            .submitReview(
                              widget.booking.id,
                              rating: _rating,
                              review: _ctrl.text.trim().isEmpty
                                  ? null
                                  : _ctrl.text.trim(),
                            );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Review submitted!'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  elevation: 0,
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
                child: const Text(
                  'Submit review',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ] else ...[
            if (widget.booking.review != null) ...[
              SizedBox(height: 8.h),
              Text(
                widget.booking.review!,
                style: TextStyle(
                  fontSize: 13.sp,
                  color: Colors.grey.shade700,
                  height: 1.5,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable local helpers
// ─────────────────────────────────────────────────────────────────────────────

class _HeroFallback extends StatelessWidget {
  final String category;
  const _HeroFallback({required this.category});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade200,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.home_repair_service_rounded,
              size: 48.sp,
              color: Colors.black26,
            ),
            SizedBox(height: 6.h),
            Text(
              category,
              style: TextStyle(color: Colors.black38, fontSize: 13.sp),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final BookingStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: status.color,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6.w,
            height: 6.h,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 5.w),
          Text(
            status.displayName,
            style: TextStyle(
              color: Colors.white,
              fontSize: 11.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 15.sp,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.2,
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(6.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16.sp, color: Colors.grey.shade600),
        ),
        SizedBox(width: 10.w),
        Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            color: Colors.grey.shade500,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// New section widgets for the redesigned booking detail page
// ─────────────────────────────────────────────────────────────────────────────

class _PaymentActionSection extends ConsumerWidget {
  final BookingModel booking;
  const _PaymentActionSection({required this.booking});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AppColors.lightOrangeBackground,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                size: 16.sp,
                color: AppColors.warning,
              ),
              SizedBox(width: 8.w),
              Text(
                'Action required to continue payment authorization.',
                style: TextStyle(fontSize: 13.sp, color: Colors.grey.shade700),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            'Status: ${formatPaymentStatus(booking.paymentStatus)}',
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.warning,
            ),
          ),
          if (booking.paymentAmount != null)
            Text(
              'Amount: ${booking.paymentAmount}',
              style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade600),
            ),
          // Show concluded price notice for variable price services
          if (booking.service.priceType == PriceType.variable &&
              booking.concludedUnitPrice != null) ...[
            SizedBox(height: 8.h),
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(6.r),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 16.sp,
                    color: Colors.green.shade700,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      'Provider has set the concluded price to NGN ${booking.concludedUnitPrice}',
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: Colors.green.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          SizedBox(height: 12.h),
          // Only show payment button if authorization URL exists and payment requires action
          if (booking.paymentAuthorizationUrl != null &&
              booking.paymentStatus == 'REQUIRES_ACTION')
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (booking.paymentAuthorizationUrl != null) {
                    // Open payment URL in-app WebView
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => _PaymentWebView(
                          url: booking.paymentAuthorizationUrl!,
                          onPaymentComplete: () {
                            // Refresh booking data after payment
                            ref
                                .read(bookingsProvider.notifier)
                                .retrieveBooking(booking.id);
                          },
                        ),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.warning,
                  elevation: 0,
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
                child: const Text(
                  'Pay Now',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            )
          else if (booking.paymentStatus != null &&
              booking.paymentStatus != 'REQUIRES_ACTION')
            // Show payment completed status
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green.shade700),
                  SizedBox(width: 12.w),
                  Text(
                    'Payment ${formatPaymentStatus(booking.paymentStatus).toLowerCase()}',
                    style: TextStyle(
                      color: Colors.green.shade800,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Provider-specific widgets
// ─────────────────────────────────────────────────────────────────────────────

class _VariablePriceWarning extends StatelessWidget {
  const _VariablePriceWarning();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColors.lightOrangeBackground,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            size: 18.sp,
            color: AppColors.warning,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              'Variable-price service detected. Make sure you set concluded prices before charging the customer.',
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.grey.shade700,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// New Card-based Layout Widgets
// ─────────────────────────────────────────────────────────────────────────────

class _CardContainer extends StatelessWidget {
  final Widget child;
  const _CardContainer({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final BookingModel booking;
  final bool isProvider;
  const _HeaderCard({required this.booking, required this.isProvider});

  @override
  Widget build(BuildContext context) {
    final avatar = isProvider
        ? booking.userProfilePhoto
        : booking.providerAvatarPath;
    final name = isProvider
        ? (booking.userDisplayName ?? booking.clientName)
        : (booking.providerName ?? 'Unknown');

    // Format date
    final dateStr = formatBookingDate(booking.scheduledDate);

    // Status text
    final statusText =
        booking.status.name[0].toUpperCase() + booking.status.name.substring(1);

    // Price
    final priceStr =
        booking.concludedUnitPrice ??
        extractNumericPrice(booking.service.formattedPrice);

    return _CardContainer(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20.r,
            backgroundColor: Colors.grey.shade200,
            backgroundImage: avatar != null && avatar.isNotEmpty
                ? NetworkImage(avatar)
                : null,
            child: avatar == null || avatar.isEmpty
                ? Icon(Icons.person, color: Colors.grey)
                : null,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isProvider ? 'Customer' : 'Service Provider',
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade500,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  name,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15.sp,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  '$dateStr • $statusText',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12.sp,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'NGN',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12.sp,
                  color: Colors.black87,
                ),
              ),
              Text(
                priceStr,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp),
              ),
              if (booking.paymentStatus != null &&
                  booking.paymentStatus!.isNotEmpty) ...[
                SizedBox(height: 4.h),
                Text(
                  'Payment:',
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  formatPaymentStatus(booking.paymentStatus),
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.bold,
                    color: booking.paymentStatus == 'REQUIRES_ACTION'
                        ? AppColors.warning
                        : (booking.paymentStatus == 'CAPTURED' ||
                                  booking.paymentStatus == 'AUTHORIZED'
                              ? Colors.green
                              : Colors.grey),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _ItemsCard extends StatelessWidget {
  final BookingModel booking;
  final bool isProvider;
  const _ItemsCard({required this.booking, required this.isProvider});

  @override
  Widget build(BuildContext context) {
    final hasConcludedPrice = booking.concludedUnitPrice != null;
    final priceStr =
        booking.concludedUnitPrice ??
        booking.service.formattedPrice.replaceAll(RegExp(r'[^0-9.]'), '');
    final priceLabel = hasConcludedPrice ? 'Concluded' : 'Price';
    return _CardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            booking.service.title,
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.sp),
          ),
          SizedBox(height: 4.h),
          Text(
            'Qty: 1 • $priceLabel: NGN $priceStr',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12.sp),
          ),
          // Only show concluded price input if it hasn't been set yet
          if (isProvider &&
              booking.service.priceType == PriceType.variable &&
              booking.concludedUnitPrice == null) ...[
            SizedBox(height: 16.h),
            _ConcludedPriceInput(booking: booking),
          ],
        ],
      ),
    );
  }
}

class _ConcludedPriceInput extends ConsumerStatefulWidget {
  final BookingModel booking;
  const _ConcludedPriceInput({required this.booking});

  @override
  ConsumerState<_ConcludedPriceInput> createState() =>
      _ConcludedPriceInputState();
}

class _ConcludedPriceInputState extends ConsumerState<_ConcludedPriceInput> {
  late TextEditingController _ctrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(
      text:
          widget.booking.concludedUnitPrice ??
          widget.booking.service.formattedPrice.replaceAll(
            RegExp(r'[^0-9.]'),
            '',
          ),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Concluded unit price',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12.sp,
              color: Colors.grey.shade800,
            ),
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 10.h,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              ElevatedButton(
                onPressed: _saving
                    ? null
                    : () async {
                        final val = _ctrl.text.trim();
                        if (val.isEmpty) return;
                        setState(() => _saving = true);
                        try {
                          await ref
                              .read(bookingsProvider.notifier)
                              .updateConcludedPrice(
                                widget.booking.id,
                                unitPriceAmount: val,
                              );
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Price updated successfully'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        } finally {
                          if (mounted) setState(() => _saving = false);
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  elevation: 0,
                  padding: EdgeInsets.symmetric(
                    horizontal: 20.w,
                    vertical: 12.h,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
                child: _saving
                    ? SizedBox(
                        width: 16.w,
                        height: 16.h,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'Save',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BookingInfoCard extends StatelessWidget {
  final BookingModel booking;
  const _BookingInfoCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    // Format date string
    String scheduledStr = formatBookingDate(booking.scheduledDate);
    if (booking.scheduledEnd != null) {
      scheduledStr += ' — ${formatBookingDate(booking.scheduledEnd!)}';
    }

    return _CardContainer(
      child: Column(
        children: [
          _InfoRow(
            icon: Icons.calendar_today_outlined,
            label: 'Scheduled',
            value: scheduledStr,
          ),
          SizedBox(height: 12.h),
          _InfoRow(
            icon: Icons.category_outlined,
            label: 'Type',
            value: booking.service.category.toUpperCase(),
          ),
          SizedBox(height: 12.h),
          _InfoRow(
            icon: Icons.location_on_outlined,
            label: 'Address',
            value: booking.addressText ?? 'Not provided',
          ),
          SizedBox(height: 12.h),
          _InfoRow(
            icon: Icons.note_outlined,
            label: 'Note',
            value: booking.note ?? 'None',
          ),
        ],
      ),
    );
  }
}

class _AdjustTimeCard extends ConsumerStatefulWidget {
  final BookingModel booking;
  const _AdjustTimeCard({required this.booking});

  @override
  ConsumerState<_AdjustTimeCard> createState() => _AdjustTimeCardState();
}

class _AdjustTimeCardState extends ConsumerState<_AdjustTimeCard> {
  DateTime? _start;
  DateTime? _end;
  bool _saving = false;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _start = widget.booking.scheduledDate;
    _end = widget.booking.scheduledEnd;
  }

  Future<void> _pickDateTime(bool isStart) async {
    final initialDate = (isStart ? _start : _end) ?? DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null) return;

    if (!mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate),
    );
    if (time == null) return;

    final dt = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    setState(() {
      if (isStart) {
        _start = dt;
      } else {
        _end = dt;
      }
    });
  }

  String _fmt(DateTime? dt) {
    if (dt == null) return 'Select date & time';
    return '${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')}/${dt.year} ${dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour)}:${dt.minute.toString().padLeft(2, '0')} ${dt.hour >= 12 ? 'PM' : 'AM'}';
  }

  @override
  Widget build(BuildContext context) {
    return _CardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(6.r),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16.sp,
                  color: Colors.blue.shade700,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    'Time can only be adjusted before confirming the booking.',
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: Colors.blue.shade800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            'Start',
            style: TextStyle(fontSize: 12.sp, color: Colors.black87),
          ),
          SizedBox(height: 6.h),
          InkWell(
            onTap: () => _pickDateTime(true),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_fmt(_start), style: TextStyle(fontSize: 14.sp)),
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 16.sp,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            'End',
            style: TextStyle(fontSize: 12.sp, color: Colors.black87),
          ),
          SizedBox(height: 6.h),
          InkWell(
            onTap: () => _pickDateTime(false),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_fmt(_end), style: TextStyle(fontSize: 14.sp)),
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 16.sp,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving || _saved
                  ? null
                  : () async {
                      if (_start == null || _end == null) return;
                      // Validate that end time is after start time
                      if (_end!.isBefore(_start!) ||
                          _end!.isAtSameMomentAs(_start!)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('End time must be after start time'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        return;
                      }
                      setState(() => _saving = true);
                      try {
                        await ref
                            .read(bookingsProvider.notifier)
                            .rescheduleBooking(
                              widget.booking.id,
                              newStart: _start!,
                              newEnd: _end!,
                            );
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Time adjusted successfully'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        setState(() => _saved = true);
                      } finally {
                        if (mounted) setState(() => _saving = false);
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                elevation: 0,
                padding: EdgeInsets.symmetric(vertical: 14.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              child: _saving
                  ? SizedBox(
                      width: 16.w,
                      height: 16.h,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      _saved ? 'Time saved' : 'Save time',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionsCard extends ConsumerWidget {
  final BookingModel booking;
  final bool isProvider;
  const _ActionsCard({required this.booking, required this.isProvider});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(bookingsProvider.notifier);
    final status = booking.status;
    final paymentCompleted = isPaymentSuccessful(booking.paymentStatus);

    List<Widget> buttons = [];

    if (status == BookingStatus.requested) {
      if (isProvider) {
        buttons = [
          _ActionButton(
            label: 'Confirm booking',
            isPrimary: true,
            onPressed: () async {
              try {
                await notifier.confirmBooking(booking.id);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Booking confirmed successfully'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Failed to confirm booking. Please try again.',
                    ),
                    backgroundColor: Colors.red.shade700,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
          ),
          SizedBox(height: 12.h),
          _ActionButton(
            label: 'Cancel booking',
            isPrimary: false,
            onPressed: paymentCompleted
                ? null // Disable if payment is complete
                : () {
                    notifier.cancelBooking(booking.id);
                    Navigator.of(context).pop();
                  },
          ),
        ];
      } else {
        buttons = [
          _ActionButton(
            label: 'Cancel booking',
            isPrimary: false,
            onPressed: paymentCompleted
                ? null // Disable if payment is complete
                : () {
                    notifier.cancelBooking(booking.id);
                    Navigator.of(context).pop();
                  },
          ),
        ];
      }
    } else if (status == BookingStatus.confirmed) {
      if (isProvider) {
        buttons = [
          _ActionButton(
            label: 'Mark as ongoing',
            isPrimary: true,
            onPressed: () => notifier.startBooking(booking.id),
          ),
          SizedBox(height: 12.h),
          _ActionButton(
            label: 'Cancel booking',
            isPrimary: false,
            onPressed: paymentCompleted
                ? null // Disable if payment is complete
                : () {
                    notifier.cancelBooking(booking.id);
                    Navigator.of(context).pop();
                  },
          ),
        ];
      } else {
        buttons = [
          _ActionButton(
            label: 'Cancel booking',
            isPrimary: false,
            onPressed: paymentCompleted
                ? null // Disable if payment is complete
                : () {
                    notifier.cancelBooking(booking.id);
                    Navigator.of(context).pop();
                  },
          ),
        ];
      }
    } else if (status == BookingStatus.ongoing) {
      if (isProvider) {
        buttons = [
          _ActionButton(
            label: 'Mark as completed',
            isPrimary: true,
            color: AppColors.success,
            onPressed: () => notifier.completeBooking(booking.id),
          ),
        ];
      }
    } else if (status == BookingStatus.completed) {
      if (!isProvider) {
        buttons = [
          _ActionButton(
            label: 'Book again',
            isPrimary: true,
            onPressed: () {
              // Navigate to service detail page to re-book
              context.push(
                '${RouteNames.services}/${booking.service.serviceId}',
                extra: booking.service,
              );
            },
          ),
        ];
      } else {
        return _CardContainer(
          child: Center(
            child: Text(
              'Booking completed',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
      }
    } else if (status == BookingStatus.cancelled) {
      return _CardContainer(
        child: Center(
          child: Text(
            'This booking was cancelled',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }

    if (buttons.isEmpty) return const SizedBox();

    return _CardContainer(child: Column(children: buttons));
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final bool isPrimary;
  final VoidCallback? onPressed;
  final Color? color;

  const _ActionButton({
    required this.label,
    required this.isPrimary,
    required this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: isPrimary
          ? ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: color ?? Colors.grey.shade600,
                elevation: 0,
                padding: EdgeInsets.symmetric(vertical: 14.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          : OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 14.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
                side: BorderSide(color: Colors.grey.shade300),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Payment WebView Widget - Opens payment URL within the app
// ─────────────────────────────────────────────────────────────────────────────

class _PaymentWebView extends StatefulWidget {
  final String url;
  final VoidCallback onPaymentComplete;

  const _PaymentWebView({required this.url, required this.onPaymentComplete});

  @override
  State<_PaymentWebView> createState() => _PaymentWebViewState();
}

class _PaymentWebViewState extends State<_PaymentWebView> {
  late InAppWebViewController _webViewController;
  double _progress = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Payment'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _webViewController.reload(),
          ),
        ],
        bottom: _progress < 1.0
            ? PreferredSize(
                preferredSize: Size.fromHeight(2.h),
                child: LinearProgressIndicator(value: _progress),
              )
            : null,
      ),
      body: InAppWebView(
        initialUrlRequest: URLRequest(url: WebUri(widget.url)),
        onWebViewCreated: (controller) {
          _webViewController = controller;
        },
        onProgressChanged: (controller, progress) {
          setState(() {
            _progress = progress / 100;
          });
        },
        onLoadStart: (controller, url) {
          final urlString = url.toString();
          if (_isPaymentComplete(urlString)) {
            widget.onPaymentComplete();
            Navigator.of(context).pop();
          }
        },
        onLoadStop: (controller, url) async {
          final urlString = url.toString();
          if (_isPaymentComplete(urlString)) {
            widget.onPaymentComplete();
            Navigator.of(context).pop();
          }
          // Check page title for error messages
          final title = await controller.getTitle();
          if (_isPaymentError(title ?? '')) {
            if (!mounted) return;
            // Show feedback to user
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('This payment has already been processed.'),
              ),
            );
            widget.onPaymentComplete(); // Refresh to check current status
            if (!mounted) return;
            Navigator.of(context).pop();
          }
        },
        onReceivedError: (controller, request, error) {
          // Handle WebView errors
          debugPrint('Payment WebView error: ${error.description}');
        },
        onReceivedHttpError: (controller, request, errorResponse) {
          // Handle HTTP errors - may indicate already completed transaction
          debugPrint('Payment WebView HTTP error: ${errorResponse.statusCode}');
          // If we get a 4xx error from Paystack API, transaction may be done
          final statusCode = errorResponse.statusCode;
          if (statusCode != null &&
              statusCode >= 400 &&
              request.url.toString().contains('paystack.com')) {
            // Show feedback to user before closing
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Payment already completed or link expired. Refreshing...',
                ),
                duration: Duration(seconds: 3),
              ),
            );
            widget.onPaymentComplete(); // Refresh to check current status
            Navigator.of(context).pop();
          }
        },
        shouldOverrideUrlLoading: (controller, navigationAction) async {
          final url = navigationAction.request.url.toString();
          if (_isPaymentComplete(url)) {
            widget.onPaymentComplete();
            Navigator.of(context).pop();
            return NavigationActionPolicy.CANCEL;
          }
          return NavigationActionPolicy.ALLOW;
        },
      ),
    );
  }

  bool _isPaymentComplete(String url) {
    final paymentSuccessPatterns = [
      '/payment/success',
      '/payment/callback',
      '/paystack/callback',
      '/flutterwave/callback',
      'payment?status=success',
      'payment_success',
      'success=true',
      'payment/verify',
      'reference=', // Paystack reference parameter indicates callback
      'trx'
          'ref=', // Paystack transaction reference
      '/payment/complete',
      '/payment/successful',
    ];
    return paymentSuccessPatterns.any(
      (pattern) => url.toLowerCase().contains(pattern.toLowerCase()),
    );
  }

  bool _isPaymentError(String title) {
    final errorPatterns = [
      'transaction is already completed',
      'payment failed',
      'error',
      'failed',
      'invalid',
      'expired',
    ];
    return errorPatterns.any(
      (pattern) => title.toLowerCase().contains(pattern.toLowerCase()),
    );
  }
}
