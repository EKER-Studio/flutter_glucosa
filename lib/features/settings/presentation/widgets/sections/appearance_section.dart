import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/domain/enums/first_day_of_week.dart';
import '../../../../../core/domain/enums/user_theme_mode.dart';
import '../../../../../core/presentation/extensions/failure_ui_extension.dart';
import '../../../../../core/presentation/utils/app_snackbar.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../calendar/presentation/extensions/first_day_of_week_ui_extension.dart';
import '../../../domain/entities/user_profile.dart';
import '../../providers/user_profile_notifier.dart';
import '../components/custom_settings_tile.dart';
import '../components/section_header.dart';
import '../components/selection_dialog.dart';
import '../components/theme_selection_dialog.dart';

/// Settings section configuring UI theme and calendar week display preferences.
class AppearanceSection extends ConsumerWidget {
  /// User profile state rendered by this section.
  final UserProfile profile;

  /// Creates an appearance settings section.
  const AppearanceSection({required this.profile, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(label: l10n.appearance),
        CustomSettingsTile(
          icon: Icons.palette_outlined,
          title: l10n.theme,
          valueText: _themeLabel(l10n, profile.themeMode),
          onTap: () => _showThemePicker(context, ref, profile.themeMode),
        ),
        CustomSettingsTile(
          icon: Icons.calendar_today_outlined,
          title: l10n.firstDayOfWeek,
          valueText: profile.firstDayOfWeek.label(l10n),
          onTap: () =>
              _showFirstDayOfWeekPicker(context, ref, profile.firstDayOfWeek),
        ),
      ],
    );
  }

  void _showThemePicker(
    BuildContext context,
    WidgetRef ref,
    UserThemeMode current,
  ) {
    ThemeSelectionDialog.show(
      context,
      currentMode: current,
      onSelected: (mode) async {
        final (success, failure) = await ref
            .read(userProfileProvider.notifier)
            .updateThemeMode(mode);
        if (!success && context.mounted) {
          final l10n = AppLocalizations.of(context)!;
          AppSnackBar.show(
            context,
            message: failure != null
                ? failure.toUserMessage(l10n)
                : l10n.failedToUpdateThemeMode,
            type: SnackBarType.error,
          );
        }
      },
    );
  }

  String _themeLabel(AppLocalizations l10n, UserThemeMode mode) {
    return switch (mode) {
      UserThemeMode.light => l10n.themeLight,
      UserThemeMode.dark => l10n.themeDark,
      UserThemeMode.system => l10n.themeSystem,
    };
  }

  void _showFirstDayOfWeekPicker(
    BuildContext context,
    WidgetRef ref,
    FirstDayOfWeek current,
  ) {
    final l10n = AppLocalizations.of(context)!;
    SelectionDialog.show<FirstDayOfWeek>(
      context,
      title: l10n.selectFirstDayOfWeek,
      currentValue: current,
      items: FirstDayOfWeek.values,
      itemLabel: (item) => item.label(l10n),
      onSelected: (selected) async {
        final (success, failure) = await ref
            .read(userProfileProvider.notifier)
            .updateFirstDayOfWeek(selected);
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
