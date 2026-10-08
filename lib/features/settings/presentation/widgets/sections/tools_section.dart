import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/router/app_routes.dart';
import '../../../../../l10n/app_localizations.dart';
import '../components/custom_settings_tile.dart';
import '../components/section_header.dart';

/// Settings section providing navigation shortcuts to application utility tools.
class ToolsSection extends StatelessWidget {
  /// Creates a tools settings section.
  const ToolsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(label: l10n.tools),
        CustomSettingsTile(
          icon: Icons.alarm_outlined,
          title: l10n.reminders,
          onTap: () => context.push(AppRoute.reminders.path),
        ),
        CustomSettingsTile(
          icon: Icons.file_upload_outlined,
          title: l10n.exportData,
          subtitle: l10n.exportSubtitle,
          onTap: () => context.push(AppRoute.export.path),
        ),
        CustomSettingsTile(
          icon: Icons.calculate_outlined,
          title: l10n.hba1cCalculator,
          subtitle: l10n.hba1cCalculatorSubtitle,
          onTap: () => context.push(AppRoute.hba1cCalculator.path),
        ),
      ],
    );
  }
}
