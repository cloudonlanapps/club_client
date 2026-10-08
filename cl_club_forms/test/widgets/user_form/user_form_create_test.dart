// Issue 61, UserForm, which creates a user.
// Every point applies. The in-form actions are the username field's
// "Check availability" and "Show" beside the default-password tick.
// The form's values are its fields as typed: nothing is trimmed here (the
// host's adapter does), so "trimmed" is tested as "comes back as typed".
import 'package:cl_club_forms/cl_club_forms.dart';
import 'package:cl_club_forms/src/widgets/user_form/user_form_validators.dart';
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
  group('Issue 61: UserForm creating, its fields', () {
    testWidgets('Issue 61: it shows the username, the default-password '
        'tick, names, gender, date of birth, phone and email; no password, '
        'no role and nothing of the edit form', (tester) async {
      await pumpCreate(tester);
      await enterField(tester, _username, 'robin');

      expect(rowLabels(tester), createRows);
      expect(fieldIds(tester), createIds);
      expect(find.text('Use default password'), findsOneWidget);
      expect(find.text('Roles'), findsNothing);
      expect(find.text('Nickname'), findsNothing);
      expect(find.text('Address'), findsNothing);
      expect(find.text('Show name publicly'), findsNothing);
      expectLabelsAreRows(tester);
      expectNoHostChrome(tester, allowedButtonTexts: {'Check availability'});
    });

    testWidgets('Issue 61: unticking the default password shows the '
        'password and its confirmation after the tick, and ticking it '
        'hides them again', (tester) async {
      await pumpCreate(tester);

      await tapCheckbox(tester, _useDefault);
      expect(rowLabels(tester), [
        'Username *',
        'Password *',
        'Confirm password *',
        ...createRows.skip(1),
      ]);
      expect(fieldIds(tester), [
        _username,
        _useDefault,
        _password,
        _confirm,
        ...createIds.skip(2),
      ]);

      await tapCheckbox(tester, _useDefault);
      expect(rowLabels(tester), createRows);
      expect(fieldIds(tester), createIds);
    });

    testWidgets('Issue 61: Show is offered only when the host can show the '
        'default password, calls it, and goes when the tick is off', (
      tester,
    ) async {
      await pumpCreate(tester);
      expect(showButton, findsNothing);

      var shown = 0;
      await pumpCreate(tester, onShowDefaultPassword: () => shown++);
      expect(showButton, findsOneWidget);
      await tester.tap(showButton);
      await tester.pumpAndSettle();
      expect(shown, 1);
      expectNoHostChrome(tester, allowedButtonTexts: {'Show'});

      await tapCheckbox(tester, _useDefault);
      expect(showButton, findsNothing);
    });

    for (final (admin, coach) in [
      (false, false),
      (true, false),
      (false, true),
      (true, true),
    ]) {
      testWidgets('Issue 61: with canAssignAdmin $admin and canAssignCoach '
          '$coach it shows just those role ticks', (tester) async {
        await pumpCreate(tester, canAssignAdmin: admin, canAssignCoach: coach);

        expect(fieldIds(tester), [
          ...createIds,
          if (admin) _admin,
          if (coach) _coach,
        ]);
        expect(rowLabels(tester), [...createRows, if (admin || coach) 'Roles']);
        expect(
          find.text('Make this user an Admin'),
          admin ? findsOneWidget : findsNothing,
        );
        expect(
          find.text('This user is a coach'),
          coach ? findsOneWidget : findsNothing,
        );
      });
    }

    testWidgets('Issue 61: gender and date of birth are fields whatever '
        'the canEdit flags say, and there is no public-name tick', (
      tester,
    ) async {
      await pumpCreate(tester);
      expect(fieldIds(tester), containsAll([_gender, _dob]));
      expect(fieldIds(tester), createIds);
      expect(rowLabels(tester), createRows);
    });

    testWidgets('Issue 61: it opens on the username, not the first name', (
      tester,
    ) async {
      await pumpCreate(tester);

      expect(hasFocus(tester, _username), isTrue);
      expect(hasFocus(tester, _first), isFalse);
    });
  });

  group('Issue 61: UserForm creating, each field rule', () {
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
        final state = await pumpCreate(tester);
        await fillCreate(tester, state);
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

        if (c.fixed != null) {
          await put(c.fixed);
          expect(state.validate(), isNotNull);
          await tester.pumpAndSettle();
          expect(find.text(c.message), findsNothing);
        }
      });
    }

    testWidgets('Issue 61: with its own password, an empty password and an '
        'empty confirmation are refused, each on its field', (tester) async {
      final state = await pumpCreate(tester);
      await fillCreate(tester, state);
      await tapCheckbox(tester, _useDefault);

      expect(state.validate(), isNull);
      await tester.pumpAndSettle();

      expectMessageOn(_password, 'Password is required');
      expectMessageOn(_confirm, UserFormValidators.confirmPasswordRequired);
    });

    testWidgets('Issue 61: with its own password, seven characters are '
        'refused on the field and eight are taken', (tester) async {
      final state = await pumpCreate(tester);
      await fillCreate(tester, state);
      await typeOwnPassword(tester, password: '1234567');

      expect(state.validate(), isNull);
      await tester.pumpAndSettle();
      expectMessageOn(_password, 'At least 8 characters');

      await enterField(tester, _password, '12345678');
      await enterField(tester, _confirm, '12345678');
      expect(state.validate()![_password], '12345678');
    });

    testWidgets('Issue 61: with the default password no password is asked '
        'for', (tester) async {
      final state = await pumpCreate(tester);
      await fillCreate(tester, state);

      final values = state.validate();

      expect(values, isNotNull);
      expect(values![_useDefault], isTrue);
      expect(values[_password], '');
    });
  });

  group('Issue 61: UserForm creating, rules across fields', () {
    testWidgets('Issue 61: a username found taken keeps the form refused '
        'inline and canSubmit false', (tester) async {
      final reported = <bool>[];
      final state = await pumpCreate(
        tester,
        available: false,
        onCanSubmitChanged: reported.add,
      );
      await fillCreate(tester, state);

      expect(find.text('Already taken'), findsOneWidget);
      expect(reported, [false]);
      expect(state.validate(), isNull);
      await tester.pumpAndSettle();
      expectInlineMessage(UserFormValidators.availabilityCheckRequired);
    });

    testWidgets('Issue 61: canSubmit is told false, true once the username '
        'is confirmed, and false again when it is edited', (tester) async {
      final reported = <bool>[];
      final state = await pumpCreate(tester, onCanSubmitChanged: reported.add);
      expect(reported, [false]);

      await checkUsername(tester, _username, 'robin');
      expect(reported, [false, true]);
      expect(state.canSubmit, isTrue);

      await enterField(tester, _username, 'robin2');
      expect(reported, [false, true, false]);
    });

    testWidgets('Issue 61: its own passwords that differ are refused '
        'inline, and taken once they are the same', (tester) async {
      final state = await pumpCreate(tester);
      await fillCreate(tester, state);
      await typeOwnPassword(tester, confirm: 'secret-passworD');

      expect(state.validate(), isNull);
      await tester.pumpAndSettle();
      expectInlineMessage(UserFormValidators.passwordsDiffer);

      await enterField(tester, _confirm, 'secret-password');
      final values = state.validate();
      await tester.pumpAndSettle();
      expect(values![_password], 'secret-password');
      expect(values[_useDefault], isFalse);
      expect(find.text(UserFormValidators.passwordsDiffer), findsNothing);
    });

    testWidgets('Issue 61: neither first nor last name is refused inline, '
        'and a last name alone is enough', (tester) async {
      final state = await pumpCreate(tester);
      await fillCreate(tester, state);
      await enterField(tester, _first, '  ');
      await enterField(tester, _middle, 'K');

      expect(state.validate(), isNull);
      await tester.pumpAndSettle();
      expectInlineMessage(noNameMessage);

      await enterField(tester, _last, 'Rao');
      expect(state.validate(), isNotNull);
      await tester.pumpAndSettle();
      expect(find.text(noNameMessage), findsNothing);
    });

    testWidgets('Issue 61: the unchecked username is reported before the '
        'passwords, and the passwords before the name', (tester) async {
      final state = await pumpCreate(tester);
      await fillCreate(tester, state);
      await typeOwnPassword(tester, confirm: 'something-else');
      await enterField(tester, _first, '');
      await enterField(tester, _username, 'robin2');

      expect(state.validate(), isNull);
      await tester.pumpAndSettle();
      expectInlineMessage(UserFormValidators.availabilityCheckRequired);
      expect(find.text(UserFormValidators.passwordsDiffer), findsNothing);
      expect(find.text(noNameMessage), findsNothing);

      await tester.tap(checkAvailabilityButton);
      await tester.pumpAndSettle();
      expect(state.validate(), isNull);
      await tester.pumpAndSettle();
      expectInlineMessage(UserFormValidators.passwordsDiffer);
      expect(find.text(noNameMessage), findsNothing);

      await enterField(tester, _confirm, 'secret-password');
      expect(state.validate(), isNull);
      await tester.pumpAndSettle();
      expectInlineMessage(noNameMessage);
    });
  });
}
