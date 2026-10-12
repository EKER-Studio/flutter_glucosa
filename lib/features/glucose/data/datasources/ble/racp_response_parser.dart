/// Sealed class representing a parsed response from the RACP characteristic (0x2A52).
sealed class RacpResponse {
  const RacpResponse();
}

/// Response containing the count of records matching a query.
class RacpNumberOfRecordsResponse extends RacpResponse {
  /// Total count of matching records reported by the device.
  final int count;

  /// Creates a [RacpNumberOfRecordsResponse].
  const RacpNumberOfRecordsResponse(this.count);
}

/// General procedure completion or status response from the RACP.
class RacpGeneralResponse extends RacpResponse {
  /// The original OpCode that initiated the request.
  final int requestOpCode;

  /// The result code returned by the device.
  final int responseCode;

  /// Creates a [RacpGeneralResponse].
  const RacpGeneralResponse({
    required this.requestOpCode,
    required this.responseCode,
  });

  /// Whether the operation completed successfully (code 1).
  bool get isSuccess => responseCode == 1;

  /// Whether the device reported that no records matched the criteria (code 6).
  bool get isNoRecordsFound => responseCode == 6;

  /// Whether the requested OpCode is not supported by this device (code 2).
  bool get isOpCodeNotSupported => responseCode == 2;
}

/// Parser for incoming indications from RACP (0x2A52).
abstract final class RacpResponseParser {
  /// OpCode indicating a response with the number of stored records.
  static const int opCodeNumberOfRecordsResponse = 5;

  /// OpCode indicating a general status response code.
  static const int opCodeResponseCode = 6;

  /// Parses raw byte data from RACP indication into a [RacpResponse].
  ///
  /// Returns `null` if the data is shorter than required or unrecognized.
  static RacpResponse? parse(List<int> data) {
    if (data.length < 3) return null;

    final opCode = data[0];

    if (opCode == opCodeNumberOfRecordsResponse) {
      if (data.length < 4) return null;
      final count = data[2] | (data[3] << 8);
      return RacpNumberOfRecordsResponse(count);
    }

    if (opCode == opCodeResponseCode) {
      if (data.length < 4) return null;
      final requestOpCode = data[2];
      final responseCode = data[3];
      return RacpGeneralResponse(
        requestOpCode: requestOpCode,
        responseCode: responseCode,
      );
    }

    return null;
  }
}
