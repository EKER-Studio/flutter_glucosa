import 'gls_measurement_context.dart';

/// Domain entity representing a glucose measurement record received from a BLE glucometer.
class GlsRecord {
  /// Sequential identifier assigned by the glucometer.
  final int sequenceNumber;

  /// Timestamp when the measurement was performed, including time offset.
  final DateTime timestamp;

  /// Measured glucose concentration in either mol/L or kg/L, or `null` if absent.
  final double? concentration;

  /// Whether the concentration unit is mol/L (`true`) or kg/L (`false`).
  final bool isMolPerLiter;

  /// Human-readable type of the blood or control sample.
  final String? sampleType;

  /// Human-readable anatomical location where the sample was obtained.
  final String? sampleLocation;

  /// Sensor status annunciation bitmask representing warnings or error codes.
  final int? sensorStatus;

  /// Whether an associated Glucose Measurement Context packet will follow.
  final bool contextInformationFollows;

  /// Optional contextual data (meal markers, carbs, medication) associated with this record.
  final GlsMeasurementContext? context;

  /// Creates an immutable [GlsRecord].
  const GlsRecord({
    required this.sequenceNumber,
    required this.timestamp,
    this.concentration,
    this.isMolPerLiter = false,
    this.sampleType,
    this.sampleLocation,
    this.sensorStatus,
    this.contextInformationFollows = false,
    this.context,
  });

  /// Converts the concentration to whole integer mg/dL.
  ///
  /// For mol/L values, applies the standard molar mass conversion factor (1 mmol/L ≈ 18.0182 mg/dL).
  /// For kg/L values, multiplies by 100,000 (1 kg/L = 100,000 mg/dL).
  int? get concentrationMgDl {
    final val = concentration;
    if (val == null) return null;
    if (isMolPerLiter) {
      // val is in mol/L -> multiply by 1000 to get mmol/L, then by 18.0182
      return (val * 18018.2).round();
    }
    // val is in kg/L -> multiply by 100,000 to get mg/dL
    return (val * 100000.0).round();
  }

  /// Returns a copy of this record with the given fields replaced by new values.
  GlsRecord copyWith({
    int? sequenceNumber,
    DateTime? timestamp,
    double? concentration,
    bool? isMolPerLiter,
    String? sampleType,
    String? sampleLocation,
    int? sensorStatus,
    bool? contextInformationFollows,
    GlsMeasurementContext? context,
  }) {
    return GlsRecord(
      sequenceNumber: sequenceNumber ?? this.sequenceNumber,
      timestamp: timestamp ?? this.timestamp,
      concentration: concentration ?? this.concentration,
      isMolPerLiter: isMolPerLiter ?? this.isMolPerLiter,
      sampleType: sampleType ?? this.sampleType,
      sampleLocation: sampleLocation ?? this.sampleLocation,
      sensorStatus: sensorStatus ?? this.sensorStatus,
      contextInformationFollows:
          contextInformationFollows ?? this.contextInformationFollows,
      context: context ?? this.context,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GlsRecord &&
          runtimeType == other.runtimeType &&
          sequenceNumber == other.sequenceNumber &&
          timestamp == other.timestamp &&
          concentration == other.concentration &&
          isMolPerLiter == other.isMolPerLiter &&
          sampleType == other.sampleType &&
          sampleLocation == other.sampleLocation &&
          sensorStatus == other.sensorStatus &&
          contextInformationFollows == other.contextInformationFollows &&
          context == other.context;

  @override
  int get hashCode => Object.hash(
    sequenceNumber,
    timestamp,
    concentration,
    isMolPerLiter,
    sampleType,
    sampleLocation,
    sensorStatus,
    contextInformationFollows,
    context,
  );
}
