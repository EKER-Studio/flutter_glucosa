import '../../../../core/domain/enums/meal_context.dart';
import '../../domain/entities/gls_record.dart';
import '../../domain/entities/glucose_reading.dart';

/// Extension providing stateless mapping from [GlsRecord] to domain [GlucoseReading].
extension GlsRecordMapper on GlsRecord {
  /// Converts this raw BLE glucometer record into a domain [GlucoseReading] entity.
  ///
  /// [defaultMealContext] Fallback food intake context when the record context is absent.
  GlucoseReading toDomain({
    MealContext defaultMealContext = MealContext.other,
  }) {
    final mgDl = concentrationMgDl ?? 0;
    final resolvedMeal = _resolveMealContext(defaultMealContext);
    final notes = _buildNotes();

    return GlucoseReading(
      id: 0,
      readingMgDl: mgDl,
      mealContext: resolvedMeal,
      notes: notes,
      createdAt: timestamp,
    );
  }

  MealContext _resolveMealContext(MealContext fallback) {
    final ctx = context;
    if (ctx == null) return fallback;

    switch (ctx.mealType) {
      case 'Fasting':
        return MealContext.fasting;
      case 'Bedtime':
        return MealContext.bedtime;
      case 'Preprandial':
        if (timestamp.hour < 11) return MealContext.beforeBreakfast;
        if (timestamp.hour < 16) return MealContext.beforeLunch;
        return MealContext.beforeDinner;
      case 'Postprandial':
        if (timestamp.hour < 11) return MealContext.afterBreakfast;
        if (timestamp.hour < 16) return MealContext.afterLunch;
        return MealContext.afterDinner;
      case 'Casual':
        if (ctx.carbohydrateType == 'Snack') return MealContext.snack;
        return MealContext.other;
      default:
        if (ctx.carbohydrateType == 'Snack') return MealContext.snack;
        return fallback;
    }
  }

  String? _buildNotes() {
    final parts = <String>[];

    if (sampleLocation != null) {
      parts.add(sampleLocation!);
    }
    if (sampleType != null) {
      parts.add(sampleType!);
    }

    final ctx = context;
    if (ctx != null) {
      if (ctx.carbohydrateGrams != null) {
        final category = ctx.carbohydrateType != null
            ? ' (${ctx.carbohydrateType})'
            : '';
        parts.add(
          'Carbs: ${ctx.carbohydrateGrams!.toStringAsFixed(1)}g$category',
        );
      }
      if (ctx.medicationAmount != null) {
        final unit = ctx.isMedicationInLiters ? 'ml' : 'mg';
        final med = ctx.medicationType != null
            ? ' (${ctx.medicationType})'
            : '';
        parts.add(
          'Medication: ${ctx.medicationAmount!.toStringAsFixed(1)}$unit$med',
        );
      }
      if (ctx.health != null) {
        parts.add('Health: ${ctx.health}');
      }
      if (ctx.tester != null) {
        parts.add('Tester: ${ctx.tester}');
      }
      if (ctx.hbA1cPercentage != null) {
        parts.add('HbA1c: ${ctx.hbA1cPercentage!.toStringAsFixed(1)}%');
      }
    }

    return parts.isEmpty ? null : parts.join(', ');
  }
}
