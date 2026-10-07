// Issue 61, UserForm while it edits a user: its rule across fields, its
// values, dirty check, server errors, enabled off and phone width. Its
// fields and field rules are in user_form_edit_test.dart, with the notes
// on what applies.
import 'package:cl_club_forms/cl_club_forms.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/account_user_form_harness.dart';
import '../../support/form_harness.dart';
import 'user_form_edit_pump.dart';

const String _first = UserFormFields.firstNameId;
const String _middle = UserFormFields.middleNameId;
const String _last = UserFormFields.lastNameId;
const String _nickname = UserFormFields.nicknameId;
const String _useName = UserFormFields.useNamePubliclyId;
const String _gender = UserFormFields.genderId;
const String _dob = UserFormFields.dateOfBirthUtcId;
const String _line1 = UserFormFields.addrLine1Id;
const String _line2 = UserFormFields.addrLine2Id;
const String _city = UserFormFields.cityId;
const String _state = UserFormFields.stateId;
const String _pincode = UserFormFields.pincodeId;
const String _phone = UserFormFields.phoneId;
const String _email = UserFormFields.emailId;
const String _ecName = UserFormFields.emergencyContactNameId;
const String _ecRelation = UserFormFields.emergencyContactRelationId;
const String _ecPhone = UserFormFields.emergencyContactPhoneId;
const String _medical = UserFormFields.medicalInfoId;

