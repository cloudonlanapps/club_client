// Issue 321, ApplicationHeaderForm: the short items of the header strip.
// Each is a fact, a header clause of the library with its gaps bound to
// facts, or written here; several may be joined on one line.
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
  {'fact': 'venue'},
  [
    {
      'clause': 'header.camp',
      'args': {'dates': 'camp'},
    },
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
    testWidgets('Issue 321: each item shows where its text comes from, a '
        'clause its English text and a fact for each gap', (tester) async {
      await _pump(tester);

      expect(fieldIds(tester), [_header]);
      expect(find.text('Item 3'), findsOneWidget);
      expect(find.text('venue (name)'), findsOneWidget);
      expect(find.text('Camp: {dates}'), findsNWidgets(2));
      expect(find.text('{dates}: date range'), findsOneWidget);
      expect(find.text('camp (date range)'), findsOneWidget);
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

    testWidgets('Issue 321: an added item is a clause, which needs choosing '
        'and its gap a fact of the right type', (tester) async {
      final state = await _pump(
        tester,
        items: [
          {'fact': 'venue'},
        ],
      );

      await tapIn(tester, _header, find.text('Add item'));
      expect(state.validate(), isNull);
      await tester.pump();
      expect(messageOn(_header, 'Item 2: Choose a clause'), findsOneWidget);

      await pickIn(tester, _header, 3, 'Camp: {dates}');
      expect(state.validate(), isNull);
      await tester.pump();
      expect(
        messageOn(_header, 'Item 2: Choose a fact for {dates}'),
        findsOneWidget,
      );

      await openIn(tester, _header, 4);
      expect(find.text('venue (name)'), findsOneWidget);
      await tester.tap(find.text('trial (date range)').last);
      await tester.pumpAndSettle();

      expect(state.isDirty, isTrue);
      expect(state.validate(), {
        _header: [
          {'fact': 'venue'},
          {
            'clause': 'header.camp',
            'args': {'dates': 'trial'},
          },
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
      await pickIn(tester, _header, 1, 'A fact');
      await pickIn(tester, _header, 2, 'phone (name)');

      expect(state.validate(), {
        _header: [
          [
            {'en': 'Open to all'},
            {'fact': 'phone'},
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
