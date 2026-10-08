import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/domain/enums/glucose_unit.dart';
import '../../../../../core/domain/enums/hba1c_unit.dart';
import '../../../../../core/domain/enums/weight_unit.dart';
import '../../../../../core/presentation/extensions/failure_ui_extension.dart';
import '../../../../../core/presentation/utils/app_snackbar.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../domain/entities/user_profile.dart';
import '../../providers/user_profile_notifier.dart';
import '../components/custom_settings_tile.dart';
import '../components/section_header.dart';
import '../components/selection_dialog.dart';

/// Settings section displaying and configuring preferred clinical measurement units.
class UnitsSection extends ConsumerWidget {
  /// User profile state rendered by this section.
  final UserProfile profile;

  /// Creates a units settings section.
  const UnitsSection({required this.profile, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(label: l10n.units),
        CustomSettingsTile(
          icon: Icons.speed_outlined,
          title: l10n.glucoseUnit,
          valueText: profile.preferredGlucoseUnit.displayName,
          onTap: () => _showGlucoseUnitPicker(
            context,
            ref,
            profile.preferredGlucoseUnit,
          ),
        ),
        CustomSettingsTile(
          icon: Icons.percent_outlined,
          title: l10n.hba1cUnit,
          valueText: profile.preferredHbA1cUnit.displayName,
          onTap: () =>
              _showHbA1cUnitPicker(context, ref, profile.preferredHbA1cUnit),
        ),
        CustomSettingsTile(
          icon: Icons.monitor_weight_outlined,
          title: l10n.weightUnit,
          valueText: profile.preferredWeightUnit.displayName,
          onTap: () =>
              _showWeightUnitPicker(context, ref, profile.preferredWeightUnit),
        ),
      ],
    );
  }

  void _showGlucoseUnitPicker(
    BuildContext context,
    WidgetRef ref,
    GlucoseUnit currentUnit,
  ) {
    final l10n = AppLocalizations.of(context)!;
    SelectionDialog.show<GlucoseUnit>(
      context,
      title: l10n.selectGlucoseUnit,
      currentValue: currentUnit,
      items: GlucoseUnit.values,
      itemLabel: (unit) => unit.displayName,
      itemSubtitle: (unit) => unit == GlucoseUnit.mgDl
          ? (l10n.glucoseUnitMgDlDescription)
          : l10n.glucoseUnitMmolLDescription,
      onSelected: (selected) async {
        final (success, failure) = await ref
            .read(userProfileProvider.notifier)
            .updateGlucoseUnit(selected);
        if (!success && context.mounted) {
          AppSnackBar.show(
            context,
            message: failure != null
                ? failure.toUserMessage(l10n)
                : l10n.failedToUpdatePreferences,
            type: SnackBarType.error,
          );
        }
      },
    );
  }

  void _showHbA1cUnitPicker(
    BuildContext context,
    WidgetRef ref,
    HbA1cUnit currentUnit,
  ) {
    final l10n = AppLocalizations.of(context)!;
    SelectionDialog.show<HbA1cUnit>(
      context,
      title: l10n.selectHbA1cUnit,
      currentValue: currentUnit,
      items: HbA1cUnit.values,
      itemLabel: (unit) => unit.displayName,
      itemSubtitle: (unit) => unit == HbA1cUnit.percentage
          ? (l10n.hba1cUnitNgspDescription)
          : l10n.hba1cUnitIfccDescription,
      onSelected: (selected) async {
        final (success, failure) = await ref
            .read(userProfileProvider.notifier)
            .updateHbA1cUnit(selected);
        if (!success && context.mounted) {
          AppSnackBar.show(
            context,
            message: failure != null
                ? failure.toUserMessage(l10n)
                : l10n.failedToUpdatePreferences,
            type: SnackBarType.error,
          );
        }
      },
    );
  }

  void _showWeightUnitPicker(
    BuildContext context,
    WidgetRef ref,
    WeightUnit currentUnit,
  ) {
    final l10n = AppLocalizations.of(context)!;
    SelectionDialog.show<WeightUnit>(
      context,
      title: l10n.selectWeightUnit,
      currentValue: currentUnit,
      items: WeightUnit.values,
      itemLabel: (unit) => unit.displayName,
      itemSubtitle: (unit) => unit == WeightUnit.kilograms
          ? (l10n.weightUnitKgDescription)
          : l10n.weightUnitLbsDescription,
      onSelected: (selected) async {
        final (success, failure) = await ref
            .read(userProfileProvider.notifier)
            .updateWeightUnit(selected);
        if (!success && context.mounted) {
          AppSnackBar.show(
            context,
            message: failure != null
                ? failure.toUserMessage(l10n)
                : l10n.failedToUpdatePreferences,
            type: SnackBarType.error,
          );
        }
      },
    );
  }
}
