import 'package:cl_club_forms/src/widgets/rename/rename_form_validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Issue 61: RenameFormValidators.required', () {
    test('Issue 61: an empty or blank text is refused, the message naming '
        'the label', () {
      expect(
        RenameFormValidators.required('', label: 'Group Name'),
        'Group Name is required',
      );
      expect(
        RenameFormValidators.required(' \t ', label: 'Venue name'),
        'Venue name is required',
      );
    });

    test('Issue 61: any text passes, a single character included', () {
      expect(RenameFormValidators.required('A', label: 'Group Name'), isNull);
      expect(
        RenameFormValidators.required('  Seniors ', label: 'Group Name'),
        isNull,
      );
    });
  });
}
