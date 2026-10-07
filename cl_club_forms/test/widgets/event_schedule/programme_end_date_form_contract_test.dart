// Points of issue 61 that do not apply to ProgrammeEndDateForm: it has no
// rule across fields and no field a parameter hides (`reasonRequired` only
// marks the Reason row and turns its rule on). The day is picked in a
// calendar, so the tests set it through the form.
import 'package:cl_calendar/cl_calendar.dart' show CLDatePicker;
import 'package:cl_club_forms/cl_club_forms.dart';
import 'package:cl_club_forms/src/widgets/event_schedule/programme_end_date_form_validators.dart'
    show ProgrammeEndDateFormValidators;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../support/form_harness.dart';

/// The local day [days] from today.
DateTime _day(int days) {
  final t = DateTime.now().add(Duration(days: days));
  return DateTime(t.year, t.month, t.day);
}

/// What the form returns for [lastDay] and [reason].
Map<String, dynamic> _values(DateTime lastDay, {String reason = ''}) => {
  ProgrammeEndDateFormFields.lastDayId: lastDay,
  ProgrammeEndDateFormFields.reasonId: reason,
};

Future<void> _pick(
  WidgetTester tester,
  ProgrammeEndDateFormState state,
  DateTime day,
) async {
  state.formKey.currentState!.setFieldValue<DateTime?>(
    ProgrammeEndDateFormFields.lastDayId,
    day,
  );
  await tester.pumpAndSettle();
}

/// Mounts the form through the shared harness and returns its state.
Future<ProgrammeEndDateFormState> _mount(
  WidgetTester tester, {
  bool reasonRequired = false,
  DateTime? initialDay,
  bool enabled = true,
}) async {
  final key = GlobalKey<ProgrammeEndDateFormState>();
  await pumpForm(
    tester,
    ProgrammeEndDateForm(
      key: key,
      initialDay: initialDay,
      reasonRequired: reasonRequired,
      enabled: enabled,
      resultOf: (day) => 'Last session: day ${day.day}.',
    ),
  );
  return key.currentState!;
}

Finder _onField(String id, String message) =>
    find.descendant(of: fieldWithId(id), matching: find.text(message));

