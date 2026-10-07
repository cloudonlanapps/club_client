import 'package:cl_club_forms/cl_club_forms.dart';
import 'package:cl_club_forms/src/widgets/event_cancellation/event_cancellation_form_validators.dart'
    show EventCancellationFormValidators;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../support/form_harness.dart';

// Issue 61, points that do not apply to EventCancellationForm: it has no rule
// across fields, and no parameter locks a field (an empty `sessions` hides
// the select, which is covered).

final _first = DateTime.utc(2030, 6, 15, 6);
final _second = DateTime.utc(2030, 6, 16, 6);

final _sessions = [
  EventCancellationSession(start: _first, label: 'Sat 15 Jun, 06:00'),
  EventCancellationSession(start: _second, label: 'Sun 16 Jun, 06:00'),
];

Future<GlobalKey<EventCancellationFormState>> _pump(
  WidgetTester tester, {
  List<EventCancellationSession> sessions = const [],
}) async {
  final key = GlobalKey<EventCancellationFormState>();
  await tester.pumpWidget(
    ShadApp(
      home: Scaffold(
        body: EventCancellationForm(key: key, sessions: sessions),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return key;
}

Future<void> _typeReason(WidgetTester tester, String reason) async {
  await tester.enterText(find.byType(EditableText), reason);
  await tester.pump();
}

void main() {
  group('Issue 40: EventCancellationFormValidators', () {
    test('Issue 40: a reason is required', () {
      expect(
        EventCancellationFormValidators.reason('   '),
        EventCancellationFormValidators.reasonRequired,
      );
      expect(EventCancellationFormValidators.reason('Rink closed'), isNull);
    });

    test('Issue 40: a reason longer than the server accepts is refused', () {
      const limit = EventCancellationFormFields.reasonMaxLength;
      expect(EventCancellationFormValidators.reason('a' * limit), isNull);
      expect(
        EventCancellationFormValidators.reason('a' * (limit + 1)),
        EventCancellationFormValidators.reasonTooLong,
      );
    });

    test('Issue 40: a session is required', () {
      expect(
        EventCancellationFormValidators.fromSession(null),
        EventCancellationFormValidators.fromSessionRequired,
      );
      expect(EventCancellationFormValidators.fromSession(_first), isNull);
    });
  });

  group('Issue 40: EventCancellationForm', () {
    testWidgets('Issue 40: without a reason it does not validate', (
      tester,
    ) async {
      final key = await _pump(tester);

      expect(key.currentState!.validate(), isNull);
      await tester.pumpAndSettle();

      expect(
        find.text(EventCancellationFormValidators.reasonRequired),
        findsOneWidget,
      );
    });

    testWidgets('Issue 40: a one-off has a reason and no session to choose', (
      tester,
    ) async {
      final key = await _pump(tester);
      expect(find.text('Cancel from *'), findsNothing);

      await _typeReason(tester, '  Rink closed  ');

      expect(key.currentState!.validate(), {
        EventCancellationFormFields.fromSessionId: null,
        EventCancellationFormFields.reasonId: 'Rink closed',
      });
    });

    testWidgets('Issue 40: a camp starts from the next session by default', (
      tester,
    ) async {
      final key = await _pump(tester, sessions: _sessions);
      expect(find.text('Cancel from *'), findsOneWidget);
      expect(find.text('Sat 15 Jun, 06:00'), findsOneWidget);

      await _typeReason(tester, 'Rink closed');

      expect(key.currentState!.validate(), {
        EventCancellationFormFields.fromSessionId: _first,
        EventCancellationFormFields.reasonId: 'Rink closed',
      });
    });

    testWidgets('Issue 40: a later session can be chosen', (tester) async {
      final key = await _pump(tester, sessions: _sessions);
      await _typeReason(tester, 'Rink closed');

      await tester.tap(find.text('Sat 15 Jun, 06:00'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sun 16 Jun, 06:00').last);
      await tester.pumpAndSettle();

      expect(
        key.currentState!
            .validate()![EventCancellationFormFields.fromSessionId],
        _second,
      );
    });
  });

  group('Issue 61: EventCancellationFormValidators', () {
    test('Issue 61: the reason is judged trimmed', () {
      const limit = EventCancellationFormFields.reasonMaxLength;
      expect(
        EventCancellationFormValidators.reason(''),
        EventCancellationFormValidators.reasonRequired,
      );
      // Surrounding blanks do not count towards the limit.
      expect(
        EventCancellationFormValidators.reason('  ${'a' * limit}  '),
        isNull,
      );
      expect(EventCancellationFormValidators.reason('a'), isNull);
    });

    test('Issue 61: the limit is 500 and its message names it', () {
      expect(EventCancellationFormFields.reasonMaxLength, 500);
      expect(
        EventCancellationFormValidators.reasonTooLong,
        'Keep the reason within 500 characters',
      );
    });
  });

  group('Issue 61: EventCancellationForm', () {
    Future<EventCancellationFormState> pump(
      WidgetTester tester, {
      List<EventCancellationSession> sessions = const [],
      bool enabled = true,
      Size size = kFormSurface,
    }) async {
      final key = GlobalKey<EventCancellationFormState>();
      await pumpForm(
        tester,
        EventCancellationForm(key: key, sessions: sessions, enabled: enabled),
        size: size,
      );
      return key.currentState!;
    }

    const reasonId = EventCancellationFormFields.reasonId;
    const fromId = EventCancellationFormFields.fromSessionId;

    testWidgets('Issue 61: a camp shows Cancel from and Reason, both required '
        'rows', (tester) async {
      await pump(tester, sessions: _sessions);

      expect(rowLabels(tester), ['Cancel from *', 'Reason *']);
      expectLabelsAreRows(tester);
      expect(fieldWithId(fromId), findsOneWidget);
      expect(fieldWithId(reasonId), findsOneWidget);
    });

    testWidgets('Issue 61: without sessions the select is hidden and Reason '
        'is the only row', (tester) async {
      final form = await pump(tester);

      expect(rowLabels(tester), ['Reason *']);
      expect(fieldWithId(fromId), findsNothing);
      expect(form.formKey.currentState!.fields.keys, [reasonId]);
    });

    testWidgets('Issue 61: the reason field shows the placeholder it is '
        'given', (tester) async {
      await pumpForm(
        tester,
        const EventCancellationForm(reasonPlaceholder: 'Why is it off?'),
      );

      expect(
        find.descendant(
          of: fieldWithId(reasonId),
          matching: find.text('Why is it off?'),
        ),
        findsOneWidget,
      );
      expect(find.text('e.g., Venue unavailable'), findsNothing);
    });

    testWidgets('Issue 61: a blank reason is refused on the reason field', (
      tester,
    ) async {
      final form = await pump(tester, sessions: _sessions);
      await enterField(tester, reasonId, '   ');

      expect(form.validate(), isNull);
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: fieldWithId(reasonId),
          matching: find.text(EventCancellationFormValidators.reasonRequired),
        ),
        findsOneWidget,
      );
    });

    testWidgets('Issue 61: a reason over 500 characters is refused on the '
        'field, one of 500 is accepted', (tester) async {
      final form = await pump(tester);
      const limit = EventCancellationFormFields.reasonMaxLength;

      await enterField(tester, reasonId, 'a' * (limit + 1));
      expect(form.validate(), isNull);
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: fieldWithId(reasonId),
          matching: find.text(EventCancellationFormValidators.reasonTooLong),
        ),
        findsOneWidget,
      );

      await enterField(tester, reasonId, 'a' * limit);
      expect(form.validate(), isNotNull);
      await tester.pumpAndSettle();
      expect(
        find.text(EventCancellationFormValidators.reasonTooLong),
        findsNothing,
      );
    });

    testWidgets('Issue 61: with no session chosen it is refused on the '
        'select', (tester) async {
      final form = await pump(tester, sessions: _sessions);
      await enterField(tester, reasonId, 'Rink closed');
      await setField(tester, form, fromId, null);

      expect(form.validate(), isNull);
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: fieldWithId(fromId),
          matching: find.text(
            EventCancellationFormValidators.fromSessionRequired,
          ),
        ),
        findsOneWidget,
      );

      await setField(tester, form, fromId, _second);
      expect(form.validate(), {fromId: _second, reasonId: 'Rink closed'});
    });

    testWidgets('Issue 61: validate returns a DateTime and a String under '
        'the two ids, and nothing else', (tester) async {
      final form = await pump(tester, sessions: _sessions);
      await enterField(tester, reasonId, '\n Rink closed \n');

      final values = form.validate()!;

      expect(values.keys, [fromId, reasonId]);
      expect(values[fromId], isA<DateTime>());
      expect(values[reasonId], isA<String>());
      expect(values[reasonId], 'Rink closed');
    });

    testWidgets('Issue 61: a one-off returns the session key, null', (
      tester,
    ) async {
      final form = await pump(tester);
      await enterField(tester, reasonId, 'Rink closed');

      final values = form.validate()!;

      expect(values.keys, [fromId, reasonId]);
      expect(values[fromId], isNull);
    });

    testWidgets('Issue 61: isDirty follows the reason: clean, changed, '
        'emptied again', (tester) async {
      final form = await pump(tester, sessions: _sessions);
      expect(form.isDirty, isFalse);

      await enterField(tester, reasonId, 'Rink closed');
      expect(form.isDirty, isTrue);

      await enterField(tester, reasonId, '');
      expect(form.isDirty, isFalse);
    });

    testWidgets('Issue 61: isDirty follows the session: another chosen, '
        'the first chosen again', (tester) async {
      final form = await pump(tester, sessions: _sessions);

      await tester.tap(find.text('Sat 15 Jun, 06:00'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sun 16 Jun, 06:00').last);
      await tester.pumpAndSettle();
      expect(form.isDirty, isTrue);

      await tester.tap(find.text('Sun 16 Jun, 06:00'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sat 15 Jun, 06:00').last);
      await tester.pumpAndSettle();
      expect(form.isDirty, isFalse);
    });

    testWidgets('Issue 61: a one-off is clean when untouched', (tester) async {
      final form = await pump(tester);
      expect(form.isDirty, isFalse);
    });

    testWidgets('Issue 61: what the server refuses shows on the reason and '
        'on the session, and inline', (tester) async {
      final form = await pump(tester, sessions: _sessions);

      await expectShowsServerErrors(tester, form, reasonId);
      await expectShowsServerErrors(tester, form, fromId);
    });

    testWidgets('Issue 61: after a refusal the form validates and returns '
        'its values again', (tester) async {
      final form = await pump(tester, sessions: _sessions);
      await enterField(tester, reasonId, 'Rink closed');

      form.showErrors(
        fieldErrors: const {reasonId: 'Too vague.'},
        formError: 'Could not cancel.',
      );
      await tester.pumpAndSettle();
      expect(find.text('Too vague.'), findsOneWidget);
      expect(find.text('Could not cancel.'), findsOneWidget);

      expect(form.validate(), {fromId: _first, reasonId: 'Rink closed'});
      await tester.pumpAndSettle();
      expect(find.text('Too vague.'), findsNothing);
      expect(find.text('Could not cancel.'), findsNothing);
    });

    testWidgets('Issue 61: enabled false leaves the reason and the select '
        'unresponsive', (tester) async {
      final form = await pump(tester, sessions: _sessions, enabled: false);

      expect(
        tester.widget<ShadInputFormField>(fieldWithId(reasonId)).enabled,
        isFalse,
      );
      await tester.tap(find.text('Sat 15 Jun, 06:00'), warnIfMissed: false);
      await tester.pumpAndSettle();
      // No option list opened: the other session is nowhere to tap.
      expect(find.text('Sun 16 Jun, 06:00'), findsNothing);

      await tester.tap(fieldWithId(reasonId), warnIfMissed: false);
      await tester.pumpAndSettle();
      tester.testTextInput.enterText('Rink closed');
      await tester.pumpAndSettle();

      expect(form.formKey.currentState!.value, {
        fromId: _first,
        reasonId: '',
      });
      expect(form.isDirty, isFalse);
    });

    testWidgets('Issue 61: it fits a phone, long session labels included', (
      tester,
    ) async {
      await expectFitsPhone(
        tester,
        EventCancellationForm(
          sessions: [
            EventCancellationSession(
              start: _first,
              label:
                  'Saturday 15 June 2030, 06:00 to 08:30, ${'Main Rink ' * 6}',
            ),
          ],
        ),
      );
      expect(rowLabels(tester), ['Cancel from *', 'Reason *']);
    });

    testWidgets('Issue 61: it draws no button of its own', (tester) async {
      await pump(tester, sessions: _sessions);
      expectNoHostChrome(tester);
    });
  });
}
