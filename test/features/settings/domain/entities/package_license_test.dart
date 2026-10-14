import 'package:flutter_glucosa/features/settings/domain/entities/package_license.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PackageLicense', () {
    test('instantiates with correct fields and values', () {
      const license = PackageLicense(
        packageName: 'flutter_glucosa',
        paragraphs: ['Paragraph 1', 'Paragraph 2'],
      );

      expect(license.packageName, equals('flutter_glucosa'));
      expect(license.paragraphs, equals(['Paragraph 1', 'Paragraph 2']));
    });
  });
}
