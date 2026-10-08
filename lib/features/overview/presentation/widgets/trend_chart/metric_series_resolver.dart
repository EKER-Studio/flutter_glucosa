import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/domain/enums/glucose_unit.dart';
import '../../../../../core/domain/enums/hba1c_unit.dart';
import '../../../../../core/domain/enums/metric_type.dart';
import '../../../../../core/domain/enums/weight_unit.dart';
import '../../../../../core/domain/utils/chart_data_utils.dart';
import '../../../../../core/domain/utils/glucose_converter.dart';
import '../../../../../core/presentation/theme/app_chart_theme.dart';
import '../../../../../core/presentation/widgets/glucosa_line_chart.dart';
import '../../../../blood_pressure/presentation/providers/blood_pressure_reading_list_notifier.dart';
import '../../../../cholesterol/presentation/providers/cholesterol_reading_list_notifier.dart';
import '../../../../glucose/presentation/providers/glucose_reading_list_notifier.dart';
import '../../../../hba1c/presentation/providers/hba1c_reading_list_notifier.dart';
import '../../../../ketones/presentation/providers/ketone_reading_list_notifier.dart';
import '../../../../settings/domain/entities/user_profile.dart';
import '../../../../weight/presentation/providers/weight_reading_list_notifier.dart';

/// Data model encapsulating parsed line chart series, display units, and target boundaries.
class MetricSeriesData {
  /// Primary value series data points.
  final List<ChartDataPoint> primary;

  /// Optional secondary series (e.g. diastolic pressure for blood pressure).
  final List<ChartDataPoint>? secondary;

  /// Display unit label shown beside metrics and stats.
  final String unitLabel;

  /// Builds target range markers; returns empty for metrics without clinical limits.
  final List<ChartLimitLine> Function(bool isDark) limitLines;

  /// Creates a series data configuration instance.
  MetricSeriesData({
    required this.primary,
    this.secondary,
    required this.unitLabel,
    List<ChartLimitLine> Function(bool isDark)? limitLines,
  }) : limitLines = limitLines ?? ((_) => const []);
}

/// Resolves raw data points, conversions, and target limit lines for the selected metric.
class MetricSeriesResolver {
  const MetricSeriesResolver._();

  /// Resolves display points, units, and limit lines for [metric] given [profile].
  static MetricSeriesData resolve({
    required WidgetRef ref,
    required MetricType metric,
    required UserProfile? profile,
  }) {
    final glucoseUnit = profile?.preferredGlucoseUnit ?? GlucoseUnit.mgDl;
    final hba1cUnit = profile?.preferredHbA1cUnit ?? HbA1cUnit.percentage;
    final weightUnit = profile?.preferredWeightUnit ?? WeightUnit.kilograms;
    final targetMin = profile?.targetRange.minMgDl ?? 70;
    final targetMax = profile?.targetRange.maxMgDl ?? 180;

    double glucoseValue(int mgDl) => glucoseUnit == GlucoseUnit.mmolL
        ? GlucoseConverter.mgDlToMmolL(mgDl)
        : mgDl.toDouble();
    double glucoseTarget(int mgDl) => glucoseValue(mgDl);

    switch (metric) {
      case MetricType.glucose:
        final readings = ref.watch(glucoseReadingListProvider).value ?? [];
        return MetricSeriesData(
          primary: [
            for (final r in readings)
              ChartDataPoint(
                time: r.createdAt,
                value: glucoseValue(r.readingMgDl),
              ),
          ],
          unitLabel: glucoseUnit.displayName,
          limitLines: (isDark) => [
            ChartLimitLine(
              y: glucoseTarget(targetMin),
              color: AppChartTheme.limitLineColor(isDark),
            ),
            ChartLimitLine(
              y: glucoseTarget(targetMax),
              color: AppChartTheme.limitLineColor(isDark),
            ),
          ],
        );
      case MetricType.hba1c:
        final readings = ref.watch(hbA1cReadingListProvider).value ?? [];
        return MetricSeriesData(
          primary: [
            for (final r in readings)
              ChartDataPoint(
                time: r.createdAt,
                value: hba1cUnit == HbA1cUnit.mmolMol
                    ? GlucoseConverter.percentageToMmolMol(r.readingPercentage)
                    : r.readingPercentage,
              ),
          ],
          unitLabel: hba1cUnit.displayName,
        );
      case MetricType.bloodPressure:
        final readings =
            ref.watch(bloodPressureReadingListProvider).value ?? [];
        return MetricSeriesData(
          primary: [
            for (final r in readings)
              ChartDataPoint(
                time: r.createdAt,
                value: r.systolicMmHg.toDouble(),
              ),
          ],
          secondary: [
            for (final r in readings)
              ChartDataPoint(
                time: r.createdAt,
                value: r.diastolicMmHg.toDouble(),
              ),
          ],
          unitLabel: 'mmHg',
        );
      case MetricType.ketones:
        final readings = ref.watch(ketoneReadingListProvider).value ?? [];
        return MetricSeriesData(
          primary: [
            for (final r in readings)
              ChartDataPoint(time: r.createdAt, value: r.readingMmolL),
          ],
          unitLabel: 'mmol/L',
        );
      case MetricType.cholesterol:
        final readings = ref.watch(cholesterolReadingListProvider).value ?? [];
        return MetricSeriesData(
          primary: [
            for (final r in readings)
              ChartDataPoint(time: r.createdAt, value: r.totalMgDl.toDouble()),
          ],
          unitLabel: GlucoseUnit.mgDl.displayName,
        );
      case MetricType.weight:
        final readings = ref.watch(weightReadingListProvider).value ?? [];
        return MetricSeriesData(
          primary: [
            for (final r in readings)
              ChartDataPoint(
                time: r.createdAt,
                value: weightUnit == WeightUnit.pounds
                    ? GlucoseConverter.kgToLbs(r.readingKg)
                    : r.readingKg,
              ),
          ],
          unitLabel: weightUnit.displayName,
        );
    }
  }
}
