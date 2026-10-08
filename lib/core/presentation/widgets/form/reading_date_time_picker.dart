import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../utils/picker_helpers.dart';

/// Form component providing interactive date and time picker buttons for a reading timestamp.
class ReadingDateTimePicker extends StatelessWidget {
  /// The currently selected date and time.
  final DateTime selectedDateTime;

  /// Callback invoked when a new date or time has been selected.
  final ValueChanged<DateTime> onDateTimeChanged;

  /// Earliest permissible date selectable in the date picker.
  final DateTime? firstDate;

  /// Creates a reading date and time picker row.
  const ReadingDateTimePicker({
    required this.selectedDateTime,
    required this.onDateTimeChanged,
    this.firstDate,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final formattedDate = DateFormat.yMMMd(locale).format(selectedDateTime);
    final formattedTime = DateFormat.jm(locale).format(selectedDateTime);

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            icon: const Icon(Icons.calendar_today_outlined, size: 18),
            label: Text(formattedDate),
            onPressed: () => _pickDate(context),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            icon: const Icon(Icons.access_time_outlined, size: 18),
            label: Text(formattedTime),
            onPressed: () => _pickTime(context),
          ),
        ),
      ],
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    final pickedDate = await PickerHelpers.showSafeDatePicker(
      context: context,
      initialDate: selectedDateTime,
      firstDate: firstDate ?? DateTime(2000),
      lastDate: now.add(const Duration(days: 1)),
    );

    if (pickedDate != null && context.mounted) {
      onDateTimeChanged(
        DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          selectedDateTime.hour,
          selectedDateTime.minute,
        ),
      );
    }
  }

  Future<void> _pickTime(BuildContext context) async {
    final pickedTime = await PickerHelpers.showSafeTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(selectedDateTime),
    );

    if (pickedTime != null && context.mounted) {
      onDateTimeChanged(
        DateTime(
          selectedDateTime.year,
          selectedDateTime.month,
          selectedDateTime.day,
          pickedTime.hour,
          pickedTime.minute,
        ),
      );
    }
  }
}
