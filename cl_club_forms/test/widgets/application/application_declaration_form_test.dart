// Issue 321, ApplicationDeclarationForm: the declaration above the
// signatures, written here in each print language (Issue 342: a printed
// text is text only).
import 'package:cl_club_forms/cl_club_forms.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/account_user_form_harness.dart';
import '../../support/form_harness.dart';
import 'application_form_harness.dart';
import 'application_samples.dart';
import 'application_section_harness.dart';

const String _declaration = ApplicationFormFields.declarationId;

Widget _form({
  required GlobalKey<ApplicationDeclarationFormState> key,
  Map<String, dynamic> initialValues = const {
    _declaration: {'en': 'I declare the above is true.'},
  },
  bool enabled = true,
}) => ApplicationDeclarationForm(
  key: key,
  initialValues: initialValues,
  languages: ApplicationSamples.printLanguages,
  enabled: enabled,
);

Future<ApplicationDeclarationFormState> _pump(
  WidgetTester tester, {
  Map<String, dynamic> initialValues = const {
    _declaration: {'en': 'I declare the above is true.'},
  },
}) async {
  final key = GlobalKey<ApplicationDeclarationFormState>();
  await pumpForm(tester, _form(key: key, initialValues: initialValues));
  return key.currentState!;
}

void main() {
  group('Issue 321: ApplicationDeclarationForm', () {
    testWidgets('Issue 342: the declaration shows an input per language '
        'and comes back as it is', (tester) async {
      final state = await _pump(tester);

      expect(fieldIds(tester), [_declaration]);
      expect(rowLabels(tester), ['Declaration', 'English *', 'Marathi']);
      expect(find.text('I declare the above is true.'), findsOneWidget);
      expect(state.isDirty, isFalse);
      expect(state.validate(), {
        _declaration: {'en': 'I declare the above is true.'},
      });
      expectLabelsAreRows(tester);
      expectNoHostChrome(tester);
    });

    testWidgets('Issue 342: no clause is offered: it is written here', (
      tester,
    ) async {
      final state = await _pump(tester, initialValues: const {});

      expect(find.text('Text from'), findsNothing);
      await typeIn(tester, _declaration, 0, 'We declare it true.');
      await typeIn(tester, _declaration, 1, 'आम्ही घोषित करतो.');

      expect(state.isDirty, isTrue);
      expect(state.validate(), {
        _declaration: {'en': 'We declare it true.', 'mr': 'आम्ही घोषित करतो.'},
      });
    });

    testWidgets('Issue 342: with none yet, English is needed', (tester) async {
      final state = await _pump(tester, initialValues: const {});

      expect(state.isDirty, isFalse);
      expect(state.validate(), isNull);
      await tester.pump();
      expect(messageOn(_declaration, 'Needs text in English'), findsOneWidget);
    });

    testWidgets('Issue 321: a refusal shows on the field or inline; off, '
        'nothing takes input', (tester) async {
      final state = await _pump(tester);
      await expectShowsServerErrors(tester, state, _declaration);
      await expectSectionFormBasics(
        tester,
        ({required enabled}) => _form(
          key: GlobalKey<ApplicationDeclarationFormState>(),
          enabled: enabled,
        ),
      );
    });
  });
}
