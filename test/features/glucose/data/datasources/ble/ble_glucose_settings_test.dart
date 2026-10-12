import 'package:flutter_glucosa/features/glucose/data/datasources/ble/ble_glucose_settings.dart';
import 'package:flutter_glucosa/features/glucose/domain/entities/ble_saved_device.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('BleGlucoseSettings', () {
    test('load loads null when no device is stored', () async {
      await BleGlucoseSettings.load();
      expect(BleGlucoseSettings.getSavedDevice(), isNull);
    });

    test('saveDevice persists device and updates in-memory cache', () async {
      final now = DateTime(2026, 6, 1, 10, 0);
      final device = BleSavedDevice(
        id: 'dev-123',
        name: 'My Glucometer',
        batteryLevel: 92,
        lastSequenceNumber: 42,
        lastSyncedAt: now,
      );

      await BleGlucoseSettings.saveDevice(device);

      expect(BleGlucoseSettings.getSavedDevice(), equals(device));

      // Reload from SharedPreferences
      await BleGlucoseSettings.load();
      final loaded = BleGlucoseSettings.getSavedDevice();
      expect(loaded, isNotNull);
      expect(loaded!.id, equals('dev-123'));
      expect(loaded.name, equals('My Glucometer'));
      expect(loaded.batteryLevel, equals(92));
      expect(loaded.lastSequenceNumber, equals(42));
      expect(loaded.lastSyncedAt, equals(now));
    });

    test('clear wipes stored device', () async {
      const device = BleSavedDevice(id: 'dev-123', name: 'My Meter');
      await BleGlucoseSettings.saveDevice(device);
      expect(BleGlucoseSettings.getSavedDevice(), isNotNull);

      await BleGlucoseSettings.clear();
      expect(BleGlucoseSettings.getSavedDevice(), isNull);

      await BleGlucoseSettings.load();
      expect(BleGlucoseSettings.getSavedDevice(), isNull);
    });
  });
}
