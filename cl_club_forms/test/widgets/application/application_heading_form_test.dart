// Issue 321, ApplicationHeadingForm: the print languages and the texts at
// the top and foot of the form. The organisation, title and footer line
// are written here, one input per print language, and so is the subtitle,
// which may be left empty (Issue 342: a printed text is text only).
import 'package:cl_club_forms/cl_club_forms.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/account_user_form_harness.dart';
import '../../support/form_harness.dart';
import 'application_form_harness.dart';
import 'application_samples.dart';

const String _languages = ApplicationFormFields.languagesId;
const String _organisation = ApplicationFormFields.organisationId;
const String _title = ApplicationFormFields.titleId;
const String _subtitle = ApplicationFormFields.subtitleId;
const String _footer = ApplicationFormFields.formFooterId;

Map<String, dynamic> _template() => {
  _languages: ['en', 'mr'],
  _organisation: {'en': 'Example Club', 'mr': 'उदाहरण क्लब'},
  _title: {'en': 'Camp Registration', 'mr': 'शिबिर नोंदणी', 'hi': 'पंजीकरण'},
  _subtitle: {'en': 'Summer camp'},
  _footer: {'en': 'See you on the ice'},
};

Widget _form({
  required GlobalKey<ApplicationHeadingFormState> key,
  Map<String, dynamic>? initialValues,
  bool enabled = true,
}) => ApplicationHeadingForm(
  key: key,
  initialValues: initialValues ?? _template(),
  languageOptions: ApplicationSamples.languageOptions,
  enabled: enabled,
);

Future<ApplicationHeadingFormState> _pump(
  WidgetTester tester, {
  Map<String, dynamic>? initialValues,
}) async {
  final key = GlobalKey<ApplicationHeadingFormState>();
  await pumpForm(tester, _form(key: key, initialValues: initialValues));
  return key.currentState!;
}

void main() {
  group('Issue 321: ApplicationHeadingForm', () {
    testWidgets('Issue 321: each written text has an input per print '
        'language, English marked where it is needed', (tester) async {
      await _pump(tester);

      expect(fieldIds(tester), [
        _languages,
        _organisation,
        _title,
        _subtitle,
        _footer,
      ]);
      expect(rowLabels(tester), [
        'Print languages',
        'Organisation',
        'English *',
        'Marathi',
        'Title',
        'English *',
        'Marathi',
        'Subtitle',
        'English',
        'Marathi',
        'Footer line',
        'English',
        'Marathi',
      ]);
      expectLabelsAreRows(tester);
      expectNoHostChrome(tester);
    });

    testWidgets('Issue 321: the seeded texts come back as the template holds '
        'them, a language not printed kept', (tester) async {
      final state = await _pump(tester);

      expect(state.isDirty, isFalse);
      expect(state.validate(), _template());
    });

    testWidgets('Issue 321: typing in a language changes only that text', (
      tester,
    ) async {
      final state = await _pump(tester);

      await typeIn(tester, _footer, 1, ' बर्फावर भेटूया ');

      expect(state.isDirty, isTrue);
      expect(state.validate()![_footer], {
        'en': 'See you on the ice',
        'mr': 'बर्फावर भेटूया',
      });
    });

    testWidgets('Issue 321: another print language gives every written text '
        'its input, filled from what the template has', (tester) async {
      final state = await _pump(tester);

      await pickOption(tester, _languages, 'English and Hindi');

      expect(find.text('Hindi'), findsNWidgets(4));
      expect(find.text('पंजीकरण'), findsOneWidget);
      expect(state.validate()![_languages], ['en', 'hi']);
    });

    testWidgets('Issue 342: the subtitle is written here, and may be left '
        'empty', (tester) async {
      final state = await _pump(tester);

      await typeIn(tester, _subtitle, 0, 'Season 2026');
      expect(state.validate()![_subtitle], {'en': 'Season 2026'});
      await typeIn(tester, _subtitle, 0, '');
      expect(state.validate()![_subtitle], isNull);
    });

    testWidgets('Issue 321: the organisation and title need English', (
      tester,
    ) async {
      final state = await _pump(tester, initialValues: const {});

      expect(state.validate(), isNull);
      await tester.pump();
      for (final id in [_organisation, _title]) {
        expect(messageOn(id, 'Needs text in English'), findsOneWidget);
      }
    });

    testWidgets('Issue 321: a refusal shows on its field or inline', (
      tester,
    ) async {
      final state = await _pump(tester);
      await expectShowsServerErrors(tester, state, _title);
    });

    testWidgets('Issue 321: turned off, nothing takes input', (tester) async {
      Widget build({required bool enabled}) => _form(
        key: GlobalKey<ApplicationHeadingFormState>(),
        enabled: enabled,
      );
      expect(await expectDrawnOffWhenTurnedOff(tester, build), 9);
      expect(await expectKeyboardIgnoredWhenOff(tester, build), 8);
      await expectFitsPhone(tester, build(enabled: true));
    });
  });
}
