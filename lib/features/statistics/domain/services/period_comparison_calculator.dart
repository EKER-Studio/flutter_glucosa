import 'dart:math' as math;

import '../../../../core/domain/value_objects/glucose_target_range.dart';
import '../../../glucose/domain/entities/glucose_reading.dart';
import '../entities/period_comparison.dart';

/// Pure domain service computing comparative metrics between rolling windows of glucose readings.
class PeriodComparisonCalculator {
  const PeriodComparisonCalculator._();

  /// Compares metrics between the current [days] rolling window and the immediately preceding [days] window.
  static GlucosePeriodComparisonResult compareRollingDays({
    required List<GlucoseReading> readings,
    int days = 7,
    GlucoseTargetRange targetRange = const GlucoseTargetRange.ada(),
    DateTime? now,
  }) {
    final referenceDate = now ?? DateTime.now();
    final endOfCurrent = DateTime(
      referenceDate.year,
      referenceDate.month,
      referenceDate.day,
      23,
      59,
      59,
      999,
    );
    final startOfCurrent = DateTime(
      referenceDate.year,
      referenceDate.month,
      referenceDate.day,
    ).subtract(Duration(days: days - 1));

    final endOfPrevious = startOfCurrent.subtract(
      const Duration(milliseconds: 1),
    );
    final startOfPrevious = DateTime(
      startOfCurrent.year,
      startOfCurrent.month,
      startOfCurrent.day,
    ).subtract(Duration(days: days));

    final currentEntries =
        readings
            .where(
              (r) =>
                  !r.createdAt.isBefore(startOfCurrent) &&
                  !r.createdAt.isAfter(endOfCurrent),
            )
            .toList()
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    final previousEntries =
        readings
            .where(
              (r) =>
                  !r.createdAt.isBefore(startOfPrevious) &&
                  !r.createdAt.isAfter(endOfPrevious),
            )
            .toList()
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    final currentSummary = _summarize(
      readings: currentEntries,
      targetRange: targetRange,
      start: startOfCurrent,
      end: endOfCurrent,
    );

    final previousSummary = _summarize(
      readings: previousEntries,
      targetRange: targetRange,
      start: startOfPrevious,
      end: endOfPrevious,
    );

    final hasComparisonData =
        currentEntries.isNotEmpty && previousEntries.isNotEmpty;

    final deltaMeanGlucose = switch ((
      currentSummary.meanGlucoseMgDl,
      previousSummary.meanGlucoseMgDl,
    )) {
      (final cur?, final prev?) => cur - prev,
      _ => null,
    };

    final deltaGlucoseSd = switch ((
      currentSummary.glucoseSd,
      previousSummary.glucoseSd,
    )) {
      (final cur?, final prev?) => cur - prev,
      _ => null,
    };

    final deltaTirPercentage = switch ((
      currentSummary.tirPercentage,
      previousSummary.tirPercentage,
    )) {
      (final cur?, final prev?) => cur - prev,
      _ => null,
    };

    final deltaReadingCount =
        currentSummary.readingCount - previousSummary.readingCount;
    final deltaHypoCount = currentSummary.hypoCount - previousSummary.hypoCount;

    return GlucosePeriodComparisonResult(
      currentPeriod: currentSummary,
      previousPeriod: previousSummary,
      deltaMeanGlucose: deltaMeanGlucose,
      deltaGlucoseSd: deltaGlucoseSd,
      deltaTirPercentage: deltaTirPercentage,
      deltaReadingCount: deltaReadingCount,
      deltaHypoCount: deltaHypoCount,
      hasComparisonData: hasComparisonData,
    );
  }

  static GlucosePeriodSummary _summarize({
    required List<GlucoseReading> readings,
    required GlucoseTargetRange targetRange,
    required DateTime start,
    required DateTime end,
  }) {
    if (readings.isEmpty) {
      return GlucosePeriodSummary(
        meanGlucoseMgDl: null,
        glucoseSd: null,
        tirPercentage: null,
        tarPercentage: null,
        tbrPercentage: null,
        readingCount: 0,
        hypoCount: 0,
        hyperCount: 0,
        start: start,
        end: end,
      );
    }

    final count = readings.length;
    final sum = readings.fold<int>(0, (prev, r) => prev + r.readingMgDl);
    final mean = sum / count;

    double? sd;
    if (count >= 2) {
      final variance =
          readings.fold<double>(
            0.0,
            (prev, r) => prev + math.pow(r.readingMgDl - mean, 2),
          ) /
          (count - 1);
      sd = math.sqrt(variance);
    }

    int inRangeCount = 0;
    int hypoCount = 0;
    int hyperCount = 0;

    for (final r in readings) {
      if (r.readingMgDl < targetRange.minMgDl) {
        hypoCount++;
      } else if (r.readingMgDl > targetRange.maxMgDl) {
        hyperCount++;
      } else {
        inRangeCount++;
      }
    }

    final tirPct = (inRangeCount / count) * 100.0;
    final tarPct = (hyperCount / count) * 100.0;
    final tbrPct = (hypoCount / count) * 100.0;

    return GlucosePeriodSummary(
      meanGlucoseMgDl: mean,
      glucoseSd: sd,
      tirPercentage: tirPct,
      tarPercentage: tarPct,
      tbrPercentage: tbrPct,
      readingCount: count,
      hypoCount: hypoCount,
      hyperCount: hyperCount,
      start: start,
      end: end,
    );
  }
}
