import 'package:flutter/material.dart';

import '../../../../../core/domain/enums/metric_type.dart';
import '../../../../../l10n/app_localizations.dart';

/// Horizontal scrolling row of choice chips for selecting health metric types.
class MetricSelectorChips extends StatelessWidget {
  /// Currently selected metric type.
  final MetricType selected;

  /// Callback invoked when a metric chip is tapped.
  final ValueChanged<MetricType> onSelected;

  /// Creates a metric selector chips row.
  const MetricSelectorChips({
    required this.selected,
    required this.onSelected,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final chips = <({String label, MetricType type})>[
      (label: l10n.glucose, type: MetricType.glucose),
      (label: l10n.hba1c, type: MetricType.hba1c),
      (label: l10n.bloodPressure, type: MetricType.bloodPressure),
      (label: l10n.ketones, type: MetricType.ketones),
      (label: l10n.cholesterol, type: MetricType.cholesterol),
      (label: l10n.weight, type: MetricType.weight),
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
