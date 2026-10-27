// Issue 321, ApplicationTermsForm: the terms printed from page 2, each a
// heading and a text written in each print language (Issue 342: a printed
// text is text only).
import 'package:cl_club_forms/cl_club_forms.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/account_user_form_harness.dart';
import '../../support/form_harness.dart';
import 'application_form_harness.dart';
import 'application_samples.dart';
import 'application_section_harness.dart';

const String _terms = ApplicationFormFields.termsId;

List<Object?> _items() => [
  {
    'heading': {'en': 'Fee', 'mr': 'शुल्क'},
    'body': {'en': 'A fee of 500 is payable.'},
  },
  {
    'heading': {'en': 'Kit', 'mr': 'साहित्य'},
    'body': {'en': 'Bring a helmet.'},
  },
];

Widget _form({
  required GlobalKey<ApplicationTermsFormState> key,
  List<Object?>? items,
  bool enabled = true,
}) => ApplicationTermsForm(
  key: key,
  initialValues: {_terms: items ?? _items()},
  languages: ApplicationSamples.printLanguages,
  facts: ApplicationSamples.facts,
  clauses: ApplicationSamples.clauses,
  enabled: enabled,
);

Future<ApplicationTermsFormState> _pump(
  WidgetTester tester, {
  List<Object?>? items,
}) async {
  final key = GlobalKey<ApplicationTermsFormState>();
  await pumpForm(tester, _form(key: key, items: items));
  return key.currentState!;
}

void main() {
  group('Issue 321: ApplicationTermsForm', () {
    testWidgets('Issue 342: each term has a heading and a text per '
        'language', (tester) async {
      await _pump(tester);

      expect(fieldIds(tester), [_terms]);
      expect(rowLabels(tester), [
        'Terms',
        for (var i = 0; i < 2; i++) ...[
          'Heading (English) *',
          'Heading (Marathi)',
          'Text (English) *',
          'Text (Marathi)',
        ],
      ]);
      expect(find.text('A fee of 500 is payable.'), findsOneWidget);
      expectLabelsAreRows(tester);
      expectNoHostChrome(tester, allowedButtonTexts: const {'Add term'});
    });

    testWidgets('Issue 321: the terms come back as the template holds '
        'them', (tester) async {
      final state = await _pump(tester);

      expect(state.isDirty, isFalse);
      expect(state.validate(), {_terms: _items()});
    });

    testWidgets('Issue 342: an added term is written here', (tester) async {
      final state = await _pump(tester);

      await tapIn(tester, _terms, find.text('Add term'));
      expect(state.validate(), isNull);
      await tester.pump();
      expect(
        messageOn(_terms, 'Term 3: Heading: Needs text in English'),
        findsOneWidget,
      );

      await typeIn(tester, _terms, 8, 'Travel');
      await typeIn(tester, _terms, 10, 'Arrange your own travel.');

      expect(state.isDirty, isTrue);
      expect((state.validate()![_terms] as List).last, {
        'heading': {'en': 'Travel'},
        'body': {'en': 'Arrange your own travel.'},
      });
    });

    testWidgets('Issue 342: no clause is offered', (tester) async {
      await _pump(tester);

      expect(selectsIn(_terms), findsNothing);
      expect(find.text('Text from'), findsNothing);
    });

    testWidgets('Issue 321: a term written here needs its text', (
      tester,
    ) async {
      final state = await _pump(
        tester,
        items: [
          {
            'heading': {'en': 'Kit'},
          },
        ],
      );

      expect(state.validate(), isNull);
      await tester.pump();
      expect(
        messageOn(_terms, 'Term 1: Text: Needs text in English'),
        findsOneWidget,
      );
    });

    testWidgets('Issue 321: a refusal shows under the list or inline; off, '
        'nothing takes input', (tester) async {
      final state = await _pump(tester);
      await expectShowsServerErrors(tester, state, _terms);
      await expectSectionFormBasics(
        tester,
        ({required enabled}) => _form(
          key: GlobalKey<ApplicationTermsFormState>(),
          enabled: enabled,
        ),
      );
    });
  });
}
