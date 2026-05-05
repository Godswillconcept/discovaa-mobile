import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:discovaa/features/profile/presentation/providers/artisan_provider.dart';

class BookingServicesSection extends ConsumerStatefulWidget {
  const BookingServicesSection({super.key});

  @override
  ConsumerState<BookingServicesSection> createState() =>
      _BookingServicesSectionState();
}

class _BookingServicesSectionState
    extends ConsumerState<BookingServicesSection> {
  bool _isServicesExpanded = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bookingProvider);
    final notifier = ref.read(bookingProvider.notifier);
    final artisan = state.selectedArtisan;

    if (artisan == null) return const SizedBox.shrink();

    final selectedServices = state.selectedServices;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Prices',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () =>
              setState(() => _isServicesExpanded = !_isServicesExpanded),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    selectedServices.isEmpty
                        ? 'Select services'
                        : selectedServices.join(', '),
                    style: const TextStyle(color: Colors.black87),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  _isServicesExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: Colors.black,
                ),
              ],
            ),
          ),
        ),
        if (_isServicesExpanded)
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children:
                  (state.availableServices.isNotEmpty
                          ? state.availableServices.map((s) => s.title).toList()
                          : artisan.services)
                      .map((service) {
                        final isSelected = selectedServices.contains(service);
                        return InkWell(
                          onTap: () {
                            notifier.toggleService(service);
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: isSelected
                                          ? Colors.black
                                          : Colors.grey,
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: isSelected
                                      ? const Icon(
                                          Icons.check,
                                          size: 14,
                                          color: Colors.black,
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  service,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        );
                      })
                      .toList(),
            ),
          ),
        const SizedBox(height: 16),
        if (selectedServices.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Hourly rate', style: TextStyle(color: Colors.grey)),
              Text(
                state.calculatedHourlyRate != null
                    ? '₦${state.calculatedHourlyRate!.toInt()}/hour'
                    : '₦${artisan.hourlyRate.toInt()}/hour',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Price range for a project',
                style: TextStyle(color: Colors.grey),
              ),
              Text(
                state.calculatedPriceRange?.isNotEmpty == true
                    ? state.calculatedPriceRange!
                    : artisan.priceRange,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ] else
          const Text(
            'Select services to see pricing',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
      ],
    );
  }
}
