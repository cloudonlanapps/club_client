// Issue 61, SignupForm. Every point applies. The in-form action is the
// username field's "Check availability"; the form has no other button.
// The username's own rules beyond "required" and "at least 3" cannot be
// broken by typing (the field drops what they refuse): they are covered in
// user_form_validators_test.dart and username_availability_field_test.dart.
import 'package:cl_club_forms/cl_club_forms.dart';
import 'package:cl_club_forms/src/widgets/user_form/user_form_validators.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/account_user_form_harness.dart';
import '../../support/form_harness.dart';

const String _username = UserFormFields.usernameId;
const String _password = UserFormFields.passwordId;
const String _confirm = UserFormFields.confirmPasswordId;
const String _first = UserFormFields.firstNameId;
const String _middle = UserFormFields.middleNameId;
const String _last = UserFormFields.lastNameId;
const String _gender = UserFormFields.genderId;
const String _dob = UserFormFields.dateOfBirthUtcId;
const String _phone = UserFormFields.phoneId;
const String _email = UserFormFields.emailId;

const _noName = 'First name or last name is required';

/// What a member reapplying is shown from their earlier application.
Map<String, dynamic> _earlier() => {
  _first: 'Robin',
  _middle: 'K',
  _last: 'Rao',
  _gender: SignupGender.other,
  _dob: DateTime.utc(2010, 3, 4),
  _phone: '9876543210',
  _email: 'robin@example.test',
};

Future<SignupFormState> _pump(
  WidgetTester tester, {
  String? username,
  Map<String, dynamic>? initialValues,
  bool enabled = true,
  bool available = true,
  ValueChanged<bool>? onCanSubmitChanged,
  Size size = kFormSurface,
}) async {
  final key = GlobalKey<SignupFormState>();
  await pumpForm(
    tester,
    SignupForm(
      defaultCountryCode: '91',
      key: key,
      username: username,
      initialValues: initialValues,
      enabled: enabled,
      onCheckUsernameAvailable: (_) async => available,
      onCanSubmitChanged: onCanSubmitChanged,
    ),
    size: size,
  );
  return key.currentState!;
}

/// Fills a signing-up form with valid values, the username confirmed.
Future<void> _fill(WidgetTester tester, SignupFormState state) async {
  await checkUsername(tester, _username, 'robin');
  await enterField(tester, _password, 'secret-password');
  await enterField(tester, _confirm, 'secret-password');
  await enterField(tester, _first, 'Robin');
  await enterField(tester, _phone, '9876543210');
  await enterField(tester, _email, 'robin@example.test');
  await setField(tester, state, _gender, SignupGender.female);
  await setField(tester, state, _dob, DateTime(2010, 3, 4));
}

