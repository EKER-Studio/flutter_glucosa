/// Domain entity representing a discovered Bluetooth LE device.
class BleDeviceInfo {
  /// Unique device identifier (MAC address on Android, UUID on iOS).
  final String id;

  /// Advertised device name or user-visible identifier.
  final String name;

  /// Received Signal Strength Indication (RSSI) in dBm.
  final int rssi;

  /// Creates an immutable [BleDeviceInfo].
  const BleDeviceInfo({
    required this.id,
    required this.name,
    required this.rssi,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BleDeviceInfo &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
