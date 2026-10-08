import 'package:flutter/material.dart';

import '../../../../../core/domain/enums/hba1c_unit.dart';
import '../../../../../l10n/app_localizations.dart';

/// Card widget providing glycated hemoglobin (HbA1c) input with a unit toggle.
class EstimatedHbA1cInputCard extends StatelessWidget {
  /// Controller managing the HbA1c input field.
  final TextEditingController controller;

  /// Currently selected HbA1c measurement unit.
  final HbA1cUnit unit;

  /// Callback invoked when the user selects a different HbA1c unit.
  final ValueChanged<HbA1cUnit> onUnitChanged;

  /// Callback invoked when the numerical input text changes.
  final ValueChanged<String> onChanged;

  /// Creates an estimated HbA1c input card.
  const EstimatedHbA1cInputCard({
    required this.controller,
    required this.unit,
    required this.onUnitChanged,
    required this.onChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.estimatedHbA1c,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SegmentedButton<HbA1cUnit>(
                  segments: [
                    ButtonSegment(
                      value: HbA1cUnit.percentage,
                      label: Text(HbA1cUnit.percentage.displayName),
                    ),
                    ButtonSegment(
                      value: HbA1cUnit.mmolMol,
                      label: Text(HbA1cUnit.mmolMol.displayName),
                    ),
                  ],
                  selected: {unit},
                  onSelectionChanged: (selected) {
                    if (selected.isNotEmpty) {
                      onUnitChanged(selected.first);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            Semantics(
              label: l10n.estimatedHbA1c,
              child: TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  hintText: unit == HbA1cUnit.percentage
                      ? l10n.hba1cValueHintPercent
                      : l10n.hba1cValueHintMmolMol,
                  suffixText: unit.displayName,
                  border: const OutlineInputBorder(),
                ),
                onChanged: onChanged,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
