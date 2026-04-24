import 'package:discovaa/app/router/route_names.dart';
import 'package:discovaa/core/constants/app_constants.dart';
import 'package:discovaa/features/authentication/presentation/providers/auth_provider.dart';
import 'package:discovaa/features/bookings/data/models/booking_api_models.dart';
import 'package:discovaa/features/bookings/data/models/booking_model.dart';
import 'package:discovaa/features/bookings/presentation/providers/bookings_provider.dart';
import 'package:discovaa/features/services/data/models/service_model.dart';
import 'package:discovaa/features/messaging/presentation/providers/messaging_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Full-screen detail view for a single [BookingModel].
class BookingDetailPage extends ConsumerStatefulWidget {
  final BookingModel booking;
  const BookingDetailPage({super.key, required this.booking});

  @override
  ConsumerState<BookingDetailPage> createState() => _BookingDetailPageState();
}

class _BookingDetailPageState extends ConsumerState<BookingDetailPage> {
  /// Always use the live booking from the provider so status changes propagate.
  BookingModel get _booking {
    final live = ref
        .watch(bookingsProvider)
        .bookings
        .where((b) => b.id == widget.booking.id)
        .toList();
    return live.isNotEmpty ? live.first : widget.booking;
  }

  @override
  Widget build(BuildContext context) {
    final booking = _booking;
    final status = booking.status;

    final authState = ref.watch(authProvider);
    final userRole = authState.user?.role;
    final isProviderView = isProviderRole(userRole);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            CustomScrollView(
              slivers: [
                // ── Hero image ─────────────────────────────────────────
                SliverAppBar(
                  automaticallyImplyLeading: false,
                  expandedHeight: 240,
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
                            : _HeroFallback(category: booking.service.category),
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
                          bottom: 16,
                          left: 20,
                          child: _StatusBadge(status: status),
                        ),
                      ],
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Header: Provider email, date/time, status, amount ───────
                        _HeaderSection(
                          booking: booking,
                          isProviderView: isProviderView,
                        ),
                        const SizedBox(height: 20),

                        // ── Chat Button ───────────────────────────────────────────
                        _ChatButtonSection(booking: booking),
                        const SizedBox(height: 20),

                        // ── Payment Status ────────────────────────────────────────
                        if (booking.paymentStatus != null) ...[
                          _PaymentStatusSection(booking: booking),
                          const SizedBox(height: 20),
                        ],

                        // ── Variable Price Warning (provider only) ────────────────
                        if (isProviderView &&
                            booking.service.priceType ==
                                PriceType.variable) ...[
                          _VariablePriceWarning(),
                          const SizedBox(height: 20),
                        ],

                        // ── Concluded Unit Price (provider only, variable) ──────────
                        if (isProviderView &&
                            booking.service.priceType ==
                                PriceType.variable) ...[
                          _SectionLabel('Concluded unit price'),
                          const SizedBox(height: 10),
                          _ConcludedPriceSection(booking: booking),
                          const SizedBox(height: 20),
                        ],

                        // ── Items Section ─────────────────────────────────────────
                        _SectionLabel('Items'),
                        const SizedBox(height: 10),
                        _ItemsSection(booking: booking),
                        const SizedBox(height: 20),

                        // ── Booking Info Section ─────────────────────────────────
                        _SectionLabel('Booking info'),
                        const SizedBox(height: 10),
                        _BookingInfoSection(booking: booking),
                        const SizedBox(height: 20),

                        // ── Adjust Time (provider only) ────────────────────────────
                        if (isProviderView) ...[
                          _SectionLabel('Adjust time'),
                          const SizedBox(height: 10),
                          _AdjustTimeSection(booking: booking),
                          const SizedBox(height: 20),
                        ],

                        // ── Payment Section (with Act Now button) ─────────────────
                        if (booking.paymentStatus != null &&
                            booking.paymentStatus == 'REQUIRES_ACTION') ...[
                          _PaymentActionSection(booking: booking),
                          const SizedBox(height: 20),
                        ],

                        // ── Review (completed only) ─────────────────────────────
                        if (status == BookingStatus.completed) ...[
                          _SectionLabel('Review'),
                          const SizedBox(height: 10),
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
                padding: const EdgeInsets.all(16),
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.92),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 18,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
            ),

            // ── Sticky action bar ───────────────────────────────────────
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _ActionBar(
                booking: booking,
                isProviderView: isProviderView,
              ),
            ),
          ],
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
// Action bar — context-sensitive buttons
// ─────────────────────────────────────────────────────────────────────────────

