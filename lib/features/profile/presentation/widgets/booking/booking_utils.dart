import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' as geocoding;

import 'package:discovaa/features/profile/presentation/providers/artisan_provider.dart';

/// Cache for memoized time slots
/// Key format: "artisanId_dateString" (e.g., "123_2024-01-15")
final Map<String, List<TimeOfDay>> _timeSlotsCache = {};

/// Parses the artisan's availability string for a given day.
/// Returns (startTime, endTime) or null if closed/unavailable.
/// Availability format: "9:00AM - 5:00PM" or "Closed"
(TimeOfDay?, TimeOfDay?)? parseAvailabilityForDay(
  DateTime date,
  Artisan artisan,
) {
  final weekdayName = getWeekdayName(date);
  final availabilityStr = artisan.availability[weekdayName];

  if (availabilityStr == null || availabilityStr.toLowerCase() == 'closed') {
    return null;
  }

  // Parse "9:00AM - 5:00PM" format
  final parts = availabilityStr.split(' - ');
  if (parts.length != 2) return null;

  final startTime = parseTimeOfDay(parts[0].trim());
  final endTime = parseTimeOfDay(parts[1].trim());

  if (startTime == null || endTime == null) return null;

  return (startTime, endTime);
}

String getWeekdayName(DateTime date) {
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
TimeOfDay? parseTimeOfDay(String timeStr) {
  // Match patterns like "9:00AM", "12:30PM", "5:00 PM"
  final regex = RegExp(r'^(\d{1,2}):(\d{2})\s*(AM|PM)$', caseSensitive: false);
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
/// Results are memoized based on artisan ID and date to avoid recalculation.
List<TimeOfDay> generateTimeSlots(DateTime? selectedDate, Artisan? artisan) {
  // Return empty list if no date or artisan
  if (selectedDate == null || artisan == null) {
    return [];
  }

  // Create cache key from artisan ID and date
  final cacheKey =
      '${artisan.id}_${selectedDate.toIso8601String().split(' ')[0]}';

  // Return cached result if available
  if (_timeSlotsCache.containsKey(cacheKey)) {
    return _timeSlotsCache[cacheKey]!;
  }

  int startHour = 8;
  int startMinute = 0;
  int endHour = 20;
  int endMinute = 0;

  final availability = parseAvailabilityForDay(selectedDate, artisan);
  if (availability != null) {
    final (startTime, endTime) = availability;
    if (startTime != null && endTime != null) {
      startHour = startTime.hour;
      startMinute = startTime.minute;
      endHour = endTime.hour;
      endMinute = endTime.minute;
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

  // Cache the result
  _timeSlotsCache[cacheKey] = slots;
  return slots;
}

/// Clear the time slots cache (call when artisan changes or on logout)
void clearTimeSlotsCache() {
  _timeSlotsCache.clear();
}

/// Check if a time slot is within the artisan's availability
bool isTimeWithinAvailability(
  TimeOfDay time,
  DateTime? selectedDate,
  Artisan? artisan,
) {
  if (artisan == null || selectedDate == null) return true;

  final availability = parseAvailabilityForDay(selectedDate, artisan);
  if (availability == null) return false; // Closed that day

  final (startTime, endTime) = availability;
  if (startTime == null || endTime == null) return false;

  final timeMinutes = time.hour * 60 + time.minute;
  final startMinutes = startTime.hour * 60 + startTime.minute;
  final endMinutes = endTime.hour * 60 + endTime.minute;

  return timeMinutes >= startMinutes && timeMinutes <= endMinutes;
}

String formatTime(TimeOfDay time) {
  final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
  final minute = time.minute.toString().padLeft(2, '0');
  final period = time.period == DayPeriod.am ? 'am' : 'pm';
  return '$hour:$minute$period';
}

List<DateTime> generateAvailableDates(Artisan artisan) {
  final now = DateTime.now();
  final dates = <DateTime>[];

  for (int i = 0; i < 30; i++) {
    // Check next 30 days
    final date = now.add(Duration(days: i));
    final weekdayName = getWeekdayName(date); // Monday, Tuesday, etc.
    final availability = artisan.availability[weekdayName];

    if (availability != null &&
        availability.toLowerCase() != 'closed' &&
        availability.toLowerCase().contains('-')) {
      dates.add(date);
    }
  }
  return dates;
}

Widget buildScatteredDots() {
  final dotPositions = [
    const Offset(-55, -45),
    const Offset(-70, 10),
    const Offset(-45, 60),
    const Offset(60, -50),
    const Offset(75, 20),
    const Offset(15, 70),
  ];
  final dotSizes = [8.0, 5.0, 6.0, 10.0, 7.0, 5.0];

  return Stack(
    alignment: Alignment.center,
    children: List.generate(dotPositions.length, (index) {
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
    }),
  );
}

Future<void> getCurrentLocation(
  BookingNotifier notifier,
  BuildContext context, {
  int retryCount = 0,
}) async {
  const maxRetries = 3;
  bool serviceEnabled;

  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    if (context.mounted) {
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
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission denied')),
        );
      }
      return;
    }

    if (permission == LocationPermission.deniedForever) {
      if (context.mounted) {
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

    // Get current position with timeout
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    ).timeout(const Duration(seconds: 15));

    // Store coordinates in state
    notifier.setLocation(position.latitude, position.longitude);

    // Get address from coordinates
    final places = await geocoding.placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );

    if (places.isNotEmpty && context.mounted) {
      final placemark = places.first;
      final address = [
        placemark.street,
        if (placemark.subLocality?.isNotEmpty == true) placemark.subLocality,
        if (placemark.locality?.isNotEmpty == true) placemark.locality,
        if (placemark.administrativeArea?.isNotEmpty == true)
          placemark.administrativeArea,
        if (placemark.country?.isNotEmpty == true) placemark.country,
      ].where((part) => part != null && part.isNotEmpty).join(', ');

      notifier.setAddress(address);
    }
  } catch (e) {
    // Implement exponential backoff retry logic
    if (retryCount < maxRetries) {
      final backoffDelay = Duration(
        seconds: (retryCount + 1) * 2,
      ); // 2, 4, 6 seconds
      await Future.delayed(backoffDelay);

      if (context.mounted) {
        return getCurrentLocation(
          notifier,
          context,
          retryCount: retryCount + 1,
        );
      }
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error getting location: $e'),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: () {
                getCurrentLocation(notifier, context);
              },
            ),
          ),
        );
      }
    }
  }
}
