import 'package:flutter/foundation.dart';
import 'package:flutter_glucosa/features/settings/data/services/license_registry_source.dart';
import 'package:flutter_test/flutter_test.dart';

class _TestLicenseEntry extends LicenseEntry {
  @override
  final List<String> packages;

  @override
  final List<LicenseParagraph> paragraphs;

  _TestLicenseEntry(this.packages, this.paragraphs);
}

void main() {
  test(
    'LicenseRegistrySource.watchLicenses yields LicenseEntryData from LicenseRegistry',
    () async {
      LicenseRegistry.addLicense(
        () => Stream<LicenseEntry>.fromIterable([
          _TestLicenseEntry(
            ['audit_test_pkg'],
            [const LicenseParagraph('Audit test license paragraph', 0)],
          ),
        ]),
      );

      final entries = await LicenseRegistrySource.watchLicenses().toList();
      final matched = entries.firstWhere(
        (e) => e.packages.contains('audit_test_pkg'),
      );

      expect(matched.packages, contains('audit_test_pkg'));
      expect(matched.paragraphTexts, contains('Audit test license paragraph'));
    },
  );
}
