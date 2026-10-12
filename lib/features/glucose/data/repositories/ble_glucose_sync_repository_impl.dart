import '../../../../core/errors/failure.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/utils/app_logger.dart';
import '../../domain/entities/ble_device_info.dart';
import '../../domain/entities/glucose_reading.dart';
import '../../domain/repositories/ble_glucose_sync_repository.dart';
import '../../domain/repositories/glucose_reading_repository.dart';
import '../datasources/ble/ble_glucose_data_source.dart';
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
  Future<DataResult<int>> syncFromDevice(String deviceId) async {
    try {
      AppLogger.info('Initiating sync with glucometer $deviceId', tag: _tag);
      final records = await dataSource.downloadRecords(deviceId);

      if (records.isEmpty) {
        AppLogger.info(
          'No records downloaded from device $deviceId',
          tag: _tag,
        );
        return (0, null);
      }

      // Filter records with valid glucose measurements
      final validRecords = records
          .where((r) => r.concentrationMgDl != null)
          .toList();
      if (validRecords.isEmpty) {
        return (0, null);
      }

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
          final diff = existing.createdAt.difference(record.timestamp).abs();
          return diff <= _matchWindow && existing.readingMgDl == mgDl;
        });

        if (!isDuplicate) {
          toInsert.add(record.toDomain());
        }
      }

      if (toInsert.isEmpty) {
        AppLogger.info(
          'All ${validRecords.length} records are already present locally.',
          tag: _tag,
        );
        return (0, null);
      }

      AppLogger.info(
        'Persisting ${toInsert.length} new glucose readings...',
        tag: _tag,
      );
      final result = await readingRepository.addAll(toInsert);
      return result;
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
