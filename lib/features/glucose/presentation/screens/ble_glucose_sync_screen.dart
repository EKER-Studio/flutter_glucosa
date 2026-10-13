import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/presentation/theme/app_layout_tokens.dart';
import '../../../../core/presentation/widgets/app_loading_indicator.dart';
import '../../../../core/presentation/widgets/app_top_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/ble_device_info.dart';
import '../providers/ble_glucose_scan_notifier.dart';
import '../providers/ble_glucose_sync_notifier.dart';
import '../providers/saved_ble_device_notifier.dart';
import '../widgets/components/ble_device_tile.dart';
import '../widgets/components/ble_empty_devices_card.dart';
import '../widgets/components/ble_saved_device_card.dart';

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
                BleSavedDeviceCard(
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
                BleEmptyDevicesCard(
                  onScan: () =>
                      ref.read(bleGlucoseScanProvider.notifier).startScan(),
                )
              else
                ...scanState.devices.map(
                  (device) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: BleDeviceTile(
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
