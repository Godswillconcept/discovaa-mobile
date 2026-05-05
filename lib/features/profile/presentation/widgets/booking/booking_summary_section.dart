import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:discovaa/features/profile/presentation/providers/artisan_provider.dart';
import 'booking_utils.dart';

class BookingSummarySection extends ConsumerWidget {
  const BookingSummarySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(bookingProvider);

    if (state.selectedDate == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timezone label
        Text(
          'In your local time zone (Africa/Lagos)',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.maxFinite,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date
              _SummaryItem(
                label: 'Date',
                value: DateFormat(
                  'EEE, d MMM yyyy',
                ).format(state.selectedDate!),
              ),
              const SizedBox(height: 12),
              // Time range
              if (state.startTime != null && state.endTime != null) ...[
                _SummaryItem(
                  label: 'Time',
                  value:
                      '${formatTime(state.startTime!)} - ${formatTime(state.endTime!)}',
                ),
                const SizedBox(height: 12),
              ],
              // Duration
              if (state.durationDisplay.isNotEmpty) ...[
                _SummaryItem(label: 'Duration', value: state.durationDisplay),
                const SizedBox(height: 12),
              ],
              // Selected Services
              if (state.selectedServices.isNotEmpty) ...[
                _SummaryItem(
                  label: 'Services',
                  value: state.selectedServices.join(', '),
                ),
                const SizedBox(height: 12),
              ],
              // Booking type
              _SummaryItem(
                label: 'Booking type',
                value: state.bookingType.name.toUpperCase(),
                isBold: true,
              ),
              if (state.bookingType == BookingType.onsite) ...[
                const SizedBox(height: 12),
                _SummaryItem(
                  label: 'Address',
                  value: (state.address?.isNotEmpty ?? false)
                      ? state.address!
                      : '-',
                ),
              ],
              // Estimated Cost
              if (state.selectedServices.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Estimated Cost',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    Text(
                      state.estimatedCostDisplay,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;

  const _SummaryItem({
    required this.label,
    required this.value,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
            color: Colors.black,
          ),
        ),
      ],
    );
  }
}
