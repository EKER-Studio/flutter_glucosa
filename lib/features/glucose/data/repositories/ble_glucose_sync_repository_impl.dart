import 'dart:math' as math;

import '../../../../core/errors/failure.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/utils/app_logger.dart';
import '../../domain/entities/ble_device_info.dart';
import '../../domain/entities/ble_saved_device.dart';
import '../../domain/entities/ble_sync_result.dart';
import '../../domain/entities/glucose_reading.dart';
import '../../domain/repositories/ble_glucose_sync_repository.dart';
import '../../domain/repositories/glucose_reading_repository.dart';
import '../datasources/ble/ble_glucose_data_source.dart';
import '../datasources/ble/ble_glucose_settings.dart';
import '../mappers/gls_record_mapper.dart';

/// Concrete implementation of [BleGlucoseSyncRepository].
class BleGlucoseSyncRepositoryImpl implements BleGlucoseSyncRepository {
  /// The underlying BLE data source.
  final BleGlucoseDataSource dataSource;

  /// The local persistence repository for blood glucose readings.
  final GlucoseReadingRepository readingRepository;

  /// Creates a [BleGlucoseSyncRepositoryImpl].
  const BleGlucoseSyncRepositoryImpl({
    required this.dataSource,
    required this.readingRepository,
  });

  static const String _tag = 'BleGlucoseSyncRepo';
  static const Duration _matchWindow = Duration(seconds: 60);

  @override
  Stream<List<BleDeviceInfo>> scanDevices({
    Duration timeout = const Duration(seconds: 15),
  }) {
    return dataSource.scanForDevices(timeout: timeout);
  }

  @override
  Future<void> stopScan() {
    return dataSource.stopScan();
  }

  @override
  BleSavedDevice? getSavedDevice() {
    return BleGlucoseSettings.getSavedDevice();
  }

  @override
  Future<void> forgetSavedDevice() {
    return BleGlucoseSettings.clear();
  }

  @override
  Future<DataResult<BleSyncResult>> syncFromDevice(
    String deviceId, {
    String? deviceName,
  }) async {
    try {
      AppLogger.info('Initiating sync with glucometer $deviceId', tag: _tag);

      // Check if we have a recorded sequence number for incremental sync
      final saved = BleGlucoseSettings.getSavedDevice();
      final sinceSeq =
          (saved != null &&
              saved.id == deviceId &&
              saved.lastSequenceNumber != null)
          ? saved.lastSequenceNumber! + 1
          : null;

      final downloadResult = await dataSource.downloadRecords(
        deviceId,
        sinceSequenceNumber: sinceSeq,
      );
      final records = downloadResult.records;

      int importedCount = 0;
      int? highestSeq = saved?.lastSequenceNumber;

      if (records.isNotEmpty) {
        // Filter records with valid glucose measurements
        final validRecords = records
            .where((r) => r.concentrationMgDl != null)
            .toList();

        if (validRecords.isNotEmpty) {
          // Track highest sequence number observed
          final maxSeq = validRecords
              .map((r) => r.sequenceNumber)
              .reduce(math.max);
          highestSeq = (highestSeq != null)
              ? math.max(highestSeq, maxSeq)
              : maxSeq;

          // Find boundaries for deduplication query
          DateTime minDate = validRecords.first.timestamp;
          DateTime maxDate = validRecords.first.timestamp;
          for (final r in validRecords) {
            if (r.timestamp.isBefore(minDate)) minDate = r.timestamp;
            if (r.timestamp.isAfter(maxDate)) maxDate = r.timestamp;
          }

          final existingReadings = await readingRepository.getByDateRange(
            minDate.subtract(_matchWindow),
            maxDate.add(_matchWindow),
          );

          final toInsert = <GlucoseReading>[];
          for (final record in validRecords) {
            final mgDl = record.concentrationMgDl!;
            final isDuplicate = existingReadings.any((existing) {
              final diff = existing.createdAt
                  .difference(record.timestamp)
                  .abs();
              return diff <= _matchWindow && existing.readingMgDl == mgDl;
            });

            if (!isDuplicate) {
              toInsert.add(record.toDomain());
            }
          }

          if (toInsert.isNotEmpty) {
            AppLogger.info(
              'Persisting ${toInsert.length} new glucose readings...',
              tag: _tag,
            );
            final (savedCount, saveFailure) = await readingRepository.addAll(
              toInsert,
            );
            if (saveFailure != null) {
              return (null, saveFailure);
            }
            importedCount = savedCount ?? 0;
          }
        }
      }

      // Persist / update saved device details including battery and last seq
      final effectiveName = deviceName ?? saved?.name ?? 'Glucose Meter';
      final effectiveBattery =
          downloadResult.batteryLevel ?? saved?.batteryLevel;

      await BleGlucoseSettings.saveDevice(
        BleSavedDevice(
          id: deviceId,
          name: effectiveName,
          batteryLevel: effectiveBattery,
          lastSequenceNumber: highestSeq,
          lastSyncedAt: DateTime.now(),
        ),
      );

      final syncResult = BleSyncResult(
        importedCount: importedCount,
        batteryLevel: effectiveBattery,
      );
      return (syncResult, null);
    } catch (e, st) {
      AppLogger.error(
        'Failed to sync from BLE glucometer: $e',
        tag: _tag,
        error: e,
        stackTrace: st,
      );
      return (null, BluetoothFailure(e.toString()));
    }
  }
}
