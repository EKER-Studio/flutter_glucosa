import '../../../../core/domain/enums/glucose_unit.dart';
import '../../../../core/domain/enums/hba1c_unit.dart';
import '../../../../core/domain/utils/glucose_converter.dart';

/// Pure calculation coordinator for bidirectional HbA1c <-> average glucose estimations.
abstract final class HbA1cCalculatorCoordinator {
  /// Computes the formatted estimated HbA1c string from [glucoseText] in [glucoseUnit] to [hba1cUnit].
  /// Returns empty string if input is blank or invalid.
  static String calculateHbA1cFromGlucose({
    required String glucoseText,
    required GlucoseUnit glucoseUnit,
    required HbA1cUnit hba1cUnit,
  }) {
    final trimmed = glucoseText.trim();
    if (trimmed.isEmpty) return '';

    final parsed = double.tryParse(trimmed.replaceAll(',', '.'));
    if (parsed == null || parsed <= 0) return '';

    final glucoseMgDl = glucoseUnit == GlucoseUnit.mmolL
        ? GlucoseConverter.mmolLToMgDl(parsed)
        : parsed;

    final estHbA1cPercentage = GlucoseConverter.glucoseToEstimatedHbA1c(
      glucoseMgDl,
    );

    return hba1cUnit == HbA1cUnit.mmolMol
        ? GlucoseConverter.percentageToMmolMol(
            estHbA1cPercentage,
          ).toStringAsFixed(1)
        : estHbA1cPercentage.toStringAsFixed(2);
  }

  /// Computes the formatted estimated glucose string from [hba1cText] in [hba1cUnit] to [glucoseUnit].
  /// Returns empty string if input is blank or invalid.
  static String calculateGlucoseFromHbA1c({
    required String hba1cText,
    required HbA1cUnit hba1cUnit,
    required GlucoseUnit glucoseUnit,
  }) {
    final trimmed = hba1cText.trim();
    if (trimmed.isEmpty) return '';

    final parsed = double.tryParse(trimmed.replaceAll(',', '.'));
    if (parsed == null || parsed <= 0) return '';

    final hba1cPercentage = hba1cUnit == HbA1cUnit.mmolMol
        ? GlucoseConverter.mmolMolToPercentage(parsed)
        : parsed;

    final estGlucoseMgDl = GlucoseConverter.hba1cToEstimatedGlucose(
      hba1cPercentage,
    );

    return glucoseUnit == GlucoseUnit.mmolL
        ? GlucoseConverter.mgDlToMmolL(estGlucoseMgDl).toStringAsFixed(1)
        : estGlucoseMgDl.round().toString();
  }

  /// Converts a displayed glucose value string from [oldUnit] to [newUnit].
  static String convertGlucoseDisplay({
    required String text,
    required GlucoseUnit oldUnit,
    required GlucoseUnit newUnit,
  }) {
    final parsed = double.tryParse(text.trim().replaceAll(',', '.'));
    if (parsed == null || parsed <= 0) return text;

    if (newUnit == GlucoseUnit.mmolL && oldUnit == GlucoseUnit.mgDl) {
      return GlucoseConverter.mgDlToMmolL(parsed).toStringAsFixed(1);
    } else if (newUnit == GlucoseUnit.mgDl && oldUnit == GlucoseUnit.mmolL) {
      return GlucoseConverter.mmolLToMgDl(parsed).toString();
    }
    return text;
  }

  /// Converts a displayed HbA1c value string from [oldUnit] to [newUnit].
  static String convertHbA1cDisplay({
    required String text,
    required HbA1cUnit oldUnit,
    required HbA1cUnit newUnit,
  }) {
    final parsed = double.tryParse(text.trim().replaceAll(',', '.'));
    if (parsed == null || parsed <= 0) return text;

    if (newUnit == HbA1cUnit.mmolMol && oldUnit == HbA1cUnit.percentage) {
      return GlucoseConverter.percentageToMmolMol(parsed).toStringAsFixed(1);
    } else if (newUnit == HbA1cUnit.percentage &&
        oldUnit == HbA1cUnit.mmolMol) {
      return GlucoseConverter.mmolMolToPercentage(parsed).toStringAsFixed(2);
    }
    return text;
  }

  /// Parses displayed HbA1c text in [hba1cUnit] to standard percentage double, or `null` if invalid.
  static double? parseHbA1cPercentage({
    required String text,
    required HbA1cUnit hba1cUnit,
  }) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;
    final parsed = double.tryParse(trimmed.replaceAll(',', '.'));
    if (parsed == null || parsed <= 0) return null;

    if (hba1cUnit == HbA1cUnit.mmolMol) {
      return GlucoseConverter.mmolMolToPercentage(parsed);
    }
    return parsed;
  }
}
