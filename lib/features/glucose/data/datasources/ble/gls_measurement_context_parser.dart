import 'dart:typed_data';

import '../../../domain/entities/gls_measurement_context.dart';
import 'ieee11073_float_parser.dart';

/// Parser for standard Bluetooth SIG Glucose Measurement Context characteristic (0x2A34).
///
/// Decodes contextual records containing meal status, carbohydrates, medications,
/// health indicators, and HbA1c associated with a primary glucose measurement.
abstract final class GlsMeasurementContextParser {
  /// Parses raw byte data from characteristic 0x2A34 into a [GlsMeasurementContext].
  ///
  /// Returns `null` if [bytes] is truncated, malformed, or shorter than the minimal 3 bytes.
  static GlsMeasurementContext? parse(List<int> bytes) {
    if (bytes.length < 3) return null;

    final data = ByteData.sublistView(Uint8List.fromList(bytes));
    int offset = 0;

    final flags = data.getUint8(offset++);
    final carbohydratePresent = (flags & 0x01) != 0;
    final mealPresent = (flags & 0x02) != 0;
    final testerHealthPresent = (flags & 0x04) != 0;
    final exercisePresent = (flags & 0x08) != 0;
    final medicationPresent = (flags & 0x10) != 0;
    final medicationUnitLiter = (flags & 0x20) != 0;
    final hbA1cPresent = (flags & 0x40) != 0;
    final extendedFlagsPresent = (flags & 0x80) != 0;

    // Validate minimal length for all flagged fields
    int expectedLength =
        3 +
        (extendedFlagsPresent ? 1 : 0) +
        (carbohydratePresent ? 3 : 0) +
        (mealPresent ? 1 : 0) +
        (testerHealthPresent ? 1 : 0) +
        (exercisePresent ? 3 : 0) +
        (medicationPresent ? 3 : 0) +
        (hbA1cPresent ? 2 : 0);

    if (bytes.length < expectedLength) {
      return null;
    }

    final sequenceNumber = data.getUint16(offset, Endian.little);
    offset += 2;

    if (extendedFlagsPresent) {
      offset += 1;
    }

    String? carbohydrateType;
    double? carbohydrateGrams;
    if (carbohydratePresent) {
      final carbId = data.getUint8(offset++);
      carbohydrateType = _resolveCarbohydrateType(carbId);
      final rawCarbAmount = data.getUint16(offset, Endian.little);
      carbohydrateGrams = Ieee11073FloatParser.parse16BitSFloat(rawCarbAmount);
      offset += 2;
    }

    String? mealType;
    if (mealPresent) {
      final mealId = data.getUint8(offset++);
      mealType = _resolveMealType(mealId);
    }

    String? tester;
    String? health;
    if (testerHealthPresent) {
      final byte = data.getUint8(offset++);
      final testerId = (byte >> 4) & 0x0F;
      final healthId = byte & 0x0F;
      tester = _resolveTester(testerId);
      health = _resolveHealth(healthId);
    }

    int? exerciseDurationSeconds;
    int? exerciseIntensityPercent;
    if (exercisePresent) {
      exerciseDurationSeconds = data.getUint16(offset, Endian.little);
      offset += 2;
      exerciseIntensityPercent = data.getUint8(offset++);
    }

    String? medicationType;
    double? medicationAmount;
    if (medicationPresent) {
      final medId = data.getUint8(offset++);
      medicationType = _resolveMedicationType(medId);
      final rawMedAmount = data.getUint16(offset, Endian.little);
      medicationAmount = Ieee11073FloatParser.parse16BitSFloat(rawMedAmount);
      offset += 2;
    }

    double? hbA1cPercentage;
    if (hbA1cPresent) {
      final rawHbA1c = data.getUint16(offset, Endian.little);
      hbA1cPercentage = Ieee11073FloatParser.parse16BitSFloat(rawHbA1c);
      offset += 2;
    }

    return GlsMeasurementContext(
      sequenceNumber: sequenceNumber,
      carbohydrateType: carbohydrateType,
      carbohydrateGrams: carbohydrateGrams,
      mealType: mealType,
      tester: tester,
      health: health,
      exerciseDurationSeconds: exerciseDurationSeconds,
      exerciseIntensityPercent: exerciseIntensityPercent,
      medicationType: medicationType,
      medicationAmount: medicationAmount,
      isMedicationInLiters: medicationUnitLiter,
      hbA1cPercentage: hbA1cPercentage,
    );
  }

  static String _resolveCarbohydrateType(int id) {
    switch (id) {
      case 1:
        return 'Breakfast';
      case 2:
        return 'Lunch';
      case 3:
        return 'Dinner';
      case 4:
        return 'Snack';
      case 5:
        return 'Drink';
      case 6:
        return 'Supper';
      case 7:
        return 'Brunch';
      default:
        return 'Carbohydrates';
    }
  }

  static String _resolveMealType(int id) {
    switch (id) {
      case 1:
        return 'Preprandial';
      case 2:
        return 'Postprandial';
      case 3:
        return 'Fasting';
      case 4:
        return 'Casual';
      case 5:
        return 'Bedtime';
      default:
        return 'Unknown';
    }
  }

  static String? _resolveTester(int id) {
    switch (id) {
      case 1:
        return 'Self';
      case 2:
        return 'Healthcare Professional';
      case 3:
        return 'Lab Test';
      case 15:
        return null;
      default:
        return 'Tester ($id)';
    }
  }

  static String? _resolveHealth(int id) {
    switch (id) {
      case 1:
        return 'Minor Health Issues';
      case 2:
        return 'Major Health Issues';
      case 3:
        return 'During Menses';
      case 4:
        return 'Under Stress';
      case 5:
        return 'No Health Issues';
      case 15:
        return null;
      default:
        return 'Health ($id)';
    }
  }

  static String _resolveMedicationType(int id) {
    switch (id) {
      case 1:
        return 'Rapid-acting insulin';
      case 2:
        return 'Short-acting insulin';
      case 3:
        return 'Intermediate-acting insulin';
      case 4:
        return 'Long-acting insulin';
      case 5:
        return 'Pre-mixed insulin';
      default:
        return 'Medication ($id)';
    }
  }
}
