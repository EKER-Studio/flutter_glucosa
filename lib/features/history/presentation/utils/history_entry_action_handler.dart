import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/domain/enums/metric_type.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../blood_pressure/domain/entities/blood_pressure_reading.dart';
import '../../../blood_pressure/presentation/providers/blood_pressure_reading_list_notifier.dart';
import '../../../cholesterol/domain/entities/cholesterol_reading.dart';
import '../../../cholesterol/presentation/providers/cholesterol_reading_list_notifier.dart';
import '../../../glucose/domain/entities/glucose_reading.dart';
import '../../../glucose/presentation/providers/glucose_reading_list_notifier.dart';
import '../../../hba1c/domain/entities/hba1c_reading.dart';
import '../../../hba1c/presentation/providers/hba1c_reading_list_notifier.dart';
import '../../../ketones/domain/entities/ketone_reading.dart';
import '../../../ketones/presentation/providers/ketone_reading_list_notifier.dart';
import '../../../weight/domain/entities/weight_reading.dart';
import '../../../weight/presentation/providers/weight_reading_list_notifier.dart';
import '../models/history_entry.dart';

/// Coordinator handling delete, confirmation, and restore actions on history measurement entries.
abstract final class HistoryEntryActionHandler {
  /// Extracts the integer identifier of a domain reading object.
  static int readingId(Object reading) {
    return switch (reading) {
      GlucoseReading r => r.id,
      HbA1cReading r => r.id,
      BloodPressureReading r => r.id,
      KetoneReading r => r.id,
      CholesterolReading r => r.id,
      WeightReading r => r.id,
      _ => 0,
    };
  }

  /// Deletes [entry] by dispatching to the respective feature list notifier.
  static Future<void> deleteEntry(WidgetRef ref, HistoryEntry entry) {
    return switch (entry.reading) {
      GlucoseReading r =>
        ref.read(glucoseReadingListProvider.notifier).deleteReading(r.id),
      HbA1cReading r =>
        ref.read(hbA1cReadingListProvider.notifier).deleteReading(r.id),
      BloodPressureReading r =>
        ref.read(bloodPressureReadingListProvider.notifier).deleteReading(r.id),
      KetoneReading r =>
        ref.read(ketoneReadingListProvider.notifier).deleteReading(r.id),
      CholesterolReading r =>
        ref.read(cholesterolReadingListProvider.notifier).deleteReading(r.id),
      WeightReading r =>
        ref.read(weightReadingListProvider.notifier).deleteReading(r.id),
      _ => Future.value(),
    };
  }

  /// Restores [entry] back to local database via respective feature list notifier.
  static Future<void> restoreEntry(WidgetRef ref, HistoryEntry entry) {
    return switch (entry.reading) {
      GlucoseReading r =>
        ref.read(glucoseReadingListProvider.notifier).addReading(r),
      HbA1cReading r =>
        ref.read(hbA1cReadingListProvider.notifier).addReading(r),
      BloodPressureReading r =>
        ref.read(bloodPressureReadingListProvider.notifier).addReading(r),
      KetoneReading r =>
        ref.read(ketoneReadingListProvider.notifier).addReading(r),
      CholesterolReading r =>
        ref.read(cholesterolReadingListProvider.notifier).addReading(r),
      WeightReading r =>
        ref.read(weightReadingListProvider.notifier).addReading(r),
      _ => Future.value(),
    };
  }

  /// Returns the localized delete confirmation message for [type].
  static String deleteConfirmMessage(MetricType type, AppLocalizations l10n) {
    return switch (type) {
      MetricType.glucose => l10n.deleteReadingConfirmationMessage,
      MetricType.hba1c => l10n.deleteHba1cConfirm,
      MetricType.bloodPressure => l10n.deleteBloodPressureConfirm,
      MetricType.ketones => l10n.deleteKetonesConfirm,
      MetricType.cholesterol => l10n.deleteCholesterolConfirm,
      MetricType.weight => l10n.deleteWeightConfirm,
    };
  }

  /// Returns the localized deletion success snackbar message for [type].
  static String deleteSuccessMessage(MetricType type, AppLocalizations l10n) {
    return switch (type) {
      MetricType.glucose => l10n.glucoseReadingDeleted,
      MetricType.hba1c => l10n.hba1cDeletedSuccess,
      MetricType.bloodPressure => l10n.bpDeletedSuccess,
      MetricType.ketones => l10n.ketonesDeletedSuccess,
      MetricType.cholesterol => l10n.cholesterolDeletedSuccess,
      MetricType.weight => l10n.weightDeletedSuccess,
    };
  }

  /// Shows the shared delete-confirmation dialog for [type].
  static Future<bool> confirmDelete(
    BuildContext context,
    MetricType type,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.deleteReadingConfirmationTitle),
        content: Text(deleteConfirmMessage(type, l10n)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    return confirmed == true;
  }
}
