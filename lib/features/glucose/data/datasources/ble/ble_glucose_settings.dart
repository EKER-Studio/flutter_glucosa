import 'package:shared_preferences/shared_preferences.dart';

import '../../../domain/entities/ble_saved_device.dart';

/// SharedPreferences-backed store for remembered BLE glucometer details.
///
/// Keeps an in-memory cache for synchronous reads across Riverpod build cycles.
abstract final class BleGlucoseSettings {
  static const String _keyId = 'ble_glucometer_id';
  static const String _keyName = 'ble_glucometer_name';
  static const String _keyBattery = 'ble_glucometer_battery';
  static const String _keyLastSeq = 'ble_glucometer_last_seq';
  static const String _keySyncedAt = 'ble_glucometer_synced_at';

  static BleSavedDevice? _cachedDevice;
  static bool _initialized = false;

  /// Loads the persisted glucometer settings into memory.
  static Future<void> load({SharedPreferences? prefs}) async {
    final store = prefs ?? await SharedPreferences.getInstance();
    final id = store.getString(_keyId);
    final name = store.getString(_keyName);

    if (id != null && name != null) {
      final battery = store.getInt(_keyBattery);
      final lastSeq = store.getInt(_keyLastSeq);
      final syncedMillis = store.getInt(_keySyncedAt);

      _cachedDevice = BleSavedDevice(
        id: id,
        name: name,
        batteryLevel: battery,
        lastSequenceNumber: lastSeq,
        lastSyncedAt: syncedMillis != null
            ? DateTime.fromMillisecondsSinceEpoch(syncedMillis)
            : null,
      );
    } else {
      _cachedDevice = null;
    }
    _initialized = true;
  }

  /// Synchronously returns the currently cached remembered device, if any.
  static BleSavedDevice? getSavedDevice() {
    return _cachedDevice;
  }

  /// Whether settings have been loaded from disk at least once.
  static bool get isInitialized => _initialized;

  /// Persists [device] and updates the in-memory cache.
  static Future<void> saveDevice(
    BleSavedDevice device, {
    SharedPreferences? prefs,
  }) async {
    final store = prefs ?? await SharedPreferences.getInstance();
    await store.setString(_keyId, device.id);
    await store.setString(_keyName, device.name);

    if (device.batteryLevel != null) {
      await store.setInt(_keyBattery, device.batteryLevel!);
    } else {
      await store.remove(_keyBattery);
    }

    if (device.lastSequenceNumber != null) {
      await store.setInt(_keyLastSeq, device.lastSequenceNumber!);
    } else {
      await store.remove(_keyLastSeq);
    }

    if (device.lastSyncedAt != null) {
      await store.setInt(
        _keySyncedAt,
        device.lastSyncedAt!.millisecondsSinceEpoch,
      );
    } else {
      await store.remove(_keySyncedAt);
    }

    _cachedDevice = device;
    _initialized = true;
  }

  /// Clears the remembered glucometer from persistent storage and resets the cache.
  static Future<void> clear({SharedPreferences? prefs}) async {
    final store = prefs ?? await SharedPreferences.getInstance();
    await store.remove(_keyId);
    await store.remove(_keyName);
    await store.remove(_keyBattery);
    await store.remove(_keyLastSeq);
    await store.remove(_keySyncedAt);

    _cachedDevice = null;
    _initialized = true;
  }
}
