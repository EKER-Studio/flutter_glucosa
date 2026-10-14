import 'package:flutter_glucosa/core/domain/enums/meal_context.dart';
import 'package:flutter_glucosa/core/domain/enums/metric_type.dart';
import 'package:flutter_glucosa/features/blood_pressure/domain/entities/blood_pressure_reading.dart';
import 'package:flutter_glucosa/features/cholesterol/domain/entities/cholesterol_reading.dart';
import 'package:flutter_glucosa/features/glucose/domain/entities/glucose_reading.dart';
import 'package:flutter_glucosa/features/hba1c/domain/entities/hba1c_reading.dart';
import 'package:flutter_glucosa/features/history/presentation/models/history_entry.dart';
import 'package:flutter_glucosa/features/history/presentation/utils/history_entry_merger.dart';
import 'package:flutter_glucosa/features/ketones/domain/entities/ketone_reading.dart';
import 'package:flutter_glucosa/features/weight/domain/entities/weight_reading.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HistoryEntryMerger', () {
    final now = DateTime(2026, 10, 15, 12, 0);

    final glucose1 = GlucoseReading(
      id: 1,
      readingMgDl: 120,
      mealContext: MealContext.fasting,
      createdAt: now.subtract(const Duration(hours: 1)),
    );
    final glucose2 = GlucoseReading(
      id: 2,
      readingMgDl: 95,
      mealContext: MealContext.afterLunch,
      createdAt: now.subtract(const Duration(hours: 5)),
    );
    final hba1c = HbA1cReading(
      id: 3,
      readingPercentage: 6.2,
      createdAt: now.subtract(const Duration(hours: 2)),
    );
    final bp = BloodPressureReading(
      id: 4,
      systolicMmHg: 120,
      diastolicMmHg: 80,
      createdAt: now.subtract(const Duration(hours: 3)),
    );
    final ketone = KetoneReading(
      id: 5,
      readingMmolL: 0.4,
      createdAt: now.subtract(const Duration(hours: 4)),
    );
    final cholesterol = CholesterolReading(
      id: 6,
      totalMgDl: 180,
      ldlMgDl: 100,
      hdlMgDl: 50,
      createdAt: now.subtract(const Duration(hours: 6)),
    );
    final weight = WeightReading(
      id: 7,
      readingKg: 75.0,
      createdAt: now.subtract(const Duration(hours: 7)),
    );

    group('merge', () {
      test('returns empty list when all inputs are empty', () {
        final result = HistoryEntryMerger.merge();
        expect(result, isEmpty);
      });

      test('merges all 6 metric lists and maps correct MetricType', () {
        final result = HistoryEntryMerger.merge(
          glucose: [glucose1],
          hba1c: [hba1c],
          bloodPressure: [bp],
          ketones: [ketone],
          cholesterol: [cholesterol],
          weight: [weight],
        );

        expect(result, hasLength(6));
        expect(
          result.map((e) => e.type),
          containsAll([
            MetricType.glucose,
            MetricType.hba1c,
            MetricType.bloodPressure,
            MetricType.ketones,
            MetricType.cholesterol,
            MetricType.weight,
          ]),
        );
      });

      test(
        'sorts entries in descending chronological order (newest first)',
        () {
          // Provided in arbitrary order
          final result = HistoryEntryMerger.merge(
            glucose: [glucose2, glucose1],
            hba1c: [hba1c],
            bloodPressure: [bp],
            ketones: [ketone],
            cholesterol: [cholesterol],
            weight: [weight],
          );

          expect(result, hasLength(7));
          // Verify timestamps are strictly descending or equal
          for (var i = 0; i < result.length - 1; i++) {
            expect(
              result[i].createdAt.isAfter(result[i + 1].createdAt) ||
                  result[i].createdAt.isAtSameMomentAs(result[i + 1].createdAt),
              isTrue,
            );
          }
          expect(result.first.reading, equals(glucose1));
          expect(result.last.reading, equals(weight));
        },
      );
    });

    group('filterAndWindow', () {
      final entries = [
        HistoryEntry(
          type: MetricType.glucose,
          createdAt: now.subtract(const Duration(days: 10)),
          reading: glucose1,
        ),
        HistoryEntry(
          type: MetricType.hba1c,
          createdAt: now.subtract(const Duration(days: 50)),
          reading: hba1c,
        ),
        HistoryEntry(
          type: MetricType.glucose,
          createdAt: now.subtract(const Duration(days: 200)),
          reading: glucose2,
        ),
        HistoryEntry(
          type: MetricType.bloodPressure,
          createdAt: now.subtract(
            const Duration(days: 400),
          ), // older than 365 days
          reading: bp,
        ),
      ];

      test('returns empty when input list is empty', () {
        final result = HistoryEntryMerger.filterAndWindow(
          entries: [],
          now: now,
        );
        expect(result, isEmpty);
      });

      test(
        'filters out entries older than the rolling window (365 days default)',
        () {
          final result = HistoryEntryMerger.filterAndWindow(
            entries: entries,
            now: now,
          );

          expect(result, hasLength(3));
          expect(result.any((e) => e.reading == bp), isFalse);
        },
      );

      test('applies custom window duration correctly', () {
        final result = HistoryEntryMerger.filterAndWindow(
          entries: entries,
          window: const Duration(days: 30),
          now: now,
        );

        expect(result, hasLength(1));
        expect(result.first.reading, equals(glucose1));
      });

      test('clamps result count to maxVisible', () {
        final result = HistoryEntryMerger.filterAndWindow(
          entries: entries,
          maxVisible: 2,
          now: now,
        );

        expect(result, hasLength(2));
        expect(result[0].reading, equals(glucose1));
        expect(result[1].reading, equals(hba1c));
      });

      test('filters by metric type when filter is specified', () {
        final result = HistoryEntryMerger.filterAndWindow(
          entries: entries,
          filter: MetricType.glucose,
          now: now,
        );

        expect(result, hasLength(2));
        expect(result.every((e) => e.type == MetricType.glucose), isTrue);
      });

      test('returns all metric types when filter is null', () {
        final result = HistoryEntryMerger.filterAndWindow(
          entries: entries,
          filter: null,
          now: now,
        );

        expect(result, hasLength(3));
      });
    });
  });
}
