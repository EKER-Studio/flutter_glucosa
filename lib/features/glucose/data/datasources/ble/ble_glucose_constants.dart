import 'package:flutter_blue_plus/flutter_blue_plus.dart';

/// Bluetooth GATT Service and Characteristic UUIDs for Glucose Profile (GLS).
///
/// Follows Bluetooth SIG Glucose Service Specification v1.0.
abstract final class BleGlucoseConstants {
  /// Standard 16-bit Glucose Service UUID (0x1808).
  static final Guid glsServiceUuid = Guid('1808');

  /// Standard 16-bit Glucose Measurement Characteristic UUID (0x2A18).
  ///
  /// Supports NOTIFY.
  static final Guid glucoseMeasurementCharacteristicUuid = Guid('2A18');

  /// Standard 16-bit Glucose Measurement Context Characteristic UUID (0x2A34).
  ///
  /// Supports NOTIFY.
  static final Guid glucoseMeasurementContextCharacteristicUuid = Guid('2A34');

  /// Standard 16-bit Glucose Feature Characteristic UUID (0x2A51).
  ///
  /// Supports READ.
  static final Guid glucoseFeatureCharacteristicUuid = Guid('2A51');

  /// Standard 16-bit Record Access Control Point (RACP) Characteristic UUID (0x2A52).
  ///
  /// Supports WRITE and INDICATE.
  static final Guid racpCharacteristicUuid = Guid('2A52');
}
