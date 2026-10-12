import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/presentation/theme/app_layout_tokens.dart';
import '../../../../core/presentation/widgets/app_loading_indicator.dart';
import '../../../../core/presentation/widgets/app_top_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/ble_device_info.dart';
import '../../domain/entities/ble_saved_device.dart';
import '../providers/ble_glucose_scan_notifier.dart';
import '../providers/ble_glucose_sync_notifier.dart';
import '../providers/saved_ble_device_notifier.dart';

/// Screen presenting Bluetooth LE glucometer discovery and data synchronization.
class BleGlucoseSyncScreen extends ConsumerStatefulWidget {
  /// Creates a [BleGlucoseSyncScreen].
  const BleGlucoseSyncScreen({super.key});

  @override
  ConsumerState<BleGlucoseSyncScreen> createState() =>
      _BleGlucoseSyncScreenState();
}

class _BleGlucoseSyncScreenState extends ConsumerState<BleGlucoseSyncScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(bleGlucoseScanProvider.notifier).startScan();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final scanState = ref.watch(bleGlucoseScanProvider);
    final syncStatus = ref.watch(bleGlucoseSyncProvider);
    final savedDevice = ref.watch(savedBleDeviceProvider);

    ref.listen<BleSyncStatus>(bleGlucoseSyncProvider, (previous, next) {
      if (next is BleSyncSuccess) {
        final String message;
        if (next.importedCount > 0) {
          if (next.batteryLevel != null) {
            message = l10n.bleSyncSuccessWithBattery(
              next.importedCount,
              next.deviceName,
              next.batteryLevel!,
            );
          } else {
            message = l10n.bleSyncSuccess(next.importedCount, next.deviceName);
          }
        } else {
          message = l10n.bleSyncNoNewReadings;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: colorScheme.primary,
          ),
        );
      } else if (next is BleSyncFailure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message),
            backgroundColor: colorScheme.error,
          ),
        );
      }
    });

    final isSyncing = syncStatus is BleSyncInProgress;

    return Scaffold(
      appBar: AppTopBar(
        title: l10n.bleGlucoseSyncTitle,
        actions: [
          IconButton(
            tooltip: scanState.isScanning
                ? l10n.bleStopScanButton
                : l10n.bleScanButton,
            icon: scanState.isScanning
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            onPressed: isSyncing
                ? null
                : () {
                    final notifier = ref.read(bleGlucoseScanProvider.notifier);
                    if (scanState.isScanning) {
                      notifier.stopScan();
                    } else {
                      notifier.startScan();
                    }
                  },
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ListView(
            padding: EdgeInsets.symmetric(
              horizontal: context.contentHorizontalPadding,
              vertical: 16,
            ),
            children: [
              // Information banner
              Card(
                elevation: 0,
                color: colorScheme.surfaceContainerHighest,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.bluetooth,
                        color: colorScheme.primary,
                        size: 28,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          l10n.bleSupportedDevicesHint,
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              if (syncStatus is BleSyncInProgress) ...[
                Card(
                  elevation: 0,
                  color: colorScheme.primaryContainer,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        const AppLoadingIndicator(),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            l10n.bleSyncingWith(syncStatus.deviceName),
                            style: textTheme.titleMedium?.copyWith(
                              color: colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Remembered glucometer card (if previously paired)
              if (savedDevice != null) ...[
                _SavedDeviceCard(
                  device: savedDevice,
                  isSyncing: isSyncing,
                  onSync: () => ref
                      .read(bleGlucoseSyncProvider.notifier)
                      .syncDevice(
                        BleDeviceInfo(
                          id: savedDevice.id,
                          name: savedDevice.name,
                          rssi: 0,
                        ),
                      ),
                  onForget: () =>
                      ref.read(savedBleDeviceProvider.notifier).forgetDevice(),
                ),
                const SizedBox(height: 24),
              ],

              // Header for discovered devices
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.bleNearbyDevicesTitle,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (scanState.isScanning)
                    Text(
                      l10n.bleScanButton,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.primary,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              if (scanState.devices.isEmpty && !scanState.isScanning)
                Card(
                  elevation: 0,
                  color: colorScheme.surfaceContainerLow,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
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
                          onPressed: () => ref
                              .read(bleGlucoseScanProvider.notifier)
                              .startScan(),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...scanState.devices.map(
                  (device) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _BleDeviceTile(
                      device: device,
                      isSyncing: isSyncing,
                      onSync: () => ref
                          .read(bleGlucoseSyncProvider.notifier)
                          .syncDevice(device),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SavedDeviceCard extends StatelessWidget {
  final BleSavedDevice device;
  final bool isSyncing;
  final VoidCallback onSync;
  final VoidCallback onForget;

  const _SavedDeviceCard({
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

class _BleDeviceTile extends StatelessWidget {
  final BleDeviceInfo device;
  final bool isSyncing;
  final VoidCallback onSync;

  const _BleDeviceTile({
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
