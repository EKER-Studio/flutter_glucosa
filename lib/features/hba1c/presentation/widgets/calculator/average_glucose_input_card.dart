import 'package:flutter/material.dart';

import '../../../../../core/domain/enums/glucose_unit.dart';
import '../../../../../l10n/app_localizations.dart';

/// Card widget providing average glucose numerical input with a unit toggle.
class AverageGlucoseInputCard extends StatelessWidget {
  /// Controller managing the average glucose input field.
  final TextEditingController controller;

  /// Currently selected glucose measurement unit.
  final GlucoseUnit unit;

  /// Callback invoked when the user selects a different glucose unit.
  final ValueChanged<GlucoseUnit> onUnitChanged;

  /// Callback invoked when the numerical input text changes.
  final ValueChanged<String> onChanged;

  /// Creates an average glucose input card.
  const AverageGlucoseInputCard({
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
                  l10n.averageGlucose,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SegmentedButton<GlucoseUnit>(
                  segments: [
                    ButtonSegment(
                      value: GlucoseUnit.mgDl,
                      label: Text(GlucoseUnit.mgDl.displayName),
                    ),
                    ButtonSegment(
                      value: GlucoseUnit.mmolL,
                      label: Text(GlucoseUnit.mmolL.displayName),
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
              label: l10n.averageGlucose,
              child: TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  hintText: unit == GlucoseUnit.mgDl
                      ? l10n.hba1cAvgGlucoseHintMgDl
                      : l10n.hba1cAvgGlucoseHintMmolL,
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
