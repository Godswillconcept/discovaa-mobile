import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:discovaa/features/profile/presentation/providers/artisan_provider.dart';
import 'booking_calendar_section.dart';
import 'booking_time_slots_section.dart';
import 'booking_services_section.dart';
import 'booking_address_section.dart';
import 'booking_summary_section.dart';
import 'booking_success_view.dart';

class BookingFlowModal extends ConsumerStatefulWidget {
  const BookingFlowModal({super.key});

  @override
  ConsumerState<BookingFlowModal> createState() => _BookingFlowModalState();
}

class _BookingFlowModalState extends ConsumerState<BookingFlowModal> {
  final TextEditingController _notesController = TextEditingController();
  bool _isDirty = false;

  @override
  void initState() {
    super.initState();
    final notes = ref.read(bookingProvider).notes;
    if (notes != null) {
      _notesController.text = notes;
    }
    // Listen to notes changes to track dirty state
    _notesController.addListener(() {
      final currentNotes = ref.read(bookingProvider).notes ?? '';
      if (_notesController.text != currentNotes) {
        setState(() {
          _isDirty = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  // Check if form has been modified
  bool _checkIfDirty(BookingState state) {
    return state.selectedServices.isNotEmpty ||
        state.selectedDate != null ||
        state.startTime != null ||
        state.endTime != null ||
        state.address?.isNotEmpty == true ||
        state.notes?.isNotEmpty == true ||
        state.bookingType != BookingType.onsite ||
        _isDirty;
  }

  // Show confirmation dialog before closing
  Future<bool> _onWillPop() async {
    final state = ref.read(bookingProvider);
    if (!_checkIfDirty(state)) return true;

    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text(
          'You have unsaved changes. Are you sure you want to close this booking?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Clear the booking state
              final notifier = ref.read(bookingProvider.notifier);
              notifier.selectDate(DateTime.now());
              notifier.selectTime('');
              notifier.selectBookingType(BookingType.onsite);
              notifier.selectStartTime(null);
              notifier.selectEndTime(null);
              notifier.setAddress('');
              notifier.setNotes('');
              notifier.clearServices();
              notifier.toggleUseCurrentLocation(false);
              notifier.setLocation(null, null);
              Navigator.of(context).pop(true);
            },
            child: const Text('Discard', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    return shouldPop ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final bookingState = ref.watch(bookingProvider);
    final notifier = ref.read(bookingProvider.notifier);

    if (bookingState.isConfirmed) {
      return BookingSuccessView();
    }

    if (bookingState.isConfirming) {
      return _buildLoadingView();
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && mounted) {
          Navigator.of(context).pop();
        }
      },
      child: _buildSelectionView(context, bookingState, notifier),
    );
  }

  Widget _buildSelectionView(
    BuildContext context,
    BookingState state,
    BookingNotifier notifier,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 20),
            const BookingCalendarSection(),
            const SizedBox(height: 20),
            const BookingTimeSlotsSection(),
            const SizedBox(height: 20),
            const BookingSummarySection(),
            const SizedBox(height: 24),
            // Service and booking details section
            const Text(
              'Service and booking details',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            const Text(
              'Select the booking type and service.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            _buildBookingTypeSelector(state, notifier),
            const SizedBox(height: 20),
            const BookingAddressSection(),
            const SizedBox(height: 20),
            const BookingServicesSection(),
            const SizedBox(height: 20),
            _buildNotesSection(state, notifier),
            const SizedBox(height: 30),
            _buildActionButtons(context, state, notifier),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Select date and time',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () async {
                final shouldPop = await _onWillPop();
                if (shouldPop && mounted) {
                  Navigator.of(context).pop();
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
          ],
        ),
        const SizedBox(height: 5),
        Text(
          'In your local time zone',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildBookingTypeSelector(
    BookingState state,
    BookingNotifier notifier,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Booking type',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<BookingType>(
              value: state.bookingType,
              isExpanded: true,
              items: BookingType.values.map((type) {
                return DropdownMenuItem<BookingType>(
                  value: type,
                  child: Text(type.name.toUpperCase()),
                );
              }).toList(),
              onChanged: (type) {
                if (type != null) notifier.selectBookingType(type);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotesSection(BookingState state, BookingNotifier notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Note (optional)',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _notesController,
          maxLines: 3,
          maxLength: 500,
          decoration: InputDecoration(
            hintText: 'Add any extra details...',
            counterText: '${_notesController.text.length}/500',
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
          ),
          onChanged: (value) {
            setState(() {
              // Trigger rebuild to update character count
            });
            notifier.setNotes(value);
          },
        ),
      ],
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    BookingState state,
    BookingNotifier notifier,
  ) {
    final bool canSubmit = state.isValid && !state.isConfirming;

    return Column(
      children: [
        if (state.errorMessage != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red.shade800, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    state.errorMessage!,
                    style: TextStyle(color: Colors.red.shade900, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        ElevatedButton(
          onPressed: canSubmit
              ? () async {
                  await notifier.confirmBooking();
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            minimumSize: const Size(double.infinity, 55),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: state.isConfirming
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text(
                  'Create booking',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: state.isConfirming ? null : () => Navigator.pop(context),
          child: const Center(
            child: Text(
              'Back',
              style: TextStyle(color: Colors.black, fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingView() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 70,
            height: 70,
            child: CircularProgressIndicator(
              color: Color(0xFFE0E0E0),
              backgroundColor: Colors.transparent,
              strokeWidth: 4,
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Just a second...',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Your booking is being confirmed.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
