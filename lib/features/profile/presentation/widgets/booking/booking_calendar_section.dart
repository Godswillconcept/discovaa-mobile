import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

import 'package:discovaa/features/profile/presentation/providers/artisan_provider.dart';
import 'booking_utils.dart';

class BookingCalendarSection extends ConsumerStatefulWidget {
  const BookingCalendarSection({super.key});

  @override
  ConsumerState<BookingCalendarSection> createState() =>
      _BookingCalendarSectionState();
}

class _BookingCalendarSectionState
    extends ConsumerState<BookingCalendarSection> {
  late DateTime _focusedDay;
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    final initialDate = ref.read(bookingProvider).selectedDate;
    if (initialDate != null) {
      _selectedDay = initialDate;
      _focusedDay = initialDate;
    } else {
      _focusedDay = DateTime.now();
      _selectedDay = _focusedDay;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookingState = ref.watch(bookingProvider);
    final notifier = ref.read(bookingProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCalendar(),
        const SizedBox(height: 20),
        _buildDateSelector(bookingState, notifier),
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

    final now = DateTime.now();

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
            itemCount: 30, // Show next 30 days
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final date = now.add(Duration(days: index));
              final weekdayName = getWeekdayName(date);
              final availability = artisan.availability[weekdayName];
              final isAvailable =
                  availability != null &&
                  availability.toLowerCase() != 'closed' &&
                  availability.toLowerCase().contains('-');
              final isSelected =
                  state.selectedDate != null &&
                  isSameDay(state.selectedDate!, date);

              return GestureDetector(
                onTap: isAvailable
                    ? () {
                        notifier.selectDate(date);
                        setState(() {
                          _selectedDay = date;
                          _focusedDay = date;
                        });
                      }
                    : null,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: !isAvailable
                          ? Colors.grey.shade300
                          : isSelected
                          ? Colors.black
                          : Colors.grey.shade200,
                      width: 1.5,
                    ),
                    color: !isAvailable ? Colors.grey.shade100 : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    spacing: 2,
                    children: [
                      Text(
                        DateFormat('E').format(date).toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          color: !isAvailable
                              ? Colors.grey.shade400
                              : Colors.grey,
                        ),
                      ),
                      Text(
                        DateFormat('d MMM').format(date),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: !isAvailable
                              ? Colors.grey.shade400
                              : Colors.black,
                        ),
                      ),
                      Text(
                        isAvailable ? 'Available' : 'Closed',
                        style: TextStyle(
                          fontSize: 10,
                          color: !isAvailable
                              ? Colors.grey.shade400
                              : Colors.grey.shade400,
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
}
