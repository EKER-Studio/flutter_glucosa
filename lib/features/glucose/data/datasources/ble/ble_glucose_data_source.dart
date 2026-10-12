import 'dart:async';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../../../../../core/utils/app_logger.dart';
import '../../../domain/entities/ble_device_info.dart';
import '../../../domain/entities/gls_measurement_context.dart';
import '../../../domain/entities/gls_record.dart';
import 'ble_glucose_constants.dart';
import 'gls_measurement_context_parser.dart';
import 'gls_measurement_parser.dart';
import 'racp_command_builder.dart';
import 'racp_response_parser.dart';

/// Contract for Bluetooth Low Energy operations with standard GLS glucometers.
abstract interface class BleGlucoseDataSource {
  /// Scans for nearby BLE glucometers supporting Glucose Service (0x1808).
  Stream<List<BleDeviceInfo>> scanForDevices({Duration timeout});

  /// Stops an active BLE discovery scan.
  Future<void> stopScan();

  /// Connects to [deviceId], queries stored records via RACP, and returns all parsed [GlsRecord]s.
  ///
  /// [sinceSequenceNumber] Optional sequence number threshold for incremental download.
  /// [timeout] Maximum duration before timing out connection and transfer.
  Future<List<GlsRecord>> downloadRecords(
    String deviceId, {
    int? sinceSequenceNumber,
    Duration timeout,
  });
}

/// Production implementation of [BleGlucoseDataSource] wrapping `flutter_blue_plus`.
class BleGlucoseDataSourceImpl implements BleGlucoseDataSource {
  /// Creates a [BleGlucoseDataSourceImpl] instance.
  const BleGlucoseDataSourceImpl();

  static const String _tag = 'BleGlucoseDataSource';

  @override
  Stream<List<BleDeviceInfo>> scanForDevices({
    Duration timeout = const Duration(seconds: 15),
  }) {
    AppLogger.info('Starting BLE scan for Glucose Service', tag: _tag);

    FlutterBluePlus.startScan(
      withServices: [BleGlucoseConstants.glsServiceUuid],
      timeout: timeout,
    );

    return FlutterBluePlus.scanResults.map((results) {
      final devices = <BleDeviceInfo>[];
      for (final r in results) {
        final name = r.device.platformName.isNotEmpty
            ? r.device.platformName
            : (r.advertisementData.advName.isNotEmpty
                  ? r.advertisementData.advName
                  : 'Glucose Meter');
        devices.add(
          BleDeviceInfo(id: r.device.remoteId.str, name: name, rssi: r.rssi),
        );
      }
      return devices;
    });
  }

  @override
  Future<void> stopScan() async {
    try {
      if (FlutterBluePlus.isScanningNow) {
        AppLogger.info('Stopping BLE scan', tag: _tag);
        await FlutterBluePlus.stopScan();
      }
    } catch (e, st) {
      AppLogger.warning('Error while stopping scan: $e', tag: _tag);
      AppLogger.debug('Stack trace: $st', tag: _tag);
    }
  }

  @override
  Future<List<GlsRecord>> downloadRecords(
    String deviceId, {
    int? sinceSequenceNumber,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final device = BluetoothDevice.fromId(deviceId);
    final records = <GlsRecord>[];
    final contexts = <int, GlsMeasurementContext>{};
    StreamSubscription<List<int>>? measurementSub;
    StreamSubscription<List<int>>? contextSub;
    StreamSubscription<List<int>>? racpSub;

    AppLogger.info('Connecting to glucometer $deviceId...', tag: _tag);
    await device.connect(
      autoConnect: false,
      timeout: const Duration(seconds: 15),
    );

    try {
      AppLogger.info('Discovering services for $deviceId...', tag: _tag);
      final services = await device.discoverServices();
      final glsService = services.firstWhere(
        (s) => s.uuid == BleGlucoseConstants.glsServiceUuid,
        orElse: () =>
            throw StateError('Glucose Service (0x1808) not found on device'),
      );

      final measurementChar = glsService.characteristics.firstWhere(
        (c) =>
            c.uuid == BleGlucoseConstants.glucoseMeasurementCharacteristicUuid,
        orElse: () => throw StateError(
          'Glucose Measurement characteristic (0x2A18) not found',
        ),
      );

      final contextChars = glsService.characteristics.where(
        (c) =>
            c.uuid ==
            BleGlucoseConstants.glucoseMeasurementContextCharacteristicUuid,
      );
      final contextChar = contextChars.isNotEmpty ? contextChars.first : null;

      final racpChar = glsService.characteristics.firstWhere(
        (c) => c.uuid == BleGlucoseConstants.racpCharacteristicUuid,
        orElse: () =>
            throw StateError('RACP characteristic (0x2A52) not found'),
      );

      final racpCompleter = Completer<void>();

      // Subscribe to Glucose Measurement (NOTIFY)
      await measurementChar.setNotifyValue(true);
      measurementSub = measurementChar.onValueReceived.listen((data) {
        final record = GlsMeasurementParser.parse(data);
        if (record != null) {
          AppLogger.debug(
            'Received GLS record: #${record.sequenceNumber}',
            tag: _tag,
          );
          records.add(record);
        }
      });

      // Subscribe to Glucose Measurement Context if supported (NOTIFY)
      if (contextChar != null) {
        AppLogger.info(
          'Enabling Glucose Measurement Context (0x2A34) notifications',
          tag: _tag,
        );
        await contextChar.setNotifyValue(true);
        contextSub = contextChar.onValueReceived.listen((data) {
          final ctx = GlsMeasurementContextParser.parse(data);
          if (ctx != null) {
            AppLogger.debug(
              'Received GLS context: #${ctx.sequenceNumber}',
              tag: _tag,
            );
            contexts[ctx.sequenceNumber] = ctx;
          }
        });
      }

      // Subscribe to RACP (INDICATE)
      await racpChar.setNotifyValue(true);
      racpSub = racpChar.onValueReceived.listen((data) {
        final response = RacpResponseParser.parse(data);
        AppLogger.debug('Received RACP response: $data', tag: _tag);
        if (response is RacpGeneralResponse) {
          if (!racpCompleter.isCompleted) {
            racpCompleter.complete();
          }
        }
      });

      // Issue RACP command
      final List<int> command = sinceSequenceNumber != null
          ? RacpCommandBuilder.reportStoredRecordsGreaterThanOrEqualTo(
              sinceSequenceNumber,
            )
          : RacpCommandBuilder.reportAllStoredRecords();

      AppLogger.info('Sending RACP command: $command', tag: _tag);
      await racpChar.write(command, withoutResponse: false);

      // Await completion or timeout
      await racpCompleter.future.timeout(
        timeout,
        onTimeout: () {
          AppLogger.warning(
            'RACP procedure timed out after $timeout',
            tag: _tag,
          );
        },
      );

      final enrichedRecords = records.map((r) {
        final ctx = contexts[r.sequenceNumber];
        return ctx != null ? r.copyWith(context: ctx) : r;
      }).toList();

      AppLogger.info(
        'Download complete. Total records received: ${enrichedRecords.length}',
        tag: _tag,
      );
      return enrichedRecords;
    } finally {
      await measurementSub?.cancel();
      await contextSub?.cancel();
      await racpSub?.cancel();
      try {
        AppLogger.info('Disconnecting from $deviceId', tag: _tag);
        await device.disconnect();
      } catch (e) {
        AppLogger.warning('Failed to disconnect cleanly: $e', tag: _tag);
      }
    }
  }
}
