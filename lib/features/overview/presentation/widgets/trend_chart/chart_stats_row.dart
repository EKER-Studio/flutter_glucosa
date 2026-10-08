import 'package:flutter/material.dart';

import '../../../../../core/domain/enums/glucose_unit.dart';
import '../../../../../core/domain/enums/metric_type.dart';
import '../../../../../core/domain/utils/chart_data_utils.dart';
import '../../../../../l10n/app_localizations.dart';

/// Row of quick summary statistics (average, minimum, maximum) displayed below the trend chart.
class ChartStatsRow extends StatelessWidget {
  /// Metric type the statistics describe.
  final MetricType metric;

  /// Grouped primary data points.
  final List<ChartDataPoint> primary;

  /// Optional grouped secondary points (e.g. diastolic pressure for blood pressure).
  final List<ChartDataPoint>? secondary;

  /// Display unit label shown beside numerical values.
  final String unitLabel;

  /// Creates a chart stats row.
  const ChartStatsRow({
    required this.metric,
    required this.primary,
    required this.secondary,
    required this.unitLabel,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    if (metric == MetricType.bloodPressure && secondary != null) {
      final sysAvg = ChartDataUtils.summarize(primary)?.average ?? 0;
      final diaAvg = ChartDataUtils.summarize(secondary!)?.average ?? 0;
      return Text(
        '${l10n.systolicLabel} ${sysAvg.toStringAsFixed(0)} · '
        '${l10n.diastolicLabel} ${diaAvg.toStringAsFixed(0)} $unitLabel',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
        textAlign: TextAlign.center,
      );
    }

    final stats = ChartDataUtils.summarize(primary);
    if (stats == null) return const SizedBox.shrink();

    String format(double value) =>
        metric == MetricType.glucose &&
            unitLabel == GlucoseUnit.mgDl.displayName
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(1);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Expanded(
          child: _StatItem(
            label: l10n.statAverage,
            value: '${format(stats.average)} $unitLabel',
          ),
        ),
        Expanded(
          child: _StatItem(
            label: l10n.statMin,
            value: '${format(stats.min)} $unitLabel',
          ),
        ),
        Expanded(
          child: _StatItem(
            label: l10n.statMax,
            value: '${format(stats.max)} $unitLabel',
          ),
        ),
      ],
    );
  }
}

/// Single labeled statistic column rendering label above value.
class _StatItem extends StatelessWidget {
  /// Statistic label (e.g. Avg).
  final String label;

  /// Formatted statistic value with unit.
  final String value;

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
