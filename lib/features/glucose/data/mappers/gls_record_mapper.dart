import '../../../../core/domain/enums/meal_context.dart';
import '../../domain/entities/gls_record.dart';
import '../../domain/entities/glucose_reading.dart';

/// Extension providing stateless mapping from [GlsRecord] to domain [GlucoseReading].
extension GlsRecordMapper on GlsRecord {
  /// Converts this raw BLE glucometer record into a domain [GlucoseReading] entity.
  ///
  /// [defaultMealContext] Default food intake context if none was supplied.
  GlucoseReading toDomain({
    MealContext defaultMealContext = MealContext.other,
  }) {
    final mgDl = concentrationMgDl ?? 0;
    final notesBuffer = StringBuffer();

    if (sampleLocation != null) {
      notesBuffer.write(sampleLocation);
    }
    if (sampleType != null) {
      if (notesBuffer.isNotEmpty) notesBuffer.write(', ');
      notesBuffer.write(sampleType);
    }

    return GlucoseReading(
      id: 0,
      readingMgDl: mgDl,
      mealContext: defaultMealContext,
      notes: notesBuffer.isEmpty ? null : notesBuffer.toString(),
      createdAt: timestamp,
    );
  }
}
