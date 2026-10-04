import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Widgets removed as unused (#63): no consumer in club_core or in the apps
/// and sites built on it.
const removed = ['reason_popover.dart', 'avatar_circle.dart'];

void main() {
  group('Issue 63: unused ui_lib widgets are gone', () {
    test('Issue 63: neither the files nor their barrel exports remain', () {
      final barrel = File('lib/ui_lib.dart').readAsStringSync();
      for (final name in removed) {
        expect(File('lib/src/widgets/$name').existsSync(), isFalse);
        expect(barrel, isNot(contains("'src/widgets/$name'")));
      }
    });
  });
}
