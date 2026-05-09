import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:discovaa/features/profile/presentation/providers/artisan_provider.dart';
import 'booking_utils.dart';

class BookingSuccessView extends ConsumerWidget {
  const BookingSuccessView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(bookingProvider);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Align(
            alignment: Alignment.topRight,
            child: GestureDetector(
              onTap: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
              },
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.black,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 16),
              ),
            ),
          ),
          const SizedBox(height: 10),
          buildScatteredDots(),
          const SizedBox(height: 32),
          const Text(
            'Booking Confirmed!',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text.rich(
              TextSpan(
                text: 'Your booking with ',
                style: const TextStyle(color: Color(0xFF666666), fontSize: 14),
                children: [
                  TextSpan(
                    text: state.selectedArtisan?.name ?? 'Artisan',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const TextSpan(text: ' has been confirmed. Details below:'),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),
          if (state.selectedDate != null)
            Text.rich(
              TextSpan(
                text: 'Date: ',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                children: [
                  TextSpan(
                    text: DateFormat(
                      'EEE, d MMM yyyy',
                    ).format(state.selectedDate!),
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.black.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
          if (state.selectedDate != null) const SizedBox(height: 12),
          if (state.startTime != null && state.endTime != null)
            Text.rich(
              TextSpan(
                text: 'Time: ',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                children: [
                  TextSpan(
                    text:
                        '${formatTime(state.startTime!)} - ${formatTime(state.endTime!)}',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.black.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
          if (state.startTime != null && state.endTime != null)
            const SizedBox(height: 12),
          if (state.durationDisplay.isNotEmpty)
            Text.rich(
              TextSpan(
                text: 'Duration: ',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                children: [
                  TextSpan(
                    text: state.durationDisplay,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.black.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
          if (state.durationDisplay.isNotEmpty) const SizedBox(height: 12),
          Text.rich(
            TextSpan(
              text: 'Booking type: ',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
              children: [
                TextSpan(
                  text: state.bookingType.name.toUpperCase(),
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.black.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          if (state.bookingType == BookingType.onsite &&
              state.address != null &&
              state.address!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text.rich(
              TextSpan(
                text: 'Address: ',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                children: [
                  TextSpan(
                    text: state.address!,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.black.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (state.selectedServices.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text.rich(
              TextSpan(
                text: 'Services: ',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                children: [
                  TextSpan(
                    text: state.selectedServices.join(', '),
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.black.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (state.notes != null && state.notes!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text.rich(
              TextSpan(
                text: 'Note: ',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                children: [
                  TextSpan(
                    text: state.notes!,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.black.withValues(alpha: 0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: () {
              ref.read(bookingProvider.notifier).reset();
              Navigator.pop(context);
              context.go('/bookings');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text(
              'View My Bookings',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
