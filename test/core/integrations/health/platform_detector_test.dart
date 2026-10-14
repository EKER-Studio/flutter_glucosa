import 'dart:io';

import 'package:flutter_glucosa/core/integrations/health/platform_detector.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NativePlatformDetector', () {
    test('delegates isAndroid and isIOS to dart:io Platform', () {
      final detector = NativePlatformDetector();
      expect(detector.isAndroid, equals(Platform.isAndroid));
      expect(detector.isIOS, equals(Platform.isIOS));
    });
  });
}
