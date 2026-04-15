import 'package:discovaa/app/router/route_names.dart';
import 'package:discovaa/core/constants/app_constants.dart';
import 'package:discovaa/features/bookings/data/models/booking_model.dart';
import 'package:discovaa/features/bookings/presentation/providers/bookings_provider.dart';
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
                        // ── Category + title ─────────────────────────
                        Text(
                          booking.service.category,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          booking.service.title,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          booking.service.formattedPrice,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.success,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Divider(height: 1, color: Color(0xFFF0F0F0)),
                        const SizedBox(height: 20),

                        // ── Schedule card ─────────────────────────────
                        _SectionLabel('Schedule'),
                        const SizedBox(height: 10),
                        _InfoCard(
                          children: [
                            _InfoRow(
                              icon: Icons.calendar_today_outlined,
                              label: 'Date',
                              value: booking.scheduledDisplayDate,
                            ),
                            _InfoRow(
                              icon: Icons.access_time_rounded,
                              label: 'Time',
                              value: booking.scheduledDisplayTime,
                            ),
                            if (booking.service.durationMinutes != null)
                              _InfoRow(
                                icon: Icons.timer_outlined,
                                label: 'Duration',
                                value: _fmtDuration(
                                  booking.service.durationMinutes!,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // ── Client card ───────────────────────────────
                        _SectionLabel('Client'),
                        const SizedBox(height: 10),
                        _ClientCard(booking: booking),
                        const SizedBox(height: 20),

                        // ── Note ──────────────────────────────────────
                        if (booking.note != null &&
                            booking.note!.isNotEmpty) ...[
                          _SectionLabel('Note'),
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FBFF),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Text(
                              booking.note!,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade700,
                                height: 1.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],

                        // ── Booking ID ────────────────────────────────
                        _SectionLabel('Booking reference'),
                        const SizedBox(height: 10),
                        _InfoCard(
                          children: [
                            _InfoRow(
                              icon: Icons.tag_rounded,
                              label: 'ID',
                              value: _shortId(booking.id),
                            ),
                            _InfoRow(
                              icon: Icons.calendar_month_outlined,
                              label: 'Booked on',
                              value: _fmtDateTime(booking.createdAt),
                            ),
                            if (booking.updatedAt != null)
                              _InfoRow(
                                icon: Icons.update_rounded,
                                label: 'Last updated',
                                value: _fmtDateTime(booking.updatedAt!),
                              ),
                          ],
                        ),

                        // ── Review (completed only) ───────────────────
                        if (status == BookingStatus.completed) ...[
                          const SizedBox(height: 20),
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
              child: _ActionBar(booking: booking),
            ),
          ],
        ),
      ),
    );
  }

  String _shortId(String id) {
    final s = id.toUpperCase().replaceAll('-', '');
    return s.substring(0, s.length < 12 ? s.length : 12);
  }

  String _fmtDuration(int minutes) {
    if (minutes < 60) return '$minutes min';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '$h hr' : '$h hr $m min';
  }

  String _fmtDateTime(DateTime dt) {
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
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
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
  const _ActionBar({required this.booking});

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
        BookingStatus.pending => Row(
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
        BookingStatus.upcoming => Row(
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
        BookingStatus.completed => SizedBox(
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

class _ClientCard extends ConsumerWidget {
  final BookingModel booking;
  const _ClientCard({required this.booking});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            backgroundImage: booking.clientAvatarPath != null
                ? AssetImage(booking.clientAvatarPath!)
                : null,
            child: booking.clientAvatarPath == null
                ? Text(
                    booking.clientName.isNotEmpty
                        ? booking.clientName[0].toUpperCase()
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
                  booking.clientName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Client',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              // Find or create a conversation for this client,
              // keyed by booking.id so each booking has its own thread.
              final conversation = ref
                  .read(messagingProvider.notifier)
                  .findOrCreateConversation(
                    artisanId: booking.id,
                    artisanName: booking.clientName,
                    artisanAvatar:
                        booking.clientAvatarPath ??
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
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Icon(icon, size: 14, color: AppColors.primary),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          ),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
