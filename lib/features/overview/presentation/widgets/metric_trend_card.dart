import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/domain/enums/chart_time_range.dart';
import '../../../../core/domain/enums/glucose_unit.dart';
import '../../../../core/domain/enums/metric_type.dart';
import '../../../../core/domain/utils/chart_data_utils.dart';
import '../../../../core/presentation/widgets/app_loading_indicator.dart';
import '../../../../core/presentation/widgets/glucosa_line_chart.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../blood_pressure/presentation/providers/blood_pressure_reading_list_notifier.dart';
import '../../../cholesterol/presentation/providers/cholesterol_reading_list_notifier.dart';
import '../../../glucose/presentation/providers/glucose_reading_list_notifier.dart';
import '../../../hba1c/presentation/providers/hba1c_reading_list_notifier.dart';
import '../../../ketones/presentation/providers/ketone_reading_list_notifier.dart';
import '../../../settings/presentation/providers/user_profile_notifier.dart';
import '../../../weight/presentation/providers/weight_reading_list_notifier.dart';
import 'trend_chart/chart_stats_row.dart';
import 'trend_chart/metric_selector_chips.dart';
import 'trend_chart/metric_series_resolver.dart';
import 'trend_chart/time_range_chips.dart';

/// Overview card rendering an interactive trend chart for the selected metric and time range.
class MetricTrendCard extends ConsumerStatefulWidget {
  /// Creates a [MetricTrendCard].
  const MetricTrendCard({super.key});

  @override
  ConsumerState<MetricTrendCard> createState() => _MetricTrendCardState();
}

class _MetricTrendCardState extends ConsumerState<MetricTrendCard> {
  MetricType _metric = MetricType.glucose;
  ChartTimeRange _range = ChartTimeRange.day;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    final glucoseAsync = ref.watch(glucoseReadingListProvider);
    final hba1cAsync = ref.watch(hbA1cReadingListProvider);
    final bloodPressureAsync = ref.watch(bloodPressureReadingListProvider);
    final ketonesAsync = ref.watch(ketoneReadingListProvider);
    final cholesterolAsync = ref.watch(cholesterolReadingListProvider);
    final weightAsync = ref.watch(weightReadingListProvider);

    final states = [
      glucoseAsync,
      hba1cAsync,
      bloodPressureAsync,
      ketonesAsync,
      cholesterolAsync,
      weightAsync,
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MetricSelectorChips(
              selected: _metric,
              onSelected: (metric) => setState(() => _metric = metric),
            ),
            const SizedBox(height: 8),
            TimeRangeChips(
              selected: _range,
              onSelected: (range) => setState(() => _range = range),
            ),
            const SizedBox(height: 12),
            Builder(
              builder: (context) {
                if (states.any((s) => s.hasError)) {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      l10n.genericError,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  );
                }
                if (states.any((s) => s.isLoading) && !_hasAnyData(states)) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: AppLoadingIndicator()),
                  );
                }
                return _buildChartBody(context, theme, l10n, isDark);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Whether at least one watched stream already emitted data.
  bool _hasAnyData(List<AsyncValue<dynamic>> states) =>
      states.any((s) => s.value != null);

  Widget _buildChartBody(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
    bool isDark,
  ) {
    final profile = ref.watch(userProfileProvider).value;
    final data = MetricSeriesResolver.resolve(
      ref: ref,
      metric: _metric,
      profile: profile,
    );

    final grouped = ChartDataUtils.groupPoints(data.primary, _range);
    if (grouped.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          l10n.noReadingsYet,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    final xLabels = <String>[];
    final seenLabels = <String>{};
    final locale = Localizations.localeOf(context).toString();
    for (final point in grouped) {
      final label = _xLabel(point, locale);
      xLabels.add(seenLabels.add(label) ? label : '');
    }
    final spots = [
      for (var i = 0; i < grouped.length; i++)
        FlSpot(i.toDouble(), grouped[i].value),
    ];

    final series = [
      ChartLineSeries(spots: spots, color: theme.colorScheme.primary),
      if (data.secondary != null)
        ChartLineSeries(
          spots: [
            for (var i = 0; i < data.secondary!.length; i++)
              FlSpot(i.toDouble(), data.secondary![i].value),
          ],
          color: theme.colorScheme.secondary,
        ),
    ];

    final metricLabel = switch (_metric) {
      MetricType.glucose => l10n.glucose,
      MetricType.hba1c => l10n.hba1c,
      MetricType.bloodPressure => l10n.bloodPressure,
      MetricType.ketones => l10n.ketones,
      MetricType.cholesterol => l10n.cholesterol,
      MetricType.weight => l10n.weight,
    };

    final stats = ChartDataUtils.summarize(grouped);
    String formatStat(double value) =>
        _metric == MetricType.glucose &&
            data.unitLabel == GlucoseUnit.mgDl.displayName
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(1);
    final semanticLabel = stats != null
        ? l10n.metricTrendSemantics(
            metricLabel,
            formatStat(stats.average),
            formatStat(stats.min),
            formatStat(stats.max),
            grouped.length,
            data.unitLabel,
          )
        : l10n.trendChartSemantics(grouped.length);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GlucosaLineChart(
          series: series,
          xLabels: xLabels,
          limitLines: data.limitLines(isDark),
          semanticLabel: semanticLabel,
        ),
        const SizedBox(height: 8),
        ChartStatsRow(
          metric: _metric,
          primary: grouped,
          secondary: data.secondary == null
              ? null
              : ChartDataUtils.groupPoints(data.secondary!, _range),
          unitLabel: data.unitLabel,
        ),
      ],
    );
  }

  /// Formats x-axis labels according to the selected time range.
  String _xLabel(ChartDataPoint point, String locale) {
    switch (_range) {
      case ChartTimeRange.day:
        return DateFormat.Hm(locale).format(point.time);
      case ChartTimeRange.week:
      case ChartTimeRange.month:
        return DateFormat.Md(locale).format(point.time);
    }
  }
}
