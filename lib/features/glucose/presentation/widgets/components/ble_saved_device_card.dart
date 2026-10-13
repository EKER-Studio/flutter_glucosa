import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../domain/entities/ble_saved_device.dart';

/// Card displaying information about a remembered BLE glucometer with sync and forget actions.
class BleSavedDeviceCard extends StatelessWidget {
  /// The saved device data.
  final BleSavedDevice device;

  /// Whether a BLE synchronization is currently in progress.
  final bool isSyncing;

  /// Callback executed when user taps the sync button.
  final VoidCallback onSync;

  /// Callback executed when user taps the forget device button.
  final VoidCallback onForget;

  /// Creates a [BleSavedDeviceCard].
  const BleSavedDeviceCard({
    super.key,
    required this.device,
    required this.isSyncing,
    required this.onSync,
    required this.onForget,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: colorScheme.primaryContainer,
                  child: Icon(
                    Icons.bluetooth_connected,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.bleSavedDeviceTitle,
                        style: textTheme.labelMedium?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        device.name,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (device.batteryLevel != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.battery_std,
                          size: 16,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${device.batteryLevel}%',
                          style: textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    icon: const Icon(Icons.sync),
                    label: Text(l10n.bleSyncNow),
                    onPressed: isSyncing ? null : onSync,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: l10n.bleForgetDevice,
                  icon: Icon(Icons.delete_outline, color: colorScheme.error),
                  onPressed: isSyncing ? null : onForget,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
