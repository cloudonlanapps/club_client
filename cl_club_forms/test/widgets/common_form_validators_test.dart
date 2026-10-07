import 'package:cl_club_forms/src/widgets/common_form_validators.dart'
    show CommonFormValidators;
import 'package:flutter_test/flutter_test.dart';

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

  group('Issue 61: CommonFormValidators.name', () {
    test('Issue 61: an empty or blank name is refused, by its label', () {
      expect(
        CommonFormValidators.name('', label: 'Group name'),
        'Group name is required',
      );
      expect(
        CommonFormValidators.name(' \t\n', label: 'Venue name'),
        'Venue name is required',
      );
    });

    test('Issue 61: a name of one character is refused, whatever the '
        'label', () {
      expect(
        CommonFormValidators.name('A', label: 'Group name'),
        'At least 2 characters',
      );
      expect(
        CommonFormValidators.name('A', label: 'Venue name'),
        'At least 2 characters',
      );
    });

    test('Issue 61: the length is counted after trimming', () {
      expect(
        CommonFormValidators.name('  A  ', label: 'Group name'),
        'At least 2 characters',
      );
    });

    test('Issue 61: two characters pass, spaces around them or between '
        'them included', () {
      expect(CommonFormValidators.name('U8', label: 'Group name'), isNull);
      expect(CommonFormValidators.name(' U8 ', label: 'Group name'), isNull);
      expect(CommonFormValidators.name('A B', label: 'Group name'), isNull);
    });
  });
}
