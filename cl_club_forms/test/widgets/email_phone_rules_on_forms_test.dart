// Issue 71, the shared email and phone rules as each form applies them:
// every form with a phone field is given the club's country code and
// refuses what is no phone number, on the field.
import 'package:cl_club_forms/cl_club_forms.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/account_user_form_harness.dart';
import '../support/form_harness.dart';
import 'club_identity_form/club_identity_form_pump.dart';
import 'user_form/user_form_create_pump.dart';

const String _phone = UserFormFields.phoneId;
const String _email = UserFormFields.emailId;
const String _ecPhone = UserFormFields.emergencyContactPhoneId;

const _phoneInvalid = 'Enter a valid phone number';
const _emailInvalid = 'Enter a valid email';

/// What no form takes as a phone number.
const _notPhones = ['abcdefghij', '12345', '+00 123'];

/// One valid number of country code 91, in each way it may be typed.
const _phones = [
  '9876543210',
  '09876543210',
  '+919876543210',
  '00919876543210',
  '98765 43210',
  '98765-43210',
];

/// What no form takes as an email address.
const _notEmails = ['@', 'a@', '@b'];

Map<String, dynamic> _member() => {
  UserFormFields.firstNameId: 'Robin',
  _email: 'robin@example.test',
  _phone: '9876543210',
  UserFormFields.genderId: SignupGender.female,
  UserFormFields.dateOfBirthUtcId: DateTime.utc(2010, 3, 4),
};

Future<SignupFormState> _pumpReapply(
  WidgetTester tester, {
  String code = '91',
}) async {
  final key = GlobalKey<SignupFormState>();
  await pumpForm(
    tester,
    SignupForm(
      key: key,
      defaultCountryCode: code,
      username: 'robin',
      initialValues: _member(),
    ),
  );
  return key.currentState!;
}

Future<UserContactFormState> _pumpContact(
  WidgetTester tester, {
  String code = '91',
}) async {
  final key = GlobalKey<UserContactFormState>();
  await pumpForm(
    tester,
    UserContactForm(
      key: key,
      defaultCountryCode: code,
      initialValues: _member(),
    ),
  );
  return key.currentState!;
}

Future<ClubContactFormState> _pumpClubContact(WidgetTester tester) async {
  final key = GlobalKey<ClubContactFormState>();
  await pumpClubIdentityForm(
    tester,
    ClubContactForm(key: key, initialValues: const {}),
  );
  return key.currentState!;
}

