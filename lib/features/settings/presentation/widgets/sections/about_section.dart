import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/presentation/utils/app_snackbar.dart';
import '../../../../../core/router/app_routes.dart';
import '../../../../../core/utils/crash_reporter.dart';
import '../../../../../l10n/app_localizations.dart';
import '../components/custom_settings_tile.dart';
import '../components/section_header.dart';

/// Settings section presenting application metadata, legal disclosures, and store links.
class AboutSection extends StatelessWidget {
  /// Creates an about and legal settings section.
  const AboutSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(label: l10n.about),
        FutureBuilder<PackageInfo>(
          future: PackageInfo.fromPlatform(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const SizedBox.shrink();
            }
            final version = snapshot.data?.version ?? '1.0.0';
            return CustomSettingsTile(
              icon: Icons.info_outline,
              title: l10n.version,
              valueText: l10n.appVersionLabel(version),
              showChevron: false,
            );
          },
        ),
        CustomSettingsTile(
          icon: Icons.policy_outlined,
          title: l10n.privacyPolicy,
          onTap: () => context.go(
            '${AppRoute.settings.path}/${AppRoute.privacyPolicy.path}',
          ),
        ),
        CustomSettingsTile(
          icon: Icons.code_rounded,
          title: l10n.licenses,
          onTap: () =>
              context.go('${AppRoute.settings.path}/${AppRoute.licenses.path}'),
        ),
        // Rate-app is Android-only until an App Store listing is wired.
        if (!Platform.isIOS)
          CustomSettingsTile(
            icon: Icons.star_outline_rounded,
            title: l10n.rateApp,
            onTap: () => _rateApp(context),
          ),
      ],
    );
  }

  Future<void> _rateApp(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final packageName = packageInfo.packageName;
      final marketUri = Uri.parse('market://details?id=$packageName');
      final webUri = Uri.parse(
        'https://play.google.com/store/apps/details?id=$packageName',
      );

      final launched = await launchUrl(
        marketUri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        final webLaunched = await launchUrl(
          webUri,
          mode: LaunchMode.externalApplication,
        );
        if (!webLaunched && context.mounted) {
          AppSnackBar.show(
            context,
            message: l10n.couldNotOpenStore,
            type: SnackBarType.error,
          );
        }
      }
    } catch (error, stack) {
      AppCrashReporter.recordError(
        error,
        stack,
        reason: 'Failed to launch app store review URL',
        fatal: false,
      );
      if (context.mounted) {
        AppSnackBar.show(
          context,
          message: l10n.couldNotOpenStore,
          type: SnackBarType.error,
        );
      }
    }
  }
}
