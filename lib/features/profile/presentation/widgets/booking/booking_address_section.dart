import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:discovaa/features/profile/presentation/providers/artisan_provider.dart';
import 'package:discovaa/features/profile/presentation/widgets/location_picker_page.dart';
import 'booking_utils.dart';

class BookingAddressSection extends ConsumerStatefulWidget {
  const BookingAddressSection({super.key});

  @override
  ConsumerState<BookingAddressSection> createState() =>
      _BookingAddressSectionState();
}

class _BookingAddressSectionState extends ConsumerState<BookingAddressSection> {
  late TextEditingController _addressController;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    final state = ref.read(bookingProvider);
    _addressController = TextEditingController(text: state.address ?? '')
      ..selection = TextSelection.fromPosition(
        TextPosition(offset: state.address?.length ?? 0),
      );
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  String? _validateAddress(String address) {
    if (address.isEmpty) return 'Address is required';
    if (address.length < 10) return 'Please enter a complete address';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bookingProvider);
    final notifier = ref.read(bookingProvider.notifier);

    // Update controller text if state changes externally (e.g., from location picker)
    if (_addressController.text != (state.address ?? '')) {
      _addressController.text = state.address ?? '';
      _addressController.selection = TextSelection.fromPosition(
        TextPosition(offset: _addressController.text.length),
      );
    }

    // Hide address section for workshop bookings
    if (state.bookingType == BookingType.workshop) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Location',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                Icon(Icons.store, color: Colors.grey.shade600),
                const SizedBox(width: 12),
                const Flexible(
                  child: Text(
                    'Booking will be at the artisan\'s workshop',
                    style: TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    _errorText = _validateAddress(state.address ?? '');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Address',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _addressController,
          decoration: InputDecoration(
            hintText: 'Enter address',
            errorText: _errorText,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.black),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red),
            ),
          ),
          onChanged: (value) {
            notifier.setAddress(value);
            setState(() {
              _errorText = _validateAddress(value);
            });
          },
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Checkbox(
              value: state.useCurrentLocation,
              onChanged: (value) {
                if (value != null) {
                  notifier.toggleUseCurrentLocation(value);
                  if (value) {
                    getCurrentLocation(notifier, context);
                  }
                }
              },
            ),
            const Text('Use my current location'),
          ],
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => LocationPickerPage(
                  initialLatitude: state.latitude,
                  initialLongitude: state.longitude,
                  initialAddress: state.address,
                ),
              ),
            );
            if (result != null && context.mounted) {
              final address = result['address'] as String?;
              final lat = result['latitude'] as double?;
              final lng = result['longitude'] as double?;
              if (address != null) {
                notifier.setAddress(address);
              }
              if (lat != null && lng != null) {
                notifier.setLocation(lat, lng);
              }
            }
          },
          icon: const Icon(Icons.map, size: 18),
          label: const Text('Open map'),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: Colors.grey.shade300),
          ),
        ),
      ],
    );
  }
}
