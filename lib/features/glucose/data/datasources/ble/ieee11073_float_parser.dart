import 'dart:math' as math;

/// Parser for IEEE-11073 16-bit SFLOAT format used in Bluetooth medical profiles.
///
/// An SFLOAT consists of a 4-bit signed exponent (base 10) and a 12-bit signed
/// mantissa, encoded in little-endian byte order.
abstract final class Ieee11073FloatParser {
  static const int _nanMantissa = 0x07FF;
  static const int _nresMantissa = 0x0800;
  static const int _plusInfinityMantissa = 0x07FE;
  static const int _minusInfinityMantissa = 0x0802;
  static const int _reservedMantissa = 0x0801;

  /// Decodes a 16-bit IEEE-11073 SFLOAT starting at [offset] in [data].
  ///
  /// Returns `null` if [data] does not have at least 2 bytes from [offset],
  /// or if the value represents NRes or Reserved.
  static double? parseSFloat(List<int> data, int offset) {
    if (offset + 1 >= data.length) return null;

    final raw = data[offset] | (data[offset + 1] << 8);
    final unsignedMantissa = raw & 0x0FFF;

    if (unsignedMantissa == _nanMantissa) return double.nan;
    if (unsignedMantissa == _plusInfinityMantissa) return double.infinity;
    if (unsignedMantissa == _minusInfinityMantissa) {
      return double.negativeInfinity;
    }
    if (unsignedMantissa == _nresMantissa ||
        unsignedMantissa == _reservedMantissa) {
      return null;
    }

    // Sign extension for 12-bit signed mantissa
    var mantissa = unsignedMantissa;
    if ((mantissa & 0x0800) != 0) {
      mantissa -= 0x1000;
    }

    // Sign extension for 4-bit signed exponent
    var exponent = (raw >> 12) & 0x0F;
    if ((exponent & 0x08) != 0) {
      exponent -= 0x10;
    }

    return mantissa * math.pow(10, exponent).toDouble();
  }
}
