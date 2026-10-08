import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/integrations/biometrics/biometric_service.dart';
import '../../../../../core/presentation/extensions/failure_ui_extension.dart';
import '../../../../../core/presentation/utils/app_snackbar.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../domain/entities/user_profile.dart';
import '../../providers/telemetry_notifier.dart';
import '../../providers/user_profile_notifier.dart';
import '../components/custom_settings_tile.dart';
import '../components/custom_settings_toggle.dart';
import '../components/section_header.dart';
import '../components/wipe_data_dialog.dart';

/// Settings section managing notifications, biometric app lock, analytics, and data deletion.
class SecuritySection extends ConsumerWidget {
  /// User profile state rendered by this section.
  final UserProfile profile;

  /// Creates a security and privacy settings section.
  const SecuritySection({required this.profile, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final telemetryEnabled = ref.watch(telemetryProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CustomSettingsToggle(
          icon: Icons.notifications_outlined,
          title: l10n.notifications,
          subtitle: l10n.receivePushNotifications,
          value: profile.isNotificationsEnabled,
          onChanged: (value) async {
            final (success, failure) = await ref
                .read(userProfileProvider.notifier)
                .updateNotificationsEnabled(value);
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
        ),
        const SizedBox(height: 12),
        SectionHeader(label: l10n.securitySection),
        CustomSettingsToggle(
          icon: Icons.fingerprint,
          title: l10n.biometricSettingTitle,
          subtitle: l10n.biometricSettingSubtitle,
          value: profile.isBiometricLockEnabled,
          onChanged: (value) => _toggleBiometricLock(context, ref, value),
        ),
        CustomSettingsToggle(
          icon: Icons.analytics_outlined,
          title: l10n.diagnosticsSharing,
          subtitle: l10n.diagnosticsSharingSubtitle,
          value: telemetryEnabled,
          onChanged: (value) =>
              ref.read(telemetryProvider.notifier).setEnabled(value),
        ),
        CustomSettingsTile(
          icon: Icons.delete_forever_outlined,
          title: l10n.wipeDataTitle,
          subtitle: l10n.wipeDataDescription,
          isError: true,
          onTap: () => _handleWipeData(context, ref),
        ),
      ],
    );
  }

  Future<void> _toggleBiometricLock(
    BuildContext context,
    WidgetRef ref,
    bool enable,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    if (enable) {
      final canAuth = await BiometricService.instance.canAuthenticate();
      if (!canAuth) {
        if (context.mounted) {
          AppSnackBar.show(
            context,
            message: l10n.biometricNotAvailable,
            type: SnackBarType.error,
          );
        }
        return;
      }

      final result = await BiometricService.instance.authenticate(
        localizedReason: l10n.biometricReason,
        authMessages: BiometricService.createAuthMessages(l10n),
      );

      if (result != BiometricAuthResult.success) {
        if (context.mounted && result != BiometricAuthResult.canceled) {
          final errorMsg = result == BiometricAuthResult.lockedOut
              ? (l10n.biometricLockedOut)
              : l10n.biometricNotAvailable;
          AppSnackBar.show(
            context,
            message: errorMsg,
            type: SnackBarType.error,
          );
        }
        return;
      }
    }

    final (success, failure) = await ref
        .read(userProfileProvider.notifier)
        .updateBiometricLockEnabled(enable);
    if (!success && context.mounted) {
      AppSnackBar.show(
        context,
        message: failure != null
            ? failure.toUserMessage(l10n)
            : l10n.failedToUpdatePreferences,
        type: SnackBarType.error,
      );
    }
  }

  Future<void> _handleWipeData(BuildContext context, WidgetRef ref) async {
    final confirmed = await WipeDataDialog.show(context);
    if (confirmed == true && context.mounted) {
      final (success, failure) = await ref
          .read(userProfileProvider.notifier)
          .wipeAllData();
      if (context.mounted) {
        final l10n = AppLocalizations.of(context)!;
        if (success) {
          AppSnackBar.show(
            context,
            message: l10n.wipeDataSuccess,
            type: SnackBarType.success,
          );
        } else {
          AppSnackBar.show(
            context,
            message: failure != null
                ? failure.toUserMessage(l10n)
                : l10n.wipeDataError,
            type: SnackBarType.error,
          );
        }
      }
    }
  }
}
