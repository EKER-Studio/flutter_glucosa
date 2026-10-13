import 'package:flutter/material.dart';

/// Single comparison row inside [PeriodComparisonCard] displaying title, current period value, previous period value, and trend badge.
class PeriodComparisonRow extends StatelessWidget {
  /// The clinical metric title (e.g. Mean Glucose, Time in Range, Hypo Incidents).
  final String title;

  /// Formatted value for the current period.
  final String currentVal;

  /// Formatted value for the previous baseline period.
  final String previousVal;

  /// Formatted delta difference between periods, or `null` if unavailable.
  final String? delta;

  /// Whether the trend delta represents a positive clinical development.
  final bool isPositiveTrend;

  /// Semantic theme color for in-range / positive clinical metrics.
  final Color inRangeColor;

  /// Semantic theme color for metrics needing clinical attention.
  final Color needsAttentionColor;

  /// Creates a [PeriodComparisonRow].
  const PeriodComparisonRow({
    super.key,
    required this.title,
    required this.currentVal,
    required this.previousVal,
    required this.delta,
    required this.isPositiveTrend,
    required this.inRangeColor,
    required this.needsAttentionColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final trendColor = isPositiveTrend ? inRangeColor : needsAttentionColor;

    return Row(
      children: [
        Expanded(
          flex: 4,
          child: Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: cs.onSurface,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            currentVal,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: cs.onSurface,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            previousVal,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
        ),
        if (delta != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: trendColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              delta!,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: trendColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }
}
