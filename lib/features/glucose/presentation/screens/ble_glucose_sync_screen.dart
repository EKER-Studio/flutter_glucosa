import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/presentation/theme/app_layout_tokens.dart';
import '../../../../core/presentation/widgets/app_loading_indicator.dart';
import '../../../../core/presentation/widgets/app_top_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/ble_device_info.dart';
import '../providers/ble_glucose_scan_notifier.dart';
import '../providers/ble_glucose_sync_notifier.dart';

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

    ref.listen<BleSyncStatus>(bleGlucoseSyncProvider, (previous, next) {
      if (next is BleSyncSuccess) {
        final message = next.importedCount > 0
            ? l10n.bleSyncSuccess(next.importedCount, next.deviceName)
            : l10n.bleSyncNoNewReadings;
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

              // Header for discovered devices
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.bleScanButton,
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
                  (device) => _BleDeviceCard(
                    device: device,
                    isSyncing: isSyncing,
                    onSync: () => ref
                        .read(bleGlucoseSyncProvider.notifier)
                        .syncDevice(device),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BleDeviceCard extends StatelessWidget {
  final BleDeviceInfo device;
  final bool isSyncing;
  final VoidCallback onSync;

  const _BleDeviceCard({
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
      margin: const EdgeInsets.only(bottom: 12),
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: colorScheme.primaryContainer,
              child: Icon(
                Icons.bluetooth_connected,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    device.name,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'RSSI: ${device.rssi} dBm',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            FilledButton(
              onPressed: isSyncing ? null : onSync,
              child: Text(l10n.bleSyncButton),
            ),
          ],
        ),
      ),
    );
  }
}
