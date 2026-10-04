import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Issue 63: the unused FooterLayout is gone', () {
    test('Issue 63: neither the file nor its barrel export remains', () {
      final barrel = File('lib/cl_club_branding.dart').readAsStringSync();
      expect(File('lib/src/widgets/footer_layout.dart').existsSync(), isFalse);
      expect(barrel, isNot(contains('footer_layout.dart')));
    });
  });
}
