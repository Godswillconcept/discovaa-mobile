import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:discovaa/features/profile/presentation/providers/artisan_provider.dart';
import 'booking_utils.dart';

class BookingTimeSlotsSection extends ConsumerWidget {
  const BookingTimeSlotsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(bookingProvider);
    final notifier = ref.read(bookingProvider.notifier);
    final artisan = state.selectedArtisan;
    final selectedDate = state.selectedDate;

    // Check if artisan is available on the selected day
    final isAvailable =
        artisan != null &&
        selectedDate != null &&
        parseAvailabilityForDay(selectedDate, artisan) != null;

    final timeSlots = generateTimeSlots(selectedDate, artisan);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select time range',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        if (isAvailable)
          Text(
            'Available: ${artisan.availability[getWeekdayName(selectedDate)] ?? 'Contact for hours'}',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          )
        else if (selectedDate != null && artisan != null)
          Text(
            'Not available on ${getWeekdayName(selectedDate)}',
            style: TextStyle(fontSize: 12, color: Colors.red.shade400),
          )
        else
          const Text(
            'Select a start time, then select an end time.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        const SizedBox(height: 16),
        if (!isAvailable && artisan != null && selectedDate != null)
          // Show unavailable message
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.event_busy, color: Colors.grey.shade500),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'This artisan is not available on ${getWeekdayName(selectedDate)}. Please select another date.',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ),
              ],
            ),
          )
        else
          _TimeSlotsGrid(
            timeSlots: timeSlots,
            startTime: state.startTime,
            endTime: state.endTime,
            artisan: artisan,
            selectedDate: selectedDate,
            onTimeSelected: (time) => _handleTimeSelection(
              time,
              state,
              notifier,
              artisan,
              selectedDate,
            ),
          ),
      ],
    );
  }

  void _handleTimeSelection(
    TimeOfDay time,
    BookingState state,
    BookingNotifier notifier,
    Artisan? artisan,
    DateTime? selectedDate,
  ) {
    if (!isTimeWithinAvailability(time, selectedDate, artisan)) return;

    if (state.startTime == null) {
      notifier.selectStartTime(time);
      notifier.selectEndTime(null);
    } else if (state.endTime == null) {
      final startMins = state.startTime!.hour * 60 + state.startTime!.minute;
      final tapMins = time.hour * 60 + time.minute;
      if (tapMins > startMins) {
        notifier.selectEndTime(time);
      } else if (tapMins < startMins) {
        notifier.selectStartTime(time);
      } else {
        notifier.selectStartTime(null);
      }
    } else {
      notifier.selectStartTime(time);
      notifier.selectEndTime(null);
    }
  }
}

class _TimeSlotsGrid extends StatefulWidget {
  final List<TimeOfDay> timeSlots;
  final TimeOfDay? startTime;
  final TimeOfDay? endTime;
  final Artisan? artisan;
  final DateTime? selectedDate;
  final Function(TimeOfDay) onTimeSelected;

  const _TimeSlotsGrid({
    required this.timeSlots,
    required this.startTime,
    required this.endTime,
    required this.artisan,
    required this.selectedDate,
    required this.onTimeSelected,
  });

  @override
  State<_TimeSlotsGrid> createState() => _TimeSlotsGridState();
}

class _TimeSlotsGridState extends State<_TimeSlotsGrid> {
  final ScrollController _scrollController = ScrollController();
  bool _showLeftIndicator = false;
  bool _showRightIndicator = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_updateScrollIndicators);
    // Initial check after frame renders
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateScrollIndicators();
    });
  }

  void _updateScrollIndicators() {
    if (!mounted) return;
    if (!_scrollController.hasClients) return;

    setState(() {
      _showLeftIndicator = _scrollController.offset > 0;
      _showRightIndicator =
          _scrollController.offset < _scrollController.position.maxScrollExtent;
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_updateScrollIndicators);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: Row(
        children: [
          // Left scroll indicator (only show if scrolled right)
          if (_showLeftIndicator)
            GestureDetector(
              onTap: () {
                _scrollController.animateTo(
                  _scrollController.offset - 200,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Icon(
                  Icons.chevron_left,
                  size: 20,
                  color: Colors.grey.shade600,
                ),
              ),
            )
          else
            const SizedBox(width: 32),
          const SizedBox(width: 8),
          // Time slots grid
          Expanded(
            child: widget.timeSlots.isEmpty
                ? Center(
                    child: Text(
                      'No available time slots',
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                  )
                : ListView.separated(
                    controller: _scrollController,
                    scrollDirection: Axis.horizontal,
                    itemCount: (widget.timeSlots.length / 2).ceil(),
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: 12),
                    itemBuilder: (context, colIndex) {
                      // Create a column with 2 time slots
                      final firstSlotIndex = colIndex * 2;
                      final secondSlotIndex = firstSlotIndex + 1;

                      return Column(
                        children: [
                          // First row time slot
                          _TimeSlotChip(
                            time: widget.timeSlots[firstSlotIndex],
                            startTime: widget.startTime,
                            endTime: widget.endTime,
                            onSelect: widget.onTimeSelected,
                          ),
                          const SizedBox(height: 12),
                          // Second row time slot (if exists)
                          if (secondSlotIndex < widget.timeSlots.length)
                            _TimeSlotChip(
                              time: widget.timeSlots[secondSlotIndex],
                              startTime: widget.startTime,
                              endTime: widget.endTime,
                              onSelect: widget.onTimeSelected,
                            ),
                        ],
                      );
                    },
                  ),
          ),
          const SizedBox(width: 8),
          // Right scroll indicator (only show if not at end)
          if (_showRightIndicator)
            GestureDetector(
              onTap: () {
                _scrollController.animateTo(
                  _scrollController.offset + 200,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: Colors.grey.shade600,
                ),
              ),
            )
          else
            const SizedBox(width: 32),
        ],
      ),
    );
  }
}

class _TimeSlotChip extends StatelessWidget {
  final TimeOfDay time;
  final TimeOfDay? startTime;
  final TimeOfDay? endTime;
  final Function(TimeOfDay) onSelect;

  const _TimeSlotChip({
    required this.time,
    required this.startTime,
    required this.endTime,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final timeMins = time.hour * 60 + time.minute;
    final startMins = startTime != null
        ? startTime!.hour * 60 + startTime!.minute
        : null;
    final endMins = endTime != null
        ? endTime!.hour * 60 + endTime!.minute
        : null;

    final isStart = startMins == timeMins;
    final isEnd = endMins == timeMins;
    final isBetween =
        startMins != null &&
        endMins != null &&
        timeMins > startMins &&
        timeMins < endMins;

    final bool isSelected = isStart || isEnd;

    return GestureDetector(
      onTap: () => onSelect(time),
      child: Container(
        width: 90,
        height: 44,
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.black
              : (isBetween ? Colors.grey.shade200 : Colors.white),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Colors.black
                : (isBetween ? Colors.grey.shade300 : Colors.grey.shade300),
          ),
        ),
        child: Center(
          child: Text(
            formatTime(time).toLowerCase().replaceAll(' ', ''),
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black,
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