void main() {
  group('Issue 61: SignupForm, its fields', () {
    testWidgets('Issue 61: signing up, it shows ten fields in order, each '
        'in a row, all required but the middle name', (tester) async {
      await _pump(tester);
      await enterField(tester, _username, 'robin');

      expect(rowLabels(tester), [
        'Username *',
        'Password *',
        'Confirm password *',
        'First name *',
        'Middle name',
        'Last name *',
        'Gender *',
        'Date of birth *',
        'Phone *',
        'Email *',
      ]);
      expect(fieldIds(tester), UserFormFields.signupIds);
      expectLabelsAreRows(tester);
      expectNoHostChrome(tester, allowedButtonTexts: {'Check availability'});
    });

    testWidgets('Issue 61: reapplying, the username is a read-only row and '
        'the username and password fields are gone', (tester) async {
      await _pump(tester, username: 'robin', initialValues: _earlier());

      expect(rowLabels(tester), [
        'Username',
        'First name *',
        'Middle name',
        'Last name *',
        'Gender *',
        'Date of birth *',
        'Phone *',
        'Email *',
      ]);
      expect(fieldIds(tester), [
        _first,
        _middle,
        _last,
        _gender,
        _dob,
        _phone,
        _email,
      ]);
      expect(find.text('robin'), findsOneWidget);
      expect(checkAvailabilityButton, findsNothing);
      expectLabelsAreRows(tester);
      expectNoHostChrome(tester);
    });

    testWidgets('Issue 61: the date of birth offers the last hundred years '
        'and none ahead', (tester) async {
      expect(SignupForm.dateOfBirthYearsBefore, 100);
      expect(SignupForm.dateOfBirthYearsAfter, 0);
    });
  });

  group('Issue 61: SignupForm, each field rule', () {
    /// A rule broken on an otherwise valid form: the field, what is typed
    /// (or set), and the message.
    final cases =
        <
          ({
            String rule,
            String id,
            Object? value,
            String message,
            Object? fixed,
          })
        >[
          (
            rule: 'an empty username',
            id: _username,
            value: '',
            message: 'Username is required',
            fixed: null,
          ),
          (
            rule: 'a username of two characters',
            id: _username,
            value: 'ro',
            message: 'At least 3 characters',
            fixed: null,
          ),
          (
            rule: 'an empty password',
            id: _password,
            value: '',
            message: 'Password is required',
            fixed: null,
          ),
          (
            rule: 'a password of seven characters',
            id: _password,
            value: '1234567',
            message: 'At least 8 characters',
            fixed: null,
          ),
          (
            rule: 'an empty confirmation',
            id: _confirm,
            value: '',
            message: UserFormValidators.confirmPasswordRequired,
            fixed: 'secret-password',
          ),
          (
            rule: 'no gender',
            id: _gender,
            value: null,
            message: 'Gender is required',
            fixed: SignupGender.male,
          ),
          (
            rule: 'no date of birth',
            id: _dob,
            value: null,
            message: 'Date of birth is required',
            fixed: DateTime(2011, 5, 6),
          ),
          (
            rule: 'an empty phone',
            id: _phone,
            value: '',
            message: 'Phone number is required',
            fixed: '9876543210',
          ),
          (
            rule: 'a phone of nine characters',
            id: _phone,
            value: '987654321',
            message: 'Enter a valid phone number',
            fixed: '9876543210',
          ),
          (
            rule: 'an empty email',
            id: _email,
            value: '',
            message: 'Email is required',
            fixed: 'robin@example.test',
          ),
          (
            rule: 'an email without @',
            id: _email,
            value: 'robin.example.test',
            message: 'Enter a valid email',
            fixed: 'robin@example.test',
          ),
        ];

    for (final c in cases) {
      testWidgets('Issue 61: ${c.rule} is refused on its field', (
        tester,
      ) async {
        final state = await _pump(tester);
        await _fill(tester, state);
        expect(state.validate(), isNotNull, reason: 'valid before the break');

        Future<void> put(Object? value) async {
          if (value is String) {
            await enterField(tester, c.id, value);
          } else {
            await setField(tester, state, c.id, value);
          }
        }

        await put(c.value);
        expect(state.validate(), isNull);
        await tester.pumpAndSettle();
        expectMessageOn(c.id, c.message);

        // Where putting the field right needs nothing else (no new
        // availability check, no second password), the form is valid again.
        if (c.fixed != null) {
          await put(c.fixed);
          expect(state.validate(), isNotNull);
          await tester.pumpAndSettle();
          expect(find.text(c.message), findsNothing);
        }
      });
    }

    testWidgets('Issue 61: a password of eight characters is taken', (
      tester,
    ) async {
      final state = await _pump(tester);
      await _fill(tester, state);
      await enterField(tester, _password, '12345678');
      await enterField(tester, _confirm, '12345678');

      expect(state.validate()![_password], '12345678');
    });
  });

  group('Issue 61: SignupForm, rules across fields', () {
    testWidgets('Issue 61: neither first nor last name is refused inline, '
        'and a last name alone is enough', (tester) async {
      final state = await _pump(tester);
      await _fill(tester, state);
      await enterField(tester, _first, '   ');
      await enterField(tester, _middle, 'K');

      expect(state.validate(), isNull);
      await tester.pumpAndSettle();
      expectInlineMessage(_noName);

      await enterField(tester, _last, 'Rao');
      final values = state.validate();
      await tester.pumpAndSettle();
      expect(find.text(_noName), findsNothing);
      expect(values![_first], isNull);
      expect(values[_last], 'Rao');
    });

    testWidgets('Issue 61: reapplying, a missing name is refused inline and '
        'no password or availability rule applies', (tester) async {
      final state = await _pump(
        tester,
        username: 'robin',
        initialValues: _earlier(),
      );
      await enterField(tester, _first, '');
      await enterField(tester, _last, '');

      expect(state.validate(), isNull);
      await tester.pumpAndSettle();
      expectInlineMessage(_noName);

      await enterField(tester, _first, 'Robin');
      expect(state.validate(), isNotNull);
      await tester.pumpAndSettle();
      expect(find.text(_noName), findsNothing);
      expect(find.text(UserFormValidators.passwordsDiffer), findsNothing);
      expect(
        find.text(UserFormValidators.availabilityCheckRequired),
        findsNothing,
      );
    });

    testWidgets('Issue 61: passwords that differ are refused inline and '
        'taken once they are the same', (tester) async {
      final state = await _pump(tester);
      await _fill(tester, state);
      await enterField(tester, _confirm, 'secret-passworD');

      expect(state.validate(), isNull);
      await tester.pumpAndSettle();
      expectInlineMessage(UserFormValidators.passwordsDiffer);

      await enterField(tester, _confirm, 'secret-password');
      expect(state.validate(), isNotNull);
      await tester.pumpAndSettle();
      expect(find.text(UserFormValidators.passwordsDiffer), findsNothing);
    });

    testWidgets('Issue 61: a username found taken keeps the form refused '
        'inline', (tester) async {
      final reported = <bool>[];
      final state = await _pump(
        tester,
        available: false,
        onCanSubmitChanged: reported.add,
      );
      await _fill(tester, state);

      expect(find.text('Already taken'), findsOneWidget);
      expect(state.canSubmit, isFalse);
      expect(reported, [false]);
      expect(state.validate(), isNull);
      await tester.pumpAndSettle();
      expectInlineMessage(UserFormValidators.availabilityCheckRequired);
    });

    testWidgets('Issue 61: the availability refusal goes as soon as the '
        'username is checked, and the form is then valid', (tester) async {
      final state = await _pump(tester);
      await _fill(tester, state);
      await enterField(tester, _username, 'robin2');
      expect(state.validate(), isNull);
      await tester.pumpAndSettle();
      expectInlineMessage(UserFormValidators.availabilityCheckRequired);

      await tester.tap(checkAvailabilityButton);
      await tester.pumpAndSettle();

      expect(
        find.text(UserFormValidators.availabilityCheckRequired),
        findsNothing,
      );
      expect(state.validate()![_username], 'robin2');
    });

    testWidgets('Issue 61: canSubmit is told false, true once the username '
        'is confirmed, and false again when it is edited', (tester) async {
      final reported = <bool>[];
      final state = await _pump(tester, onCanSubmitChanged: reported.add);
      expect(reported, [false]);

      await checkUsername(tester, _username, 'robin');
      expect(reported, [false, true]);

      await enterField(tester, _username, 'robin2');
      expect(reported, [false, true, false]);
      expect(state.canSubmit, isFalse);
    });

    testWidgets('Issue 61: a missing name is reported before the username '
        'and the passwords', (tester) async {
      final state = await _pump(tester);
      await _fill(tester, state);
      await enterField(tester, _first, '');
      await enterField(tester, _confirm, 'something-else');
      await enterField(tester, _username, 'robin2');

      expect(state.validate(), isNull);
      await tester.pumpAndSettle();

      expectInlineMessage(_noName);
      expect(find.text(UserFormValidators.passwordsDiffer), findsNothing);
    });
  });

  group('Issue 61: SignupForm, its values', () {
    testWidgets('Issue 61: signing up, validate returns exactly the nine '
        'documented keys, trimmed, with their types', (tester) async {
      final state = await _pump(tester);
      await _fill(tester, state);
      await enterField(tester, _password, ' secret password ');
      await enterField(tester, _confirm, ' secret password ');
      await enterField(tester, _first, '  Robin ');
      await enterField(tester, _middle, ' K ');
      await enterField(tester, _last, ' Rao  ');
      await enterField(tester, _phone, ' 9876543210 ');
      await enterField(tester, _email, ' robin@example.test ');
      await setField(tester, state, _dob, DateTime(2010, 3, 4, 23, 59));

      final values = state.validate();

      expect(values, {
        _username: 'robin',
        _password: ' secret password ',
        _email: 'robin@example.test',
        _phone: '9876543210',
        _first: 'Robin',
        _middle: 'K',
        _last: 'Rao',
        _dob: DateTime.utc(2010, 3, 4),
        _gender: SignupGender.female,
      });
      expect(values!.containsKey(_confirm), isFalse);
      expect(values[_dob], isA<DateTime>());
      expect((values[_dob] as DateTime).isUtc, isTrue);
      expect(values[_gender], isA<SignupGender>());
    });

    testWidgets('Issue 61: an optional name left empty, or of spaces, comes '
        'back null', (tester) async {
      final state = await _pump(tester);
      await _fill(tester, state);
      await enterField(tester, _middle, '   ');

      final values = state.validate()!;

      expect(values.containsKey(_middle), isTrue);
      expect(values[_middle], isNull);
      expect(values.containsKey(_last), isTrue);
      expect(values[_last], isNull);
    });

    testWidgets('Issue 61: reapplying, the seeded values come back '
        'unchanged, under exactly seven keys', (tester) async {
      final state = await _pump(
        tester,
        username: 'robin',
        initialValues: _earlier(),
      );

      expect(state.isDirty, isFalse);
      expect(state.validate(), _earlier());
    });

    testWidgets('Issue 61: the gender is picked from its four options', (
      tester,
    ) async {
      final state = await _pump(tester);
      await _fill(tester, state);

      await tapSelect(tester, _gender);
      for (final option in SignupGender.values) {
        expect(find.text(option.label), findsWidgets, reason: option.name);
      }
      await tester.tap(find.text('Prefer not to say').last);
      await tester.pumpAndSettle();

      expect(state.validate()![_gender], SignupGender.preferNotToSay);
    });
  });

  group('Issue 61: SignupForm, dirty check', () {
    testWidgets('Issue 61: signing up, isDirty follows the username, a '
        'password and a name, and each undone', (tester) async {
      final state = await _pump(tester);
      expect(state.isDirty, isFalse);

      for (final id in [_username, _password, _confirm, _first, _phone]) {
        await enterField(tester, id, 'abc');
        expect(state.isDirty, isTrue, reason: id);
        await enterField(tester, id, '');
        expect(state.isDirty, isFalse, reason: id);
      }
    });

    testWidgets('Issue 61: isDirty follows the gender select, and is false '
        'again when the first choice is picked back', (tester) async {
      final state = await _pump(
        tester,
        username: 'robin',
        initialValues: _earlier(),
      );
      expect(state.isDirty, isFalse);

      await pickOption(tester, _gender, 'Male');
      expect(heldValue(state, _gender), SignupGender.male);
      expect(state.isDirty, isTrue);

      await pickOption(tester, _gender, 'Other');
      expect(state.isDirty, isFalse);
    });

    testWidgets('Issue 61: isDirty follows the date of birth, and is false '
        'again when the first date is put back', (tester) async {
      final state = await _pump(
        tester,
        username: 'robin',
        initialValues: _earlier(),
      );

      await setField(tester, state, _dob, DateTime.utc(2011, 5, 6));
      expect(state.isDirty, isTrue);

      await setField(tester, state, _dob, DateTime.utc(2010, 3, 4));
      expect(state.isDirty, isFalse);
    });

    testWidgets('Issue 61: reapplying, isDirty follows a seeded text and is '
        'false again when it is retyped as it was', (tester) async {
      final state = await _pump(
        tester,
        username: 'robin',
        initialValues: _earlier(),
      );

      await enterField(tester, _email, 'robin@example.org');
      expect(state.isDirty, isTrue);

      await enterField(tester, _email, 'robin@example.test');
      expect(state.isDirty, isFalse);
    });
  });

  group('Issue 61: SignupForm, server errors', () {
    testWidgets('Issue 61: a refusal shows on the email and inline, and the '
        'form submits again afterwards', (tester) async {
      final state = await _pump(tester);
      await _fill(tester, state);

      await expectShowsServerErrors(tester, state, _email);

      state.showErrors(
        fieldErrors: const {_email: 'That email is already registered.'},
        formError: 'Could not create the account.',
      );
      await tester.pumpAndSettle();
      expectMessageOn(_email, 'That email is already registered.');
      expectInlineMessage('Could not create the account.');

      await enterField(tester, _email, 'robin@example.org');
      expect(state.validate()![_email], 'robin@example.org');
      await tester.pumpAndSettle();
      expect(find.text('That email is already registered.'), findsNothing);
      expect(find.text('Could not create the account.'), findsNothing);
    });

    testWidgets('Issue 61: a refused username shows on the username field', (
      tester,
    ) async {
      final state = await _pump(tester);
      await _fill(tester, state);

      state.showErrors(fieldErrors: const {_username: 'Just taken.'});
      await tester.pumpAndSettle();

      expectMessageOn(_username, 'Just taken.');
    });

    testWidgets('Issue 61: reapplying, a refusal for the absent username '
        'field shows inline', (tester) async {
      final state = await _pump(
        tester,
        username: 'robin',
        initialValues: _earlier(),
      );

      state.showErrors(fieldErrors: const {_username: 'No such member.'});
      await tester.pumpAndSettle();

      expectInlineMessage('No such member.');
    });
  });

  group('Issue 61: SignupForm, disabled and narrow', () {
    testWidgets('Issue 61: with enabled off no field takes a tap, the '
        'gender does not open and nothing changes', (tester) async {
      final state = await _pump(
        tester,
        username: 'robin',
        initialValues: _earlier(),
        enabled: false,
      );

      expectEveryFieldOff(tester);
      await expectTapsIgnored(tester, [_first, _middle, _last, _phone, _email]);
      await tapSelect(tester, _gender);
      expect(find.text('Male'), findsNothing);
      await tester.tap(fieldWithId(_dob), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(state.isDirty, isFalse);
      expect(state.validate(), _earlier());
    });

    testWidgets('Issue 61: signing up with enabled off, the username and '
        'the passwords are off too', (tester) async {
      await _pump(tester, enabled: false);

      expectEveryFieldOff(tester);
      expect(fieldIds(tester), UserFormFields.signupIds);
      await expectTapsIgnored(tester, [_password, _confirm]);
    });

    testWidgets('Issue 61: with enabled on a tap opens the gender', (
      tester,
    ) async {
      await _pump(tester);

      await tapSelect(tester, _gender);

      expect(find.text('Male'), findsOneWidget);
    });

    testWidgets('Issue 61: signing up, it fits a phone, empty and with '
        'every message and the check row showing', (tester) async {
      final state = await _pump(tester, size: kPhoneSurface);
      expect(tester.takeException(), isNull);

      await enterField(tester, _username, 'ro');
      expect(state.validate(), isNull);
      await tester.pumpAndSettle();
      expect(find.text('Gender is required'), findsOneWidget);
      expect(find.text('Date of birth is required'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await checkUsername(tester, _username, 'a_long_username_on_a_phone');
      expect(find.text('Available'), findsOneWidget);
      expect(state.validate(), isNull);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('Issue 61: reapplying, it fits a phone with its values', (
      tester,
    ) async {
      await _pump(
        tester,
        username: 'robin',
        initialValues: {..._earlier(), _gender: SignupGender.preferNotToSay},
        size: kPhoneSurface,
      );

      expect(find.text('Prefer not to say'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
