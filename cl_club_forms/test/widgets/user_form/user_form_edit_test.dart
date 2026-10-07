// Issue 61, UserForm while it edits a user (readOnlyUsername given).
// Every point applies. The form has no button of its own in this mode.
// Its values are its fields as typed: nothing is trimmed here (the host's
// adapter does).
import 'package:cl_club_forms/cl_club_forms.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/account_user_form_harness.dart';
import '../../support/form_harness.dart';
import 'user_form_edit_pump.dart';

const String _first = UserFormFields.firstNameId;
const String _useName = UserFormFields.useNamePubliclyId;
const String _gender = UserFormFields.genderId;
const String _dob = UserFormFields.dateOfBirthUtcId;
const String _pincode = UserFormFields.pincodeId;
const String _phone = UserFormFields.phoneId;
const String _email = UserFormFields.emailId;
const String _ecPhone = UserFormFields.emergencyContactPhoneId;

void main() {
  group('Issue 61: UserForm editing, its fields', () {
    testWidgets('Issue 61: it shows the username read-only, the names with '
        'the nickname, then address, contact and emergency fields; the '
        'protected ones read-only; no password and no username check', (
      tester,
    ) async {
      await pumpEdit(tester);

      expect(rowLabels(tester), [
        'Username',
        'First name *',
        'Middle name',
        'Last name *',
        'Nickname',
        'Show name publicly',
        'Gender',
        'Date of birth',
        ...editLowerRows,
      ]);
      expect(fieldIds(tester), [...editNameIds, ...editLowerIds]);
      expect(find.text('robin'), findsOneWidget);
      expect(find.text('Yes'), findsOneWidget);
      expect(find.text('Other'), findsOneWidget);
      expect(find.text('4 Mar 2010'), findsOneWidget);
      expect(find.text('Use default password'), findsNothing);
      expect(checkAvailabilityButton, findsNothing);
      expectLabelsAreRows(tester);
      expectNoHostChrome(tester);
    });

    testWidgets('Issue 61: canEditGender makes the gender a required field', (
      tester,
    ) async {
      await pumpEdit(tester, canEditGender: true);

      expect(fieldIds(tester), [...editNameIds, _gender, ...editLowerIds]);
      expect(rowLabels(tester), containsAllInOrder(['Gender *', 'Address']));
      expect(rowLabels(tester), contains('Date of birth'));
    });

    testWidgets('Issue 61: canEditDateOfBirth makes the date of birth a '
        'required field', (tester) async {
      await pumpEdit(tester, canEditDateOfBirth: true);

      expect(fieldIds(tester), [...editNameIds, _dob, ...editLowerIds]);
      expect(rowLabels(tester), contains('Date of birth *'));
      expect(rowLabels(tester), contains('Gender'));
    });

    testWidgets('Issue 61: canEditUseNamePublicly makes the public name a '
        'tick, ticked from the member', (tester) async {
      final state = await pumpEdit(tester, canEditUseNamePublicly: true);

      expect(fieldIds(tester), [...editNameIds, _useName, ...editLowerIds]);
      expect(find.text('Yes'), findsNothing);
      expect(heldValue(state, _useName), isTrue);

      await tapCheckbox(tester, _useName);
      expect(heldValue(state, _useName), isFalse);
    });

    testWidgets('Issue 61: the canAssign flags show no role while editing', (
      tester,
    ) async {
      await pumpEdit(tester, canAssignAdmin: true, canAssignCoach: true);

      expect(find.text('Roles'), findsNothing);
      expect(fieldIds(tester), [...editNameIds, ...editLowerIds]);
    });

    testWidgets('Issue 61: it opens on the first name and may be submitted '
        'from the start', (tester) async {
      final reported = <bool>[];
      final state = await pumpEdit(tester, onCanSubmitChanged: reported.add);

      expect(hasFocus(tester, _first), isTrue);
      expect(reported, [true]);
      expect(state.canSubmit, isTrue);
    });

    testWidgets('Issue 61: a member with nothing set reads "No" and "Not '
        'set" where the viewer may not edit', (tester) async {
      await pumpEdit(tester, initialValues: const {_first: 'Robin'});

      expect(find.text('No'), findsOneWidget);
      expect(find.text('Not set'), findsNWidgets(2));
    });
  });

  group('Issue 61: UserForm editing, each field rule', () {
    final cases = <({String rule, String id, String value, String message})>[
      (
        rule: 'an empty phone',
        id: _phone,
        value: '',
        message: 'Phone number is required',
      ),
      (
        rule: 'a phone of nine characters',
        id: _phone,
        value: '987654321',
        message: 'Enter a valid phone number',
      ),
      (
        rule: 'an empty email',
        id: _email,
        value: '',
        message: 'Email is required',
      ),
      (
        rule: 'an email without @',
        id: _email,
        value: 'robin.example.test',
        message: 'Enter a valid email',
      ),
      (
        rule: 'an emergency phone of nine characters',
        id: _ecPhone,
        value: '987654321',
        message: 'Enter a valid phone number',
      ),
      (
        rule: 'a pincode of five digits',
        id: _pincode,
        value: '41100',
        message: 'Enter a valid 6-digit pincode',
      ),
    ];

    for (final c in cases) {
      testWidgets('Issue 61: ${c.rule} is refused on its field', (
        tester,
      ) async {
        final state = await pumpEdit(tester);
        final before = editedMember()[c.id] as String;
        expect(state.validate(), isNotNull, reason: 'valid before the break');

        await enterField(tester, c.id, c.value);
        expect(state.validate(), isNull);
        await tester.pumpAndSettle();
        expectMessageOn(c.id, c.message);

        await enterField(tester, c.id, before);
        expect(state.validate(), isNotNull);
        await tester.pumpAndSettle();
        expect(find.text(c.message), findsNothing);
      });
    }

    testWidgets('Issue 61: an emptied emergency phone and pincode are '
        'taken', (tester) async {
      final state = await pumpEdit(tester);
      await enterField(tester, _ecPhone, '');
      await enterField(tester, _pincode, '');

      final values = state.validate();

      expect(values, isNotNull);
      expect(values![_ecPhone], '');
      expect(values[_pincode], '');
    });

    testWidgets('Issue 61: an editable gender and date of birth are '
        'required, each on its field', (tester) async {
      final state = await pumpEdit(
        tester,
        initialValues: {...editedMember(), _gender: null, _dob: null},
        canEditGender: true,
        canEditDateOfBirth: true,
      );

      expect(state.validate(), isNull);
      await tester.pumpAndSettle();
      expectMessageOn(_gender, 'Gender is required');
      expectMessageOn(_dob, 'Date of birth is required');

      await setField(tester, state, _gender, SignupGender.male);
      await setField(tester, state, _dob, DateTime(2010, 3, 4));
      expect(state.validate(), isNotNull);
    });

    testWidgets('Issue 61: a read-only gender and date of birth that were '
        'never set do not block the save', (tester) async {
      final state = await pumpEdit(
        tester,
        initialValues: {...editedMember(), _gender: null, _dob: null},
      );

      expect(state.validate(), isNotNull);
    });
  });
}
