import 'package:cl_club_events/src/utils/programme_end_date.dart';
import 'package:cl_club_events/src/widgets/event_editor/event_schedule_section.dart';
import 'package:cl_club_events/src/widgets/event_editor/programme_end_date_dialog.dart';
import 'package:cl_club_events/src/widgets/event_editor/programme_schedule_actions.dart';
import 'package:cl_remote_store/cl_remote_store.dart'
    show
        clEventSchedulesProvider,
        clEventsMasterProvider,
        clSingleOccurrenceProvider,
        clVenuesProvider;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart' hide Visibility;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/src/widgets/event_schedule/programme_end_date_form_validators.dart'
    show ProgrammeEndDateFormValidators;
import 'package:ui_lib/ui_lib.dart'
    show ProgrammeEndDateForm, ProgrammeEndDateFormState;

import '../../support/programme_fixtures.dart';
import '../../support/recording_schedule_events.dart';

/// The local calendar day [days] from today.
DateTime _day(int days) {
  final t = localNoon(days);
  return DateTime(t.year, t.month, t.day);
}

Future<RecordingScheduleEvents> _pump(
  WidgetTester tester,
  Event event, {
  bool canEdit = true,
}) async {
  tester.view.physicalSize = const Size(1400, 2600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final events = RecordingScheduleEvents(event);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        clEventsMasterProvider.overrideWith(() => events),
        clEventSchedulesProvider.overrideWith((ref, id) async => const []),
        clVenuesProvider.overrideWith((ref, key) async => const []),
        clSingleOccurrenceProvider.overrideWith(
          (ref, key) async => Occurrence(
            eventId: key.eventId,
            originalStartTimeUtc: key.occurrenceTimeUtc,
            actualStartTimeUtc: key.occurrenceTimeUtc,
            actualEndTimeUtc: key.occurrenceTimeUtc.add(
              const Duration(hours: 1),
            ),
            status: OccurrenceStatus.scheduled,
            venueId: 7,
          ),
        ),
      ],
      child: ShadApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: EventScheduleSection(event: event, canEdit: canEdit),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return events;
}

final Finder _action = find.widgetWithText(
  ShadButton,
  ProgrammeScheduleActions.adjustEndDateLabel,
);

Future<void> _open(WidgetTester tester) async {
  await tester.tap(_action);
  await tester.pumpAndSettle();
}

ProgrammeEndDateFormState _form(WidgetTester tester) =>
    tester.state<ProgrammeEndDateFormState>(find.byType(ProgrammeEndDateForm));

Future<void> _pick(WidgetTester tester, DateTime day) async {
  _form(tester).formKey.currentState!.setFieldValue<DateTime?>(
    ProgrammeEndDateForm.lastDayId,
    day,
  );
  await tester.pumpAndSettle();
}

