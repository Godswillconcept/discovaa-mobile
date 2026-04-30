import 'package:discovaa/features/profile/presentation/providers/artisan_provider.dart';
import 'package:discovaa/features/profile/presentation/widgets/location_picker_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

class BookingFlowModal extends ConsumerStatefulWidget {
  const BookingFlowModal({super.key});

  @override
  ConsumerState<BookingFlowModal> createState() => _BookingFlowModalState();
}

class _BookingFlowModalState extends ConsumerState<BookingFlowModal> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final ScrollController _timeSlotScrollController = ScrollController();
  String? _errorMessage;
  bool _isServicesExpanded = false;

  @override
  void initState() {
    super.initState();
    final initialDate = ref.read(bookingProvider).selectedDate;
    if (initialDate != null) {
      _selectedDay = initialDate;
      _focusedDay = initialDate;
    } else {
      _selectedDay = _focusedDay;
    }

    final address = ref.read(bookingProvider).address;
    if (address != null) {
      _addressController.text = address;
    }

    final notes = ref.read(bookingProvider).notes;
    if (notes != null) {
      _notesController.text = notes;
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    _notesController.dispose();
    _timeSlotScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bookingState = ref.watch(bookingProvider);
    final notifier = ref.read(bookingProvider.notifier);

    if (bookingState.isConfirmed) {
      return _buildSuccessView(context, bookingState);
    }

    if (bookingState.isConfirming) {
      return _buildLoadingView();
    }

    return _buildSelectionView(context, bookingState, notifier);
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
            _buildCalendar(),
            const SizedBox(height: 20),
            _buildDateSelector(state, notifier),
            const SizedBox(height: 20),
            _buildTimeRangeSelector(state, notifier),
            const SizedBox(height: 20),
            _buildBookingSummary(state, notifier),
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
            _buildAddressSection(state, notifier),
            const SizedBox(height: 20),
            _buildServicesSection(state, notifier),
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
              onTap: () {
                if (mounted && Navigator.canPop(context)) {
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

  Widget _buildCalendar() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: TableCalendar(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
          ref.read(bookingProvider.notifier).selectDate(selectedDay);
        },
        calendarFormat: CalendarFormat.month,
        headerStyle: const HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          leftChevronIcon: Icon(Icons.chevron_left, color: Colors.grey),
          rightChevronIcon: Icon(Icons.chevron_right, color: Colors.grey),
        ),
        daysOfWeekStyle: const DaysOfWeekStyle(
          weekdayStyle: TextStyle(color: Colors.grey, fontSize: 12),
          weekendStyle: TextStyle(color: Colors.grey, fontSize: 12),
        ),
        calendarStyle: CalendarStyle(
          todayDecoration: BoxDecoration(
            color: Colors.grey.shade200,
            shape: BoxShape.circle,
          ),
          selectedDecoration: const BoxDecoration(
            color: Color(0xFF5C5C5C),
            shape: BoxShape.circle,
          ),
          todayTextStyle: const TextStyle(color: Colors.black),
          defaultTextStyle: const TextStyle(fontSize: 14),
          weekendTextStyle: const TextStyle(fontSize: 14),
          outsideDaysVisible: false,
        ),
      ),
    );
  }

  Widget _buildDateSelector(BookingState state, BookingNotifier notifier) {
    final artisan = state.selectedArtisan;
    if (artisan == null) return const SizedBox.shrink();

    final availabilityDates = _generateAvailableDates(artisan);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Available dates',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          "${artisan.name}'s available date slots...",
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 80,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: availabilityDates.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final date = availabilityDates[index];
              final isSelected =
                  state.selectedDate != null &&
                  isSameDay(state.selectedDate!, date);
              return GestureDetector(
                onTap: () {
                  notifier.selectDate(date);
                  setState(() {
                    _selectedDay = date;
                    _focusedDay = date;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? Colors.black : Colors.grey.shade200,
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    spacing: 2,
                    children: [
                      Text(
                        DateFormat('E').format(date).toUpperCase(),
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        DateFormat('d MMM').format(date),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Available',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  List<DateTime> _generateAvailableDates(Artisan artisan) {
    final now = DateTime.now();
    final dates = <DateTime>[];

    for (int i = 0; i < 7; i++) {
      final date = now.add(Duration(days: i));
      dates.add(date);
    }

    return dates;
  }

  /// Parses the artisan's availability string for a given day.
  /// Returns (startTime, endTime) or null if closed/unavailable.
  /// Availability format: "9:00AM - 5:00PM" or "Closed"
  (TimeOfDay?, TimeOfDay?)? _parseAvailabilityForDay(
    DateTime date,
    Artisan artisan,
  ) {
    final weekdayName = _getWeekdayName(date);
    final availabilityStr = artisan.availability[weekdayName];

    if (availabilityStr == null || availabilityStr.toLowerCase() == 'closed') {
      return null;
    }

    // Parse "9:00AM - 5:00PM" format
    final parts = availabilityStr.split(' - ');
    if (parts.length != 2) return null;

    final startTime = _parseTimeOfDay(parts[0].trim());
    final endTime = _parseTimeOfDay(parts[1].trim());

    if (startTime == null || endTime == null) return null;

    return (startTime, endTime);
  }

  String _getWeekdayName(DateTime date) {
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return weekdays[date.weekday - 1];
  }

  /// Parses time string like "9:00AM" or "5:00 PM" to TimeOfDay
  TimeOfDay? _parseTimeOfDay(String timeStr) {
    // Match patterns like "9:00AM", "12:30PM", "5:00 PM"
    final regex = RegExp(
      r'^(\d{1,2}):(\d{2})\s*(AM|PM)$',
      caseSensitive: false,
    );
    final match = regex.firstMatch(timeStr);

    if (match == null) return null;

    var hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    final period = match.group(3)!.toUpperCase();

    // Convert to 24-hour format
    if (period == 'PM' && hour != 12) {
      hour += 12;
    } else if (period == 'AM' && hour == 12) {
      hour = 0;
    }

    return TimeOfDay(hour: hour, minute: minute);
  }

  /// Generate time slots within the artisan's availability for the selected day
  List<TimeOfDay> _generateTimeSlots(DateTime? selectedDate, Artisan? artisan) {
    int startHour = 8;
    int startMinute = 0;
    int endHour = 20;
    int endMinute = 0;

    if (artisan != null && selectedDate != null) {
      final availability = _parseAvailabilityForDay(selectedDate, artisan);
      if (availability != null) {
        final (startTime, endTime) = availability;
        if (startTime != null && endTime != null) {
          startHour = startTime.hour;
          startMinute = startTime.minute;
          endHour = endTime.hour;
          endMinute = endTime.minute;
        }
      }
    }

    final startTotalMins = startHour * 60 + startMinute;
    final endTotalMins = endHour * 60 + endMinute;

    final slots = <TimeOfDay>[];
    int currentMins = startTotalMins;
    if (currentMins % 30 != 0) {
      currentMins += (30 - (currentMins % 30));
    }

    while (currentMins <= endTotalMins) {
      slots.add(TimeOfDay(hour: currentMins ~/ 60, minute: currentMins % 60));
      currentMins += 30;
    }
    return slots;
  }

  /// Check if a time slot is within the artisan's availability
  bool _isTimeWithinAvailability(
    TimeOfDay time,
    DateTime? selectedDate,
    Artisan? artisan,
  ) {
    if (artisan == null || selectedDate == null) return true;

    final availability = _parseAvailabilityForDay(selectedDate, artisan);
    if (availability == null) return false; // Closed that day

    final (startTime, endTime) = availability;
    if (startTime == null || endTime == null) return false;

    final timeMinutes = time.hour * 60 + time.minute;
    final startMinutes = startTime.hour * 60 + startTime.minute;
    final endMinutes = endTime.hour * 60 + endTime.minute;

    return timeMinutes >= startMinutes && timeMinutes <= endMinutes;
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'am' : 'pm';
    return '$hour:$minute$period';
  }

  void _handleTimeSelection(
    TimeOfDay time,
    BookingState state,
    BookingNotifier notifier,
    Artisan? artisan,
    DateTime? selectedDate,
  ) {
    if (!_isTimeWithinAvailability(time, selectedDate, artisan)) return;

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

  Widget _buildTimeRangeSelector(BookingState state, BookingNotifier notifier) {
    final artisan = state.selectedArtisan;
    final selectedDate = state.selectedDate;

    // Check if artisan is available on the selected day
    // ignore: unnecessary_null_comparison
    final isAvailable =
        artisan != null &&
        selectedDate != null &&
        _parseAvailabilityForDay(selectedDate, artisan) != null;

    final timeSlots = _generateTimeSlots(selectedDate, artisan);

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
            'Available: ${artisan.availability[_getWeekdayName(selectedDate)] ?? 'Contact for hours'}',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          )
        else if (selectedDate != null && artisan != null)
          Text(
            'Not available on ${_getWeekdayName(selectedDate)}',
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
                    'This artisan is not available on ${_getWeekdayName(selectedDate)}. Please select another date.',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ),
              ],
            ),
          )
        else
          SizedBox(
            height: 120,
            child: Row(
              children: [
                // Left scroll indicator
                GestureDetector(
                  onTap: () {
                    _timeSlotScrollController.animateTo(
                      _timeSlotScrollController.offset - 200,
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
                ),
                const SizedBox(width: 8),
                // Time slots grid
                Expanded(
                  child: timeSlots.isEmpty
                      ? Center(
                          child: Text(
                            'No available time slots',
                            style: TextStyle(color: Colors.grey.shade500),
                          ),
                        )
                      : ListView.separated(
                          controller: _timeSlotScrollController,
                          scrollDirection: Axis.horizontal,
                          itemCount: (timeSlots.length / 2).ceil(),
                          separatorBuilder: (context, index) =>
                              const SizedBox(width: 12),
                          itemBuilder: (context, colIndex) {
                            // Create a column with 2 time slots
                            final firstSlotIndex = colIndex * 2;
                            final secondSlotIndex = firstSlotIndex + 1;

                            return Column(
                              children: [
                                // First row time slot
                                _buildTimeSlotChip(
                                  timeSlots[firstSlotIndex],
                                  state.startTime,
                                  state.endTime,
                                  onSelect: (time) => _handleTimeSelection(
                                    time,
                                    state,
                                    notifier,
                                    artisan,
                                    selectedDate,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                // Second row time slot (if exists)
                                if (secondSlotIndex < timeSlots.length)
                                  _buildTimeSlotChip(
                                    timeSlots[secondSlotIndex],
                                    state.startTime,
                                    state.endTime,
                                    onSelect: (time) => _handleTimeSelection(
                                      time,
                                      state,
                                      notifier,
                                      artisan,
                                      selectedDate,
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                ),
                const SizedBox(width: 8),
                // Right scroll indicator
                GestureDetector(
                  onTap: () {
                    _timeSlotScrollController.animateTo(
                      _timeSlotScrollController.offset + 200,
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
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildTimeSlotChip(
    TimeOfDay time,
    TimeOfDay? startTime,
    TimeOfDay? endTime, {
    required Function(TimeOfDay) onSelect,
  }) {
    final timeMins = time.hour * 60 + time.minute;
    final startMins = startTime != null
        ? startTime.hour * 60 + startTime.minute
        : null;
    final endMins = endTime != null ? endTime.hour * 60 + endTime.minute : null;

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
            _formatTime(time).toLowerCase().replaceAll(' ', ''),
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

  Widget _buildBookingSummary(BookingState state, BookingNotifier notifier) {
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
              _buildSummaryItem(
                label: 'Date',
                value: DateFormat(
                  'EEE, d MMM yyyy',
                ).format(state.selectedDate!),
              ),
              const SizedBox(height: 12),
              // Time range
              if (state.startTime != null && state.endTime != null)
                _buildSummaryItem(
                  label: 'Time',
                  value:
                      '${_formatTime(state.startTime!)} - ${_formatTime(state.endTime!)}',
                ),
              if (state.startTime != null && state.endTime != null)
                const SizedBox(height: 12),
              // Duration
              if (state.durationDisplay.isNotEmpty)
                _buildSummaryItem(
                  label: 'Duration',
                  value: state.durationDisplay,
                ),
              if (state.durationDisplay.isNotEmpty) const SizedBox(height: 12),
              // Selected Services
              if (state.selectedServices.isNotEmpty) ...[
                _buildSummaryItem(
                  label: 'Services',
                  value: state.selectedServices.join(', '),
                ),
                const SizedBox(height: 12),
              ],
              // Booking type
              _buildSummaryItem(
                label: 'Booking type',
                value: state.bookingType.name.toUpperCase(),
                isBold: true,
              ),
              if (state.bookingType == BookingType.onsite) ...[
                const SizedBox(height: 12),
                _buildSummaryItem(
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

  Widget _buildSummaryItem({
    required String label,
    required String value,
    bool isBold = false,
  }) {
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

  Widget _buildAddressSection(BookingState state, BookingNotifier notifier) {
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
                Flexible(
                  child: const Text(
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
          onChanged: (value) => notifier.setAddress(value),
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
                    _getCurrentLocation(notifier);
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
            if (result != null && mounted) {
              final address = result['address'] as String?;
              final lat = result['latitude'] as double?;
              final lng = result['longitude'] as double?;
              if (address != null) {
                _addressController.text = address;
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

  Widget _buildServicesSection(BookingState state, BookingNotifier notifier) {
    final artisan = state.selectedArtisan;
    if (artisan == null) return const SizedBox.shrink();

    final selectedServices = state.selectedServices;

    // Helper functions for pricing calculation (matching ArtisanPricesDropdown logic)
    String calculatedPriceRange(Set<String> selected) {
      final selectedServiceObjects = state.availableServices
          .where((s) => selected.contains(s.title))
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

    double calculatedHourlyRate(Set<String> selected) {
      final selectedServiceObjects = state.availableServices
          .where((s) => selected.contains(s.title) && s.hourlyRate != null)
          .toList();

      if (selectedServiceObjects.isEmpty) return artisan.hourlyRate;

      final rates = selectedServiceObjects.map((s) => s.hourlyRate!).toList();
      return rates.reduce((a, b) => (a < b ? a : b));
    }

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
                '₦${calculatedHourlyRate(selectedServices).toInt()}/hour',
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
                calculatedPriceRange(selectedServices).isNotEmpty
                    ? calculatedPriceRange(selectedServices)
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
          decoration: InputDecoration(
            hintText: 'Add any extra details...',
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
          onChanged: (value) => notifier.setNotes(value),
        ),
      ],
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    BookingState state,
    BookingNotifier notifier,
  ) {
    return Column(
      children: [
        if (_errorMessage != null) ...[
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
                    _errorMessage!,
                    style: TextStyle(color: Colors.red.shade900, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        ElevatedButton(
          onPressed: state.isValid
              ? () async {
                  if (mounted) {
                    setState(() => _errorMessage = null);
                  }
                  final errorMsg = await notifier.confirmBooking();
                  if (errorMsg != null && mounted) {
                    setState(() => _errorMessage = errorMsg);
                  }
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            minimumSize: const Size(double.infinity, 55),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Create booking',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => Navigator.pop(context),
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

  Future<void> _getCurrentLocation(BookingNotifier notifier) async {
    bool serviceEnabled;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location services are disabled.')),
        );
      }
      return;
    }

    try {
      // Request location permission
      LocationPermission permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission denied')),
          );
        }
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Location permission permanently denied. Please enable in settings.',
              ),
            ),
          );
        }
        return;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      // Store coordinates in state
      notifier.setLocation(position.latitude, position.longitude);

      // Get address from coordinates
      final places = await geocoding.placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (places.isNotEmpty) {
        final placemark = places.first;
        final address = [
          placemark.street,
          if (placemark.subLocality?.isNotEmpty == true) placemark.subLocality,
          if (placemark.locality?.isNotEmpty == true) placemark.locality,
          if (placemark.administrativeArea?.isNotEmpty == true)
            placemark.administrativeArea,
          if (placemark.country?.isNotEmpty == true) placemark.country,
        ].where((part) => part != null && part.isNotEmpty).join(', ');

        _addressController.text = address;
        notifier.setAddress(address);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error getting location: $e')));
      }
    }
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

  Widget _buildSuccessView(BuildContext context, BookingState state) {
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
                if (mounted && Navigator.canPop(context)) {
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
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
              ),
              Container(
                width: 85,
                height: 85,
                decoration: const BoxDecoration(
                  color: Color(0xFF4A80F0),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.description_outlined,
                  color: Colors.white,
                  size: 40,
                ),
              ),
              // Decorative dots scattered as in Image 7
              ..._buildScatteredDots(),
            ],
          ),
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
                        '${_formatTime(state.startTime!)} - ${_formatTime(state.endTime!)}',
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

  List<Widget> _buildScatteredDots() {
    final dotPositions = [
      const Offset(-55, -45),
      const Offset(-70, 10),
      const Offset(-45, 60),
      const Offset(60, -50),
      const Offset(75, 20),
      const Offset(15, 70),
    ];
    final dotSizes = [8.0, 5.0, 6.0, 10.0, 7.0, 5.0];

    return List.generate(dotPositions.length, (index) {
      return Transform.translate(
        offset: dotPositions[index],
        child: Container(
          width: dotSizes[index],
          height: dotSizes[index],
          decoration: const BoxDecoration(
            color: Color(0xFF4A80F0),
            shape: BoxShape.circle,
          ),
        ),
      );
    });
  }
}