void main() {
  group('Issue 61: UserForm editing, rules across fields and values', () {
    testWidgets('Issue 61: neither first nor last name is refused inline, '
        'and either alone is enough', (tester) async {
      final state = await pumpEdit(tester);
      await enterField(tester, _first, '');
      await enterField(tester, _last, '  ');

      expect(state.validate(), isNull);
      await tester.pumpAndSettle();
      expectInlineMessage(noNameMessage);

      await enterField(tester, _first, 'Robin');
      expect(state.validate(), isNotNull);
      await tester.pumpAndSettle();
      expect(find.text(noNameMessage), findsNothing);

      await enterField(tester, _first, '');
      await enterField(tester, _last, 'Rao');
      expect(state.validate(), isNotNull);
    });

    testWidgets('Issue 61: with every protected field editable, the '
        "member's values come back unchanged under every id of UserForm", (
      tester,
    ) async {
      final state = await pumpEditAllEditable(tester);

      expect(state.isDirty, isFalse);
      final values = state.validate();

      expect(
        values,
        UserFormAssembly.seed(UserFormFields.userIds, editedMember()),
      );
      expect(values!.keys.toSet(), UserFormFields.userIds.toSet());
      expect(values[_gender], isA<SignupGender>());
      expect(values[_dob], isA<DateTime>());
      expect(values[_useName], isA<bool>());
      expect(values[_state], isA<String>());
    });

    testWidgets('Issue 61: what is typed comes back as typed, and an '
        'emptied text as an empty string', (tester) async {
      final state = await pumpEdit(tester);
      await enterField(tester, _nickname, ' Robby ');
      await enterField(tester, _middle, '');
      await enterField(tester, _medical, 'Asthma\nPollen allergy');

      final values = state.validate()!;

      expect(values[_nickname], ' Robby ');
      expect(values[_middle], '');
      expect(values[_medical], 'Asthma\nPollen allergy');
      expect(values[_city], 'Pune');
      expect(values[_ecRelation], 'Parent');
    });

    testWidgets('Issue 61: a member with only a name, phone and email '
        'comes back with empty texts and no state or relation', (tester) async {
      final state = await pumpEdit(
        tester,
        initialValues: const {
          _first: 'Robin',
          _phone: '9876543210',
          _email: 'robin@example.test',
        },
      );

      final values = state.validate()!;

      for (final id in [_middle, _last, _nickname, _line1, _city, _medical]) {
        expect(values[id], '', reason: id);
      }
      expect(values[_state], isNull);
      expect(values[_ecRelation], isNull);
    });
  });

  group('Issue 61: UserForm editing, dirty check', () {
    testWidgets('Issue 61: isDirty follows each text, and is false again '
        'when it is retyped as it was', (tester) async {
      final state = await pumpEdit(tester);
      expect(state.isDirty, isFalse);

      for (final id in [
        _first,
        _nickname,
        _line1,
        _pincode,
        _email,
        _medical,
      ]) {
        final before = editedMember()[id] as String;
        await enterField(tester, id, '${before}x');
        expect(state.isDirty, isTrue, reason: id);
        await enterField(tester, id, before);
        expect(state.isDirty, isFalse, reason: id);
      }
    });

    testWidgets('Issue 61: isDirty follows the relation and the state '
        'selects, and is false again when each is picked back', (tester) async {
      final state = await pumpEdit(tester);

      await pickOption(tester, _ecRelation, 'Sibling');
      expect(heldValue(state, _ecRelation), 'Sibling');
      expect(state.isDirty, isTrue);
      await pickOption(tester, _ecRelation, 'Parent');
      expect(state.isDirty, isFalse);

      await setField(tester, state, _state, 'Goa');
      expect(state.isDirty, isTrue);
      await setField(tester, state, _state, 'Maharashtra');
      expect(state.isDirty, isFalse);
    });

    testWidgets('Issue 61: isDirty follows the public-name tick, the '
        'gender and the date of birth, and is false again when each is '
        'put back', (tester) async {
      final state = await pumpEditAllEditable(tester);
      expect(state.isDirty, isFalse);

      await tapCheckbox(tester, _useName);
      expect(state.isDirty, isTrue);
      await tapCheckbox(tester, _useName);
      expect(state.isDirty, isFalse);

      await pickOption(tester, _gender, 'Female');
      expect(state.isDirty, isTrue);
      await pickOption(tester, _gender, 'Other');
      expect(state.isDirty, isFalse);

      await setField(tester, state, _dob, DateTime.utc(2011, 5, 6));
      expect(state.isDirty, isTrue);
      await setField(tester, state, _dob, DateTime.utc(2010, 3, 4));
      expect(state.isDirty, isFalse);
    });
  });

  group('Issue 61: UserForm editing, server errors, disabled, narrow', () {
    testWidgets('Issue 61: a refusal shows on the pincode and inline, and '
        'the form saves again afterwards', (tester) async {
      final state = await pumpEdit(tester);

      await expectShowsServerErrors(tester, state, _pincode);

      state.showErrors(
        fieldErrors: const {_pincode: 'No such pincode.'},
        formError: 'Could not save the user.',
      );
      await tester.pumpAndSettle();
      expectMessageOn(_pincode, 'No such pincode.');
      expectInlineMessage('Could not save the user.');

      await enterField(tester, _pincode, '411002');
      expect(state.validate()![_pincode], '411002');
      await tester.pumpAndSettle();
      expect(find.text('No such pincode.'), findsNothing);
      expect(find.text('Could not save the user.'), findsNothing);
    });

    testWidgets('Issue 61: a refusal for a protected field the viewer sees '
        'read-only shows inline', (tester) async {
      final state = await pumpEdit(tester);

      state.showErrors(fieldErrors: const {_gender: 'Gender is locked.'});
      await tester.pumpAndSettle();

      expectInlineMessage('Gender is locked.');
    });

    testWidgets('Issue 61: with enabled off no field, tick or select '
        'responds', (tester) async {
      final key = GlobalKey<UserFormState>();
      await pumpForm(
        tester,
        UserForm(
          key: key,
          readOnlyUsername: 'robin',
          initialValues: editedMember(),
          enabled: false,
          canEditGender: true,
          canEditDateOfBirth: true,
          canEditUseNamePublicly: true,
        ),
      );
      final state = key.currentState!;

      expectEveryFieldOff(tester);
      expect(fieldIds(tester), hasLength(18));
      // The first name opens focused; the others are reached by a tap.
      await expectTapsIgnored(tester, [
        _middle,
        _last,
        _nickname,
        _line1,
        _line2,
        _city,
        _pincode,
        _phone,
        _email,
        _ecName,
        _ecPhone,
        _medical,
      ]);
      await tapCheckbox(tester, _useName);
      await tapSelect(tester, _gender);
      expect(find.text('Female'), findsNothing);
      await tapSelect(tester, _state);
      expect(find.text('Assam'), findsNothing);
      await tapSelect(tester, _ecRelation);
      expect(find.text('Sibling'), findsNothing);

      expect(state.isDirty, isFalse);
    });

    testWidgets('Issue 61: it fits a phone, with the longest state, every '
        'protected field editable and its messages showing', (tester) async {
      final key = GlobalKey<UserFormState>();
      await pumpForm(
        tester,
        UserForm(
          key: key,
          readOnlyUsername: 'a_long_username_on_a_phone',
          initialValues: {
            ...editedMember(),
            _state: 'Dadra and Nagar Haveli and Daman and Diu',
            _gender: SignupGender.preferNotToSay,
            _phone: '',
            _email: '',
            _pincode: '1',
            _ecPhone: '1',
          },
          canEditGender: true,
          canEditDateOfBirth: true,
          canEditUseNamePublicly: true,
        ),
        size: kPhoneSurface,
      );
      expect(tester.takeException(), isNull);

      expect(key.currentState!.validate(), isNull);
      await tester.pumpAndSettle();

      expect(find.text('Enter a valid 6-digit pincode'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Issue 61: it fits a phone with the protected fields '
        'read-only', (tester) async {
      await pumpEdit(tester, size: kPhoneSurface);

      expect(tester.takeException(), isNull);
    });
  });
}
