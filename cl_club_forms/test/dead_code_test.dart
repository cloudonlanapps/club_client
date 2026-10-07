import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Issue 50: unused form code is gone', () {
    test('Issue 50: the unused weekdayNames constant is gone', () {
      final source = File(
        'lib/src/widgets/event_schedule/weekday_selector.dart',
      ).readAsStringSync();
      expect(source, isNot(contains('weekdayNames ')));
    });
  });
}
