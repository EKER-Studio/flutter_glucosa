import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/domain/enums/metric_type.dart';
import '../../../../core/router/app_routes.dart';
import '../../../blood_pressure/domain/entities/blood_pressure_reading.dart';
import '../../../blood_pressure/presentation/widgets/blood_pressure_reading_card.dart';
import '../../../cholesterol/domain/entities/cholesterol_reading.dart';
import '../../../cholesterol/presentation/widgets/cholesterol_reading_card.dart';
import '../../../glucose/domain/entities/glucose_reading.dart';
import '../../../glucose/presentation/widgets/glucose_reading_card.dart';
import '../../../hba1c/domain/entities/hba1c_reading.dart';
import '../../../hba1c/presentation/widgets/hba1c_reading_card.dart';
import '../../../ketones/domain/entities/ketone_reading.dart';
import '../../../ketones/presentation/widgets/ketone_reading_card.dart';
import '../../../weight/domain/entities/weight_reading.dart';
import '../../../weight/presentation/widgets/weight_reading_card.dart';
import '../models/history_entry.dart';

/// Helper responsible for instantiating the appropriate reading presentation card for a history entry.
class HistoryCardBuilder {
  const HistoryCardBuilder._();

  /// Builds the metric reading card matching [entry] with navigation to its edit screen.
  static Widget build(BuildContext context, HistoryEntry entry) {
    switch (entry.type) {
      case MetricType.glucose:
        final reading = entry.reading as GlucoseReading;
        return GlucoseReadingCard(
          reading: reading,
          onTap: () => context.pushNamed(
            AppRoute.editGlucose.name,
            pathParameters: {'id': '${reading.id}'},
          ),
        );
      case MetricType.hba1c:
        final reading = entry.reading as HbA1cReading;
        return HbA1cReadingCard(
          reading: reading,
          onTap: () => context.pushNamed(
            AppRoute.editHba1c.name,
            pathParameters: {'id': '${reading.id}'},
          ),
        );
      case MetricType.bloodPressure:
        final reading = entry.reading as BloodPressureReading;
        return BloodPressureReadingCard(
          reading: reading,
          onTap: () => context.pushNamed(
            AppRoute.editBloodPressure.name,
            pathParameters: {'id': '${reading.id}'},
          ),
        );
      case MetricType.ketones:
        final reading = entry.reading as KetoneReading;
        return KetoneReadingCard(
          reading: reading,
          onTap: () => context.pushNamed(
            AppRoute.editKetones.name,
            pathParameters: {'id': '${reading.id}'},
          ),
        );
      case MetricType.cholesterol:
        final reading = entry.reading as CholesterolReading;
        return CholesterolReadingCard(
          reading: reading,
          onTap: () => context.pushNamed(
            AppRoute.editCholesterol.name,
            pathParameters: {'id': '${reading.id}'},
          ),
        );
      case MetricType.weight:
        final reading = entry.reading as WeightReading;
        return WeightReadingCard(
          reading: reading,
          onTap: () => context.pushNamed(
            AppRoute.editWeight.name,
            pathParameters: {'id': '${reading.id}'},
          ),
        );
    }
  }
}
