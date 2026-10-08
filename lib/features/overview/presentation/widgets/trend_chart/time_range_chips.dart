import 'package:flutter/material.dart';

import '../../../../../core/domain/enums/chart_time_range.dart';
import '../../../../../l10n/app_localizations.dart';

/// Horizontal scrolling row of choice chips for selecting chart time intervals.
class TimeRangeChips extends StatelessWidget {
  /// Currently selected time range.
  final ChartTimeRange selected;

  /// Callback invoked when a time range chip is tapped.
  final ValueChanged<ChartTimeRange> onSelected;

  /// Creates a time range selector chips row.
  const TimeRangeChips({
    required this.selected,
    required this.onSelected,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final chips = <({String label, ChartTimeRange type})>[
      (label: l10n.timeRangeDay, type: ChartTimeRange.day),
      (label: l10n.timeRangeWeek, type: ChartTimeRange.week),
      (label: l10n.timeRangeMonth, type: ChartTimeRange.month),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final chip in chips)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(chip.label),
                selected: selected == chip.type,
                onSelected: (_) => onSelected(chip.type),
              ),
            ),
        ],
      ),
    );
  }
}
