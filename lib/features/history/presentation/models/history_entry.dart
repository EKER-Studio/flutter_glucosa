import '../../../../core/domain/enums/metric_type.dart';

/// Single entry in the merged chronological health history list.
class HistoryEntry {
  /// Metric type of the health measurement.
  final MetricType type;

  /// Timestamp used for chronological sorting.
  final DateTime createdAt;

  /// The underlying domain reading entity.
  final Object reading;

  /// Creates a history entry wrapping [reading].
  const HistoryEntry({
    required this.type,
    required this.createdAt,
    required this.reading,
  });
}
