import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../domain/entities/ble_device_info.dart';

/// List tile representing a discovered BLE glucometer during scanning.
class BleDeviceTile extends StatelessWidget {
  /// The discovered peripheral device metadata.
  final BleDeviceInfo device;

  /// Whether synchronization is currently active.
  final bool isSyncing;

  /// Callback to initiate synchronization with this device.
  final VoidCallback onSync;

  /// Creates a [BleDeviceTile].
  const BleDeviceTile({
    super.key,
    required this.device,
    required this.isSyncing,
    required this.onSync,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: colorScheme.surfaceContainerHighest,
          child: Icon(Icons.bluetooth, color: colorScheme.onSurfaceVariant),
        ),
        title: Text(
          device.name,
          style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          device.id,
          style: textTheme.bodySmall?.copyWith(color: colorScheme.outline),
        ),
        trailing: FilledButton.tonal(
          onPressed: isSyncing ? null : onSync,
          child: Text(l10n.bleSyncButton),
        ),
      ),
    );
  }
}
