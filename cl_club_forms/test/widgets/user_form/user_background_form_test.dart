// Issue 320, UserBackgroundForm: nationality and preferred languages of
// the extended profile. Both optional; the languages are checkboxes of the
// club's languages, any number ticked (Issue 335), and a language the club
// no longer lists stays ticked.
import 'package:cl_club_forms/cl_club_forms.dart';
import 'package:cl_club_forms/src/widgets/user_form/user_form_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart' show ShadCheckbox;

import '../../support/account_user_form_harness.dart';
import '../../support/form_harness.dart';

const String _nationality = UserFormFields.nationalityId;
const String _language = UserFormFields.preferredLanguagesId;

const List<String> _languages = ['English', 'Marathi', 'Hindi'];

Map<String, dynamic> _member() => {
  _nationality: 'Indian',
  _language: ['Marathi'],
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
    testWidgets('Issue 320: it shows nationality and preferred languages, '
        'neither required', (tester) async {
      await _pump(tester);

      expect(rowLabels(tester), ['Nationality', 'Preferred languages']);
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

    testWidgets('Issue 335: a blank member comes back as an empty text and '
        'no language, with the muted line shown', (tester) async {
      final state = await _pump(tester, initialValues: const {});

      expect(find.text(UserFormStrings.noLanguageChosen), findsOneWidget);
      expect(state.validate(), {_nationality: '', _language: <String>[]});
    });

    testWidgets('Issue 335: a box for every language by name; two ticked '
        'come back as both', (tester) async {
      final state = await _pump(tester);

      for (final text in _languages) {
        expect(
          find.descendant(
            of: fieldWithId(_language),
            matching: find.widgetWithText(ShadCheckbox, text),
          ),
          findsOneWidget,
          reason: text,
        );
      }
      expect(choiceTicked(tester, _language, 'Marathi'), isTrue);

      await tapChoice(tester, _language, 'English');
      expect(state.validate()![_language], ['English', 'Marathi']);
      expect(state.isDirty, isTrue);
    });

    testWidgets('Issue 335: none ticked comes back as an empty list', (
      tester,
    ) async {
      final state = await _pump(tester);

      await tapChoice(tester, _language, 'Marathi');
      expect(find.text(UserFormStrings.noLanguageChosen), findsOneWidget);
      expect(state.validate()![_language], <String>[]);
    });

    testWidgets('Issue 335: a language the club no longer lists stays '
        'ticked and is kept', (tester) async {
      final state = await _pump(
        tester,
        initialValues: {
          ..._member(),
          _language: ['Kannada'],
        },
      );

      expect(choiceTicked(tester, _language, 'Kannada'), isTrue);
      expect(state.isDirty, isFalse);
      expect(state.validate()![_language], ['Kannada']);
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

    testWidgets('Issue 320: with enabled off every field is off and no '
        'box ticks', (tester) async {
      final state = await _pump(tester, enabled: false);

      expectEveryFieldOff(tester);
      await expectTapsIgnored(tester, [_nationality]);
      await tapChoice(tester, _language, 'Hindi');
      expect(choiceTicked(tester, _language, 'Hindi'), isFalse);
      expect(state.isDirty, isFalse);
    });

    testWidgets('Issue 320: turned off while saving, every control is '
        'drawn off and typing is ignored', (tester) async {
      final key = GlobalKey<UserBackgroundFormState>();
      Widget build({required bool enabled}) =>
          _form(key: key, enabled: enabled);

      expect(await expectDrawnOffWhenTurnedOff(tester, build), 4);
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
