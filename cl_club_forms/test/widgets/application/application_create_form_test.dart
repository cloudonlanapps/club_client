// Issue 321, ApplicationCreateForm: what a new application draft needs,
// its English title and its print languages (English alone, or English and
// one other language of the catalogue).
import 'package:cl_club_forms/cl_club_forms.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/account_user_form_harness.dart';
import '../../support/form_harness.dart';
import 'application_samples.dart';

const String _title = ApplicationFormFields.titleId;
const String _languages = ApplicationFormFields.languagesId;

Widget _form({
  required GlobalKey<ApplicationCreateFormState> key,
  Map<String, dynamic> initialValues = const {},
  bool enabled = true,
}) => ApplicationCreateForm(
  key: key,
  initialValues: initialValues,
  languageOptions: ApplicationSamples.languageOptions,
  enabled: enabled,
);

Future<ApplicationCreateFormState> _pump(
  WidgetTester tester, {
  Map<String, dynamic> initialValues = const {},
}) async {
  final key = GlobalKey<ApplicationCreateFormState>();
  await pumpForm(tester, _form(key: key, initialValues: initialValues));
  return key.currentState!;
}

void main() {
  group('Issue 321: ApplicationCreateForm', () {
    testWidgets('Issue 321: it asks for the English title and the print '
        'languages', (tester) async {
      await _pump(tester);

      expect(rowLabels(tester), ['Title (English) *', 'Print languages']);
      expect(fieldIds(tester), [_title, _languages]);
      expect(find.text('English only'), findsOneWidget);
      expectLabelsAreRows(tester);
      expectNoHostChrome(tester);
    });

    testWidgets('Issue 321: a new draft is titled in English and printed in '
        'English alone unless another language is picked', (tester) async {
      final state = await _pump(tester);
      expect(state.isDirty, isFalse);

      await enterField(tester, _title, ' Example Club Camp ');
      expect(state.isDirty, isTrue);
      expect(state.validate(), {
        _title: {'en': 'Example Club Camp'},
        _languages: ['en'],
      });

      await pickOption(tester, _languages, 'English and Hindi');
      expect(state.validate(), {
        _title: {'en': 'Example Club Camp'},
        _languages: ['en', 'hi'],
      });
    });

    testWidgets('Issue 321: a draft copied from another starts from its '
        'title and languages', (tester) async {
      final state = await _pump(
        tester,
        initialValues: {
          _title: {'en': 'Example Club Trial', 'mr': 'उदाहरण चाचणी'},
          _languages: ['en', 'mr'],
        },
      );

      expect(find.text('English and Marathi'), findsOneWidget);
      expect(state.validate(), {
        _title: {'en': 'Example Club Trial'},
        _languages: ['en', 'mr'],
      });
    });

    testWidgets('Issue 321: no title is refused on the field', (tester) async {
      final state = await _pump(tester);

      expect(state.validate(), isNull);
      await tester.pump();
      expectMessageOn(_title, 'Needs text in English');
    });

    testWidgets('Issue 321: a refusal shows on its field or inline', (
      tester,
    ) async {
      final state = await _pump(tester);
      await expectShowsServerErrors(tester, state, _title);
    });

    testWidgets('Issue 321: turned off, nothing takes input', (tester) async {
      Widget build({required bool enabled}) => _form(
        key: GlobalKey<ApplicationCreateFormState>(),
        enabled: enabled,
      );
      expect(await expectDrawnOffWhenTurnedOff(tester, build), 2);
      expect(await expectKeyboardIgnoredWhenOff(tester, build), 1);
      await expectFitsPhone(tester, build(enabled: true));
    });
  });
}
