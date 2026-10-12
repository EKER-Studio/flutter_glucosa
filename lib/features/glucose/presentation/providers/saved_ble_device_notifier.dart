import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/providers/ble_glucose_sync_providers.dart';
import '../../domain/entities/ble_saved_device.dart';

part 'saved_ble_device_notifier.g.dart';

/// Riverpod notifier managing the remembered BLE glucometer state.
@riverpod
class SavedBleDeviceNotifier extends _$SavedBleDeviceNotifier {
  @override
  BleSavedDevice? build() {
    final repo = ref.watch(bleGlucoseSyncRepositoryProvider);
    return repo.getSavedDevice();
  }

  /// Removes the remembered device from persistent storage.
  Future<void> forgetDevice() async {
    final repo = ref.read(bleGlucoseSyncRepositoryProvider);
    await repo.forgetSavedDevice();
    ref.invalidateSelf();
  }

  /// Refreshes the cached saved device state.
  void refresh() {
    ref.invalidateSelf();
  }
}
