// Issue 113: while its save is in flight, each dialog here is closed by
// nothing: not its close X, a tap outside, Escape or system back.
import 'package:cl_club_events/src/models/event_cancellation_messages.dart';
import 'package:cl_club_events/src/widgets/cards/actions/occurrence_reschedule_dialog.dart';
import 'package:cl_club_events/src/widgets/event_editor/event_cancellation_dialog.dart';
import 'package:cl_club_events/src/widgets/event_editor/programme_adjust_schedule_dialog.dart';
import 'package:cl_club_events/src/widgets/event_editor/programme_end_date_dialog.dart';
import 'package:club_sdk_2/club_sdk_2.dart' show EventType;
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../support/dialog_dismissal.dart';
import '../support/held_events.dart';

/// Presses [label], and checks that [dialog] stays through every way of
/// dismissing it until the held change answers, when it closes.
Future<void> _expectStaysOpen(
  WidgetTester tester,
  HeldEvents events, {
  required String label,
  required String call,
  required Type dialog,
}) async {
  await tester.tap(find.widgetWithText(ShadButton, label).last);
  await tester.pump();
  expect(events.calls, [call]);

  await expectNoDismissal(tester, find.byType(dialog));
  expect(events.calls, [call]);

  events.held.complete();
  await tester.pumpAndSettle();
  expect(find.byType(dialog), findsNothing);
}

void main() {
  group('Issue 113: a dialog that is saving stays open', () {
    testWidgets('Issue 113: the occurrence reschedule dialog stays open '
        'while it saves', (tester) async {
      final events = await openHeldReschedule(tester);

      await _expectStaysOpen(
        tester,
        events,
        label: 'Save',
        call: 'reschedule',
        dialog: OccurrenceRescheduleDialog,
      );
    });

    testWidgets('Issue 113: Cancel camp stays open while it cancels', (
      tester,
    ) async {
      final events = await openHeldCancellation(tester, EventType.camp);

      await _expectStaysOpen(
        tester,
        events,
        label: EventCancellationMessages.cancelCamp,
        call: 'cancel',
        dialog: EventCancellationDialog,
      );
    });

    testWidgets('Issue 113: Call off stays open while it calls off', (
      tester,
    ) async {
      final events = await openHeldCancellation(tester, EventType.oneOff);

      await _expectStaysOpen(
        tester,
        events,
        label: EventCancellationMessages.callOff,
        call: 'drop',
        dialog: EventCancellationDialog,
      );
    });

    testWidgets('Issue 113: the programme end date dialog stays open while '
        'it saves', (tester) async {
      final events = await openHeldEndDate(tester);

      await _expectStaysOpen(
        tester,
        events,
        label: 'Save',
        call: 'terminate',
        dialog: ProgrammeEndDateDialog,
      );
    });

    testWidgets('Issue 113: the Adjust Schedule dialog stays open while it '
        'saves', (tester) async {
      final events = await openHeldAdjustSchedule(tester);

      await _expectStaysOpen(
        tester,
        events,
        label: 'Save',
        call: 'adjust',
        dialog: ProgrammeAdjustScheduleDialog,
      );
    });
  });
}
