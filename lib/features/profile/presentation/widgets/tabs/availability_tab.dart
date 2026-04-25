import 'package:discovaa/features/profile/domain/entities/availability.dart';
import 'package:discovaa/features/profile/domain/entities/profile_enums.dart';
import 'package:discovaa/features/profile/presentation/providers/user_profile_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Availability Tab - Working hours configuration
class AvailabilityTab extends ConsumerStatefulWidget {
  const AvailabilityTab({super.key});

  @override
  ConsumerState<AvailabilityTab> createState() => _AvailabilityTabState();
}

class _AvailabilityTabState extends ConsumerState<AvailabilityTab> {
  late List<DayAvailability> _days;
  bool _hasChanges = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _initializeDays();
  }

  void _initializeDays() {
    final profile = ref.read(userProfileProvider).profile;
    _days =
        profile?.availability?.days.toList() ??
        DayOfWeek.values.map((d) => DayAvailability(day: d)).toList();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(userProfileProvider, (previous, next) {
      if (!_hasChanges) {
        final newDays = next.profile?.availability?.days.toList();
        if (newDays != null) {
          setState(() {
            _days = newDays;
          });
        }
      }
    });

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section (Figma-style white card with left-aligned Save button)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Availability Rules',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Set your working hours for each day of the week',
                  style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: ElevatedButton.icon(
                    onPressed: (_hasChanges && !_isSaving)
                        ? _saveChanges
                        : null,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save, size: 18),
                    label: _isSaving
                        ? const Text('Saving...')
                        : const Text('Save Changes'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      disabledBackgroundColor: const Color(0xFFE5E7EB),
                      disabledForegroundColor: const Color(0xFF9CA3AF),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Days List
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              children: _days.map((day) => _buildDayRow(day)).toList(),
            ),
          ),

          // Weekly Summary
          const SizedBox(height: 24),
          _buildWeeklySummary(),
        ],
      ),
    );
  }

  Widget _buildDayRow(DayAvailability day) {
    final isEnabled = day.isAvailable;

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: day.day != DayOfWeek.sunday
              ? const BorderSide(color: Color(0xFFE5E7EB))
              : BorderSide.none,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          Row(
            children: [
              // Checkbox
              Checkbox(
                value: isEnabled,
                onChanged: (value) => _toggleDay(day.day, value ?? false),
                activeColor: const Color(0xFF111827),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 8),
              // Day Label
              Expanded(
                child: Text(
                  day.day.displayName,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: isEnabled
                        ? const Color(0xFF111827)
                        : const Color(0xFF9CA3AF),
                  ),
                ),
              ),
            ],
          ),
          if (isEnabled) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 48),
              child: Row(
                children: [
                  // Start Time Picker
                  Expanded(
                    child: _buildTimePickerButton(
                      value: day.startTime ?? '09:00',
                      onChanged: (time) => _updateStartTime(day.day, time),
                      label: 'Start',
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'to',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ),
                  // End Time Picker
                  Expanded(
                    child: _buildTimePickerButton(
                      value: day.endTime ?? '17:00',
                      onChanged: (time) => _updateEndTime(day.day, time),
                      label: 'End',
                    ),
                  ),
                ],
              ),
            ),
            if (!day.isValid) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 48),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 16,
                      color: Colors.red.shade400,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'End time must be after start time',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red.shade400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildTimePickerButton({
    required String value,
    required ValueChanged<String> onChanged,
    required String label,
  }) {
    return InkWell(
      onTap: () async {
        final parts = value.split(':');
        final initialTime = TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );

        final pickedTime = await showTimePicker(
          context: context,
          initialTime: initialTime,
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(alwaysUse24HourFormat: false),
              child: child!,
            );
          },
        );

        if (pickedTime != null) {
          final hour = pickedTime.hour.toString().padLeft(2, '0');
          final minute = pickedTime.minute.toString().padLeft(2, '0');
          onChanged('$hour:$minute');
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF6B7280),
                  ),
                ),
                Text(
                  _formatTime(value),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF111827),
                  ),
                ),
              ],
            ),
            const Icon(Icons.access_time, size: 18, color: Color(0xFF6B7280)),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklySummary() {
    final availableDays = _days.where((d) => d.isAvailable && d.isValid).length;
    final totalHours = _calculateTotalHours();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF10B981).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.access_time,
              color: Color(0xFF10B981),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$availableDays days available',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Approximately $totalHours hours per week',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(String time) {
    final parts = time.split(':');
    final hour = int.parse(parts[0]);
    final minute = parts[1];
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$displayHour:$minute $period';
  }

  int _calculateTotalHours() {
    return _days.fold(0, (total, day) {
      if (!day.isAvailable || !day.isValid) return total;
      final startParts = day.startTime!.split(':');
      final endParts = day.endTime!.split(':');
      final startMinutes =
          int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
      final endMinutes = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);
      return total + ((endMinutes - startMinutes) ~/ 60);
    });
  }

  void _toggleDay(DayOfWeek day, bool isAvailable) {
    setState(() {
      final index = _days.indexWhere((d) => d.day == day);
      if (index != -1) {
        _days[index] = _days[index].copyWith(
          isAvailable: isAvailable,
          startTime: isAvailable ? (_days[index].startTime ?? '09:00') : null,
          endTime: isAvailable ? (_days[index].endTime ?? '17:00') : null,
        );
        _hasChanges = true;
      }
    });
  }

  void _updateStartTime(DayOfWeek day, String time) {
    setState(() {
      final index = _days.indexWhere((d) => d.day == day);
      if (index != -1) {
        _days[index] = _days[index].copyWith(startTime: time);
        _hasChanges = true;
      }
    });
  }

  void _updateEndTime(DayOfWeek day, String time) {
    setState(() {
      final index = _days.indexWhere((d) => d.day == day);
      if (index != -1) {
        _days[index] = _days[index].copyWith(endTime: time);
        _hasChanges = true;
      }
    });
  }

  Future<void> _saveChanges() async {
    setState(() => _isSaving = true);

    final availability = Availability(days: _days);
    final success = await ref
        .read(userProfileProvider.notifier)
        .updateAvailability(availability);

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        setState(() => _hasChanges = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Availability updated successfully'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update availability'),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
      }
    }
  }
}
