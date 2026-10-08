// Issue 69, UserForm creates only: a user is edited section by section.
import 'dart:io';

import 'package:cl_club_forms/cl_club_forms.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/account_user_form_harness.dart';
import 'user_form_create_pump.dart';

const _userForm = 'lib/src/widgets/user_form';

void main() {
  group('Issue 69: UserForm has no edit mode', () {
    test('Issue 69: UserForm takes no read-only username and no canEdit '
        'flag', () {
      final source = File('$_userForm/user_form.dart').readAsStringSync();
      for (final gone in [
        'readOnlyUsername',
        'canEditGender',
        'canEditDateOfBirth',
        'canEditUseNamePublicly',
        'isCreate',
      ]) {
        expect(source, isNot(contains(gone)), reason: gone);
      }
    });

    test('Issue 69: the block UserForm added while editing is gone', () {
      expect(
        File('$_userForm/user_edit_only_fields.dart').existsSync(),
        isFalse,
      );
    });

    testWidgets('Issue 69: UserForm always asks for a username, gender and '
        'date of birth, and returns them', (tester) async {
      final state = await pumpCreate(tester);

      expect(state.asksForUsername, isTrue);
      expect(state.canSubmit, isFalse);
      expect(
        fieldIds(tester),
        containsAll([
          UserFormFields.usernameId,
          UserFormFields.genderId,
          UserFormFields.dateOfBirthUtcId,
        ]),
      );

      await fillCreate(tester, state);
      final values = state.validate();

      expect(values, isNotNull);
      expect(values![UserFormFields.usernameId], 'robin');
      expect(values[UserFormFields.genderId], SignupGender.female);
      expect(values[UserFormFields.dateOfBirthUtcId], DateTime(2010, 3, 4));
    });
  });
}
