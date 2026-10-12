import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/errors/failure.dart';
import '../../data/providers/ble_glucose_sync_providers.dart';
import '../../domain/entities/ble_device_info.dart';
import 'saved_ble_device_notifier.dart';

part 'ble_glucose_sync_notifier.g.dart';

/// Sealed hierarchy representing the state of an ongoing or completed BLE synchronization.
sealed class BleSyncStatus {
  const BleSyncStatus();
}

/// Initial state before any synchronization has been triggered.
class BleSyncInitial extends BleSyncStatus {
  /// Creates a [BleSyncInitial] state.
  const BleSyncInitial();
}

/// State indicating synchronization is currently in progress with [deviceName].
class BleSyncInProgress extends BleSyncStatus {
  /// Name of the glucometer currently synchronizing.
  final String deviceName;

  /// Creates a [BleSyncInProgress] state.
  const BleSyncInProgress(this.deviceName);
}

/// State indicating synchronization completed successfully with [importedCount] new readings.
class BleSyncSuccess extends BleSyncStatus {
  /// Count of newly inserted readings.
  final int importedCount;

  /// Name of the glucometer that was synchronized.
  final String deviceName;

  /// Battery level percentage (0-100) if read from the device, or `null`.
  final int? batteryLevel;

  /// Creates a [BleSyncSuccess] state.
  const BleSyncSuccess(
    this.importedCount,
    this.deviceName, {
    this.batteryLevel,
  });
}

/// State indicating synchronization failed with [message].
class BleSyncFailure extends BleSyncStatus {
  /// Diagnostic error description.
  final String message;

  /// Creates a [BleSyncFailure] state.
  const BleSyncFailure(this.message);
}

/// Riverpod notifier managing synchronization state with a target BLE glucometer.
@riverpod
class BleGlucoseSyncNotifier extends _$BleGlucoseSyncNotifier {
  @override
  BleSyncStatus build() => const BleSyncInitial();

  /// Synchronizes readings from [device], updating state according to outcome.
  Future<void> syncDevice(BleDeviceInfo device) async {
    state = BleSyncInProgress(device.name);
    final repo = ref.read(bleGlucoseSyncRepositoryProvider);

    final (result, failure) = await repo.syncFromDevice(
      device.id,
      deviceName: device.name,
    );
    if (failure != null) {
      state = BleSyncFailure(failure.userMessage);
    } else {
      state = BleSyncSuccess(
        result?.importedCount ?? 0,
        device.name,
        batteryLevel: result?.batteryLevel,
      );
      ref.invalidate(savedBleDeviceProvider);
    }
  }

  /// Resets state back to [BleSyncInitial].
  void reset() {
    state = const BleSyncInitial();
  }
}
