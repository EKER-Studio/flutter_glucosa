/// Domain entity representing the outcome of a BLE synchronization session.
class BleSyncResult {
  /// Number of new readings successfully imported into the local database.
  final int importedCount;

  /// Battery level percentage (0-100) reported by the device, or `null` if unavailable.
  final int? batteryLevel;

  /// Creates an immutable [BleSyncResult].
  const BleSyncResult({required this.importedCount, this.batteryLevel});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BleSyncResult &&
          runtimeType == other.runtimeType &&
          importedCount == other.importedCount &&
          batteryLevel == other.batteryLevel;

  @override
  int get hashCode => Object.hash(importedCount, batteryLevel);
}
