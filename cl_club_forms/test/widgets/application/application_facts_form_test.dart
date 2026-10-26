// Issue 321, ApplicationFactsForm: the values that change each time,
// typed once and named, each of a type: a name (as typed, or per print
// language), a day, a range of days, a time, an amount or choices of the
// library's list. Names are unique, non-empty and identifier-like.
import 'package:cl_club_forms/cl_club_forms.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../support/account_user_form_harness.dart';
import '../../support/form_harness.dart';
import 'application_form_harness.dart';
import 'application_samples.dart';

const String _facts = ApplicationFormFields.factsId;

Map<String, Object?> _all() => {
  'venue': {
    'type': 'name',
    'value': {'en': 'City Rink', 'mr': 'शहर रिंक'},
  },
  'phone': {'type': 'name', 'value': '555 0100'},
  'camp': {'type': 'date_range', 'from': '2026-11-16', 'to': '2026-11-17'},
  'arrive': {'type': 'date', 'value': '2026-11-15'},
  'report': {'type': 'time', 'value': '06:00'},
  'fee': {'type': 'amount', 'value': 1500},
  'kinds': {
    'type': 'choices',
    'value': ['on_ice'],
  },
};

Widget _form({
  required GlobalKey<ApplicationFactsFormState> key,
  Map<String, Object?>? facts,
  bool enabled = true,
}) => ApplicationFactsForm(
  key: key,
  initialValues: {_facts: facts ?? _all()},
  languages: ApplicationSamples.printLanguages,
  choices: ApplicationSamples.choices,
  enabled: enabled,
);

Future<ApplicationFactsFormState> _pump(
  WidgetTester tester, {
  Map<String, Object?>? facts,
  Size size = kFormSurface,
}) async {
  final key = GlobalKey<ApplicationFactsFormState>();
  await pumpForm(
    tester,
    _form(key: key, facts: facts),
    size: size,
  );
  return key.currentState!;
}

