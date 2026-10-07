// Issue 61, UserForm while it creates a user: its values, dirty check,
// server errors, enabled off and phone width. Its fields and rules are in
// user_form_create_test.dart, with the notes on what applies.
import 'package:cl_club_forms/cl_club_forms.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/account_user_form_harness.dart';
import '../../support/form_harness.dart';
import 'user_form_create_pump.dart';

const String _username = UserFormFields.usernameId;
const String _password = UserFormFields.passwordId;
const String _confirm = UserFormFields.confirmPasswordId;
const String _useDefault = UserFormFields.useDefaultPasswordId;
const String _first = UserFormFields.firstNameId;
const String _middle = UserFormFields.middleNameId;
const String _last = UserFormFields.lastNameId;
const String _gender = UserFormFields.genderId;
const String _dob = UserFormFields.dateOfBirthUtcId;
const String _phone = UserFormFields.phoneId;
const String _email = UserFormFields.emailId;
const String _admin = UserFormFields.assignAdminId;
const String _coach = UserFormFields.assignCoachId;

void main() {
  group('Issue 61: UserForm creating, its values', () {
    testWidgets('Issue 61: validate returns every id of UserForm, the '
        'fields as typed and the rest at their empty values', (tester) async {
      final state = await pumpCreate(tester, canAssignAdmin: true);
      await fillCreate(tester, state);
      await enterField(tester, _first, ' Robin ');
      await enterField(tester, _middle, 'K');
      await enterField(tester, _phone, ' 9876543210 ');

      final values = state.validate();

      expect(values, {
        ...UserFormAssembly.seed(UserFormFields.userIds, null),
        _username: 'robin',
        _first: ' Robin ',
        _middle: 'K',
        _phone: ' 9876543210 ',
        _email: 'robin@example.test',
        _gender: SignupGender.female,
        _dob: DateTime(2010, 3, 4),
      });
      expect(values!.keys.toSet(), UserFormFields.userIds.toSet());
      expect(values[_useDefault], isTrue);
      expect(values[_admin], isFalse);
      expect(values[_coach], isFalse);
      expect(values[_gender], isA<SignupGender>());
      expect(values[_dob], isA<DateTime>());
    });

    testWidgets('Issue 61: a ticked role and its own password come back in '
        'the values', (tester) async {
      final state = await pumpCreate(
        tester,
        canAssignAdmin: true,
        canAssignCoach: true,
      );
      await fillCreate(tester, state);
      await typeOwnPassword(tester);
      await tapCheckbox(tester, _coach);

      final values = state.validate()!;

      expect(values[_useDefault], isFalse);
      expect(values[_password], 'secret-password');
      expect(values[_confirm], 'secret-password');
      expect(values[_admin], isFalse);
      expect(values[_coach], isTrue);
    });

    testWidgets('Issue 61: seeded values show and come back unchanged', (
      tester,
    ) async {
      final seeded = <String, dynamic>{
        _first: 'Robin',
        _last: 'Rao',
        _phone: '9876543210',
        _email: 'robin@example.test',
        _gender: SignupGender.other,
        _dob: DateTime.utc(2010, 3, 4),
      };
      final state = await pumpCreate(tester, initialValues: seeded);
      expect(state.isDirty, isFalse);
      expect(find.text('Other'), findsOneWidget);
      expect(find.text('4 Mar 2010'), findsOneWidget);

      await checkUsername(tester, _username, 'robin');

      expect(state.validate(), {
        ...UserFormAssembly.seed(UserFormFields.userIds, seeded),
        _username: 'robin',
      });
    });
  });

  group('Issue 61: UserForm creating, dirty check', () {
    testWidgets('Issue 61: isDirty follows each text, and is false again '
        'when it is emptied', (tester) async {
      final state = await pumpCreate(tester);
      expect(state.isDirty, isFalse);

      for (final id in [_username, _first, _middle, _last, _phone, _email]) {
        await enterField(tester, id, 'abc');
        expect(state.isDirty, isTrue, reason: id);
        await enterField(tester, id, '');
        expect(state.isDirty, isFalse, reason: id);
      }
    });

    testWidgets('Issue 61: isDirty follows the default-password tick and a '
        'role tick, and is false again when each is put back', (tester) async {
      final state = await pumpCreate(tester, canAssignCoach: true);

      await tapCheckbox(tester, _useDefault);
      expect(state.isDirty, isTrue);
      await tapCheckbox(tester, _useDefault);
      expect(state.isDirty, isFalse);

      await tapCheckbox(tester, _coach);
      expect(state.isDirty, isTrue);
      await tapCheckbox(tester, _coach);
      expect(state.isDirty, isFalse);
    });

    testWidgets('Issue 61: isDirty follows the gender and the date of '
        'birth, and is false again when each is cleared', (tester) async {
      final state = await pumpCreate(tester);

      await pickOption(tester, _gender, 'Male');
      expect(heldValue(state, _gender), SignupGender.male);
      expect(state.isDirty, isTrue);
      await setField(tester, state, _gender, null);
      expect(state.isDirty, isFalse);

      await setField(tester, state, _dob, DateTime(2010, 3, 4));
      expect(state.isDirty, isTrue);
      await setField(tester, state, _dob, null);
      expect(state.isDirty, isFalse);
    });
  });

  group('Issue 61: UserForm creating, server errors, disabled, narrow', () {
    testWidgets('Issue 61: a refusal shows on the email and inline, and '
        'the form saves again afterwards', (tester) async {
      final state = await pumpCreate(tester);
      await fillCreate(tester, state);

      await expectShowsServerErrors(tester, state, _email);

      state.showErrors(
        fieldErrors: const {_email: 'That email is already registered.'},
        formError: 'Could not create the user.',
      );
      await tester.pumpAndSettle();
      expectMessageOn(_email, 'That email is already registered.');
      expectInlineMessage('Could not create the user.');

      await enterField(tester, _email, 'robin@example.org');
      expect(state.validate()![_email], 'robin@example.org');
      await tester.pumpAndSettle();
      expect(find.text('That email is already registered.'), findsNothing);
      expect(find.text('Could not create the user.'), findsNothing);
    });

    testWidgets('Issue 61: a refusal for a field that is not showing, the '
        'password under the default one, shows inline', (tester) async {
      final state = await pumpCreate(tester);

      state.showErrors(fieldErrors: const {_password: 'Too common.'});
      await tester.pumpAndSettle();

      expectInlineMessage('Too common.');
    });

    testWidgets('Issue 61: with enabled off no field, tick, select or '
        'action responds', (tester) async {
      var shown = 0;
      final state = await pumpCreate(
        tester,
        enabled: false,
        canAssignAdmin: true,
        canAssignCoach: true,
        onShowDefaultPassword: () => shown++,
      );

      expectEveryFieldOff(tester);
      await expectTapsIgnored(tester, [_first, _middle, _last, _phone, _email]);
      await tapCheckbox(tester, _useDefault);
      await tapCheckbox(tester, _admin);
      await tapCheckbox(tester, _coach);
      await tapSelect(tester, _gender);
      expect(find.text('Female'), findsNothing);
      await tester.tap(showButton, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(shown, 0);
      expect(fieldIds(tester), [...createIds, _admin, _coach]);
      expect(state.isDirty, isFalse);
    });

    testWidgets('Issue 61: it fits a phone, with roles, its own password, '
        'the check row and every message showing', (tester) async {
      final state = await pumpCreate(
        tester,
        canAssignAdmin: true,
        canAssignCoach: true,
        onShowDefaultPassword: () {},
        size: kPhoneSurface,
      );
      expect(tester.takeException(), isNull);

      await tapCheckbox(tester, _useDefault);
      await enterField(tester, _username, 'a_long_username_on_a_phone');
      expect(state.validate(), isNull);
      await tester.pumpAndSettle();

      expect(find.text('Gender is required'), findsOneWidget);
      expect(find.text('Password is required'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
