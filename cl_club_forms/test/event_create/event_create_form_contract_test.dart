import 'package:cl_club_forms/cl_club_forms.dart';
import 'package:cl_club_forms/src/widgets/event_schedule/camp_schedule_fields.dart'
    show CampScheduleFormField;
import 'package:cl_club_forms/src/widgets/event_schedule/event_venue_select_field.dart'
    show EventVenueSelectField;
import 'package:cl_club_forms/src/widgets/event_schedule/one_off_schedule_fields.dart'
    show OneOffScheduleFormField;
import 'package:cl_club_forms/src/widgets/event_schedule/programme_schedule_fields.dart'
    show ProgrammeScheduleFormField;
import 'package:cl_club_forms/src/widgets/event_schedule/weekday_selector.dart'
    show WeekdayChip;
import 'package:flutter_test/flutter_test.dart';

import '../support/event_create_form_support.dart';
import '../support/form_harness.dart';

// Issue 61, points that do not apply to EventCreateForm: no parameter hides
// or locks a field (the event type swaps the schedule cluster, which is
// covered per type). The form has no button of its own; the only one that
// can show is Clear, inside the programme cluster's end date. Every rule of
// a schedule cluster is tested with the cluster
// (test/event_schedule/*_schedule_fields_test.dart); here one rule per type
// shows the cluster's verdict stops the form. Its other tests are in
// event_create_form_test.dart and event_create_form_defaults_test.dart.

