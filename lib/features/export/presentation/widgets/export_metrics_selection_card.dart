import 'package:flutter/material.dart';

import '../../../../core/domain/enums/metric_type.dart';
import '../../../../l10n/app_localizations.dart';

/// Card enabling the selection of health metric types to be included in data exports.
class ExportMetricsSelectionCard extends StatelessWidget {
  /// The set of currently selected metric types.
  final Set<MetricType> selectedMetrics;

  /// Callback to toggle select-all / deselect-all state.
  final VoidCallback onToggleSelectAll;

  /// Callback to toggle a specific metric type.
  final void Function(MetricType metric) onToggleMetric;

  /// Creates an [ExportMetricsSelectionCard].
  const ExportMetricsSelectionCard({
    super.key,
    required this.selectedMetrics,
    required this.onToggleSelectAll,
    required this.onToggleMetric,
  });

  static (IconData, String) _metricInfo(
    MetricType type,
    AppLocalizations l10n,
  ) {
    return switch (type) {
      MetricType.glucose => (Icons.water_drop_outlined, l10n.glucose),
      MetricType.hba1c => (Icons.biotech_outlined, l10n.hba1c),
      MetricType.bloodPressure => (Icons.favorite_outline, l10n.bloodPressure),
      MetricType.ketones => (Icons.science_outlined, l10n.ketones),
      MetricType.cholesterol => (Icons.bubble_chart_outlined, l10n.cholesterol),
      MetricType.weight => (Icons.monitor_weight_outlined, l10n.weight),
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final allSelected = selectedMetrics.length == MetricType.values.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.exportMetrics,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: onToggleSelectAll,
              child: Text(
                allSelected ? l10n.exportDeselectAll : l10n.exportSelectAll,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Card(
          elevation: 0,
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.4,
          ),
          child: Column(
            children: MetricType.values.map((metric) {
              final isChecked = selectedMetrics.contains(metric);
              final (icon, label) = _metricInfo(metric, l10n);
              return CheckboxListTile(
                secondary: Icon(icon, color: theme.colorScheme.primary),
                title: Text(label),
                value: isChecked,
                onChanged: (_) => onToggleMetric(metric),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