void main() {
  group('Issue 61: ProgrammeEndDateForm fields', () {
    testWidgets('Issue 61: Last day is required, and Reason is marked '
        'required only when the host needs one', (tester) async {
      await _mount(tester, reasonRequired: true);
      expect(rowLabels(tester), ['Last day *', 'Reason *']);
      expectLabelsAreRows(tester);

      await _mount(tester, reasonRequired: false);
      expect(rowLabels(tester), ['Last day *', 'Reason']);
      expectLabelsAreRows(tester);
    });

    testWidgets('Issue 61: the result line shows for the day the programme '
        'ends on now, and goes when the day is cleared', (tester) async {
      final state = await _mount(tester, initialDay: _day(9));
      expect(find.text('Last session: day ${_day(9).day}.'), findsOneWidget);

      await setField(
        tester,
        state,
        ProgrammeEndDateFormFields.lastDayId,
        null,
      );
      expect(find.textContaining('Last session'), findsNothing);
    });
  });

  group('Issue 61: ProgrammeEndDateForm validation', () {
    testWidgets('Issue 61: no day is refused on Last day', (tester) async {
      final state = await _mount(tester);

      expect(state.validate(), isNull);
      await tester.pumpAndSettle();

      expect(
        _onField(
          ProgrammeEndDateFormFields.lastDayId,
          ProgrammeEndDateFormValidators.dayRequiredMessage,
        ),
        findsOneWidget,
      );
    });

    testWidgets('Issue 61: yesterday is refused on Last day', (tester) async {
      final state = await _mount(tester, initialDay: _day(-1));

      expect(state.validate(), isNull);
      await tester.pumpAndSettle();

      expect(
        _onField(
          ProgrammeEndDateFormFields.lastDayId,
          ProgrammeEndDateFormValidators.dayInPastMessage,
        ),
        findsOneWidget,
      );
    });

    testWidgets('Issue 61: a missing or blank reason is refused on Reason '
        'when one is needed', (tester) async {
      final state = await _mount(
        tester,
        reasonRequired: true,
        initialDay: _day(9),
      );

      for (final typed in ['', '   ']) {
        await enterField(tester, ProgrammeEndDateFormFields.reasonId, typed);
        expect(state.validate(), isNull);
        await tester.pumpAndSettle();
        expect(
          _onField(
            ProgrammeEndDateFormFields.reasonId,
            ProgrammeEndDateFormValidators.reasonRequiredMessage,
          ),
          findsOneWidget,
        );
      }
    });

    testWidgets('Issue 61: a reason over 500 characters is refused on '
        'Reason; 500 are accepted', (tester) async {
      final state = await _mount(tester, initialDay: _day(9));

      // The input stops typing at 500, so the longer text goes in through
      // the form.
      await setField(
        tester,
        state,
        ProgrammeEndDateFormFields.reasonId,
        'x' * 501,
      );
      expect(state.validate(), isNull);
      await tester.pumpAndSettle();
      expect(
        _onField(
          ProgrammeEndDateFormFields.reasonId,
          ProgrammeEndDateFormValidators.reasonTooLongMessage,
        ),
        findsOneWidget,
      );

      await setField(
        tester,
        state,
        ProgrammeEndDateFormFields.reasonId,
        'x' * 500,
      );
      expect(state.validate(), _values(_day(9), reason: 'x' * 500));
    });

    testWidgets('Issue 61: the Reason input takes no more than 500 '
        'characters', (tester) async {
      final state = await _mount(tester, initialDay: _day(9));

      await enterField(
        tester,
        ProgrammeEndDateFormFields.reasonId,
        'x' * 600,
      );

      expect(state.reason, hasLength(500));
    });
  });

  group('Issue 61: ProgrammeEndDateForm values', () {
    testWidgets('Issue 61: validate returns exactly the day and the trimmed '
        'reason, typed', (tester) async {
      final state = await _mount(tester, initialDay: _day(9));
      await enterField(
        tester,
        ProgrammeEndDateFormFields.reasonId,
        '  Rink closes  ',
      );

      final values = state.validate()!;

      expect(values.keys, [
        ProgrammeEndDateFormFields.lastDayId,
        ProgrammeEndDateFormFields.reasonId,
      ]);
      expect(values[ProgrammeEndDateFormFields.lastDayId], isA<DateTime>());
      expect(values, _values(_day(9), reason: 'Rink closes'));
    });

    testWidgets('Issue 61: reason gives what is typed, trimmed, before any '
        'validation', (tester) async {
      final state = await _mount(tester, reasonRequired: true);
      expect(state.reason, '');

      await enterField(
        tester,
        ProgrammeEndDateFormFields.reasonId,
        '  Coach left ',
      );

      expect(state.reason, 'Coach left');
    });

    testWidgets('Issue 61: an optional reason left empty comes back as an '
        'empty string', (tester) async {
      final state = await _mount(tester, initialDay: _day(9));

      expect(
        state.validate()?[ProgrammeEndDateFormFields.reasonId],
        '',
      );
    });
  });

  group('Issue 61: ProgrammeEndDateForm dirty check', () {
    testWidgets('Issue 61: with no end yet, a picked day makes the form '
        'dirty and clearing it makes it clean', (tester) async {
      final state = await _mount(tester);
      expect(state.isDirty, isFalse);

      await _pick(tester, state, _day(9));
      expect(state.isDirty, isTrue);

      await setField(
        tester,
        state,
        ProgrammeEndDateFormFields.lastDayId,
        null,
      );
      expect(state.isDirty, isFalse);
    });

    testWidgets('Issue 61: another day makes the form dirty, the same day '
        'again makes it clean, whatever the time of day', (tester) async {
      final state = await _mount(tester, initialDay: _day(9));

      await _pick(tester, state, _day(10));
      expect(state.isDirty, isTrue);

      await _pick(tester, state, _day(9).add(const Duration(hours: 18)));
      expect(state.isDirty, isFalse);

      await setField(
        tester,
        state,
        ProgrammeEndDateFormFields.lastDayId,
        null,
      );
      expect(state.isDirty, isTrue, reason: 'the end was taken away');
    });

    testWidgets('Issue 61: a reason alone is not a change of end date', (
      tester,
    ) async {
      final state = await _mount(tester, initialDay: _day(9));

      await enterField(tester, ProgrammeEndDateFormFields.reasonId, 'Why');

      expect(state.isDirty, isFalse);
    });
  });

  group('Issue 61: ProgrammeEndDateForm contract', () {
    testWidgets('Issue 61: a refusal shows on each field and inline, and '
        'the form validates again afterwards', (tester) async {
      final state = await _mount(tester, initialDay: _day(9));

      await expectShowsServerErrors(
        tester,
        state,
        ProgrammeEndDateFormFields.lastDayId,
      );
      await expectShowsServerErrors(
        tester,
        state,
        ProgrammeEndDateFormFields.reasonId,
      );

      state.showErrors(
        fieldErrors: const {
          ProgrammeEndDateFormFields.lastDayId: 'No session on that day.',
          ProgrammeEndDateFormFields.reasonId: 'Say more.',
        },
        formError: 'Could not save.',
      );
      await tester.pumpAndSettle();
      expect(
        _onField(
          ProgrammeEndDateFormFields.lastDayId,
          'No session on that day.',
        ),
        findsOneWidget,
      );
      expect(
        _onField(ProgrammeEndDateFormFields.reasonId, 'Say more.'),
        findsOneWidget,
      );

      expect(state.validate(), _values(_day(9)));
      await tester.pumpAndSettle();
      expect(find.text('No session on that day.'), findsNothing);
      expect(find.text('Say more.'), findsNothing);
      expect(find.text('Could not save.'), findsNothing);
    });

    testWidgets('Issue 61: disabled, the day cannot be picked and the '
        'reason cannot be typed', (tester) async {
      await _mount(tester, initialDay: _day(9));
      expect(find.byType(CLDatePicker), findsOneWidget);

      final state = await _mount(tester, initialDay: _day(9), enabled: false);

      expect(
        find.byType(CLDatePicker),
        findsNothing,
        reason: 'no calendar to open',
      );
      expect(
        tester
            .widget<ShadInput>(
              find.descendant(
                of: fieldWithId(ProgrammeEndDateFormFields.reasonId),
                matching: find.byType(ShadInput),
              ),
            )
            .enabled,
        isFalse,
      );
      expect(state.isDirty, isFalse);
    });

    testWidgets('Issue 61: the form fits a phone', (tester) async {
      await expectFitsPhone(
        tester,
        ProgrammeEndDateForm(
          initialDay: _day(9),
          reasonRequired: true,
          resultOf: (day) =>
              'Last session: Saturday 14 November 2026, then the programme '
              'ends and its members are told.',
        ),
      );
      expect(rowLabels(tester), ['Last day *', 'Reason *']);
    });

    testWidgets('Issue 61: the form has no heading and no button', (
      tester,
    ) async {
      await _mount(tester, initialDay: _day(9));

      expectNoHostChrome(tester);
      expect(find.byType(ShadButton), findsNothing);
    });
  });
}
