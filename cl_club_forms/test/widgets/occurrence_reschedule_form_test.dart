// Points of issue 61 that do not apply to OccurrenceRescheduleForm: it has
// no rule across fields, no optional field, nothing typed is trimmed, and no
// parameter hides or locks a field. The date is picked in a calendar, so
// the tests set it on the date field directly.
import 'package:cl_calendar/cl_calendar.dart'
    show CLDatePicker, CLDatePickerFormField;
import 'package:cl_club_forms/cl_club_forms.dart';
import 'package:cl_club_forms/src/widgets/event_schedule/event_venue_select_field.dart'
    show EventVenueSelectField;
import 'package:cl_club_forms/src/widgets/occurrence_reschedule/occurrence_reschedule_form_validators.dart'
    show OccurrenceRescheduleFormValidators;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../support/form_harness.dart';
import '../support/programme_timetable_support.dart';

Widget _wrap(Widget child) => ShadApp(home: Scaffold(body: child));

Future<void> _setSurface(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(1024, 2000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

Map<String, dynamic> _seed() => {
  OccurrenceRescheduleFormFields.scheduleId: OneOffScheduleData(
    date: DateTime(2026, 7, 1),
    startTime: const ShadTimeOfDay(hour: 6, minute: 0, second: 0),
    durationMinutes: 90,
  ),
  OccurrenceRescheduleFormFields.venueId: 7,
};

const _venues = [
  EventVenueOption(id: 7, name: 'Rink A'),
  EventVenueOption(id: 9, name: 'Rink B'),
];

final OneOffScheduleData _seededSchedule =
    _seed()[OccurrenceRescheduleFormFields.scheduleId] as OneOffScheduleData;

/// Mounts the form through the shared harness and returns its state.
Future<OccurrenceRescheduleFormState> _mount(
  WidgetTester tester, {
  OneOffScheduleData? schedule,
  int? venueId = 7,
  bool enabled = true,
}) async {
  final key = GlobalKey<OccurrenceRescheduleFormState>();
  await pumpForm(
    tester,
    OccurrenceRescheduleForm(
      key: key,
      initialValues: {
        OccurrenceRescheduleFormFields.scheduleId: schedule ?? _seededSchedule,
        OccurrenceRescheduleFormFields.venueId: venueId,
      },
      venues: _venues,
      enabled: enabled,
    ),
  );
  return key.currentState!;
}

/// Picks [day] in the Date field, as its calendar does.
Future<void> _pickDate(WidgetTester tester, DateTime? day) async {
  tester
      .state<FormFieldState<DateTime?>>(find.byType(CLDatePickerFormField))
      .didChange(day);
  await tester.pumpAndSettle();
}

Finder _onField(String id, String message) =>
    find.descendant(of: fieldWithId(id), matching: find.text(message));

OneOffScheduleData _scheduleOf(Map<String, dynamic> values) =>
    values[OccurrenceRescheduleFormFields.scheduleId] as OneOffScheduleData;

void main() {
  testWidgets('Issue 750: renders the seeded venue and is not dirty at mount', (
    tester,
  ) async {
    await _setSurface(tester);
    final key = GlobalKey<OccurrenceRescheduleFormState>();
    await tester.pumpWidget(
      _wrap(
        OccurrenceRescheduleForm(
          key: key,
          initialValues: _seed(),
          venues: _venues,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Rink A'), findsOneWidget);
    expect(key.currentState!.isDirty, isFalse);
  });

  testWidgets('Issue 750: validate returns the seeded schedule and venue', (
    tester,
  ) async {
    await _setSurface(tester);
    final key = GlobalKey<OccurrenceRescheduleFormState>();
    await tester.pumpWidget(
      _wrap(
        OccurrenceRescheduleForm(
          key: key,
          initialValues: _seed(),
          venues: _venues,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final values = key.currentState!.validate();
    expect(values, isNotNull);
    expect(values![OccurrenceRescheduleFormFields.venueId], 7);
    final schedule =
        values[OccurrenceRescheduleFormFields.scheduleId] as OneOffScheduleData;
    expect(schedule.durationMinutes, 90);
    expect(schedule.date, DateTime(2026, 7, 1));
  });

  group('Issue 61: OccurrenceRescheduleForm fields', () {
    testWidgets('Issue 61: its rows are Date, Start Time, Duration and '
        'Venue, all required', (tester) async {
      await _mount(tester);

      expect(rowLabels(tester), [
        'Date *',
        'Start Time *',
        'Duration *',
        'Venue *',
      ]);
      expectLabelsAreRows(tester);
      expect(find.text('1 Jul 2026'), findsOneWidget);
      expect(find.text('1:30'), findsOneWidget);
    });
  });

  group('Issue 61: OccurrenceRescheduleForm validation', () {
    testWidgets('Issue 61: no date is refused', (tester) async {
      final state = await _mount(
        tester,
        schedule: _seededSchedule.copyWith(date: () => null),
      );

      expect(state.validate(), isNull);
      await tester.pumpAndSettle();
      expect(
        _onField(OccurrenceRescheduleFormFields.scheduleId, 'Date is required'),
        findsWidgets,
      );
    });

    testWidgets('Issue 61: a picked date is accepted', (tester) async {
      final state = await _mount(
        tester,
        schedule: _seededSchedule.copyWith(date: () => null),
      );

      await _pickDate(tester, DateTime(2026, 7, 4));

      expect(_scheduleOf(state.validate()!).date, DateTime(2026, 7, 4));
    });

    testWidgets('Issue 61: no start time is refused', (tester) async {
      final state = await _mount(
        tester,
        schedule: _seededSchedule.copyWith(startTime: () => null),
      );

      expect(state.validate(), isNull);
      await tester.pumpAndSettle();
      expect(
        _onField(
          OccurrenceRescheduleFormFields.scheduleId,
          'Start time is required',
        ),
        findsWidgets,
      );
    });

    testWidgets('Issue 61: a duration of nothing is refused on Duration', (
      tester,
    ) async {
      final state = await _mount(
        tester,
        schedule: _seededSchedule.copyWith(durationMinutes: 0),
      );

      expect(state.validate(), isNull);
      await tester.pumpAndSettle();
      expect(find.text('Duration must be greater than 0'), findsOneWidget);

      await pickDuration(tester, 0, 45);
      expect(_scheduleOf(state.validate()!).durationMinutes, 45);
    });

    testWidgets('Issue 61: no venue is refused on Venue, and a picked one '
        'is accepted', (tester) async {
      final state = await _mount(tester, venueId: null);

      expect(state.validate(), isNull);
      await tester.pumpAndSettle();
      expect(
        _onField(
          OccurrenceRescheduleFormFields.venueId,
          OccurrenceRescheduleFormValidators.venueRequiredMessage,
        ),
        findsOneWidget,
      );

      await pickOption(tester, EventVenueSelectField.placeholder, 'Rink B');
      expect(state.validate()?[OccurrenceRescheduleFormFields.venueId], 9);
    });
  });

  group('Issue 61: OccurrenceRescheduleForm values', () {
    testWidgets('Issue 61: validate returns exactly the schedule and the '
        'venue id, typed, as seeded', (tester) async {
      final state = await _mount(tester);

      final values = state.validate()!;

      expect(values.keys, [
        OccurrenceRescheduleFormFields.scheduleId,
        OccurrenceRescheduleFormFields.venueId,
      ]);
      expect(
        values[OccurrenceRescheduleFormFields.scheduleId],
        isA<OneOffScheduleData>(),
      );
      expect(values[OccurrenceRescheduleFormFields.venueId], isA<int>());
      expect(values, _seed());
    });

    testWidgets('Issue 61: a new day, time, length and venue are what '
        'validate returns', (tester) async {
      final state = await _mount(tester);

      await _pickDate(tester, DateTime(2026, 7, 3));
      await enterStartTime(tester, 17, 45);
      await pickDuration(tester, 2);
      await pickOption(tester, 'Rink A', 'Rink B');

      expect(state.validate(), {
        OccurrenceRescheduleFormFields.scheduleId: OneOffScheduleData(
          date: DateTime(2026, 7, 3),
          startTime: const ShadTimeOfDay(hour: 17, minute: 45, second: 0),
          durationMinutes: 120,
        ),
        OccurrenceRescheduleFormFields.venueId: 9,
      });
    });
  });

  group('Issue 61: OccurrenceRescheduleForm dirty check', () {
    testWidgets('Issue 61: another date makes the form dirty, and the old '
        'one makes it clean', (tester) async {
      final state = await _mount(tester);
      expect(state.isDirty, isFalse);

      await _pickDate(tester, DateTime(2026, 7, 2));
      expect(state.isDirty, isTrue);

      await _pickDate(tester, DateTime(2026, 7, 1));
      expect(state.isDirty, isFalse);
    });

    testWidgets('Issue 61: another start time makes the form dirty, and the '
        'old one makes it clean', (tester) async {
      final state = await _mount(tester);

      await enterStartTime(tester, 7);
      expect(state.isDirty, isTrue);

      await enterStartTime(tester, 6);
      expect(state.isDirty, isFalse);
    });

    testWidgets('Issue 61: another duration makes the form dirty, and the '
        'old one makes it clean', (tester) async {
      final state = await _mount(tester);

      await pickDuration(tester, 2);
      expect(state.isDirty, isTrue);

      await pickDuration(tester, 1, 30);
      expect(state.isDirty, isFalse);
    });

    testWidgets('Issue 61: another venue makes the form dirty, and the old '
        'one makes it clean', (tester) async {
      final state = await _mount(tester);

      await pickOption(tester, 'Rink A', 'Rink B');
      expect(state.isDirty, isTrue);

      await pickOption(tester, 'Rink B', 'Rink A');
      expect(state.isDirty, isFalse);
    });
  });

  group('Issue 61: OccurrenceRescheduleForm contract', () {
    testWidgets('Issue 61: a refusal shows on the schedule or Venue, and '
        'inline; the form validates again afterwards', (tester) async {
      final state = await _mount(tester);

      await expectShowsServerErrors(
        tester,
        state,
        OccurrenceRescheduleFormFields.scheduleId,
      );
      await expectShowsServerErrors(
        tester,
        state,
        OccurrenceRescheduleFormFields.venueId,
      );

      state.showErrors(
        fieldErrors: const {
          OccurrenceRescheduleFormFields.venueId: 'That rink is booked.',
        },
        formError: 'Could not reschedule.',
      );
      await tester.pumpAndSettle();
      expect(
        _onField(
          OccurrenceRescheduleFormFields.venueId,
          'That rink is booked.',
        ),
        findsOneWidget,
      );
      expect(find.text('Could not reschedule.'), findsOneWidget);

      expect(state.validate(), _seed());
      await tester.pumpAndSettle();
      expect(find.text('That rink is booked.'), findsNothing);
      expect(find.text('Could not reschedule.'), findsNothing);
    });

    testWidgets('Issue 61: disabled, no picker opens and no input takes '
        'text', (tester) async {
      await _mount(tester);
      expect(find.byType(CLDatePicker), findsOneWidget);

      final state = await _mount(tester, enabled: false);

      expect(
        find.byType(CLDatePicker),
        findsNothing,
        reason: 'no calendar to open',
      );
      await tester.tap(find.text('Rink A'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.text('Rink B'), findsNothing);
      expectInputsDisabled(tester);
      expect(
        tester.widget<ShadTimePicker>(find.byType(ShadTimePicker)).enabled,
        isFalse,
      );
      expect(state.isDirty, isFalse);
    });

    testWidgets('Issue 61: the form fits a phone', (tester) async {
      await expectFitsPhone(
        tester,
        OccurrenceRescheduleForm(initialValues: _seed(), venues: _venues),
      );
      expect(rowLabels(tester), hasLength(4));
    });

    testWidgets('Issue 61: the form has no heading and no button', (
      tester,
    ) async {
      await _mount(tester);

      expectNoHostChrome(tester);
      expect(find.byType(ShadButton), findsNothing);
    });
  });
}
