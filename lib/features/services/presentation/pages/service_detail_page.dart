import 'package:discovaa/core/constants/app_constants.dart';
import 'package:discovaa/features/profile/presentation/providers/saved_services_provider.dart';
import 'package:discovaa/features/services/data/models/service_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Full-screen detail view for a single [ServiceModel].
/// Opened via [Navigator.push] — no named route needed since [service] is
/// passed directly, avoiding serialisation overhead.
class ServiceDetailPage extends ConsumerStatefulWidget {
  final ServiceModel service;

  const ServiceDetailPage({super.key, required this.service});

  @override
  ConsumerState<ServiceDetailPage> createState() => _ServiceDetailPageState();
}

class _ServiceDetailPageState extends ConsumerState<ServiceDetailPage> {
  ServiceModel get _s => widget.service;

  @override
  Widget build(BuildContext context) {
    final isSaved = ref.watch(isServiceSavedProvider(_s.id));
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
            // ── Scrollable content ──────────────────────────────────────
            CustomScrollView(
              slivers: [
                _ServiceHeroSliver(service: _s),
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Title + badges ─────────────────────────────
                      _TitleSection(service: _s),
                      const _Divider(),

                      // ── Description ────────────────────────────────
                      if (_s.description.isNotEmpty) ...[
                        _SectionHeader('About this service'),
                        _DescriptionSection(description: _s.description),
                        const _Divider(),
                      ],

                      // ── Pricing details ────────────────────────────
                      _SectionHeader('Pricing'),
                      _PricingSection(service: _s),
                      const _Divider(),

                      // ── Weekly availability ────────────────────────
                      if (_s.weeklySchedule.isNotEmpty) ...[
                        _SectionHeader('Availability'),
                        _AvailabilitySection(schedule: _s.weeklySchedule),
                        const _Divider(),
                      ],

                      // ── Meta info chips ────────────────────────────
                      _SectionHeader('Details'),
                      _MetaSection(service: _s),

                    ],
                  ),
                ),
              ],
            ),

            // ── Floating back + favourite buttons (over hero) ──────────
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _CircleIconButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      onTap: () => Navigator.of(context).pop(),
                    ),
                    _CircleIconButton(
                      icon: isSaved
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      iconColor: isSaved
                          ? AppColors.primaryRed
                          : Colors.black87,
                      onTap: () {
                        final nowSaved = ref
                            .read(savedServicesProvider.notifier)
                            .toggle(_s);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              nowSaved
                                  ? 'Saved to your list'
                                  : 'Removed from saved',
                            ),
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hero sliver — full-width cover image with gradient fade at the bottom
// ─────────────────────────────────────────────────────────────────────────────

class _ServiceHeroSliver extends StatelessWidget {
  final ServiceModel service;
  const _ServiceHeroSliver({required this.service});

  /// Builds hero image widget, handling both network URLs and local assets
  Widget _buildHeroImage(String imagePath) {
    final isNetworkUrl =
        imagePath.startsWith('http://') || imagePath.startsWith('https://');
    if (isNetworkUrl) {
      return Image.network(
        imagePath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stack) =>
            _HeroFallback(category: service.category ?? 'Service'),
      );
    }
    return Image.asset(
      imagePath,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stack) =>
          _HeroFallback(category: service.category ?? 'Service'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      automaticallyImplyLeading: false,
      expandedHeight: 280,
      pinned: false,
      stretch: true,
      backgroundColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Cover image — handles both network URLs and local assets
            service.imagePath != null
                ? _buildHeroImage(service.imagePath!)
                : _HeroFallback(category: service.category ?? 'Service'),

            // Bottom gradient so text beneath reads cleanly
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.white],
                  stops: [0.55, 1.0],
                ),
              ),
            ),

            // Status badge — active / inactive
            Positioned(
              bottom: 16,
              left: 20,
              child: _StatusBadge(isActive: service.isActive),
            ),
          ],
        ),
      ),
    );
  }
}

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
              size: 56,
              color: Colors.black26,
            ),
            const SizedBox(height: 8),
            Text(
              category,
              style: const TextStyle(color: Colors.black38, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Title section — name, category chip, pricing model badge
// ─────────────────────────────────────────────────────────────────────────────

class _TitleSection extends StatelessWidget {
  final ServiceModel service;
  const _TitleSection({required this.service});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category + pricing model row
          Row(
            children: [
              if (service.category != null && service.category!.isNotEmpty) ...[
                _Chip(
                  label: service.category!,
                  color: AppColors.primary.withValues(alpha: 0.08),
                  textColor: AppColors.primary,
                ),
                const SizedBox(width: 8),
              ],
              _Chip(
                label: service.pricingModel.displayName,
                color: Colors.grey.shade100,
                textColor: Colors.black54,
              ),
              if (service.priceType == PriceType.variable) ...[
                const SizedBox(width: 8),
                _Chip(
                  label: 'Variable rate',
                  color: Colors.orange.shade50,
                  textColor: Colors.orange.shade700,
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          // Title
          Text(
            service.title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          // Price
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                service.formattedPrice,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.success,
                ),
              ),
              if (service.durationMinutes != null) ...[
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    '· ${_formatDuration(service.durationMinutes!)}',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String _formatDuration(int minutes) {
    if (minutes < 60) return '${minutes}min';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}min';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Description
// ─────────────────────────────────────────────────────────────────────────────

class _DescriptionSection extends StatefulWidget {
  final String description;
  const _DescriptionSection({required this.description});

  @override
  State<_DescriptionSection> createState() => _DescriptionSectionState();
}

class _DescriptionSectionState extends State<_DescriptionSection> {
  bool _expanded = false;
  static const int _collapseAt = 140;

  @override
  Widget build(BuildContext context) {
    final isLong = widget.description.length > _collapseAt;
    final text = (!_expanded && isLong)
        ? '${widget.description.substring(0, _collapseAt)}…'
        : widget.description;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
              height: 1.6,
            ),
          ),
          if (isLong) ...[
            const SizedBox(height: 4),
            GestureDetector(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Text(
                _expanded ? 'Show less' : 'Read more',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Pricing section — visual breakdown of pricing model, type, currency, amount
// ─────────────────────────────────────────────────────────────────────────────

class _PricingSection extends StatelessWidget {
  final ServiceModel service;
  const _PricingSection({required this.service});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FBFF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            _PricingRow(
              icon: Icons.sell_outlined,
              label: 'Pricing model',
              value: service.pricingModel.displayName,
            ),
            const SizedBox(height: 12),
            _PricingRow(
              icon: Icons.tune_rounded,
              label: 'Price type',
              value: service.priceType.displayName,
            ),
            const SizedBox(height: 12),
            _PricingRow(
              icon: Icons.currency_exchange_rounded,
              label: 'Currency',
              value: service.currency.isNotEmpty ? service.currency : '—',
            ),
            const SizedBox(height: 12),
            _PricingRow(
              icon: Icons.attach_money_rounded,
              label: service.priceType == PriceType.variable
                  ? 'Price Range'
                  : 'Amount',
              value: _getPriceDisplay(service),
              valueColor: AppColors.success,
              valueBold: true,
            ),
            if (service.priceType == PriceType.variable &&
                (service.priceMinAmount != null ||
                    service.priceMaxAmount != null)) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 40),
                child: Text(
                  service.formattedPrice,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
            if (service.durationMinutes != null) ...[
              const SizedBox(height: 12),
              _PricingRow(
                icon: Icons.timer_outlined,
                label: 'Duration',
                value: _formatDuration(service.durationMinutes!),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDuration(int minutes) {
    if (minutes < 60) return '$minutes min';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '$h hr' : '$h hr $m min';
  }

  String _getPriceDisplay(ServiceModel service) {
    if (service.priceType == PriceType.variable) {
      if (service.priceMinAmount != null && service.priceMaxAmount != null) {
        return '${service.currency} ${service.priceMinAmount!.toStringAsFixed(0)} - ${service.currency} ${service.priceMaxAmount!.toStringAsFixed(0)}';
      }
      if (service.priceMinAmount != null) {
        return 'From ${service.currency} ${service.priceMinAmount!.toStringAsFixed(0)}';
      }
      if (service.priceMaxAmount != null) {
        return 'Up to ${service.currency} ${service.priceMaxAmount!.toStringAsFixed(0)}';
      }
    }

    if (service.amount != null) {
      return '${service.currency} ${service.amount!.toStringAsFixed(0)}';
    }

    return 'Price on request';
  }
}

class _PricingRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final bool valueBold;

  const _PricingRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.valueBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Icon(icon, size: 15, color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: valueBold ? FontWeight.bold : FontWeight.w600,
            color: valueColor ?? Colors.black87,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Availability — weekly schedule grid
// ─────────────────────────────────────────────────────────────────────────────

class _AvailabilitySection extends StatelessWidget {
  final Map<WeekDay, List<ServiceTimeSlot>> schedule;
  const _AvailabilitySection({required this.schedule});

  @override
  Widget build(BuildContext context) {
    // Show days in canonical order
    final orderedDays = WeekDay.values.where(schedule.containsKey).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Column(
        children: orderedDays.map((day) {
          final slots = schedule[day]!;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Day pill
                Container(
                  width: 44,
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    day.shortName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Time slots
                Expanded(
                  child: slots.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Available (no specific times)',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        )
                      : Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: slots
                              .map(
                                (slot) => Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.success.withValues(
                                      alpha: 0.08,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: AppColors.success.withValues(
                                        alpha: 0.3,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.schedule_rounded,
                                        size: 12,
                                        color: AppColors.success.withValues(
                                          alpha: 0.8,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        slot.displayLabel,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.success.withValues(
                                            alpha: 0.9,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Meta details chips row
// ─────────────────────────────────────────────────────────────────────────────

class _MetaSection extends StatelessWidget {
  final ServiceModel service;
  const _MetaSection({required this.service});

  @override
  Widget build(BuildContext context) {
    final activeDays = service.weeklySchedule.keys.length;
    final totalSlots = service.weeklySchedule.values.fold<int>(
      0,
      (sum, slots) => sum + slots.length,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          if (service.durationMinutes != null)
            _MetaChip(
              icon: Icons.timer_outlined,
              label: _fmtDuration(service.durationMinutes!),
            ),
          if (activeDays > 0)
            _MetaChip(
              icon: Icons.calendar_today_outlined,
              label: '$activeDays day${activeDays == 1 ? '' : 's'} / week',
            ),
          if (totalSlots > 0)
            _MetaChip(
              icon: Icons.schedule_rounded,
              label: '$totalSlots time slot${totalSlots == 1 ? '' : 's'}',
            ),
          _MetaChip(
            icon: service.isActive
                ? Icons.check_circle_outline_rounded
                : Icons.cancel_outlined,
            label: service.isActive ? 'Currently active' : 'Not available',
            iconColor: service.isActive
                ? AppColors.success
                : Colors.grey.shade400,
          ),
          _MetaChip(
            icon: Icons.tune_rounded,
            label: service.priceType.displayName,
          ),
        ],
      ),
    );
  }

  String _fmtDuration(int minutes) {
    if (minutes < 60) return '$minutes min';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '$h hr' : '$h hr $m min';
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? iconColor;

  const _MetaChip({required this.icon, required this.label, this.iconColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: iconColor ?? Colors.black54),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Booking sheet helper — date + time picker bottom sheet
// ─────────────────────────────────────────────────────────────────────────────


// ─────────────────────────────────────────────────────────────────────────────
// Status badge
// ─────────────────────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final bool isActive;
  const _StatusBadge({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? AppColors.success : Colors.grey.shade500,
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
            isActive ? 'Active' : 'Inactive',
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

// ─────────────────────────────────────────────────────────────────────────────
// Reusable local helpers
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.2,
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Divider(height: 1, color: Colors.grey.shade100);
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;

  const _Chip({
    required this.label,
    required this.color,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? iconColor;

  const _CircleIconButton({
    required this.icon,
    required this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
        child: Icon(icon, size: 18, color: iconColor ?? Colors.black87),
      ),
    );
  }
}
