// Issue 321, ApplicationLabelsForm: the form's standard labels in the
// print languages, each pre-filled from the catalogue or the template's
// override; what differs from the catalogue is returned as an override,
// every language of the label in it.
import 'package:cl_club_forms/cl_club_forms.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/account_user_form_harness.dart';
import '../../support/form_harness.dart';
import 'application_samples.dart';

const String _overrides = ApplicationFormFields.labelOverridesId;

String _id(String label, String code) =>
    ApplicationFormFields.labelFieldId(label, code);

Map<String, Object?> _override() => {
  'field.past_experience': {
    'en': 'Past experience in any sport',
    'mr': 'पूर्व अनुभव',
    'hi': 'अनुभव',
  },
};

Widget _form({
  required GlobalKey<ApplicationLabelsFormState> key,
  Map<String, Object?>? overrides,
  bool enabled = true,
}) => ApplicationLabelsForm(
  key: key,
  initialValues: {_overrides: overrides ?? _override()},
  labels: ApplicationSamples.labels,
  languages: ApplicationSamples.printLanguages,
  enabled: enabled,
);

Future<ApplicationLabelsFormState> _pump(
  WidgetTester tester, {
  Map<String, Object?>? overrides,
}) async {
  final key = GlobalKey<ApplicationLabelsFormState>();
  await pumpForm(tester, _form(key: key, overrides: overrides));
  return key.currentState!;
}

void main() {
  group('Issue 321: ApplicationLabelsForm', () {
    testWidgets('Issue 321: every label has an input per print language, '
        'filled from the override or the catalogue', (tester) async {
      await _pump(tester);

      expect(rowLabels(tester), [
        'Full name (English) *',
        'Full name (Marathi) *',
        'Past experience (English) *',
        'Past experience (Marathi) *',
      ]);
      expect(fieldIds(tester), [
        _id('field.full_name', 'en'),
        _id('field.full_name', 'mr'),
        _id('field.past_experience', 'en'),
        _id('field.past_experience', 'mr'),
      ]);
      expect(find.text('Past experience in any sport'), findsOneWidget);
      expectLabelsAreRows(tester);
      expectNoHostChrome(tester);
    });

    testWidgets('Issue 321: only what differs from the catalogue comes '
        'back', (tester) async {
      final state = await _pump(tester);

      expect(state.isDirty, isFalse);
      expect(state.validate(), {_overrides: _override()});
    });

    testWidgets('Issue 321: a changed label comes back with its other '
        'languages; one put back as the catalogue has it goes', (
      tester,
    ) async {
      final state = await _pump(tester);

      await enterField(tester, _id('field.full_name', 'mr'), ' नाव ');
      await enterField(
        tester,
        _id('field.past_experience', 'en'),
        'Past experience',
      );

      expect(state.isDirty, isTrue);
      expect(state.validate(), {
        _overrides: {
          'field.full_name': {'en': 'Full name', 'mr': 'नाव', 'hi': 'पूरा नाम'},
        },
      });
    });

    testWidgets('Issue 321: an override of a label the catalogue no longer '
        'has is kept', (tester) async {
      final state = await _pump(
        tester,
        overrides: {
          'field.retired': {'en': 'Old label'},
        },
      );

      expect(state.validate(), {
        _overrides: {
          'field.retired': {'en': 'Old label'},
        },
      });
    });

    testWidgets('Issue 321: an emptied label is refused on its field', (
      tester,
    ) async {
      final state = await _pump(tester);

      await enterField(tester, _id('field.full_name', 'en'), ' ');

      expect(state.validate(), isNull);
      await tester.pump();
      expectMessageOn(_id('field.full_name', 'en'), 'A label cannot be empty');
    });

    testWidgets('Issue 321: a refusal shows on its field or inline; off, '
        'nothing takes input', (tester) async {
      final state = await _pump(tester);
      await expectShowsServerErrors(
        tester,
        state,
        _id('field.full_name', 'en'),
      );
      Widget build({required bool enabled}) => _form(
        key: GlobalKey<ApplicationLabelsFormState>(),
        enabled: enabled,
      );
      expect(await expectDrawnOffWhenTurnedOff(tester, build), 4);
      expect(await expectKeyboardIgnoredWhenOff(tester, build), 4);
      await expectFitsPhone(tester, build(enabled: true));
    });
  });
}
