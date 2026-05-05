import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:discovaa/features/profile/domain/repositories/artisan_detail_repository.dart'
    show ArtisanService;
import 'package:discovaa/features/profile/presentation/providers/artisan_provider.dart';

class ArtisanPricesDropdown extends ConsumerStatefulWidget {
  final Artisan artisan;
  final List<ArtisanService> services;

  const ArtisanPricesDropdown({
    super.key,
    required this.artisan,
    required this.services,
  });

  @override
  ConsumerState<ArtisanPricesDropdown> createState() =>
      _ArtisanPricesDropdownState();
}

class _ArtisanPricesDropdownState extends ConsumerState<ArtisanPricesDropdown> {
  bool _isExpanded = false;

  String _calculatedPriceRange(Set<String> selectedServices) {
    final selectedServiceObjects = widget.services
        .where((s) => selectedServices.contains(s.title))
        .toList();

    if (selectedServiceObjects.isEmpty) return '';

    final ranges = selectedServiceObjects
        .map((s) => s.priceRange)
        .where((r) => r.isNotEmpty)
        .toSet()
        .toList();
    if (ranges.length == 1) {
      return ranges.first;
    } else if (ranges.length > 1) {
      return '${ranges.first} - ${ranges.last}';
    }
    return '';
  }

  double _calculatedHourlyRate(Set<String> selectedServices) {
    final selectedServiceObjects = widget.services
        .where(
          (s) => selectedServices.contains(s.title) && s.hourlyRate != null,
        )
        .toList();

    if (selectedServiceObjects.isEmpty) return widget.artisan.hourlyRate;

    final rates = selectedServiceObjects.map((s) => s.hourlyRate!).toList();
    return rates.reduce((a, b) => (a < b ? a : b));
  }

  @override
  Widget build(BuildContext context) {
    final selectedServices = ref.watch(bookingProvider).selectedServices;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Prices',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
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
                  _isExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: Colors.black,
                ),
              ],
            ),
          ),
        ),
        if (_isExpanded)
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
                  (widget.services.isNotEmpty
                          ? widget.services.map((s) => s.title).toList()
                          : widget.artisan.services)
                      .map((service) {
                        final isSelected = selectedServices.contains(service);
                        return InkWell(
                          onTap: () {
                            ref
                                .read(bookingProvider.notifier)
                                .toggleService(service);
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
                '₦${_calculatedHourlyRate(selectedServices).toInt()}/hour',
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
                _calculatedPriceRange(selectedServices).isNotEmpty
                    ? _calculatedPriceRange(selectedServices)
                    : widget.artisan.priceRange,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ] else
          const Text(
            'Select services to see pricing',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
        const SizedBox(height: 16),
        const Divider(),
      ],
    );
  }
}
