import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';

/// Card displayed when no BLE glucometer devices are discovered in proximity.
class BleEmptyDevicesCard extends StatelessWidget {
  /// Callback to retry or start scanning for devices.
  final VoidCallback onScan;

  /// Creates a [BleEmptyDevicesCard].
  const BleEmptyDevicesCard({super.key, required this.onScan});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.bluetooth_searching,
              size: 48,
              color: colorScheme.outline,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.bleNoDevicesFound,
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.bleNoDevicesHint,
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.tonalIcon(
              icon: const Icon(Icons.search),
              label: Text(l10n.bleScanButton),
              onPressed: onScan,
            ),
          ],
        ),
      ),
    );
  }
}
