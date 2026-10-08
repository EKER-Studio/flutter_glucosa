import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/presentation/extensions/failure_ui_extension.dart';
import '../../../../core/presentation/widgets/app_error_view.dart';
import '../../../../core/presentation/widgets/app_loading_indicator.dart';
import '../../../../core/presentation/widgets/app_top_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/user_profile_notifier.dart';
import '../widgets/components/health_sync_section.dart';
import '../widgets/components/section_header.dart';
import '../widgets/sections/about_section.dart';
import '../widgets/sections/appearance_section.dart';
import '../widgets/sections/profile_section.dart';
import '../widgets/sections/security_section.dart';
import '../widgets/sections/target_range_section.dart';
import '../widgets/sections/tools_section.dart';
import '../widgets/sections/units_section.dart';

/// Presentation widget rendering the user profile and application settings screen.
///
/// Composes domain-specific settings sections backed by [userProfileProvider].
class SettingsScreen extends ConsumerWidget {
  /// Creates a settings screen widget instance.
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppTopBar(title: l10n.settingsTitle),
      body: profileAsync.when(
        loading: () => const AppLoadingIndicator(),
        error: (error, _) => AppErrorView(
          message: error is Failure
              ? error.toUserMessage(l10n)
              : error.toString(),
          retryLabel: l10n.tryAgain,
          onRetry: () => ref.invalidate(userProfileProvider),
        ),
        data: (profile) => Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                ProfileSection(profile: profile),
                const SizedBox(height: 12),
                UnitsSection(profile: profile),
                const SizedBox(height: 12),
                TargetRangeSection(profile: profile),
                const SizedBox(height: 12),
                AppearanceSection(profile: profile),
                const SizedBox(height: 12),
                SecuritySection(profile: profile),
                const SizedBox(height: 12),
                SectionHeader(label: l10n.healthSyncSection),
                HealthSyncSection(profile: profile),
                const SizedBox(height: 12),
                const ToolsSection(),
                const SizedBox(height: 12),
                const AboutSection(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
