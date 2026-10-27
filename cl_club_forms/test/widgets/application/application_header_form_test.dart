// Issue 321, ApplicationHeaderForm: the short items of the header strip,
// each written here in each print language; several may be joined on one
// line (Issue 342: a printed text is text only).
import 'package:cl_club_forms/cl_club_forms.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/account_user_form_harness.dart';
import '../../support/form_harness.dart';
import 'application_form_harness.dart';
import 'application_samples.dart';
import 'application_section_harness.dart';

const String _header = ApplicationFormFields.headerId;

List<Object?> _items() => [
  {'en': 'Northfield Rink'},
  [
    {'en': 'Camp: 1–15 Nov'},
    {'en': 'Trial: 7–8 Nov'},
  ],
  {'en': 'Open to all'},
];

Widget _form({
  required GlobalKey<ApplicationHeaderFormState> key,
  List<Object?>? items,
  bool enabled = true,
}) => ApplicationHeaderForm(
  key: key,
  initialValues: {_header: items ?? _items()},
  languages: ApplicationSamples.printLanguages,
  facts: ApplicationSamples.facts,
  clauses: ApplicationSamples.clauses,
  enabled: enabled,
);

Future<ApplicationHeaderFormState> _pump(
  WidgetTester tester, {
  List<Object?>? items,
}) async {
  final key = GlobalKey<ApplicationHeaderFormState>();
  await pumpForm(tester, _form(key: key, items: items));
  return key.currentState!;
}

void main() {
  group('Issue 321: ApplicationHeaderForm', () {
    testWidgets('Issue 342: each item is written here, a joined line a text '
        'per part', (tester) async {
      await _pump(tester);

      expect(fieldIds(tester), [_header]);
      expect(find.text('Item 3'), findsOneWidget);
      expect(find.text('Camp: 1–15 Nov'), findsOneWidget);
      expect(selectsIn(_header), findsNothing);
      expect(find.text('Text from'), findsNothing);
      expectLabelsAreRows(tester);
      expectNoHostChrome(
        tester,
        allowedButtonTexts: const {'Add item', 'Add to this line'},
      );
    });

    testWidgets('Issue 321: the items come back as the template holds '
        'them, a joined line as a list', (tester) async {
      final state = await _pump(tester);

      expect(state.isDirty, isFalse);
      expect(state.validate(), {_header: _items()});
    });

    testWidgets('Issue 342: an added item is written here, and needs '
        'English', (tester) async {
      final state = await _pump(
        tester,
        items: [
          {'en': 'Northfield Rink'},
        ],
      );

      await tapIn(tester, _header, find.text('Add item'));
      expect(state.validate(), isNull);
      await tester.pump();
      expect(
        messageOn(_header, 'Item 2: Needs text in English'),
        findsOneWidget,
      );

      await typeIn(tester, _header, 2, 'Camp: 1–15 Nov');

      expect(state.isDirty, isTrue);
      expect(state.validate(), {
        _header: [
          {'en': 'Northfield Rink'},
          {'en': 'Camp: 1–15 Nov'},
        ],
      });
    });

    testWidgets('Issue 321: a text added to an item joins it on one line', (
      tester,
    ) async {
      final state = await _pump(
        tester,
        items: [
          {'en': 'Open to all'},
        ],
      );

      await tapIn(tester, _header, find.text('Add to this line'));
      await typeIn(tester, _header, 2, 'Under-14');

      expect(state.validate(), {
        _header: [
          [
            {'en': 'Open to all'},
            {'en': 'Under-14'},
          ],
        ],
      });
    });

    testWidgets('Issue 321: a fact the template does not have is refused', (
      tester,
    ) async {
      final state = await _pump(
        tester,
        items: [
          {'fact': 'city'},
        ],
      );

      expect(state.validate(), isNull);
      await tester.pump();
      expect(
        messageOn(_header, 'Item 1: There is no fact "city"'),
        findsOneWidget,
      );
    });

    testWidgets('Issue 321: a refusal shows under the list or inline; off, '
        'nothing takes input', (tester) async {
      final state = await _pump(tester);
      await expectShowsServerErrors(tester, state, _header);
      await expectSectionFormBasics(
        tester,
        ({required enabled}) => _form(
          key: GlobalKey<ApplicationHeaderFormState>(),
          enabled: enabled,
        ),
      );
    });
  });
}
