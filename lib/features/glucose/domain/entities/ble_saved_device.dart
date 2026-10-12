/// Domain entity representing a remembered BLE glucometer with its last known state.
class BleSavedDevice {
  /// Unique remote identifier of the device.
  final String id;

  /// Advertised name of the device.
  final String name;

  /// Last observed battery level percentage (0-100), or `null` if unknown.
  final int? batteryLevel;

  /// Highest sequence number recorded during the last sync session.
  final int? lastSequenceNumber;

  /// Timestamp of the last successful synchronization.
  final DateTime? lastSyncedAt;

  /// Creates an immutable [BleSavedDevice].
  const BleSavedDevice({
    required this.id,
    required this.name,
    this.batteryLevel,
    this.lastSequenceNumber,
    this.lastSyncedAt,
  });

  /// Returns a copy of this device with the given fields replaced by new values.
  BleSavedDevice copyWith({
    String? id,
    String? name,
    int? batteryLevel,
    int? lastSequenceNumber,
    DateTime? lastSyncedAt,
  }) {
    return BleSavedDevice(
      id: id ?? this.id,
      name: name ?? this.name,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      lastSequenceNumber: lastSequenceNumber ?? this.lastSequenceNumber,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BleSavedDevice &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          batteryLevel == other.batteryLevel &&
          lastSequenceNumber == other.lastSequenceNumber &&
          lastSyncedAt == other.lastSyncedAt;

  @override
  int get hashCode =>
      Object.hash(id, name, batteryLevel, lastSequenceNumber, lastSyncedAt);
}
