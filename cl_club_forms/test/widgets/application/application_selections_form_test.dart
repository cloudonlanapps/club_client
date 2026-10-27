// Issue 321, ApplicationSelectionsForm: the additional selections a member
// ticks by hand, each written here in each print language (Issue 342: a
// printed text is text only).
import 'package:cl_club_forms/cl_club_forms.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/account_user_form_harness.dart';
import '../../support/form_harness.dart';
import 'application_form_harness.dart';
import 'application_samples.dart';
import 'application_section_harness.dart';

const String _selections = ApplicationFormFields.selectionsId;

List<Object?> _items() => [
  {'en': 'I will attend the camp.'},
  {'en': 'I bring my own kit.', 'mr': 'मी माझे साहित्य आणीन.'},
];

Widget _form({
  required GlobalKey<ApplicationSelectionsFormState> key,
  List<Object?>? items,
  bool enabled = true,
}) => ApplicationSelectionsForm(
  key: key,
  initialValues: {_selections: items ?? _items()},
  languages: ApplicationSamples.printLanguages,
  facts: ApplicationSamples.facts,
  clauses: ApplicationSamples.clauses,
  enabled: enabled,
);

Future<ApplicationSelectionsFormState> _pump(
  WidgetTester tester, {
  List<Object?>? items,
}) async {
  final key = GlobalKey<ApplicationSelectionsFormState>();
  await pumpForm(tester, _form(key: key, items: items));
  return key.currentState!;
}

void main() {
  group('Issue 321: ApplicationSelectionsForm', () {
    testWidgets('Issue 321: the selections come back as the template holds '
        'them', (tester) async {
      final state = await _pump(tester);

      expect(fieldIds(tester), [_selections]);
      expect(find.text('Selection 2'), findsOneWidget);
      expect(state.isDirty, isFalse);
      expect(state.validate(), {_selections: _items()});
      expectLabelsAreRows(tester);
      expectNoHostChrome(tester, allowedButtonTexts: const {'Add selection'});
    });

    testWidgets('Issue 342: no clause is offered: each selection is '
        'written here', (tester) async {
      await _pump(tester);

      expect(selectsIn(_selections), findsNothing);
      expect(find.text('Text from'), findsNothing);
    });

    testWidgets('Issue 321: an added selection written here comes back '
        'last', (tester) async {
      final state = await _pump(tester);

      await tapIn(tester, _selections, find.text('Add selection'));
      await typeIn(tester, _selections, 4, 'I can travel.');

      expect(state.isDirty, isTrue);
      expect((state.validate()![_selections] as List).last, {
        'en': 'I can travel.',
      });
    });

    testWidgets('Issue 321: a refusal shows under the list or inline; off, '
        'nothing takes input', (tester) async {
      final state = await _pump(tester);
      await expectShowsServerErrors(tester, state, _selections);
      await expectSectionFormBasics(
        tester,
        ({required enabled}) => _form(
          key: GlobalKey<ApplicationSelectionsFormState>(),
          enabled: enabled,
        ),
      );
    });
  });
}