void main() {
  group('Issue 321: ApplicationFactsForm', () {
    testWidgets('Issue 321: a fact shows its name, its type and the inputs '
        'of its value', (tester) async {
      await _pump(
        tester,
        facts: {
          'venue': {'type': 'name', 'value': 'City Rink'},
        },
      );

      expect(fieldIds(tester), [_facts]);
      expect(rowLabels(tester), [
        'Facts',
        'Name *',
        'Type',
        'English *',
        'Marathi',
      ]);
      expect(find.text('Fact 1'), findsOneWidget);
      expectLabelsAreRows(tester);
      expectNoHostChrome(tester, allowedButtonTexts: const {'Add fact'});
    });

    testWidgets('Issue 321: every type of value comes back as the template '
        'holds it, a name typed once as one text', (tester) async {
      final state = await _pump(tester);

      expect(find.text('16 Nov 2026'), findsOneWidget);
      expect(find.text('17 Nov 2026'), findsOneWidget);
      expect(state.isDirty, isFalse);
      expect(state.validate(), {_facts: _all()});
    });

    testWidgets('Issue 321: an added fact is a name until its type is '
        'changed, and comes back last', (tester) async {
      final state = await _pump(
        tester,
        facts: {
          'venue': {'type': 'name', 'value': 'City Rink'},
        },
      );

      await tapIn(tester, _facts, find.text('Add fact'));
      await typeIn(tester, _facts, 3, ' city ');
      await typeIn(tester, _facts, 4, 'Example Town');
      await typeIn(tester, _facts, 5, 'उदाहरण नगर');

      expect(state.isDirty, isTrue);
      expect(state.validate(), {
        _facts: {
          'venue': {'type': 'name', 'value': 'City Rink'},
          'city': {
            'type': 'name',
            'value': {'en': 'Example Town', 'mr': 'उदाहरण नगर'},
          },
        },
      });
    });

    testWidgets('Issue 321: an amount, a time and a choice are typed and '
        'ticked', (tester) async {
      final state = await _pump(
        tester,
        facts: {
          'fee': {'type': 'amount', 'value': 1500},
          'report': {'type': 'time', 'value': '06:00'},
          'kinds': {
            'type': 'choices',
            'value': ['on_ice'],
          },
        },
      );

      await typeIn(tester, _facts, 1, '2500');
      await typeIn(tester, _facts, 3, '07');
      await tapIn(tester, _facts, find.byType(ShadCheckbox), 1);

      expect(state.validate(), {
        _facts: {
          'fee': {'type': 'amount', 'value': 2500},
          'report': {'type': 'time', 'value': '07:00'},
          'kinds': {
            'type': 'choices',
            'value': ['on_ice', 'inline'],
          },
        },
      });
    });

    testWidgets('Issue 321: a fact whose type changes asks for the new '
        'value', (tester) async {
      final state = await _pump(
        tester,
        facts: {
          'venue': {'type': 'name', 'value': 'City Rink'},
        },
      );

      await pickIn(tester, _facts, 0, 'date');

      expect(find.text('Day'), findsOneWidget);
      expect(state.validate(), isNull);
      await tester.pump();
      expect(messageOn(_facts, 'Fact 1: Pick a date'), findsOneWidget);
    });

    testWidgets('Issue 321: facts are removed and moved', (tester) async {
      final state = await _pump(
        tester,
        facts: {
          'venue': {'type': 'name', 'value': 'City Rink'},
          'phone': {'type': 'name', 'value': '555 0100'},
          'fee': {'type': 'amount', 'value': 10},
        },
      );

      await tapIn(tester, _facts, find.byIcon(LucideIcons.trash2));
      await tapIn(tester, _facts, find.byIcon(LucideIcons.arrowUp), 1);

      expect(
        (state.validate()![_facts] as Map).keys,
        ['fee', 'phone'],
      );
    });

    final refusals = <(String, Map<String, Object?>, String)>[
      (
        'a name not like an identifier',
        {
          'Venue': {'type': 'name', 'value': 'City Rink'},
        },
        'Fact 1: "Venue" is not a fact name: use lower-case letters, '
            'digits and _, starting with a letter',
      ),
      (
        'a name with no English',
        {
          'venue': {
            'type': 'name',
            'value': {'mr': 'रिंक'},
          },
        },
        'Fact 1: Needs text in English',
      ),
      (
        'a range ending before it starts',
        {
          'camp': {
            'type': 'date_range',
            'from': '2026-11-17',
            'to': '2026-11-16',
          },
        },
        'Fact 1: The last day is before the first',
      ),
    ];
    for (final (rule, facts, message) in refusals) {
      testWidgets('Issue 321: refuses $rule under the list', (tester) async {
        final state = await _pump(tester, facts: facts);

        expect(state.validate(), isNull);
        await tester.pump();
        expect(messageOn(_facts, message), findsOneWidget);
      });
    }

    testWidgets('Issue 321: two facts of one name are refused', (
      tester,
    ) async {
      final state = await _pump(
        tester,
        facts: {
          'venue': {'type': 'name', 'value': 'City Rink'},
        },
      );

      await tapIn(tester, _facts, find.text('Add fact'));
      await typeIn(tester, _facts, 3, 'venue');
      await typeIn(tester, _facts, 4, 'Town Hall');

      expect(state.validate(), isNull);
      await tester.pump();
      expect(
        messageOn(_facts, 'Fact 2: Two facts are named "venue"'),
        findsOneWidget,
      );
    });

    testWidgets('Issue 321: a refusal shows under the list or inline', (
      tester,
    ) async {
      final state = await _pump(tester);
      await expectShowsServerErrors(tester, state, _facts);
    });

    testWidgets('Issue 321: turned off, nothing takes input; it fits a '
        'phone', (tester) async {
      Widget build({required bool enabled}) => _form(
        key: GlobalKey<ApplicationFactsFormState>(),
        enabled: enabled,
      );
      expect(await expectDrawnOffWhenTurnedOff(tester, build), greaterThan(20));
      expect(await expectKeyboardIgnoredWhenOff(tester, build), 14);
      await expectFitsPhone(tester, build(enabled: true));
    });
  });
}
