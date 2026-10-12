import 'dart:async';

import 'package:flutter_glucosa/core/errors/result.dart';
import 'package:flutter_glucosa/features/glucose/domain/entities/ble_device_info.dart';
import 'package:flutter_glucosa/features/glucose/domain/entities/ble_saved_device.dart';
import 'package:flutter_glucosa/features/glucose/domain/entities/ble_sync_result.dart';
import 'package:flutter_glucosa/features/glucose/domain/repositories/ble_glucose_sync_repository.dart';

/// In-memory fake implementation of [BleGlucoseSyncRepository] for testing.
class FakeBleGlucoseSyncRepository implements BleGlucoseSyncRepository {
  /// Creates a [FakeBleGlucoseSyncRepository] with optional initial state.
  FakeBleGlucoseSyncRepository({
    this.initialSavedDevice,
    List<BleDeviceInfo>? initialDevices,
  }) : _devices = initialDevices ?? [];

  final List<BleDeviceInfo> _devices;
  final StreamController<List<BleDeviceInfo>> _scanController =
      StreamController<List<BleDeviceInfo>>.broadcast();

  /// The currently remembered device.
  BleSavedDevice? initialSavedDevice;

  /// Whether the scan is currently active.
  bool isScanning = false;

  /// Closes stream resources.
  void dispose() {
    _scanController.close();
  }

  /// Emits the given list of devices to the scan stream.
  void emitDevices(List<BleDeviceInfo> devices) {
    _devices
      ..clear()
      ..addAll(devices);
    _scanController.add(List.unmodifiable(_devices));
  }

  @override
  Stream<List<BleDeviceInfo>> scanDevices({
    Duration timeout = const Duration(seconds: 10),
  }) async* {
    isScanning = true;
    yield List.unmodifiable(_devices);
    isScanning = false;
  }

  @override
  Future<void> stopScan() async {
    isScanning = false;
  }

  @override
  BleSavedDevice? getSavedDevice() {
    return initialSavedDevice;
  }

  @override
  Future<void> forgetSavedDevice() async {
    initialSavedDevice = null;
  }

  @override
  Future<DataResult<BleSyncResult>> syncFromDevice(
    String deviceId, {
    String? deviceName,
  }) async {
    return (const BleSyncResult(importedCount: 0), null);
  }
}
