import '../../../domain/entities/gls_record.dart';
import 'ieee11073_float_parser.dart';

/// Parser for Bluetooth Glucose Measurement characteristic (0x2A18) data packets.
///
/// Complies with Bluetooth SIG Glucose Service Specification v1.0.
abstract final class GlsMeasurementParser {
  static const Map<int, String> _sampleTypes = {
    1: 'Capillary Whole Blood',
    2: 'Capillary Plasma',
    3: 'Venous Whole Blood',
    4: 'Venous Plasma',
    5: 'Arterial Whole Blood',
    6: 'Arterial Plasma',
    7: 'Undetermined Whole Blood',
    8: 'Undetermined Plasma',
    9: 'Interstitial Fluid',
    10: 'Control Solution',
  };

  static const Map<int, String> _sampleLocations = {
    1: 'Finger',
    2: 'Alternate Site Test (AST)',
    3: 'Earlobe',
    4: 'Control Solution',
    15: 'Not Available',
  };

  /// Parses raw byte data received from characteristic 0x2A18 into a [GlsRecord].
  ///
  /// Returns `null` if the data is shorter than required or malformed.
  static GlsRecord? parse(List<int> data) {
    if (data.length < 10) return null;

    var offset = 0;
    final flags = data[offset++];

    final timeOffsetPresent = (flags & 0x01) != 0;
    final glucoseDataPresent = (flags & 0x02) != 0;
    final unitMolPerL = (flags & 0x04) != 0;
    final sensorStatusPresent = (flags & 0x08) != 0;
    final contextFollows = (flags & 0x10) != 0;

    final expectedMinLength =
        10 +
        (timeOffsetPresent ? 2 : 0) +
        (glucoseDataPresent ? 3 : 0) +
        (sensorStatusPresent ? 2 : 0);

    if (data.length < expectedMinLength) return null;

    // Sequence Number (UINT16, Little Endian)
    final sequenceNumber = data[offset] | (data[offset + 1] << 8);
    offset += 2;

    // Base Time (7 bytes)
    final year = data[offset] | (data[offset + 1] << 8);
    final month = data[offset + 2];
    final day = data[offset + 3];
    final hour = data[offset + 4];
    final minute = data[offset + 5];
    final second = data[offset + 6];
    offset += 7;

    if (year < 1900 ||
        month < 1 ||
        month > 12 ||
        day < 1 ||
        day > 31 ||
        hour > 23 ||
        minute > 59 ||
        second > 59) {
      return null;
    }

    var timestamp = DateTime(year, month, day, hour, minute, second);

    // Optional Time Offset (INT16, Little Endian)
    if (timeOffsetPresent) {
      var rawOffset = data[offset] | (data[offset + 1] << 8);
      if ((rawOffset & 0x8000) != 0) {
        rawOffset -= 0x10000;
      }
      offset += 2;
      timestamp = timestamp.add(Duration(minutes: rawOffset));
    }

    // Optional Glucose Concentration and Type/Location
    double? concentration;
    String? sampleType;
    String? sampleLocation;

    if (glucoseDataPresent) {
      concentration = Ieee11073FloatParser.parseSFloat(data, offset);
      offset += 2;

      final typeAndLocation = data[offset++];
      final typeId = typeAndLocation & 0x0F;
      final locationId = (typeAndLocation >> 4) & 0x0F;

      sampleType = _sampleTypes[typeId];
      sampleLocation = _sampleLocations[locationId];
    }

    // Optional Sensor Status Annunciation (UINT16, Little Endian)
    int? sensorStatus;
    if (sensorStatusPresent) {
      sensorStatus = data[offset] | (data[offset + 1] << 8);
      offset += 2;
    }

    return GlsRecord(
      sequenceNumber: sequenceNumber,
      timestamp: timestamp,
      concentration: concentration,
      isMolPerLiter: unitMolPerL,
      sampleType: sampleType,
      sampleLocation: sampleLocation,
      sensorStatus: sensorStatus,
      contextInformationFollows: contextFollows,
    );
  }
}
