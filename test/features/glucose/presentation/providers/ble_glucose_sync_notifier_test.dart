import 'dart:async';

import 'package:flutter_glucosa/core/errors/failure.dart';
import 'package:flutter_glucosa/features/glucose/data/providers/ble_glucose_sync_providers.dart';
import 'package:flutter_glucosa/features/glucose/domain/entities/ble_device_info.dart';
import 'package:flutter_glucosa/features/glucose/domain/entities/ble_sync_result.dart';
import 'package:flutter_glucosa/features/glucose/domain/repositories/ble_glucose_sync_repository.dart';
import 'package:flutter_glucosa/features/glucose/presentation/providers/ble_glucose_scan_notifier.dart';
import 'package:flutter_glucosa/features/glucose/presentation/providers/ble_glucose_sync_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockBleGlucoseSyncRepository extends Mock
    implements BleGlucoseSyncRepository {}

void main() {
  late MockBleGlucoseSyncRepository mockRepository;
  late ProviderContainer container;

  setUpAll(() {
    registerFallbackValue(const Duration(seconds: 1));
  });

  setUp(() {
    mockRepository = MockBleGlucoseSyncRepository();
    when(() => mockRepository.stopScan()).thenAnswer((_) async {});
    when(() => mockRepository.getSavedDevice()).thenReturn(null);
    when(() => mockRepository.forgetSavedDevice()).thenAnswer((_) async {});
    container = ProviderContainer(
      overrides: [
        bleGlucoseSyncRepositoryProvider.overrideWithValue(mockRepository),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('BleGlucoseScanNotifier', () {
    test('initial state has empty devices and is not scanning', () {
      final sub = container.listen(bleGlucoseScanProvider, (_, _) {});
      final state = sub.read();
      expect(state.devices, isEmpty);
      expect(state.isScanning, isFalse);
    });

    test('startScan emits discovered devices and updates isScanning', () async {
      const device = BleDeviceInfo(id: 'dev1', name: 'Accu-Chek', rssi: -50);
      final controller = StreamController<List<BleDeviceInfo>>();
      when(
        () => mockRepository.scanDevices(timeout: any(named: 'timeout')),
      ).thenAnswer((_) => controller.stream);

      final sub = container.listen(bleGlucoseScanProvider, (_, _) {});
      container.read(bleGlucoseScanProvider.notifier).startScan();
      controller.add([device]);

      await pumpEventQueue();

      final state = sub.read();
      expect(state.devices, equals([device]));
      expect(state.isScanning, isTrue);

      await controller.close();
    });

    test('stopScan halts scanning and updates state', () async {
      when(() => mockRepository.stopScan()).thenAnswer((_) async {});

      await container.read(bleGlucoseScanProvider.notifier).stopScan();

      final state = container.read(bleGlucoseScanProvider);
      expect(state.isScanning, isFalse);
      verify(() => mockRepository.stopScan()).called(1);
    });
  });

  group('BleGlucoseSyncNotifier', () {
    test('initial state is BleSyncInitial', () {
      final state = container.read(bleGlucoseSyncProvider);
      expect(state, isA<BleSyncInitial>());
    });

    test(
      'syncDevice transitions to Success with battery level on valid sync pass',
      () async {
        const device = BleDeviceInfo(
          id: 'dev1',
          name: 'Contour Plus',
          rssi: -65,
        );
        when(
          () => mockRepository.syncFromDevice(
            'dev1',
            deviceName: any(named: 'deviceName'),
          ),
        ).thenAnswer(
          (_) async =>
              (const BleSyncResult(importedCount: 5, batteryLevel: 80), null),
        );

        final notifier = container.read(bleGlucoseSyncProvider.notifier);
        final future = notifier.syncDevice(device);

        expect(
          container.read(bleGlucoseSyncProvider),
          isA<BleSyncInProgress>(),
        );

        await future;

        final state = container.read(bleGlucoseSyncProvider);
        expect(state, isA<BleSyncSuccess>());
        final success = state as BleSyncSuccess;
        expect(success.importedCount, equals(5));
        expect(success.deviceName, equals('Contour Plus'));
        expect(success.batteryLevel, equals(80));
      },
    );

    test('syncDevice transitions to Failure when repository fails', () async {
      const device = BleDeviceInfo(id: 'dev1', name: 'Contour Plus', rssi: -65);
      when(
        () => mockRepository.syncFromDevice(
          'dev1',
          deviceName: any(named: 'deviceName'),
        ),
      ).thenAnswer(
        (_) async => (null, const BluetoothFailure('Device disconnected')),
      );

      final notifier = container.read(bleGlucoseSyncProvider.notifier);
      await notifier.syncDevice(device);

      final state = container.read(bleGlucoseSyncProvider);
      expect(state, isA<BleSyncFailure>());
      final failure = state as BleSyncFailure;
      expect(failure.message, equals('Device disconnected'));
    });
  });
}
