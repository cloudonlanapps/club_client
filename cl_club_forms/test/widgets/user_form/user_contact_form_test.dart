// Issue 61, UserContactForm. Points that do not apply: it has no rule
// across fields, and no parameter hides or locks a field. The form has no
// button of its own. Its values are its fields as typed: nothing is
// trimmed here (the host's adapter does).
import 'package:cl_club_forms/cl_club_forms.dart';
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

Map<String, dynamic> _member() => {
  _email: 'robin@example.test',
  _phone: '9876543210',
  _ecName: 'Meera Rao',
  _ecRelation: 'Parent',
  _ecPhone: '9876543211',
  _medical: 'Asthma',
};

Future<UserContactFormState> _pump(
  WidgetTester tester, {
  Map<String, dynamic>? initialValues,
  bool enabled = true,
  Size size = kFormSurface,
}) async {
  final key = GlobalKey<UserContactFormState>();
  await pumpForm(
    tester,
    UserContactForm(
      key: key,
      initialValues: initialValues ?? _member(),
      enabled: enabled,
    ),
    size: size,
  );
  return key.currentState!;
}

void main() {
  group('Issue 61: UserContactForm', () {
    testWidgets('Issue 61: it shows email, phone, the emergency contact '
        'and the medical notes, email and phone required, every row '
        'stacked', (tester) async {
      await _pump(tester);

      expect(rowLabels(tester), [
        'Email *',
        'Phone *',
        'Emergency contact name',
        'Emergency contact relation',
        'Emergency contact phone',
        'Medical info',
      ]);
      expect(fieldIds(tester), UserFormFields.contactIds);
      expect(sideBySide(tester, _ecRelation, _ecPhone), isFalse);
      expectLabelsAreRows(tester);
      expectNoHostChrome(tester);
    });

    final cases = <({String rule, String id, String value, String message})>[
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
        rule: 'an emergency phone of nine characters',
        id: _ecPhone,
        value: '987654321',
        message: 'Enter a valid phone number',
      ),
    ];

    for (final c in cases) {
      testWidgets('Issue 61: ${c.rule} is refused on its field', (
        tester,
      ) async {
        final state = await _pump(tester);
        final before = _member()[c.id] as String;
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

    testWidgets('Issue 61: the seeded values come back unchanged under '
        'exactly the six contact ids', (tester) async {
      final state = await _pump(tester);

      expect(state.isDirty, isFalse);
      final values = state.validate();

      expect(values, _member());
      expect(values!.keys, UserFormFields.contactIds);
    });

    testWidgets('Issue 61: what is typed comes back as typed', (tester) async {
      final state = await _pump(tester);
      await enterField(tester, _email, ' robin@example.org ');
      await enterField(tester, _phone, ' 9876543210 ');
      await enterField(tester, _medical, 'Asthma\nPollen allergy');
      await pickOption(tester, _ecRelation, 'Sibling');

      expect(state.validate(), {
        ..._member(),
        _email: ' robin@example.org ',
        _phone: ' 9876543210 ',
        _medical: 'Asthma\nPollen allergy',
        _ecRelation: 'Sibling',
      });
    });

    testWidgets('Issue 61: with only email and phone, the optional texts '
        'come back empty and the relation null', (tester) async {
      final state = await _pump(
        tester,
        initialValues: const {
          _email: 'robin@example.test',
          _phone: '9876543210',
        },
      );

      expect(state.validate(), {
        _email: 'robin@example.test',
        _phone: '9876543210',
        _ecName: '',
        _ecRelation: null,
        _ecPhone: '',
        _medical: '',
      });
    });

    testWidgets('Issue 61: values of other sections given to it are '
        'neither shown nor returned', (tester) async {
      final state = await _pump(
        tester,
        initialValues: {..._member(), UserFormFields.cityId: 'Pune'},
      );

      expect(find.text('Pune'), findsNothing);
      expect(state.validate(), _member());
    });

    testWidgets('Issue 61: isDirty follows each text, and is false again '
        'when it is retyped as it was', (tester) async {
      final state = await _pump(tester);
      expect(state.isDirty, isFalse);

      for (final id in [_email, _phone, _ecName, _ecPhone, _medical]) {
        final before = _member()[id] as String;
        await enterField(tester, id, '${before}1');
        expect(state.isDirty, isTrue, reason: id);
        await enterField(tester, id, before);
        expect(state.isDirty, isFalse, reason: id);
      }
    });

    testWidgets('Issue 61: isDirty follows the relation, and is false '
        'again when the first one is picked back', (tester) async {
      final state = await _pump(tester);

      await pickOption(tester, _ecRelation, 'Friend');
      expect(heldValue(state, _ecRelation), 'Friend');
      expect(state.isDirty, isTrue);

      await pickOption(tester, _ecRelation, 'Parent');
      expect(state.isDirty, isFalse);
    });

    testWidgets('Issue 61: a refusal shows on the email and inline, and '
        'the form saves again afterwards', (tester) async {
      final state = await _pump(tester);

      await expectShowsServerErrors(tester, state, _email);

      state.showErrors(
        fieldErrors: const {_email: 'That email is already registered.'},
        formError: 'Could not save the contact details.',
      );
      await tester.pumpAndSettle();
      expectMessageOn(_email, 'That email is already registered.');
      expectInlineMessage('Could not save the contact details.');

      await enterField(tester, _email, 'robin@example.org');
      expect(state.validate()![_email], 'robin@example.org');
      await tester.pumpAndSettle();
      expect(find.text('That email is already registered.'), findsNothing);
      expect(find.text('Could not save the contact details.'), findsNothing);
    });

    testWidgets('Issue 61: with enabled off no field takes a tap and the '
        'relation does not open', (tester) async {
      final state = await _pump(tester, enabled: false);

      expectEveryFieldOff(tester);
      expect(fieldIds(tester), UserFormFields.contactIds);
      await expectTapsIgnored(tester, [
        _email,
        _phone,
        _ecName,
        _ecPhone,
        _medical,
      ]);
      await tapSelect(tester, _ecRelation);
      expect(find.text('Sibling'), findsNothing);
      expect(state.isDirty, isFalse);
    });

    testWidgets('Issue 61: with enabled on a tap gives a field the focus '
        'and opens the relation', (tester) async {
      await _pump(tester);

      await tapField(tester, _ecName);
      expect(hasFocus(tester, _ecName), isTrue);
      await tapSelect(tester, _ecRelation);
      expect(find.text('Sibling'), findsOneWidget);
    });

    testWidgets('Issue 61: it fits a phone, with every message showing', (
      tester,
    ) async {
      final state = await _pump(
        tester,
        initialValues: const {_ecPhone: '1', _ecRelation: 'Parent'},
        size: kPhoneSurface,
      );
      expect(tester.takeException(), isNull);

      expect(state.validate(), isNull);
      await tester.pumpAndSettle();

      expect(find.text('Email is required'), findsOneWidget);
      expect(find.text('Phone number is required'), findsOneWidget);
      expect(find.text('Enter a valid phone number'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
