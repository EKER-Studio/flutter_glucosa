import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/domain/enums/glucose_unit.dart';
import '../../../../../core/domain/utils/glucose_converter.dart';
import '../../../../../core/domain/value_objects/glucose_target_range.dart';
import '../../../../../core/presentation/extensions/failure_ui_extension.dart';
import '../../../../../core/presentation/utils/app_snackbar.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../domain/entities/user_profile.dart';
import '../../providers/user_profile_notifier.dart';
import '../components/custom_settings_tile.dart';
import '../components/section_header.dart';
import '../components/target_range_dialog.dart';

/// Settings section displaying and editing target blood glucose ranges.
class TargetRangeSection extends ConsumerWidget {
  /// User profile state rendered by this section.
  final UserProfile profile;

  /// Creates a target range settings section.
  const TargetRangeSection({required this.profile, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(label: l10n.targetRange),
        CustomSettingsTile(
          icon: Icons.track_changes_outlined,
          title: l10n.targetRange,
          valueText: _targetRangeLabel(
            l10n,
            profile.targetRange,
            profile.preferredGlucoseUnit,
          ),
          onTap: () => _showTargetRangeDialog(
            context,
            ref,
            profile.targetRange,
            profile.preferredGlucoseUnit,
          ),
        ),
      ],
    );
  }

  String _targetRangeLabel(
    AppLocalizations l10n,
    GlucoseTargetRange range,
    GlucoseUnit unit,
  ) {
    final presetName = range.preset.displayName;
    if (unit == GlucoseUnit.mmolL) {
      final minMmol = GlucoseConverter.mgDlToMmolL(
        range.minMgDl,
      ).toStringAsFixed(1);
      final maxMmol = GlucoseConverter.mgDlToMmolL(
        range.maxMgDl,
      ).toStringAsFixed(1);
      return l10n.targetRangeValue(
        minMmol,
        maxMmol,
        unit.displayName,
        presetName,
      );
    }
    return l10n.targetRangeValue(
      range.minMgDl.toString(),
      range.maxMgDl.toString(),
      unit.displayName,
      presetName,
    );
  }

  void _showTargetRangeDialog(
    BuildContext context,
    WidgetRef ref,
    GlucoseTargetRange currentRange,
    GlucoseUnit preferredUnit,
  ) {
    TargetRangeDialog.show(
      context,
      currentRange: currentRange,
      preferredUnit: preferredUnit,
      onSaved: (newRange) async {
        final (success, failure) = await ref
            .read(userProfileProvider.notifier)
            .updateTargetRange(newRange);
        if (!success && context.mounted) {
          final l10n = AppLocalizations.of(context)!;
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
