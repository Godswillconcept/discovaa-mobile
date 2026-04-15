import 'package:discovaa/features/profile/presentation/providers/artisan_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';

class BookingFlowModal extends ConsumerStatefulWidget {
  const BookingFlowModal({super.key});

  @override
  ConsumerState<BookingFlowModal> createState() => _BookingFlowModalState();
}

class _BookingFlowModalState extends ConsumerState<BookingFlowModal> {
  DateTime _focusedDay = DateTime(2024, 2, 8);
  DateTime? _selectedDay;

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
      // height: 600,
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Select date and time',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.black,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 5),
                Text(
                  'In your local time zone (Europe, Estonia)',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),

            const SizedBox(height: 30),

            // Calendar Integration
            _buildCalendar(),

            const SizedBox(height: 30),
            const Text(
              'Available dates',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              "${state.selectedArtisan?.name ?? 'Artisan'}'s available date slots...",
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            _buildDateSelector(state, notifier),

            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Available time slots',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Icon(Icons.arrow_forward_ios, size: 16),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              "${state.selectedArtisan?.name ?? 'Artisan'}'s available time slots...",
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            _buildTimeSelector(state, notifier),

            const SizedBox(height: 40),
            ElevatedButton(
              onPressed:
                  (state.selectedDate != null && state.selectedTime != null)
                  ? () => notifier.confirmBooking()
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Confirm Booking',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Center(
                child: Text(
                  'Cancel',
                  style: TextStyle(color: Colors.black, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
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
    final dates = [
      {'day': 'MON', 'date': '2nd Feb'},
      {'day': 'TUE', 'date': '3rd Feb'},
      {'day': 'WED', 'date': '4th Feb'},
    ];

    return SizedBox(
      height: 85,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: dates.length + 1,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          if (index == dates.length) {
            return Center(
              child: Row(
                children: [
                  const Text(
                    'See All',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.black,
                    size: 14,
                  ),
                ],
              ),
            );
          }
          final date = dates[index];
          final isSelected =
              state.selectedDate != null &&
              state.selectedDate!.day == (index + 2); // Mock matching Feb 2,3,4
          return GestureDetector(
            onTap: () {
              final newDate = DateTime(2024, 2, index + 2);
              notifier.selectDate(newDate);
              setState(() {
                _selectedDay = newDate;
                _focusedDay = newDate;
              });
            },
            child: Container(
              width: 100,
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
                children: [
                  Text(
                    date['day']!,
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date['date']!,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Available',
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimeSelector(BookingState state, BookingNotifier notifier) {
    final times = [
      '8:00AM',
      '8:30AM',
      '9:00AM',
      '9:30AM',
      '10:00AM',
      '10:30AM',
    ];
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: times.map((t) {
        final isSelected = t == state.selectedTime;
        return GestureDetector(
          onTap: () => notifier.selectTime(t),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? Colors.black : Colors.grey.shade200,
              ),
            ),
            child: Text(t, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        );
      }).toList(),
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
              onTap: () => Navigator.pop(context),
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
                text: 'Your booking with Plum ',
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
                  text: 'Monday, 2nd February, 2023',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.black.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
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
                  text: '8:00AM UTC',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.black.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: () {
              ref.read(bookingProvider.notifier).reset();
              Navigator.pop(context);
              context.go('/home');
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
              'Back to Home Page',
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
