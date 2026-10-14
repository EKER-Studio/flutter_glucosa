import 'package:flutter_glucosa/features/glucose/domain/csv_error_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CsvErrorType', () {
    test('contains all expected enum values and supports name lookup', () {
      expect(
        CsvErrorType.values,
        containsAll([
          CsvErrorType.fileTooLarge,
          CsvErrorType.invalidFormat,
          CsvErrorType.noEntries,
        ]),
      );
      for (final value in CsvErrorType.values) {
        expect(CsvErrorType.values.byName(value.name), equals(value));
      }
    });
  });
}