class _ActionBar extends ConsumerWidget {
  final BookingModel booking;
  final bool isProviderView;
  const _ActionBar({required this.booking, required this.isProviderView});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(bookingsProvider.notifier);

    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        14,
        20,
        MediaQuery.of(context).padding.bottom + 14,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: switch (booking.status) {
        BookingStatus.requested => Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  notifier.cancelBooking(booking.id);
                  Navigator.of(context).pop();
                },
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.grey.shade300),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: () => notifier.confirmBooking(booking.id),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Confirm booking',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
        BookingStatus.confirmed => Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  notifier.cancelBooking(booking.id);
                  Navigator.of(context).pop();
                },
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.grey.shade300),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: () => notifier.startBooking(booking.id),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Mark as ongoing',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
        BookingStatus.ongoing => SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => notifier.completeBooking(booking.id),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              padding: const EdgeInsets.symmetric(vertical: 14),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Mark as completed',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
        ),
        BookingStatus.completed =>
          isProviderView
              ? Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Booking completed',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )
              : SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      /* navigate to re-book */
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Book again',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
        BookingStatus.cancelled => Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'This booking was cancelled',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      },
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
        color: const Color(0xFFF8FBFF),
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
                  size: 28,
                  color: i < _rating
                      ? const Color(0xFFF59E0B)
                      : Colors.grey.shade300,
                ),
              );
            }),
          ),
          if (!hasExisting) ...[
            const SizedBox(height: 10),
            TextField(
              controller: _ctrl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Write a review (optional)…',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
            const SizedBox(height: 10),
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
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
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
              const SizedBox(height: 8),
              Text(
                widget.booking.review!,
                style: TextStyle(
                  fontSize: 13,
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
      color: const Color(0xFFF0F0F0),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.home_repair_service_rounded,
              size: 48,
              color: Colors.black26,
            ),
            const SizedBox(height: 6),
            Text(
              category,
              style: const TextStyle(color: Colors.black38, fontSize: 13),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: status.color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            status.displayName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
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
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.2,
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children:
            children.expand((w) => [w, const SizedBox(height: 10)]).toList()
              ..removeLast(),
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
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: Colors.grey.shade600),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade500,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
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

class _HeaderSection extends StatelessWidget {
  final BookingModel booking;
  final bool isProviderView;
  const _HeaderSection({required this.booking, required this.isProviderView});

  @override
  Widget build(BuildContext context) {
    final displayName = isProviderView
        ? (booking.userDisplayName ?? booking.clientName)
        : (booking.providerName ?? booking.providerEmail ?? 'Unknown');
    final status = booking.status;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          displayName,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Text(
              '${booking.scheduledDisplayDate}, ${booking.scheduledDisplayTime}',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(width: 8),
            Text(
              '•',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: status.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                status.displayName,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: status.color,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        if (booking.paymentAmount != null)
          Text(
            '${booking.paymentAmount}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
      ],
    );
  }
}

class _PaymentStatusSection extends StatelessWidget {
  final BookingModel booking;
  const _PaymentStatusSection({required this.booking});

  @override
  Widget build(BuildContext context) {
    final status = booking.paymentStatus ?? 'UNKNOWN';
    Color statusColor;
    String statusLabel;

    switch (status) {
      case 'REQUIRES_ACTION':
        statusColor = const Color(0xFFF59E0B);
        statusLabel = 'Payment: REQUIRES_ACTION';
        break;
      case 'COMPLETED':
        statusColor = const Color(0xFF10B981);
        statusLabel = 'Payment: COMPLETED';
        break;
      case 'PENDING':
        statusColor = const Color(0xFF3B82F6);
        statusLabel = 'Payment: PENDING';
        break;
      default:
        statusColor = Colors.grey;
        statusLabel = 'Payment: $status';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Text(
        statusLabel,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: statusColor,
        ),
      ),
    );
  }
}

class _ItemsSection extends StatelessWidget {
  final BookingModel booking;
  const _ItemsSection({required this.booking});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            booking.service.title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                'Qty: 1',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(width: 8),
              Text(
                '•',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
              ),
              const SizedBox(width: 8),
              Text(
                booking.concludedUnitPrice != null
                    ? '${(booking.service.formattedPrice.split(' ').isNotEmpty ? booking.service.formattedPrice.split(' ').first : '')} ${booking.concludedUnitPrice}'
                    : booking.service.formattedPrice,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BookingInfoSection extends StatelessWidget {
  final BookingModel booking;
  const _BookingInfoSection({required this.booking});

  @override
  Widget build(BuildContext context) {
    return _InfoCard(
      children: [
        _InfoRow(
          icon: Icons.calendar_today_outlined,
          label: 'Scheduled',
          value: booking.scheduledEnd != null
              ? '${booking.scheduledDisplayDate}, ${booking.scheduledDisplayTime} — ${_formatDateTime(booking.scheduledEnd!)}'
              : '${booking.scheduledDisplayDate}, ${booking.scheduledDisplayTime}',
        ),
        _InfoRow(
          icon: Icons.create_rounded,
          label: 'Time Created',
          value: _formatDateTime(booking.createdAt),
        ),
        if (booking.serviceType != null)
          _InfoRow(
            icon: Icons.category_outlined,
            label: 'Type',
            value: booking.serviceType!,
          ),
        if (booking.addressText != null && booking.addressText!.isNotEmpty)
          _InfoRow(
            icon: Icons.location_on_outlined,
            label: 'Address',
            value: booking.addressText!,
          ),
        _InfoRow(
          icon: Icons.note_outlined,
          label: 'Note',
          value: booking.note?.isNotEmpty == true ? booking.note! : '—',
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final hour = dt.hour;
    final h = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final m = dt.minute.toString().padLeft(2, '0');
    final p = hour >= 12 ? 'PM' : 'AM';
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}, $h:$m $p';
  }
}

class _PaymentActionSection extends StatelessWidget {
  final BookingModel booking;
  const _PaymentActionSection({required this.booking});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                size: 16,
                color: Color(0xFFF59E0B),
              ),
              const SizedBox(width: 8),
              Text(
                'Action required to continue payment authorization.',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Status: ${booking.paymentStatus}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFFF59E0B),
            ),
          ),
          if (booking.paymentAmount != null)
            Text(
              'Amount: ${booking.paymentAmount}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          const SizedBox(height: 12),
          if (booking.paymentAuthorizationUrl != null)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Open the payment authorization URL
                  // TODO: Implement URL launcher
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF59E0B),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Act Now',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ChatButtonSection extends ConsumerWidget {
  final BookingModel booking;
  const _ChatButtonSection({required this.booking});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final userRole = authState.user?.role;
    final isProvider = isProviderRole(userRole);

    // Determine which name/avatar to show based on role
    final displayName = isProvider
        ? booking.userDisplayName
        : booking.providerName;
    final displayAvatarPath = isProvider
        ? booking.userProfilePhoto
        : booking.providerAvatarPath;
    final displayLabel = isProvider ? 'Client' : 'Provider';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: const Color(0xFFE5E7EB),
            backgroundImage: displayAvatarPath != null
                ? AssetImage(displayAvatarPath)
                : null,
            child: displayAvatarPath == null
                ? Text(
                    (displayName?.isNotEmpty == true)
                        ? displayName![0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black54,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayLabel,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  displayName ?? displayLabel,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              // Find or create a conversation for this booking,
              // keyed by booking.id so each booking has its own thread.
              final conversation = ref
                  .read(messagingProvider.notifier)
                  .findOrCreateConversation(
                    artisanId: booking.id,
                    artisanName: displayName ?? displayLabel,
                    artisanAvatar:
                        displayAvatarPath ??
                        'assets/images/placeholders/user_avatar.png',
                  );
              context.push('${RouteNames.messages}/chat', extra: conversation);
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2),
                ),
              ),
              child: const Icon(
                Icons.message_outlined,
                size: 16,
                color: AppColors.primary,
              ),
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            size: 18,
            color: Color(0xFFF59E0B),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Variable-price service detected. Make sure you set concluded prices before charging the customer.',
              style: TextStyle(
                fontSize: 12,
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

class _ConcludedPriceSection extends ConsumerStatefulWidget {
  final BookingModel booking;
  const _ConcludedPriceSection({required this.booking});

  @override
  ConsumerState<_ConcludedPriceSection> createState() =>
      _ConcludedPriceSectionState();
}

class _ConcludedPriceSectionState
    extends ConsumerState<_ConcludedPriceSection> {
  late TextEditingController _ctrl;

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
    final parts = widget.booking.service.formattedPrice.split(' ');
    final currency = parts.isNotEmpty ? parts.first : '';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _ctrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'Enter concluded price',
              prefixText: currency.isNotEmpty ? '$currency ' : null,
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                final value = _ctrl.text.trim();
                if (value.isNotEmpty) {
                  ref
                      .read(bookingsProvider.notifier)
                      .updateConcludedPrice(
                        widget.booking.id,
                        unitPriceAmount: value,
                      );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Concluded price saved'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Save',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdjustTimeSection extends ConsumerStatefulWidget {
  final BookingModel booking;
  const _AdjustTimeSection({required this.booking});

  @override
  ConsumerState<_AdjustTimeSection> createState() => _AdjustTimeSectionState();
}

class _AdjustTimeSectionState extends ConsumerState<_AdjustTimeSection> {
  late DateTime _start;
  late DateTime? _end;

  @override
  void initState() {
    super.initState();
    _start = widget.booking.scheduledDate;
    _end = widget.booking.scheduledEnd;
  }

  Future<void> _pickDateTime(BuildContext context, bool isStart) async {
    final initialDate = isStart ? _start : (_end ?? _start);

    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !context.mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate),
    );
    if (time == null || !context.mounted) return;

    final newDateTime = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    setState(() {
      if (isStart) {
        _start = newDateTime;
      } else {
        _end = newDateTime;
      }
    });
  }

  String _formatDateTime(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final hour = dt.hour;
    final h = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final m = dt.minute.toString().padLeft(2, '0');
    final p = hour >= 12 ? 'PM' : 'AM';
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}, $h:$m $p';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTimeRow(context, 'Start', _start, true),
          const SizedBox(height: 12),
          _buildTimeRow(context, 'End', _end, false),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                ref
                    .read(bookingsProvider.notifier)
                    .rescheduleBooking(
                      widget.booking.id,
                      newStart: _start,
                      newEnd: _end,
                    );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Time saved'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Save time',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeRow(
    BuildContext context,
    String label,
    DateTime? dateTime,
    bool isStart,
  ) {
    return GestureDetector(
      onTap: () => _pickDateTime(context, isStart),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
            const Spacer(),
            Text(
              dateTime != null ? _formatDateTime(dateTime) : 'Not set',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.calendar_today_outlined,
              size: 16,
              color: Colors.grey.shade500,
            ),
          ],
        ),
      ),
    );
  }
}
