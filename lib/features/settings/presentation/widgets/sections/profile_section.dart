import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/domain/enums/diabetes_type.dart';
import '../../../../../core/presentation/extensions/failure_ui_extension.dart';
import '../../../../../core/presentation/utils/app_snackbar.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../onboarding/presentation/extensions/diabetes_type_l10n.dart';
import '../../../domain/entities/user_profile.dart';
import '../../providers/user_profile_notifier.dart';
import '../components/custom_settings_tile.dart';
import '../components/edit_name_dialog.dart';
import '../components/section_header.dart';
import '../components/selection_dialog.dart';

/// Settings section displaying and editing user profile identity details.
class ProfileSection extends ConsumerWidget {
  /// User profile state rendered by this section.
  final UserProfile profile;

  /// Creates a profile settings section.
  const ProfileSection({required this.profile, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(label: l10n.userProfile),
        CustomSettingsTile(
          icon: Icons.person_outline,
          title: l10n.name,
          valueText: profile.name.isNotEmpty ? profile.name : l10n.notSet,
          onTap: () => _showEditNameDialog(context, ref, profile.name),
        ),
        CustomSettingsTile(
          icon: Icons.medical_services_outlined,
          title: l10n.diabetesType,
          valueText: profile.diabetesType.label(l10n),
          onTap: () =>
              _showDiabetesTypePicker(context, ref, profile.diabetesType),
        ),
      ],
    );
  }

  void _showEditNameDialog(
    BuildContext context,
    WidgetRef ref,
    String currentName,
  ) {
    EditNameDialog.show(
      context,
      currentName: currentName,
      onSaved: (newName) async {
        final (success, failure) = await ref
            .read(userProfileProvider.notifier)
            .updateName(newName);
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

  void _showDiabetesTypePicker(
    BuildContext context,
    WidgetRef ref,
    DiabetesType currentType,
  ) {
    final l10n = AppLocalizations.of(context)!;
    SelectionDialog.show<DiabetesType>(
      context,
      title: l10n.selectDiabetesType,
      currentValue: currentType,
      items: DiabetesType.values,
      itemLabel: (type) => type.label(l10n),
      onSelected: (selected) async {
        final (success, failure) = await ref
            .read(userProfileProvider.notifier)
            .updateDiabetesType(selected);
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
