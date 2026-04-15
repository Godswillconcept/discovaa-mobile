import 'profile_enums.dart';

/// Represents a single day's availability configuration
class DayAvailability {
  final DayOfWeek day;
  final bool isAvailable;
  final String? startTime; // Format: "HH:mm"
  final String? endTime; // Format: "HH:mm"

  const DayAvailability({
    required this.day,
    this.isAvailable = false,
    this.startTime,
    this.endTime,
  });

  DayAvailability copyWith({
    DayOfWeek? day,
    bool? isAvailable,
    String? startTime,
    String? endTime,
  }) {
    return DayAvailability(
      day: day ?? this.day,
      isAvailable: isAvailable ?? this.isAvailable,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'day': day.name,
      'isAvailable': isAvailable,
      'startTime': startTime,
      'endTime': endTime,
    };
  }

  factory DayAvailability.fromJson(Map<String, dynamic> json) {
    return DayAvailability(
      day: DayOfWeek.values.firstWhere(
        (e) => e.name == json['day'],
        orElse: () => DayOfWeek.monday,
      ),
      isAvailable: json['isAvailable'] ?? false,
      startTime: json['startTime'],
      endTime: json['endTime'],
    );
  }

  /// Validate that end time is after start time
  bool get isValid {
    if (!isAvailable) return true;
    if (startTime == null || endTime == null) return false;
    return _timeToMinutes(startTime!) < _timeToMinutes(endTime!);
  }

  int _timeToMinutes(String time) {
    final parts = time.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }
}

/// Complete availability configuration for a user
class Availability {
  final List<DayAvailability> days;
  final String? timezone;

  const Availability({
    required this.days,
    this.timezone,
  });

  factory Availability.defaultSchedule() {
    return Availability(
      days: DayOfWeek.values
          .map((day) => DayAvailability(day: day))
          .toList(),
      timezone: 'UTC',
    );
  }

  Availability copyWith({
    List<DayAvailability>? days,
    String? timezone,
  }) {
    return Availability(
      days: days ?? this.days,
      timezone: timezone ?? this.timezone,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'days': days.map((d) => d.toJson()).toList(),
      'timezone': timezone,
    };
  }

  factory Availability.fromJson(Map<String, dynamic> json) {
    return Availability(
      days: (json['days'] as List)
          .map((d) => DayAvailability.fromJson(d))
          .toList(),
      timezone: json['timezone'],
    );
  }

  /// Get availability for a specific day
  DayAvailability? getDayAvailability(DayOfWeek day) {
    return days.firstWhere((d) => d.day == day);
  }

  /// Check if the schedule is valid (all enabled days have valid times)
  bool get isValid {
    return days.every((day) => day.isValid);
  }

  /// Get total available hours per week
  int get totalWeeklyHours {
    return days.fold(0, (total, day) {
      if (!day.isAvailable || !day.isValid) return total;
      final start = day.startTime!.split(':');
      final end = day.endTime!.split(':');
      final startMinutes = int.parse(start[0]) * 60 + int.parse(start[1]);
      final endMinutes = int.parse(end[0]) * 60 + int.parse(end[1]);
      return total + ((endMinutes - startMinutes) ~/ 60);
    });
  }
}
