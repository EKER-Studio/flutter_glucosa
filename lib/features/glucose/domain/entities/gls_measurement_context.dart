/// Domain entity representing contextual metadata associated with a glucose measurement.
///
/// Follows Bluetooth SIG Glucose Measurement Context characteristic (0x2A34).
class GlsMeasurementContext {
  /// Sequence number linking this context to its corresponding [GlsRecord].
  final int sequenceNumber;

  /// Human-readable carbohydrate category (e.g. Breakfast, Lunch, Dinner, Snack).
  final String? carbohydrateType;

  /// Amount of carbohydrates recorded in grams.
  final double? carbohydrateGrams;

  /// Meal timing relationship (e.g. Preprandial, Postprandial, Fasting, Bedtime).
  final String? mealType;

  /// Who performed the measurement (e.g. Self, Healthcare Professional, Lab).
  final String? tester;

  /// Health status during measurement (e.g. Under Stress, Minor Illness, Normal).
  final String? health;

  /// Duration of recorded physical exercise in seconds.
  final int? exerciseDurationSeconds;

  /// Exercise intensity percentage (0-100%).
  final int? exerciseIntensityPercent;

  /// Type of medication administered (e.g. Rapid-acting insulin, Long-acting insulin).
  final String? medicationType;

  /// Amount of medication administered in units or milligrams.
  final double? medicationAmount;

  /// Whether the medication unit is liters/milliliters (`true`) or kilograms/milligrams (`false`).
  final bool isMedicationInLiters;

  /// Glycated hemoglobin measurement percentage (HbA1c).
  final double? hbA1cPercentage;

  /// Creates an immutable [GlsMeasurementContext].
  const GlsMeasurementContext({
    required this.sequenceNumber,
    this.carbohydrateType,
    this.carbohydrateGrams,
    this.mealType,
    this.tester,
    this.health,
    this.exerciseDurationSeconds,
    this.exerciseIntensityPercent,
    this.medicationType,
    this.medicationAmount,
    this.isMedicationInLiters = false,
    this.hbA1cPercentage,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GlsMeasurementContext &&
          runtimeType == other.runtimeType &&
          sequenceNumber == other.sequenceNumber &&
          carbohydrateType == other.carbohydrateType &&
          carbohydrateGrams == other.carbohydrateGrams &&
          mealType == other.mealType &&
          tester == other.tester &&
          health == other.health &&
          exerciseDurationSeconds == other.exerciseDurationSeconds &&
          exerciseIntensityPercent == other.exerciseIntensityPercent &&
          medicationType == other.medicationType &&
          medicationAmount == other.medicationAmount &&
          isMedicationInLiters == other.isMedicationInLiters &&
          hbA1cPercentage == other.hbA1cPercentage;

  @override
  int get hashCode => Object.hash(
    sequenceNumber,
    carbohydrateType,
    carbohydrateGrams,
    mealType,
    tester,
    health,
    exerciseDurationSeconds,
    exerciseIntensityPercent,
    medicationType,
    medicationAmount,
    isMedicationInLiters,
    hbA1cPercentage,
  );
}
