import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/providers/ble_glucose_sync_providers.dart';
import '../../domain/entities/ble_device_info.dart';

part 'ble_glucose_scan_notifier.g.dart';

/// State representation indicating whether a BLE discovery scan is active.
typedef BleScanState = ({List<BleDeviceInfo> devices, bool isScanning});

/// Riverpod notifier managing Bluetooth LE discovery for compatible glucometers.
@riverpod
class BleGlucoseScanNotifier extends _$BleGlucoseScanNotifier {
  StreamSubscription<List<BleDeviceInfo>>? _scanSubscription;

  @override
  BleScanState build() {
    final repo = ref.read(bleGlucoseSyncRepositoryProvider);
    ref.onDispose(() {
      _scanSubscription?.cancel();
      repo.stopScan();
    });
    return (devices: const <BleDeviceInfo>[], isScanning: false);
  }

  /// Initiates discovery of nearby BLE glucometers with [timeout].
  void startScan({Duration timeout = const Duration(seconds: 15)}) {
    _scanSubscription?.cancel();
    state = (devices: const <BleDeviceInfo>[], isScanning: true);

    final repo = ref.read(bleGlucoseSyncRepositoryProvider);
    _scanSubscription = repo
        .scanDevices(timeout: timeout)
        .listen(
          (devices) {
            state = (devices: devices, isScanning: true);
          },
          onError: (_) {
            state = (devices: state.devices, isScanning: false);
          },
          onDone: () {
            state = (devices: state.devices, isScanning: false);
          },
        );
  }

  /// Explicitly halts an active discovery scan.
  Future<void> stopScan() async {
    await _scanSubscription?.cancel();
    _scanSubscription = null;
    await ref.read(bleGlucoseSyncRepositoryProvider).stopScan();
    state = (devices: state.devices, isScanning: false);
  }
}
