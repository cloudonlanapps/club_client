// The field clusters of the user forms that hold the contact details:
// email and phone, and the emergency contact with the medical notes.
// Each is mounted alone in a bare ShadForm. A cluster has no validate() or
// isDirty of its own (the embedding form has) and no rule across fields;
// those points are tested on the forms.
import 'package:cl_club_forms/cl_club_forms.dart';
import 'package:cl_club_forms/src/widgets/user_form/user_contact_fields.dart';
import 'package:cl_club_forms/src/widgets/user_form/user_emergency_fields.dart';
import 'package:cl_club_forms/src/widgets/user_form/user_field_pair.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/account_user_form_harness.dart';
import '../../support/form_harness.dart';

const String _email = UserFormFields.emailId;
const String _phone = UserFormFields.phoneId;
const String _ecName = UserFormFields.emergencyContactNameId;
const String _ecRelation = UserFormFields.emergencyContactRelationId;
const String _ecPhone = UserFormFields.emergencyContactPhoneId;
const String _medical = UserFormFields.medicalInfoId;

/// Narrower than `UserFieldPair.sideBySideMinWidth` once padded.
const _narrow = Size(480, 2400);

void main() {
  group('Issue 61: UserContactFields', () {
    testWidgets('Issue 61: it shows email then phone, both required', (
      tester,
    ) async {
      await pumpCluster(
        tester,
        const UserContactFields(defaultCountryCode: '91'),
      );

      expect(rowLabels(tester), ['Email *', 'Phone *']);
      expect(fieldIds(tester), [_email, _phone]);
      expect(find.text('name@example.com'), findsOneWidget);
      expectLabelsAreRows(tester);
    });

    testWidgets('Issue 61: with emailFirst off the phone comes first', (
      tester,
    ) async {
      await pumpCluster(
        tester,
        const UserContactFields(defaultCountryCode: '91', emailFirst: false),
      );

      expect(rowLabels(tester), ['Phone *', 'Email *']);
      expect(fieldIds(tester), [_phone, _email]);
    });

    testWidgets('Issue 61: an empty email and an empty phone are refused, '
        'each on its field', (tester) async {
      final form = await pumpCluster(
        tester,
        const UserContactFields(defaultCountryCode: '91'),
      );

      expect(form.saveAndValidate(), isFalse);
      await tester.pumpAndSettle();

      expectMessageOn(_email, 'Email is required');
      expectMessageOn(_phone, 'Phone number is required');
    });

    testWidgets('Issue 61: an email without @ is refused on its field', (
      tester,
    ) async {
      final form = await pumpCluster(
        tester,
        const UserContactFields(defaultCountryCode: '91'),
      );
      await enterField(tester, _phone, '9876543210');
      await enterField(tester, _email, 'robin.example.test');

      expect(form.saveAndValidate(), isFalse);
      await tester.pumpAndSettle();
      expectMessageOn(_email, 'Enter a valid email');

      await enterField(tester, _email, 'robin@example.test');
      expect(form.saveAndValidate(), isTrue);
    });

    testWidgets('Issue 61: a phone of nine characters is refused on its '
        'field and one of ten is taken', (tester) async {
      final form = await pumpCluster(
        tester,
        const UserContactFields(defaultCountryCode: '91'),
      );
      await enterField(tester, _email, 'robin@example.test');
      await enterField(tester, _phone, '987654321');

      expect(form.saveAndValidate(), isFalse);
      await tester.pumpAndSettle();
      expectMessageOn(_phone, 'Enter a valid phone number');

      await enterField(tester, _phone, '9876543210');
      expect(form.saveAndValidate(), isTrue);
    });

    testWidgets("Issue 61: it starts from the form's values and asks for "
        'the email and phone keyboards', (tester) async {
      await pumpCluster(
        tester,
        const UserContactFields(defaultCountryCode: '91'),
        initial: const {_email: 'robin@example.test', _phone: '9876543210'},
      );

      expect(editableOf(tester, _email).controller.text, 'robin@example.test');
      expect(editableOf(tester, _phone).controller.text, '9876543210');
      expect(
        editableOf(tester, _email).keyboardType,
        TextInputType.emailAddress,
      );
      expect(editableOf(tester, _phone).keyboardType, TextInputType.phone);
    });

    testWidgets('Issue 61: with enabled off both are off', (tester) async {
      await pumpCluster(
        tester,
        const UserContactFields(defaultCountryCode: '91', enabled: false),
      );

      expectEveryFieldOff(tester);
      await expectTapsIgnored(tester, [_email, _phone]);
    });
  });

  group('Issue 61: UserEmergencyFields', () {
    testWidgets("Issue 61: it shows the contact's name, relation and "
        'phone and the medical notes, none required', (tester) async {
      await pumpCluster(
        tester,
        const UserEmergencyFields(defaultCountryCode: '91'),
      );

      expect(rowLabels(tester), [
        'Emergency contact name',
        'Emergency contact relation',
        'Emergency contact phone',
        'Medical info',
      ]);
      expect(fieldIds(tester), [_ecName, _ecRelation, _ecPhone, _medical]);
      expect(find.text('Select relation'), findsOneWidget);
      expectLabelsAreRows(tester);
      expectNoHostChrome(tester);
    });

    testWidgets('Issue 61: left empty it is valid, the texts empty and the '
        'relation null', (tester) async {
      final form = await pumpCluster(
        tester,
        const UserEmergencyFields(defaultCountryCode: '91'),
        initial: UserFormAssembly.seed(const [
          _ecName,
          _ecRelation,
          _ecPhone,
          _medical,
        ], null),
      );

      expect(form.saveAndValidate(), isTrue);
      expect(form.value, {
        _ecName: '',
        _ecRelation: null,
        _ecPhone: '',
        _medical: '',
      });
    });

    testWidgets('Issue 61: a contact phone of nine characters is refused on '
        'its field; ten, or none, is taken', (tester) async {
      final form = await pumpCluster(
        tester,
        const UserEmergencyFields(defaultCountryCode: '91'),
      );
      await enterField(tester, _ecPhone, '987654321');

      expect(form.saveAndValidate(), isFalse);
      await tester.pumpAndSettle();
      expectMessageOn(_ecPhone, 'Enter a valid phone number');

      await enterField(tester, _ecPhone, '9876543210');
      expect(form.saveAndValidate(), isTrue);
      await enterField(tester, _ecPhone, '');
      expect(form.saveAndValidate(), isTrue);
    });

    testWidgets('Issue 61: the relation offers its six options and holds '
        'the one picked', (tester) async {
      final form = await pumpCluster(
        tester,
        const UserEmergencyFields(defaultCountryCode: '91'),
      );

      await tapSelect(tester, _ecRelation);
      for (final relation in UserFormAssembly.emergencyRelations) {
        expect(find.text(relation), findsOneWidget, reason: relation);
      }
      await tester.tap(find.text('Sibling'));
      await tester.pumpAndSettle();

      expect(form.value[_ecRelation], 'Sibling');
      expect(find.text('Sibling'), findsOneWidget);
      expect(find.text('Select relation'), findsNothing);
    });

    testWidgets("Issue 61: it starts from the form's values, the relation "
        'included', (tester) async {
      final form = await pumpCluster(
        tester,
        const UserEmergencyFields(defaultCountryCode: '91'),
        initial: const {
          _ecName: 'Meera',
          _ecRelation: 'Parent',
          _ecPhone: '9876543210',
          _medical: 'Asthma',
        },
      );

      expect(find.text('Parent'), findsOneWidget);
      expect(editableOf(tester, _ecName).controller.text, 'Meera');
      expect(editableOf(tester, _medical).controller.text, 'Asthma');
      expect(form.value[_ecRelation], 'Parent');
    });

    testWidgets('Issue 61: the medical notes show two lines and grow to '
        'four', (tester) async {
      await pumpCluster(
        tester,
        const UserEmergencyFields(defaultCountryCode: '91'),
      );

      final notes = editableOf(tester, _medical);
      expect(notes.minLines, UserEmergencyFields.medicalInfoMinLines);
      expect(notes.maxLines, UserEmergencyFields.medicalInfoMaxLines);
      expect([notes.minLines, notes.maxLines], [2, 4]);
      expect(notes.keyboardType, TextInputType.multiline);
    });

    testWidgets('Issue 61: relation and phone sit side by side where there '
        'is room and follow pairMinWidth', (tester) async {
      await pumpCluster(
        tester,
        const UserEmergencyFields(defaultCountryCode: '91'),
      );
      expect(sideBySide(tester, _ecRelation, _ecPhone), isTrue);

      await pumpCluster(
        tester,
        const UserEmergencyFields(defaultCountryCode: '91'),
        size: _narrow,
      );
      expect(sideBySide(tester, _ecRelation, _ecPhone), isFalse);

      await pumpCluster(
        tester,
        const UserEmergencyFields(
          defaultCountryCode: '91',
          pairMinWidth: UserFieldPair.never,
        ),
      );
      expect(sideBySide(tester, _ecRelation, _ecPhone), isFalse);
    });

    testWidgets('Issue 61: with enabled off nothing takes a tap and the '
        'relation does not open', (tester) async {
      await pumpCluster(
        tester,
        const UserEmergencyFields(defaultCountryCode: '91', enabled: false),
      );

      expectEveryFieldOff(tester);
      await expectTapsIgnored(tester, [_ecName, _ecPhone, _medical]);
      await tapSelect(tester, _ecRelation);
      expect(find.text('Sibling'), findsNothing);
    });
  });
}
