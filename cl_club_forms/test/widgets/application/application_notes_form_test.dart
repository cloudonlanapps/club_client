// Issue 321, ApplicationNotesForm: the notes boxed under the terms, each
// written here with an optional attribution (Issue 342: a printed text is
// text only).
import 'package:cl_club_forms/cl_club_forms.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/account_user_form_harness.dart';
import '../../support/form_harness.dart';
import 'application_form_harness.dart';
import 'application_samples.dart';
import 'application_section_harness.dart';

const String _notes = ApplicationFormFields.termsNotesId;

Widget _form({
  required GlobalKey<ApplicationNotesFormState> key,
  List<Object?>? items,
  bool enabled = true,
}) => ApplicationNotesForm(
  key: key,
  initialValues: {
    _notes:
        items ??
        [
          {
            'text': {'en': 'Follow the rules above.'},
          },
        ],
  },
  languages: ApplicationSamples.printLanguages,
  enabled: enabled,
);

Future<ApplicationNotesFormState> _pump(
  WidgetTester tester, {
  List<Object?>? items,
}) async {
  final key = GlobalKey<ApplicationNotesFormState>();
  await pumpForm(tester, _form(key: key, items: items));
  return key.currentState!;
}

void main() {
  group('Issue 321: ApplicationNotesForm', () {
    testWidgets('Issue 321: a note shows its text and an attribution per '
        'language', (tester) async {
      await _pump(tester);

      expect(fieldIds(tester), [_notes]);
      expect(rowLabels(tester), [
        'Notes',
        'English *',
        'Marathi',
        'Attribution (English)',
        'Attribution (Marathi)',
      ]);
      expectLabelsAreRows(tester);
      expectNoHostChrome(tester, allowedButtonTexts: const {'Add note'});
    });

    testWidgets('Issue 321: a note given as a bare text comes back under '
        'its text, with its attribution', (tester) async {
      final state = await _pump(
        tester,
        items: [
          {'en': 'Follow the rules above.'},
          {
            'text': {'en': 'Play fair.', 'mr': 'खिलाडूवृत्ती ठेवा.'},
            'attribution': {'en': '— Example Club'},
          },
        ],
      );

      expect(state.isDirty, isFalse);
      expect(state.validate(), {
        _notes: [
          {
            'text': {'en': 'Follow the rules above.'},
          },
          {
            'text': {'en': 'Play fair.', 'mr': 'खिलाडूवृत्ती ठेवा.'},
            'attribution': {'en': '— Example Club'},
          },
        ],
      });
    });

    testWidgets('Issue 321: an attribution typed is added to its note', (
      tester,
    ) async {
      final state = await _pump(tester);

      await typeIn(tester, _notes, 2, '— Example Club');

      expect(state.isDirty, isTrue);
      expect(state.validate(), {
        _notes: [
          {
            'text': {'en': 'Follow the rules above.'},
            'attribution': {'en': '— Example Club'},
          },
        ],
      });
    });

    testWidgets('Issue 321: an attribution with no English is refused', (
      tester,
    ) async {
      final state = await _pump(
        tester,
        items: [
          {
            'text': {'en': 'Follow the rules above.'},
            'attribution': {'mr': 'क्लब'},
          },
        ],
      );

      expect(state.validate(), isNull);
      await tester.pump();
      expect(
        messageOn(_notes, 'Note 1: Attribution: Needs text in English'),
        findsOneWidget,
      );
    });

    testWidgets('Issue 321: a refusal shows under the list or inline; off, '
        'nothing takes input', (tester) async {
      final state = await _pump(tester);
      await expectShowsServerErrors(tester, state, _notes);
      await expectSectionFormBasics(
        tester,
        ({required enabled}) => _form(
          key: GlobalKey<ApplicationNotesFormState>(),
          enabled: enabled,
        ),
      );
    });
  });
}
