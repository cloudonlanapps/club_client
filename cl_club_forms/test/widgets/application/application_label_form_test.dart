// Issue 396, ApplicationLabelForm: one of the club's application labels —
// its text in each of the club's languages, English required, a blank
// translation allowed (the server stores it blank and Finalize asks for it).
import 'package:cl_club_forms/cl_club_forms.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/account_user_form_harness.dart';
import '../../support/form_harness.dart';
import 'application_samples.dart';

const String _text = ApplicationLabelFormFields.textId;
String _in(String code) => ApplicationLabelFormFields.textFieldId(code);

Widget _form({
  required GlobalKey<ApplicationLabelFormState> key,
  Map<String, dynamic> initialValues = const {
    _text: {'en': 'Full name', 'mr': 'पूर्ण नाव'},
  },
  bool enabled = true,
}) => ApplicationLabelForm(
  key: key,
  initialValues: initialValues,
  languages: ApplicationSamples.languageOptions,
  enabled: enabled,
);

Future<ApplicationLabelFormState> _pump(
  WidgetTester tester, {
  Map<String, dynamic> initialValues = const {
    _text: {'en': 'Full name', 'mr': 'पूर्ण नाव'},
  },
}) async {
  final key = GlobalKey<ApplicationLabelFormState>();
  await pumpForm(tester, _form(key: key, initialValues: initialValues));
  return key.currentState!;
}

void main() {
  group('Issue 396: ApplicationLabelForm', () {
    testWidgets('Issue 396: an input per club language, English required; '
        'the seeded text comes back, a blank language left out', (
      tester,
    ) async {
      final state = await _pump(tester);

      expect(rowLabels(tester), ['English *', 'Marathi', 'Hindi']);
      expect(fieldIds(tester), [_in('en'), _in('mr'), _in('hi')]);
      expectLabelsAreRows(tester);
      expectNoHostChrome(tester);
      expect(state.isDirty, isFalse);
      expect(state.validate(), {
        _text: {'en': 'Full name', 'mr': 'पूर्ण नाव'},
      });
    });

    testWidgets('Issue 396: a translation typed comes back trimmed', (
      tester,
    ) async {
      final state = await _pump(tester);

      await enterField(tester, _in('hi'), '  पूरा नाम ');

      expect(state.isDirty, isTrue);
      expect(state.validate(), {
        _text: {'en': 'Full name', 'mr': 'पूर्ण नाव', 'hi': 'पूरा नाम'},
      });
    });

    testWidgets('Issue 396: English left blank is refused on its input', (
      tester,
    ) async {
      final state = await _pump(tester);

      await enterField(tester, _in('en'), '  ');

      expect(state.validate(), isNull);
      await tester.pumpAndSettle();
      expectMessageOn(_in('en'), 'A label cannot be empty');
    });

    testWidgets('Issue 396: a refusal shows on its input and inline', (
      tester,
    ) async {
      final state = await _pump(tester);
      await expectShowsServerErrors(tester, state, _in('mr'));
    });

    testWidgets('Issue 396: turned off while saving, every input is drawn '
        'off', (tester) async {
      final key = GlobalKey<ApplicationLabelFormState>();
      expect(
        await expectDrawnOffWhenTurnedOff(
          tester,
          ({required enabled}) => _form(key: key, enabled: enabled),
        ),
        3,
      );
    });

    testWidgets('Issue 396: it fits a phone', (tester) async {
      await expectFitsPhone(
        tester,
        _form(key: GlobalKey<ApplicationLabelFormState>()),
      );
    });
  });
}
