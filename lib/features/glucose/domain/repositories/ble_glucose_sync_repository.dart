import '../../../../core/errors/result.dart';
import '../entities/ble_device_info.dart';

/// Contract managing Bluetooth discovery and synchronization of blood glucose readings.
abstract interface class BleGlucoseSyncRepository {
  /// Emits nearby BLE devices supporting the Glucose Service (GLS 0x1808).
  Stream<List<BleDeviceInfo>> scanDevices({Duration timeout});

  /// Stops an ongoing BLE discovery scan.
  Future<void> stopScan();

  /// Synchronizes blood glucose measurements from the specified [deviceId].
  ///
  /// Returns the count of newly inserted readings, or a [Failure] if an error occurred.
  Future<DataResult<int>> syncFromDevice(String deviceId);
}