void main() {
  group('Issue 61: EventCreateForm fields', () {
    const scheduleRows = {
      EventFormType.camp: [
        'Start Date *',
        'Training Days *',
        'Start Time *',
        'Duration *',
        'Sessions',
        'Rest Days (tap to toggle)',
      ],
      EventFormType.programme: [
        'Days of Week *',
        'Start Date *',
        'Start Time *',
        'Duration *',
        'Sessions',
      ],
      EventFormType.oneOff: ['Date *', 'Start Time *', 'Duration *'],
    };
    const scheduleFields = {
      EventFormType.camp: CampScheduleFormField,
      EventFormType.programme: ProgrammeScheduleFormField,
      EventFormType.oneOff: OneOffScheduleFormField,
    };

    for (final type in EventFormType.values) {
      testWidgets('Issue 61: a ${type.name} shows Title, Visibility, Venue '
          'and the rows of its schedule, the required ones marked', (
        tester,
      ) async {
        await pumpCreateForm(tester, type);

        expect(rowLabels(tester), [
          'Title *',
          'Visibility',
          'Venue *',
          ...scheduleRows[type]!,
        ]);
        expectLabelsAreRows(tester);
        expect(
          tester.widget(fieldWithId(scheduleId)).runtimeType,
          scheduleFields[type],
        );
        expect(
          find.descendant(
            of: fieldWithId(titleId),
            matching: find.text('${type.label} title'),
          ),
          findsOneWidget,
        );
      });
    }

    testWidgets('Issue 61: the venue select offers the venues it is given '
        'and the visibility select both visibilities', (tester) async {
      await pumpCreateForm(tester, EventFormType.oneOff);
      expect(find.text(EventVenueSelectField.placeholder), findsOneWidget);
      expect(find.text('Public'), findsOneWidget);

      await tester.tap(find.text(EventVenueSelectField.placeholder));
      await tester.pumpAndSettle();
      expect(find.text('Main Rink'), findsOneWidget);
      expect(find.text('Practice Rink'), findsOneWidget);
      await tester.tap(find.text('Practice Rink'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Public'));
      await tester.pumpAndSettle();
      expect(find.text('Private'), findsOneWidget);
    });

    testWidgets('Issue 61: seeded values show: the title, Private and the '
        "venue's name", (tester) async {
      await pumpCreateForm(
        tester,
        EventFormType.oneOff,
        initial: completeCreateValues(EventFormType.oneOff),
      );

      expect(find.text('Open day'), findsOneWidget);
      expect(find.text('Private'), findsOneWidget);
      expect(find.text('Practice Rink'), findsOneWidget);
      expect(find.text(EventVenueSelectField.placeholder), findsNothing);
    });
  });

  group('Issue 61: EventCreateForm validation', () {
    testWidgets('Issue 61: a blank title is refused on the title field, a '
        'typed one accepted', (tester) async {
      final form = await pumpCreateForm(
        tester,
        EventFormType.oneOff,
        initial: completeCreateValues(EventFormType.oneOff)..[titleId] = '',
      );
      await enterField(tester, titleId, '   ');

      expect(form.validate(), isNull);
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: fieldWithId(titleId),
          matching: find.text('Title is required'),
        ),
        findsOneWidget,
      );

      await enterField(tester, titleId, 'A');
      expect(form.validate(), isNotNull);
      await tester.pumpAndSettle();
      expect(find.text('Title is required'), findsNothing);
    });

    testWidgets('Issue 61: with no venue it is refused inline, and passes '
        'once one is picked', (tester) async {
      final form = await pumpCreateForm(
        tester,
        EventFormType.oneOff,
        initial: completeCreateValues(EventFormType.oneOff)..[venueId] = null,
      );

      expect(form.validate(), isNull);
      await tester.pumpAndSettle();
      final message = find.text('Please select a venue');
      expect(message, findsOneWidget);
      // Inline under the rows, not on the venue field.
      expect(
        find.descendant(of: fieldWithId(venueId), matching: message),
        findsNothing,
      );
      expect(
        tester.getTopLeft(message).dy,
        greaterThan(tester.getBottomLeft(fieldWithId(scheduleId)).dy),
      );

      await pickOption(tester, EventVenueSelectField.placeholder, 'Main Rink');
      final values = form.validate();
      await tester.pumpAndSettle();
      expect(values![venueId], 1);
      expect(message, findsNothing);
    });

    testWidgets('Issue 61: a field refused keeps the venue rule quiet until '
        'the fields pass', (tester) async {
      final form = await pumpCreateForm(tester, EventFormType.oneOff);

      expect(form.validate(), isNull);
      await tester.pumpAndSettle();

      expect(find.text('Title is required'), findsOneWidget);
      expect(find.text('Please select a venue'), findsNothing);
    });

    testWidgets('Issue 61: a programme on no weekday is refused by its '
        'schedule, and passes once a day is picked', (tester) async {
      final form = await pumpCreateForm(
        tester,
        EventFormType.programme,
        initial: completeCreateValues(EventFormType.programme)
          ..[scheduleId] = ProgrammeScheduleData(
            startDate: DateTime(2030, 7),
            sessionStartTime: nineOClock,
          ),
      );

      expect(form.validate(), isNull);
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: fieldWithId(scheduleId),
          matching: find.text('Pick at least one day'),
        ),
        findsWidgets,
      );

      await tester.tap(find.byType(WeekdayChip).first);
      await tester.pumpAndSettle();
      final values = form.validate();
      await tester.pumpAndSettle();
      expect((values![scheduleId] as ProgrammeScheduleData).weekdays, {1});
      expect(find.text('Pick at least one day'), findsNothing);
    });

    testWidgets('Issue 61: a camp without a start date is refused by its '
        'schedule', (tester) async {
      final form = await pumpCreateForm(
        tester,
        EventFormType.camp,
        initial: completeCreateValues(EventFormType.camp)
          ..[scheduleId] = const CampScheduleData(sessionStartTime: nineOClock),
      );

      expect(form.validate(), isNull);
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: fieldWithId(scheduleId),
          matching: find.text('Start date is required'),
        ),
        findsWidgets,
      );
    });

    testWidgets('Issue 61: a camp with its Training Days emptied is refused '
        'on that input', (tester) async {
      final form = await pumpCreateForm(
        tester,
        EventFormType.camp,
        initial: completeCreateValues(EventFormType.camp),
      );
      expect(form.validate(), isNotNull);

      await tester.enterText(trainingDaysInput('4'), '');
      await tester.pumpAndSettle();

      expect(form.validate(), isNull);
      await tester.pumpAndSettle();
      expect(find.text('Required'), findsOneWidget);
    });

    testWidgets('Issue 61: a one-off without a date is refused by its '
        'schedule', (tester) async {
      final form = await pumpCreateForm(
        tester,
        EventFormType.oneOff,
        initial: completeCreateValues(EventFormType.oneOff)
          ..[scheduleId] = const OneOffScheduleData(startTime: nineOClock),
      );

      expect(form.validate(), isNull);
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: fieldWithId(scheduleId),
          matching: find.text('Date is required'),
        ),
        findsWidgets,
      );
    });
  });

  group('Issue 61: EventCreateForm values', () {
    final scheduleTypes = <EventFormType, Matcher>{
      EventFormType.camp: isA<CampScheduleData>(),
      EventFormType.programme: isA<ProgrammeScheduleData>(),
      EventFormType.oneOff: isA<OneOffScheduleData>(),
    };

    for (final type in EventFormType.values) {
      testWidgets('Issue 61: a seeded ${type.name} comes back unchanged: '
          'four entries, the schedule of its type', (tester) async {
        final initial = completeCreateValues(type);
        final form = await pumpCreateForm(tester, type, initial: initial);

        final values = form.validate()!;

        expect(values, initial);
        expect(values.keys, EventCreateFormState.trackedIds);
        expect(values[titleId], isA<String>());
        expect(values[visibilityId], isA<EventFormVisibility>());
        expect(values[venueId], isA<int>());
        expect(values[scheduleId], scheduleTypes[type]);
        expect(form.isDirty, isFalse);
      });
    }

    testWidgets('Issue 61: what is typed and picked comes back from '
        'validate', (tester) async {
      final form = await pumpCreateForm(
        tester,
        EventFormType.camp,
        initial: EventCreateForm.defaultValues(
          EventFormType.camp,
          now: createFormNow,
        )..[scheduleId] = completeSchedule(EventFormType.camp),
      );

      await enterField(tester, titleId, 'Summer Camp');
      await pickOption(tester, 'Public', 'Private');
      await pickOption(
        tester,
        EventVenueSelectField.placeholder,
        'Practice Rink',
      );
      await tester.enterText(trainingDaysInput('4'), '6');
      await tester.pumpAndSettle();

      final values = form.validate()!;
      expect(values[titleId], 'Summer Camp');
      expect(values[visibilityId], EventFormVisibility.private);
      expect(values[venueId], 2);
      expect(
        values[scheduleId],
        (completeSchedule(EventFormType.camp) as CampScheduleData).copyWith(
          trainingDays: 6,
        ),
      );
    });

    testWidgets('Issue 61: the title comes back as typed: trimming it is '
        "the host adapter's", (tester) async {
      final form = await pumpCreateForm(
        tester,
        EventFormType.oneOff,
        initial: completeCreateValues(EventFormType.oneOff),
      );

      await enterField(tester, titleId, '  Open day  ');

      expect(form.validate()![titleId], '  Open day  ');
    });
  });

  group('Issue 61: EventCreateForm isDirty', () {
    testWidgets('Issue 61: a title of blanks alone is not a change', (
      tester,
    ) async {
      final form = await pumpCreateForm(tester, EventFormType.oneOff);

      await enterField(tester, titleId, '   ');

      expect(form.isDirty, isFalse);
    });

    testWidgets('Issue 61: a seeded title changed, then typed back', (
      tester,
    ) async {
      final form = await pumpCreateForm(
        tester,
        EventFormType.oneOff,
        initial: completeCreateValues(EventFormType.oneOff),
      );

      await enterField(tester, titleId, 'Open evening');
      expect(form.isDirty, isTrue);

      await enterField(tester, titleId, 'Open day');
      expect(form.isDirty, isFalse);
    });

    testWidgets('Issue 61: the visibility switched to Private, then back to '
        'Public', (tester) async {
      final form = await pumpCreateForm(tester, EventFormType.oneOff);

      await pickOption(tester, 'Public', 'Private');
      expect(form.isDirty, isTrue);

      await pickOption(tester, 'Private', 'Public');
      expect(form.isDirty, isFalse);
    });

    testWidgets('Issue 61: another venue picked, then the first again', (
      tester,
    ) async {
      final form = await pumpCreateForm(
        tester,
        EventFormType.oneOff,
        initial: completeCreateValues(EventFormType.oneOff),
      );

      await pickOption(tester, 'Practice Rink', 'Main Rink');
      expect(form.isDirty, isTrue);

      await pickOption(tester, 'Main Rink', 'Practice Rink');
      expect(form.isDirty, isFalse);
    });

    testWidgets('Issue 61: a venue picked on a fresh form makes it dirty', (
      tester,
    ) async {
      final form = await pumpCreateForm(tester, EventFormType.oneOff);

      await pickOption(tester, EventVenueSelectField.placeholder, 'Main Rink');

      expect(form.isDirty, isTrue);
    });

    testWidgets("Issue 61: a camp's training days changed, then typed "
        'back', (tester) async {
      final form = await pumpCreateForm(tester, EventFormType.camp);
      expect(form.isDirty, isFalse);

      await tester.enterText(trainingDaysInput('5'), '6');
      await tester.pumpAndSettle();
      expect(form.isDirty, isTrue);

      await tester.enterText(trainingDaysInput('6'), '5');
      await tester.pumpAndSettle();
      expect(form.isDirty, isFalse);
    });

    testWidgets("Issue 61: a programme's weekday picked, then unpicked", (
      tester,
    ) async {
      final form = await pumpCreateForm(tester, EventFormType.programme);
      expect(form.isDirty, isFalse);

      await tester.tap(find.byType(WeekdayChip).first);
      await tester.pumpAndSettle();
      expect(form.isDirty, isTrue);

      await tester.tap(find.byType(WeekdayChip).first);
      await tester.pumpAndSettle();
      expect(form.isDirty, isFalse);
    });

    testWidgets("Issue 61: a one-off's schedule replaced, then put back", (
      tester,
    ) async {
      final form = await pumpCreateForm(
        tester,
        EventFormType.oneOff,
        initial: completeCreateValues(EventFormType.oneOff),
      );
      final schedule =
          completeSchedule(EventFormType.oneOff) as OneOffScheduleData;

      await setField(
        tester,
        form,
        scheduleId,
        schedule.copyWith(durationMinutes: 60),
      );
      expect(form.isDirty, isTrue);

      await setField(tester, form, scheduleId, schedule);
      expect(form.isDirty, isFalse);
    });
  });
}
