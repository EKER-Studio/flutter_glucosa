import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/models/date_range_filter.dart';

/// Preset date range options available for data export.
enum ExportDatePreset {
  /// Export all recorded data across all time.
  allTime,

  /// Export data from the last 7 days.
  last7Days,

  /// Export data from the last 30 days.
  last30Days,

  /// Export data from the last 90 days.
  last90Days,

  /// Export data within a custom date range.
  custom,
}

/// Selector chips allowing users to choose an export time range preset or custom date range.
class ExportDatePresetChips extends StatelessWidget {
  /// The active date preset.
  final ExportDatePreset activePreset;

  /// The active custom date range filter, if any.
  final DateRangeFilter? dateRange;

  /// Callback when a preset is chosen.
  final void Function(ExportDatePreset preset, int? days) onPresetSelected;

  /// Callback when a custom date range is selected via date picker.
  final void Function(DateTimeRange range) onCustomRangeSelected;

  /// Creates an [ExportDatePresetChips].
  const ExportDatePresetChips({
    super.key,
    required this.activePreset,
    required this.dateRange,
    required this.onPresetSelected,
    required this.onCustomRangeSelected,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.exportDateRange,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            ChoiceChip(
              label: Text(l10n.exportAllTime),
              selected: activePreset == ExportDatePreset.allTime,
              onSelected: (selected) {
                if (selected) {
                  onPresetSelected(ExportDatePreset.allTime, null);
                }
              },
            ),
            ChoiceChip(
              label: Text(l10n.exportLast7Days),
              selected: activePreset == ExportDatePreset.last7Days,
              onSelected: (selected) {
                if (selected) {
                  onPresetSelected(ExportDatePreset.last7Days, 7);
                }
              },
            ),
            ChoiceChip(
              label: Text(l10n.exportLast30Days),
              selected: activePreset == ExportDatePreset.last30Days,
              onSelected: (selected) {
                if (selected) {
                  onPresetSelected(ExportDatePreset.last30Days, 30);
                }
              },
            ),
            ChoiceChip(
              label: Text(l10n.exportLast90Days),
              selected: activePreset == ExportDatePreset.last90Days,
              onSelected: (selected) {
                if (selected) {
                  onPresetSelected(ExportDatePreset.last90Days, 90);
                }
              },
            ),
            ChoiceChip(
              label: Text(
                activePreset == ExportDatePreset.custom && dateRange != null
                    ? _formatCustomRange(context, dateRange!)
                    : l10n.exportCustomRange,
              ),
              selected: activePreset == ExportDatePreset.custom,
              onSelected: (_) => _pickCustomRange(context),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _pickCustomRange(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: now,
      initialDateRange: dateRange != null
          ? DateTimeRange(start: dateRange!.start, end: dateRange!.end)
          : DateTimeRange(
              start: now.subtract(const Duration(days: 30)),
              end: now,
            ),
    );

    if (picked != null) {
      onCustomRangeSelected(picked);
    }
  }

  String _formatCustomRange(BuildContext context, DateRangeFilter range) {
    final format = DateFormat.yMMMd(Localizations.localeOf(context).toString());
    return '${format.format(range.start)} - ${format.format(range.end)}';
  }
}
