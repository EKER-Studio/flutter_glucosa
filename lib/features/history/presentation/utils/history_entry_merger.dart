import '../../../../core/domain/enums/metric_type.dart';
import '../../../blood_pressure/domain/entities/blood_pressure_reading.dart';
import '../../../cholesterol/domain/entities/cholesterol_reading.dart';
import '../../../glucose/domain/entities/glucose_reading.dart';
import '../../../hba1c/domain/entities/hba1c_reading.dart';
import '../../../ketones/domain/entities/ketone_reading.dart';
import '../../../weight/domain/entities/weight_reading.dart';
import '../models/history_entry.dart';

/// Pure transformation utility that aggregates multi-metric reading streams into unified chronological history entries.
abstract final class HistoryEntryMerger {
  /// Rolling display window applied to history feed items.
  static const Duration defaultHistoryWindow = Duration(days: 365);

  /// Upper bound on visible entries to prevent excessive memory retention.
  static const int defaultMaxVisibleEntries = 1000;

  /// Merges all metric readings into a single chronological list (newest first).
  static List<HistoryEntry> merge({
    List<GlucoseReading> glucose = const [],
    List<HbA1cReading> hba1c = const [],
    List<BloodPressureReading> bloodPressure = const [],
    List<KetoneReading> ketones = const [],
    List<CholesterolReading> cholesterol = const [],
    List<WeightReading> weight = const [],
  }) {
    final entries = <HistoryEntry>[
      for (final r in glucose)
        HistoryEntry(
          type: MetricType.glucose,
          createdAt: r.createdAt,
          reading: r,
        ),
      for (final r in hba1c)
        HistoryEntry(
          type: MetricType.hba1c,
          createdAt: r.createdAt,
          reading: r,
        ),
      for (final r in bloodPressure)
        HistoryEntry(
          type: MetricType.bloodPressure,
          createdAt: r.createdAt,
          reading: r,
        ),
      for (final r in ketones)
        HistoryEntry(
          type: MetricType.ketones,
          createdAt: r.createdAt,
          reading: r,
        ),
      for (final r in cholesterol)
        HistoryEntry(
          type: MetricType.cholesterol,
          createdAt: r.createdAt,
          reading: r,
        ),
      for (final r in weight)
        HistoryEntry(
          type: MetricType.weight,
          createdAt: r.createdAt,
          reading: r,
        ),
    ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return entries;
  }

  /// Filters [entries] by [filter] and clamps to rolling [window] and [maxVisible].
  static List<HistoryEntry> filterAndWindow({
    required List<HistoryEntry> entries,
    MetricType? filter,
    Duration window = defaultHistoryWindow,
    int maxVisible = defaultMaxVisibleEntries,
    DateTime? now,
  }) {
    final referenceNow = now ?? DateTime.now();
    final cutoff = referenceNow.subtract(window);
    final windowed = entries
        .where((e) => e.createdAt.isAfter(cutoff))
        .take(maxVisible)
        .toList();

    if (filter == null) return windowed;
    return windowed.where((e) => e.type == filter).toList();
  }
}
