// Issue 108: while its save is in flight, the Save button of each dialog
// here is off and its label says what is happening.
import 'dart:io';

import 'package:cl_club_events/src/models/event_cancellation_messages.dart';
import 'package:cl_club_events/src/widgets/cards/actions/occurrence_reschedule_dialog.dart';
import 'package:cl_club_events/src/widgets/event_editor/event_cancellation_dialog.dart';
import 'package:cl_club_events/src/widgets/event_editor/programme_adjust_schedule_dialog.dart';
import 'package:cl_club_events/src/widgets/event_editor/programme_end_date_dialog.dart';
import 'package:club_sdk_2/club_sdk_2.dart' show EventType;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../support/held_events.dart';

ShadButton _button(WidgetTester tester, String label) =>
    tester.widget<ShadButton>(find.widgetWithText(ShadButton, label).last);

/// Presses [label], and checks that the button then reads [inFlight] and is
/// off until the held change answers, when the dialog [dialog] closes.
Future<void> _expectInFlight(
  WidgetTester tester,
  HeldEvents events, {
  required String label,
  required String inFlight,
  required String call,
  required Type dialog,
}) async {
  expect(_button(tester, label).onPressed, isNotNull);
  expect(find.text(inFlight), findsNothing);

  await tester.tap(find.widgetWithText(ShadButton, label).last);
  await tester.pump();

  expect(events.calls, [call]);
  expect(find.widgetWithText(ShadButton, label), findsNothing);
  expect(_button(tester, inFlight).onPressed, isNull);
  expect(find.byType(CircularProgressIndicator), findsNothing);

  events.held.complete();
  await tester.pumpAndSettle();
  expect(find.byType(dialog), findsNothing);
}

void main() {
  group('Issue 108: a Save in flight says so', () {
    testWidgets('Issue 108: the occurrence reschedule dialog reads '
        '"Saving…", with no spinner', (tester) async {
      final events = await openHeldReschedule(tester);

      await _expectInFlight(
        tester,
        events,
        label: 'Save',
        inFlight: 'Saving…',
        call: 'reschedule',
        dialog: OccurrenceRescheduleDialog,
      );
    });

    testWidgets('Issue 108: Cancel camp reads "Cancelling…"', (tester) async {
      final events = await openHeldCancellation(tester, EventType.camp);

      await _expectInFlight(
        tester,
        events,
        label: EventCancellationMessages.cancelCamp,
        inFlight: 'Cancelling…',
        call: 'cancel',
        dialog: EventCancellationDialog,
      );
    });

    testWidgets('Issue 108: Call off reads "Calling off…"', (tester) async {
      final events = await openHeldCancellation(tester, EventType.oneOff);

      await _expectInFlight(
        tester,
        events,
        label: EventCancellationMessages.callOff,
        inFlight: 'Calling off…',
        call: 'drop',
        dialog: EventCancellationDialog,
      );
    });

    testWidgets('Issue 108: the programme end date dialog reads "Saving…"', (
      tester,
    ) async {
      final events = await openHeldEndDate(tester);

      await _expectInFlight(
        tester,
        events,
        label: 'Save',
        inFlight: 'Saving…',
        call: 'terminate',
        dialog: ProgrammeEndDateDialog,
      );
    });

    testWidgets('Issue 108: the Adjust Schedule dialog reads "Saving…"', (
      tester,
    ) async {
      final events = await openHeldAdjustSchedule(tester);

      await _expectInFlight(
        tester,
        events,
        label: 'Save',
        inFlight: 'Saving…',
        call: 'adjust',
        dialog: ProgrammeAdjustScheduleDialog,
      );
    });

    test('Issue 108: Create event writes its in-flight label with one '
        'character, not three dots', () {
      final source = File(
        'lib/src/views/event_create_view.dart',
      ).readAsStringSync();
      expect(source, contains("'Creating…'"));
      expect(source, isNot(contains("'Creating...'")));
    });
  });
}
