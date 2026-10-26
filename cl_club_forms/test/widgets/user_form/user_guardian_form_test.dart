// Issue 320, UserGuardianForm: the guardian of the extended profile, apart
// from the emergency contact. All three fields optional; the phone is
// checked like every other phone, and a relation or phone without a name
// is refused as a rule across the fields, inline.
import 'package:cl_club_forms/cl_club_forms.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/account_user_form_harness.dart';
import '../../support/form_harness.dart';

const String _name = UserFormFields.guardianNameId;
const String _relation = UserFormFields.guardianRelationId;
const String _phone = UserFormFields.guardianPhoneId;

const String _nameRequired =
    "Enter the guardian's name, or clear the relation and phone";

Map<String, dynamic> _member() => {
  _name: 'Meera Rao',
  _relation: 'Mother',
  _phone: '9876543211',
};

Widget _form({
  required GlobalKey<UserGuardianFormState> key,
  Map<String, dynamic>? initialValues,
  bool enabled = true,
}) => UserGuardianForm(
  key: key,
  initialValues: initialValues ?? _member(),
  defaultCountryCode: '91',
  enabled: enabled,
);

Future<UserGuardianFormState> _pump(
  WidgetTester tester, {
  Map<String, dynamic>? initialValues,
  bool enabled = true,
}) async {
  final key = GlobalKey<UserGuardianFormState>();
  await pumpForm(
    tester,
    _form(key: key, initialValues: initialValues, enabled: enabled),
  );
  return key.currentState!;
}

void main() {
  group('Issue 320: UserGuardianForm', () {
    testWidgets('Issue 320: it shows name, relation and phone, none marked '
        'required, with the keyboards of each', (tester) async {
      await _pump(tester);

      expect(rowLabels(tester), [
        'Guardian name',
        'Guardian relation',
        'Guardian phone',
      ]);
      expect(fieldIds(tester), UserFormFields.guardianIds);
      expect(editableOf(tester, _name).keyboardType, TextInputType.name);
      expect(editableOf(tester, _phone).keyboardType, TextInputType.phone);
      expectLabelsAreRows(tester);
      expectNoHostChrome(tester);
    });

    testWidgets('Issue 320: the seeded values come back unchanged under '
        'exactly the three ids', (tester) async {
      final state = await _pump(tester);

      expect(state.isDirty, isFalse);
      final values = state.validate();
      expect(values, _member());
      expect(values!.keys, UserFormFields.guardianIds);
    });

    testWidgets('Issue 320: left blank it is valid and comes back as empty '
        'texts', (tester) async {
      final state = await _pump(tester, initialValues: const {});

      expect(state.validate(), {_name: '', _relation: '', _phone: ''});
    });

    testWidgets('Issue 320: a phone of nine characters is refused on the '
        'phone', (tester) async {
      final state = await _pump(tester);

      await enterField(tester, _phone, '987654321');
      expect(state.validate(), isNull);
      await tester.pumpAndSettle();
      expectMessageOn(_phone, 'Enter a valid phone number');

      await enterField(tester, _phone, '+12025550144');
      expect(state.validate(), isNotNull);
    });

    for (final other in [_relation, _phone]) {
      testWidgets('Issue 320: $other without a name is refused inline, and '
          'the message goes once the name is typed', (tester) async {
        final state = await _pump(
          tester,
          initialValues: {_name: '', other: _member()[other]},
        );

        expect(state.validate(), isNull);
        await tester.pumpAndSettle();
        expectInlineMessage(_nameRequired);

        await enterField(tester, _name, 'Meera Rao');
        await tester.pumpAndSettle();
        expect(find.text(_nameRequired), findsNothing);
        expect(state.validate(), isNotNull);
      });
    }

    testWidgets('Issue 320: a name alone is enough', (tester) async {
      final state = await _pump(tester, initialValues: const {_name: 'Ravi'});

      expect(state.validate(), {_name: 'Ravi', _relation: '', _phone: ''});
    });

    testWidgets('Issue 320: blanks of spaces count as empty for the rule', (
      tester,
    ) async {
      final state = await _pump(tester, initialValues: const {});

      await enterField(tester, _relation, '   ');
      expect(state.validate(), isNotNull);
      await enterField(tester, _name, '  ');
      await enterField(tester, _relation, 'Uncle');
      expect(state.validate(), isNull);
    });

    testWidgets('Issue 320: isDirty follows each text and is false again '
        'when it is retyped as it was', (tester) async {
      final state = await _pump(tester);

      for (final id in UserFormFields.guardianIds) {
        final before = _member()[id] as String;
        await enterField(tester, id, '${before}1');
        expect(state.isDirty, isTrue, reason: id);
        await enterField(tester, id, before);
        expect(state.isDirty, isFalse, reason: id);
      }
    });

    testWidgets('Issue 320: a refusal shows on the phone and inline', (
      tester,
    ) async {
      final state = await _pump(tester);
      await expectShowsServerErrors(tester, state, _phone);
    });

    testWidgets('Issue 320: with enabled off no field takes a tap', (
      tester,
    ) async {
      final state = await _pump(tester, enabled: false);

      expectEveryFieldOff(tester);
      await expectTapsIgnored(tester, UserFormFields.guardianIds);
      expect(state.isDirty, isFalse);
    });

    testWidgets('Issue 320: turned off while saving, every control is '
        'drawn off and typing is ignored', (tester) async {
      final key = GlobalKey<UserGuardianFormState>();
      Widget build({required bool enabled}) =>
          _form(key: key, enabled: enabled);

      expect(await expectDrawnOffWhenTurnedOff(tester, build), 3);
      expect(await expectKeyboardIgnoredWhenOff(tester, build), 3);
    });

    testWidgets('Issue 320: it fits a phone, with its messages showing', (
      tester,
    ) async {
      final key = GlobalKey<UserGuardianFormState>();
      await pumpForm(
        tester,
        _form(key: key, initialValues: const {_phone: '1'}),
        size: kPhoneSurface,
      );
      expect(tester.takeException(), isNull);

      expect(key.currentState!.validate(), isNull);
      await tester.pumpAndSettle();
      expect(find.text('Enter a valid phone number'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
