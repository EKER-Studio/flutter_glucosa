/// Builder for Bluetooth Record Access Control Point (RACP 0x2A52) request commands.
abstract final class RacpCommandBuilder {
  /// OpCode to report stored records.
  static const int opCodeReportStoredRecords = 1;

  /// OpCode to delete stored records.
  static const int opCodeDeleteStoredRecords = 2;

  /// OpCode to abort in-progress operation.
  static const int opCodeAbortOperation = 3;

  /// OpCode to report number of stored records.
  static const int opCodeReportNumberOfRecords = 4;

  /// Operator matching all records.
  static const int operatorAllRecords = 1;

  /// Operator matching records less than or equal to threshold.
  static const int operatorLessThanOrEqualTo = 2;

  /// Operator matching records greater than or equal to threshold.
  static const int operatorGreaterThanOrEqualTo = 3;

  /// Operator matching first (oldest) stored record.
  static const int operatorFirstRecord = 5;

  /// Operator matching last (most recent) stored record.
  static const int operatorLastRecord = 6;

  /// Filter operand type specifying sequence number.
  static const int filterTypeSequenceNumber = 1;

  /// Creates command requesting the total number of all stored records.
  static List<int> reportNumberOfAllStoredRecords() {
    return [opCodeReportNumberOfRecords, operatorAllRecords];
  }

  /// Creates command requesting all stored records.
  static List<int> reportAllStoredRecords() {
    return [opCodeReportStoredRecords, operatorAllRecords];
  }

  /// Creates command requesting the oldest (first) stored record.
  static List<int> reportFirstStoredRecord() {
    return [opCodeReportStoredRecords, operatorFirstRecord];
  }

  /// Creates command requesting the most recent (last) stored record.
  static List<int> reportLastStoredRecord() {
    return [opCodeReportStoredRecords, operatorLastRecord];
  }

  /// Creates command requesting stored records with sequence number greater than or equal to [sequenceNumber].
  static List<int> reportStoredRecordsGreaterThanOrEqualTo(int sequenceNumber) {
    return [
      opCodeReportStoredRecords,
      operatorGreaterThanOrEqualTo,
      filterTypeSequenceNumber,
      sequenceNumber & 0xFF,
      (sequenceNumber >> 8) & 0xFF,
    ];
  }

  /// Creates command to abort current in-flight RACP procedure.
  static List<int> abortOperation() {
    return [opCodeAbortOperation, 0];
  }
}
