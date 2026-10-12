import '../../../../core/errors/result.dart';
import '../entities/ble_device_info.dart';
import '../entities/ble_saved_device.dart';
import '../entities/ble_sync_result.dart';

/// Contract managing Bluetooth discovery and synchronization of blood glucose readings.
abstract interface class BleGlucoseSyncRepository {
  /// Emits nearby BLE devices supporting the Glucose Service (GLS 0x1808).
  Stream<List<BleDeviceInfo>> scanDevices({Duration timeout});

  /// Stops an ongoing BLE discovery scan.
  Future<void> stopScan();

  /// Synchronizes blood glucose measurements from the specified [deviceId].
  ///
  /// [deviceName] Optional user-facing label or advertised name to persist.
  /// Returns the [BleSyncResult], or a [Failure] if an error occurred.
  Future<DataResult<BleSyncResult>> syncFromDevice(
    String deviceId, {
    String? deviceName,
  });

  /// Retrieves the currently remembered glucometer, or `null` if none.
  BleSavedDevice? getSavedDevice();

  /// Clears the remembered glucometer from persistent storage.
  Future<void> forgetSavedDevice();
}
