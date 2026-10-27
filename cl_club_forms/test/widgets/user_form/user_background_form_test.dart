// Issue 320, UserBackgroundForm: nationality and preferred language of the
// extended profile. Both optional; the language select offers the club's
// languages and a "None" choice, and keeps a language the club no longer
// lists.
import 'package:cl_club_forms/cl_club_forms.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/account_user_form_harness.dart';
import '../../support/form_harness.dart';

const String _nationality = UserFormFields.nationalityId;
const String _language = UserFormFields.preferredLanguagesId;

const List<String> _languages = ['English', 'Marathi', 'Hindi'];

Map<String, dynamic> _member() => {
  _nationality: 'Indian',
  _language: 'Marathi',
};

Widget _form({
  required GlobalKey<UserBackgroundFormState> key,
  Map<String, dynamic>? initialValues,
  bool enabled = true,
}) => UserBackgroundForm(
  key: key,
  initialValues: initialValues ?? _member(),
  languages: _languages,
  enabled: enabled,
);

Future<UserBackgroundFormState> _pump(
  WidgetTester tester, {
  Map<String, dynamic>? initialValues,
  bool enabled = true,
}) async {
  final key = GlobalKey<UserBackgroundFormState>();
  await pumpForm(
    tester,
    _form(key: key, initialValues: initialValues, enabled: enabled),
  );
  return key.currentState!;
}

void main() {
  group('Issue 320: UserBackgroundForm', () {
    testWidgets('Issue 320: it shows nationality and preferred language, '
        'neither required', (tester) async {
      await _pump(tester);

      expect(rowLabels(tester), ['Nationality', 'Preferred language']);
      expect(fieldIds(tester), UserFormFields.backgroundIds);
      expectLabelsAreRows(tester);
      expectNoHostChrome(tester);
    });

    testWidgets('Issue 320: the seeded values come back unchanged under '
        'exactly the two ids', (tester) async {
      final state = await _pump(tester);

      expect(state.isDirty, isFalse);
      final values = state.validate();
      expect(values, _member());
      expect(values!.keys, UserFormFields.backgroundIds);
    });

    testWidgets('Issue 320: a blank member comes back as empty texts and '
        'is valid', (tester) async {
      final state = await _pump(tester, initialValues: const {});

      expect(find.text('None'), findsOneWidget);
      expect(state.validate(), {_nationality: '', _language: ''});
    });

    testWidgets('Issue 320: the select offers None and every language, and '
        'returns the one picked', (tester) async {
      final state = await _pump(tester);

      await tapSelect(tester, _language);
      for (final text in ['None', ..._languages]) {
        expect(find.text(text), findsWidgets, reason: text);
      }
      await tester.tap(find.text('Hindi').last);
      await tester.pumpAndSettle();
      expect(state.validate()![_language], 'Hindi');
      expect(state.isDirty, isTrue);

      await pickOption(tester, _language, 'None');
      expect(state.validate()![_language], '');
    });

    testWidgets('Issue 320: a language the club no longer lists shows and '
        'is kept', (tester) async {
      final state = await _pump(
        tester,
        initialValues: {..._member(), _language: 'Kannada'},
      );

      expect(find.text('Kannada'), findsOneWidget);
      expect(state.isDirty, isFalse);
      expect(state.validate()![_language], 'Kannada');
    });

    testWidgets('Issue 320: the nationality comes back as typed, and '
        'isDirty follows it', (tester) async {
      final state = await _pump(tester);

      await enterField(tester, _nationality, ' Nepali ');
      expect(state.isDirty, isTrue);
      expect(state.validate()![_nationality], ' Nepali ');
      await enterField(tester, _nationality, 'Indian');
      expect(state.isDirty, isFalse);
    });

    testWidgets('Issue 320: a refusal shows on its field and inline', (
      tester,
    ) async {
      final state = await _pump(tester);
      await expectShowsServerErrors(tester, state, _language);
      await expectShowsServerErrors(tester, state, _nationality);
    });

    testWidgets('Issue 320: with enabled off every field is off and the '
        'select does not open', (tester) async {
      final state = await _pump(tester, enabled: false);

      expectEveryFieldOff(tester);
      await expectTapsIgnored(tester, [_nationality]);
      await tapSelect(tester, _language);
      expect(find.text('Hindi'), findsNothing);
      expect(state.isDirty, isFalse);
    });

    testWidgets('Issue 320: turned off while saving, every control is '
        'drawn off and typing is ignored', (tester) async {
      final key = GlobalKey<UserBackgroundFormState>();
      Widget build({required bool enabled}) =>
          _form(key: key, enabled: enabled);

      expect(await expectDrawnOffWhenTurnedOff(tester, build), 2);
      expect(await expectKeyboardIgnoredWhenOff(tester, build), 1);
    });

    testWidgets('Issue 320: it fits a phone', (tester) async {
      await expectFitsPhone(
        tester,
        _form(key: GlobalKey<UserBackgroundFormState>()),
      );
    });
  });
}