void main() {
  group('Issue 71: UserForm', () {
    testWidgets('Issue 71: what is no phone number is refused on the '
        'phone', (tester) async {
      final state = await pumpCreate(tester);
      await fillCreate(tester, state);

      for (final typed in _notPhones) {
        await enterField(tester, _phone, typed);
        expect(state.validate(), isNull, reason: typed);
        await tester.pumpAndSettle();
        expectMessageOn(_phone, _phoneInvalid);
      }
    });

    testWidgets('Issue 71: a valid number passes however it is typed, and '
        'comes back as typed', (tester) async {
      final state = await pumpCreate(tester);
      await fillCreate(tester, state);

      for (final typed in [..._phones, '+1 415 555 0123']) {
        await enterField(tester, _phone, typed);
        expect(state.validate()?[_phone], typed, reason: typed);
      }
    });

    testWidgets('Issue 71: @, a@ and @b are refused on the email', (
      tester,
    ) async {
      final state = await pumpCreate(tester);
      await fillCreate(tester, state);

      for (final typed in _notEmails) {
        await enterField(tester, _email, typed);
        expect(state.validate(), isNull, reason: typed);
        await tester.pumpAndSettle();
        expectMessageOn(_email, _emailInvalid);
      }
    });
  });

  group('Issue 71: SignupForm', () {
    testWidgets('Issue 71: what is no phone number is refused on the '
        'phone', (tester) async {
      final state = await _pumpReapply(tester);

      for (final typed in _notPhones) {
        await enterField(tester, _phone, typed);
        expect(state.validate(), isNull, reason: typed);
        await tester.pumpAndSettle();
        expectMessageOn(_phone, _phoneInvalid);
      }
    });

    testWidgets('Issue 71: a valid number passes however it is typed', (
      tester,
    ) async {
      final state = await _pumpReapply(tester);

      for (final typed in [..._phones, '+1 415 555 0123']) {
        await enterField(tester, _phone, typed);
        expect(state.validate()?[_phone], typed, reason: typed);
      }
    });

    testWidgets('Issue 71: a national number is judged in the country code '
        'the form is given', (tester) async {
      const french = '06 12 34 56 78';
      var state = await _pumpReapply(tester);
      await enterField(tester, _phone, french);
      expect(state.validate(), isNull);

      await tester.pumpWidget(const SizedBox.shrink());
      state = await _pumpReapply(tester, code: '33');
      await enterField(tester, _phone, french);
      expect(state.validate()?[_phone], french);
    });

    testWidgets('Issue 71: @, a@ and @b are refused on the email', (
      tester,
    ) async {
      final state = await _pumpReapply(tester);

      for (final typed in _notEmails) {
        await enterField(tester, _email, typed);
        expect(state.validate(), isNull, reason: typed);
        await tester.pumpAndSettle();
        expectMessageOn(_email, _emailInvalid);
      }
    });
  });

  group('Issue 71: UserContactForm', () {
    testWidgets('Issue 71: what is no phone number is refused on the '
        'phone', (tester) async {
      final state = await _pumpContact(tester);

      for (final typed in _notPhones) {
        await enterField(tester, _phone, typed);
        expect(state.validate(), isNull, reason: typed);
        await tester.pumpAndSettle();
        expectMessageOn(_phone, _phoneInvalid);
      }
    });

    testWidgets('Issue 71: what is no phone number is refused on the '
        "emergency contact's phone, which may stay empty", (tester) async {
      final state = await _pumpContact(tester);
      expect(state.validate()?[_ecPhone], '');

      for (final typed in _notPhones) {
        await enterField(tester, _ecPhone, typed);
        expect(state.validate(), isNull, reason: typed);
        await tester.pumpAndSettle();
        expectMessageOn(_ecPhone, _phoneInvalid);
      }
    });

    testWidgets('Issue 71: a valid number passes on both phones however it '
        'is typed', (tester) async {
      final state = await _pumpContact(tester);

      for (final typed in [..._phones, '+44 7400 123456']) {
        await enterField(tester, _phone, typed);
        await enterField(tester, _ecPhone, typed);
        final values = state.validate();
        expect(values?[_phone], typed, reason: typed);
        expect(values?[_ecPhone], typed, reason: typed);
      }
    });

    testWidgets('Issue 71: both phones are judged in the country code the '
        'form is given', (tester) async {
      const french = '06 12 34 56 78';
      final state = await _pumpContact(tester, code: '33');
      await enterField(tester, _phone, french);
      await enterField(tester, _ecPhone, french);

      final values = state.validate();

      expect(values?[_phone], french);
      expect(values?[_ecPhone], french);
    });

    testWidgets('Issue 71: @, a@ and @b are refused on the email', (
      tester,
    ) async {
      final state = await _pumpContact(tester);

      for (final typed in _notEmails) {
        await enterField(tester, _email, typed);
        expect(state.validate(), isNull, reason: typed);
        await tester.pumpAndSettle();
        expectMessageOn(_email, _emailInvalid);
      }
    });
  });

  group('Issue 71: ClubContactForm', () {
    for (final id in const [
      ClubContactFormFields.phoneNumberId,
      ClubContactFormFields.whatsappNumberId,
    ]) {
      testWidgets('Issue 71: $id takes a valid number in international '
          'format only', (tester) async {
        final state = await _pumpClubContact(tester);

        await enterClubIdentityText(tester, id, '+919876543210');
        expect(state.validate()?[id], '+919876543210');

        await enterClubIdentityText(tester, id, '9876543210');
        expect(state.validate(), isNull);
        await tester.pumpAndSettle();
        expect(
          find.descendant(
            of: clubIdentityInput(id),
            matching: find.textContaining('Use the international format'),
          ),
          findsOneWidget,
        );
      });

      testWidgets('Issue 71: $id refuses a number in international format '
          'that is no number of its country', (tester) async {
        final state = await _pumpClubContact(tester);

        for (final typed in const ['+91987654321', '+10000000000']) {
          await enterClubIdentityText(tester, id, typed);
          expect(state.validate(), isNull, reason: typed);
          await tester.pumpAndSettle();
          expect(
            find.descendant(
              of: clubIdentityInput(id),
              matching: find.text(_phoneInvalid),
            ),
            findsOneWidget,
            reason: typed,
          );
        }
      });
    }
  });

  group('Issue 71: ForgotPasswordForm', () {
    testWidgets('Issue 71: @, a@ and @b are refused on the email, and an '
        'address passes', (tester) async {
      const id = ForgotPasswordFormFields.emailId;
      final key = GlobalKey<ForgotPasswordFormState>();
      await pumpForm(tester, ForgotPasswordForm(key: key));
      final state = key.currentState!;

      for (final typed in _notEmails) {
        await enterField(tester, id, typed);
        expect(state.validate(), isNull, reason: typed);
        await tester.pumpAndSettle();
        expectMessageOn(id, _emailInvalid);
      }

      await enterField(tester, id, 'robin@example.test');
      expect(state.validate(), isNotNull);
    });
  });
}
