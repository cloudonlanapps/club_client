// Issue 321, ApplicationDeclarationForm: the declaration above the
// signatures, a declaration clause of the library or written here.
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
    _declaration: {'clause': 'declaration.camp'},
  },
  bool enabled = true,
}) => ApplicationDeclarationForm(
  key: key,
  initialValues: initialValues,
  languages: ApplicationSamples.printLanguages,
  facts: ApplicationSamples.facts,
  clauses: ApplicationSamples.clauses,
  enabled: enabled,
);

Future<ApplicationDeclarationFormState> _pump(
  WidgetTester tester, {
  Map<String, dynamic> initialValues = const {
    _declaration: {'clause': 'declaration.camp'},
  },
}) async {
  final key = GlobalKey<ApplicationDeclarationFormState>();
  await pumpForm(tester, _form(key: key, initialValues: initialValues));
  return key.currentState!;
}

void main() {
  group('Issue 321: ApplicationDeclarationForm', () {
    testWidgets('Issue 321: the declaration clause shows by its English '
        'text and comes back as it is', (tester) async {
      final state = await _pump(tester);

      expect(fieldIds(tester), [_declaration]);
      expect(rowLabels(tester), ['Declaration', 'Text from', 'Clause']);
      expect(
        find.text('I declare the above is true.'),
        findsNWidgets(2),
      );
      expect(state.isDirty, isFalse);
      expect(state.validate(), {
        _declaration: {'clause': 'declaration.camp'},
      });
      expectLabelsAreRows(tester);
      expectNoHostChrome(tester);
    });

    testWidgets('Issue 321: only declarations are offered', (tester) async {
      await _pump(tester);

      await openIn(tester, _declaration, 1);

      expect(find.text('Follow the rules above.'), findsNothing);
      expect(find.text('I declare the above is true.'), findsNWidgets(3));
    });

    testWidgets('Issue 321: written here it has an input per language', (
      tester,
    ) async {
      final state = await _pump(tester);

      await pickIn(tester, _declaration, 0, 'Written here');
      await typeIn(tester, _declaration, 0, 'We declare it true.');
      await typeIn(tester, _declaration, 1, 'आम्ही घोषित करतो.');

      expect(state.isDirty, isTrue);
      expect(state.validate(), {
        _declaration: {'en': 'We declare it true.', 'mr': 'आम्ही घोषित करतो.'},
      });
    });

    testWidgets('Issue 321: with none yet, a clause must be chosen', (
      tester,
    ) async {
      final state = await _pump(tester, initialValues: const {});

      expect(state.isDirty, isFalse);
      expect(state.validate(), isNull);
      await tester.pump();
      expect(messageOn(_declaration, 'Choose a clause'), findsOneWidget);
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
