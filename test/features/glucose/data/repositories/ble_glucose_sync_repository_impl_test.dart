import 'package:flutter_glucosa/core/domain/enums/meal_context.dart';
import 'package:flutter_glucosa/core/errors/failure.dart';
import 'package:flutter_glucosa/features/glucose/data/datasources/ble/ble_glucose_data_source.dart';
import 'package:flutter_glucosa/features/glucose/data/mappers/gls_record_mapper.dart';
import 'package:flutter_glucosa/features/glucose/data/repositories/ble_glucose_sync_repository_impl.dart';
import 'package:flutter_glucosa/features/glucose/domain/entities/ble_device_info.dart';
import 'package:flutter_glucosa/features/glucose/domain/entities/gls_record.dart';
import 'package:flutter_glucosa/features/glucose/domain/entities/glucose_reading.dart';
import 'package:flutter_glucosa/features/glucose/domain/repositories/glucose_reading_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockBleGlucoseDataSource extends Mock implements BleGlucoseDataSource {}

class MockGlucoseReadingRepository extends Mock
    implements GlucoseReadingRepository {}

void main() {
  late MockBleGlucoseDataSource mockDataSource;
  late MockGlucoseReadingRepository mockReadingRepository;
  late BleGlucoseSyncRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(
      GlucoseReading(
        readingMgDl: 100,
        mealContext: MealContext.other,
        createdAt: DateTime.fromMillisecondsSinceEpoch(0),
      ),
    );
    registerFallbackValue(<GlucoseReading>[]);
    registerFallbackValue(const Duration(seconds: 1));
  });

  setUp(() {
    mockDataSource = MockBleGlucoseDataSource();
    mockReadingRepository = MockGlucoseReadingRepository();
    repository = BleGlucoseSyncRepositoryImpl(
      dataSource: mockDataSource,
      readingRepository: mockReadingRepository,
    );
  });

  group('BleGlucoseSyncRepositoryImpl', () {
    test('scanDevices delegates to dataSource.scanForDevices', () {
      when(
        () => mockDataSource.scanForDevices(timeout: any(named: 'timeout')),
      ).thenAnswer(
        (_) => Stream.value([
          const BleDeviceInfo(id: 'dev1', name: 'Accu-Chek', rssi: -60),
        ]),
      );

      expect(
        repository.scanDevices(),
        emits([const BleDeviceInfo(id: 'dev1', name: 'Accu-Chek', rssi: -60)]),
      );
    });

    test(
      'syncFromDevice returns 0 when dataSource returns no records',
      () async {
        when(
          () => mockDataSource.downloadRecords('dev1'),
        ).thenAnswer((_) async => []);

        final result = await repository.syncFromDevice('dev1');
        expect(result.$1, equals(0));
        expect(result.$2, isNull);
        verifyNever(() => mockReadingRepository.addAll(any()));
      },
    );

    test('syncFromDevice imports new records and skips duplicates', () async {
      final now = DateTime(2026, 1, 1, 12, 0, 0);
      final record1 = GlsRecord(
        sequenceNumber: 1,
        timestamp: now,
        concentration: 0.00100, // 100 mg/dL
        isMolPerLiter: false,
        sampleLocation: 'Finger',
      );
      final record2 = GlsRecord(
        sequenceNumber: 2,
        timestamp: now.add(const Duration(hours: 2)),
        concentration: 0.00120, // 120 mg/dL
        isMolPerLiter: false,
      );

      when(
        () => mockDataSource.downloadRecords('dev1'),
      ).thenAnswer((_) async => [record1, record2]);

      // Simulate record1 is already in DB, record2 is new
      final existingReading = GlucoseReading(
        id: 1,
        readingMgDl: 100,
        mealContext: MealContext.other,
        createdAt: now.add(const Duration(seconds: 10)), // within 60s
      );

      when(
        () => mockReadingRepository.getByDateRange(any(), any()),
      ).thenAnswer((_) async => [existingReading]);

      when(() => mockReadingRepository.addAll(any())).thenAnswer((
        invocation,
      ) async {
        final list =
            invocation.positionalArguments.first as List<GlucoseReading>;
        return (list.length, null);
      });

      final result = await repository.syncFromDevice('dev1');
      expect(result.$1, equals(1)); // Only record2 imported
      expect(result.$2, isNull);

      verify(
        () => mockReadingRepository.addAll(
          any(
            that: predicate<List<GlucoseReading>>(
              (list) => list.length == 1 && list.first.readingMgDl == 120,
            ),
          ),
        ),
      ).called(1);
    });

    test(
      'syncFromDevice returns BluetoothFailure when exception is thrown',
      () async {
        when(
          () => mockDataSource.downloadRecords('dev1'),
        ).thenThrow(Exception('Connection lost'));

        final result = await repository.syncFromDevice('dev1');
        expect(result.$1, isNull);
        expect(result.$2, isA<BluetoothFailure>());
        expect(result.$2!.message, contains('Connection lost'));
      },
    );
  });

  group('GlsRecordMapper', () {
    test('maps GlsRecord to GlucoseReading correctly', () {
      final record = GlsRecord(
        sequenceNumber: 1,
        timestamp: DateTime(2026, 3, 15, 8, 30),
        concentration: 0.00110,
        isMolPerLiter: false,
        sampleType: 'Capillary Whole Blood',
        sampleLocation: 'Finger',
      );

      final reading = record.toDomain();
      expect(reading.readingMgDl, equals(110));
      expect(reading.mealContext, equals(MealContext.other));
      expect(reading.notes, equals('Finger, Capillary Whole Blood'));
      expect(reading.createdAt, equals(DateTime(2026, 3, 15, 8, 30)));
    });
  });
}
