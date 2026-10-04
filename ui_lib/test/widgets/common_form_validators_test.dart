import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lib/ui_lib.dart' show CommonFormValidators;

void main() {
  group('CommonFormValidators.name', () {
    test('Issue 676: shared rule — required and at least 2 characters', () {
      expect(CommonFormValidators.name('', label: 'Group name'), isNotNull);
      expect(CommonFormValidators.name('   ', label: 'Group name'), isNotNull);
      expect(CommonFormValidators.name('A', label: 'Group name'), isNotNull);
      expect(CommonFormValidators.name('U8', label: 'Group name'), isNull);
    });

    test('Issue 676: label prefixes the required message', () {
      expect(
        CommonFormValidators.name('', label: 'Venue name'),
        'Venue name is required',
      );
      expect(
        CommonFormValidators.name('', label: 'Event name'),
        'Event name is required',
      );
    });
  });
}