Future<void> _press(WidgetTester tester, String label) async {
  await tester.tap(find.widgetWithText(ShadButton, label));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'Issue 39: a programme with no end reads "No end date" and sets one '
    'with a reason, after the dialog shows the last session',
    (tester) async {
      final events = await _pump(tester, programmeFixture());
      expect(find.text(programmeNoEndDateLine), findsOneWidget);

      await _open(tester);
      expect(
        find.text(ProgrammeEndDateDialog.clearLabel),
        findsNothing,
        reason: 'there is no end date to clear',
      );
      await _pick(tester, _day(5));
      expect(
        find.text(
          'Last session: ${programmeEndDayFormat.format(localNoon(5))}.',
        ),
        findsOneWidget,
      );

      await _press(tester, 'Save');
      expect(
        find.text(ProgrammeEndDateFormValidators.reasonRequiredMessage),
        findsOneWidget,
      );
      expect(events.endDateCalls, isEmpty);

      await tester.enterText(
        find.descendant(
          of: find.byType(ProgrammeEndDateForm),
          matching: find.byType(EditableText),
        ),
        'Season over',
      );
      await tester.pump();
      await _press(tester, 'Save');

      expect(events.endDateCalls, [
        'terminate(${localNoon(6).toUtc()}, Season over)',
      ]);
      expect(find.text(programmeEndDateSetMessage), findsOneWidget);
      expect(find.byType(ProgrammeEndDateDialog), findsNothing);
    },
  );

  testWidgets(
    'Issue 39: an end ahead shows as the end date and moves to an earlier '
    'or a later day without a reason',
    (tester) async {
      final event = programmeFixture(untilTimeUtc: localNoon(6).toUtc());
      final events = await _pump(tester, event);
      expect(
        find.text('End date: ${programmeEndDayFormat.format(localNoon(5))}'),
        findsOneWidget,
      );
      expect(find.text(programmeNoEndDateLine), findsNothing);

      await _open(tester);
      expect(_form(tester).widget.initialDay, _day(5));
      await _pick(tester, _day(9));
      await _press(tester, 'Save');
      expect(find.text(programmeEndDateChangedMessage), findsOneWidget);

      await _open(tester);
      await _pick(tester, _day(2));
      await _press(tester, 'Save');

      expect(events.endDateCalls, [
        'extend(${localNoon(10).toUtc()}, null)',
        'extend(${localNoon(3).toUtc()}, null)',
      ]);
    },
  );

  testWidgets('Issue 39: an end ahead can be cleared', (tester) async {
    final events = await _pump(
      tester,
      programmeFixture(untilTimeUtc: localNoon(6).toUtc()),
    );

    await _open(tester);
    await _press(tester, ProgrammeEndDateDialog.clearLabel);

    expect(events.endDateCalls, ['extendIndefinitely(null)']);
    expect(find.text(programmeEndDateClearedMessage), findsOneWidget);
    expect(find.byType(ProgrammeEndDateDialog), findsNothing);
  });

  testWidgets('Issue 39: saving the same end date sends nothing', (
    tester,
  ) async {
    final events = await _pump(
      tester,
      programmeFixture(untilTimeUtc: localNoon(6).toUtc()),
    );

    await _open(tester);
    await _press(tester, 'Save');

    expect(events.endDateCalls, isEmpty);
    expect(find.byType(ProgrammeEndDateDialog), findsNothing);
  });

  testWidgets('Issue 39: a day before today cannot be chosen', (tester) async {
    final events = await _pump(tester, programmeFixture());

    await _open(tester);
    await _pick(tester, _day(-1));
    await _press(tester, 'Save');

    expect(
      find.text(ProgrammeEndDateFormValidators.dayInPastMessage),
      findsOneWidget,
    );
    expect(events.endDateCalls, isEmpty);
  });

  testWidgets(
    'Issue 39: a programme whose end has passed shows the action locked '
    'with the reason',
    (tester) async {
      await _pump(
        tester,
        programmeFixture(untilTimeUtc: localNoon(-2).toUtc()),
      );

      expect(find.text(programmeEndedMessage), findsOneWidget);
      expect(tester.widget<ShadButton>(_action).onPressed, isNull);
    },
  );

  testWidgets('Issue 39: the server refusals read as fixed messages', (
    tester,
  ) async {
    final events = await _pump(
      tester,
      programmeFixture(untilTimeUtc: localNoon(6).toUtc()),
    );

    Future<void> refuse(ServerException error) async {
      events.error = error;
      await _pick(tester, _day(_form(tester).isDirty ? 8 : 9));
      await _press(tester, 'Save');
    }

    await _open(tester);
    await refuse(
      const ServerException(
        statusCode: 422,
        code: SdkErrorCode.cutoffTooSoon,
        message: 'raw too soon',
      ),
    );
    expect(find.textContaining('under 30 minutes'), findsOneWidget);

    await refuse(
      const ServerException(
        statusCode: 400,
        code: SdkErrorCode.effectiveTimeNotSessionBoundary,
        message: 'raw boundary',
      ),
    );
    expect(
      find.textContaining('no longer part of the schedule'),
      findsOneWidget,
    );

    await refuse(
      const ServerException(
        statusCode: 422,
        code: SdkErrorCode.invalidState,
        message: 'raw ended',
      ),
    );
    expect(find.text(programmeEndDateOutdatedMessage), findsOneWidget);
    expect(find.textContaining('raw'), findsNothing);
    expect(find.byType(ProgrammeEndDateDialog), findsOneWidget);
  });

  testWidgets('Issue 39: the action is not offered on a camp or a one-off', (
    tester,
  ) async {
    final start = localNoon(3).toUtc();
    final base = programmeFixture().copyWith(
      startTimeUtc: start,
      endTimeUtc: start.add(const Duration(hours: 1)),
    );
    await _pump(
      tester,
      base.copyWith(type: EventType.camp, rrule: () => 'FREQ=DAILY;COUNT=3'),
    );
    expect(_action, findsNothing);
    expect(find.text(programmeNoEndDateLine), findsNothing);

    await _pump(
      tester,
      base.copyWith(type: EventType.oneOff, rrule: () => null),
    );
    expect(_action, findsNothing);
  });

  testWidgets('Issue 39: a viewer who may not edit is not offered the '
      'action', (tester) async {
    await _pump(tester, programmeFixture(), canEdit: false);

    expect(_action, findsNothing);
  });
}
