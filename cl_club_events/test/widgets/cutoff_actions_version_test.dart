import 'package:cl_club_events/src/models/event_cancellation_messages.dart';
import 'package:cl_club_events/src/widgets/cards/actions/admin_occurrence_actions.dart';
import 'package:cl_club_events/src/widgets/cards/actions/cancel_reason_dialog.dart';
import 'package:cl_club_events/src/widgets/event_editor/event_cancellation_dialog.dart';
import 'package:cl_club_events/src/widgets/event_editor/event_management_section.dart';
import 'package:cl_club_events/src/widgets/event_editor/programme_end_date_dialog.dart';
import 'package:cl_club_forms/cl_club_forms.dart'
    show
        ProgrammeEndDateForm,
        ProgrammeEndDateFormFields,
        ProgrammeEndDateFormState;
import 'package:cl_member_auth/cl_member_auth.dart'
    show AuthNotifier, authStateProvider;
import 'package:cl_remote_store/cl_remote_store.dart'
    show
        clEventsMasterProvider,
        clOccurrencesProvider,
        clSingleOccurrenceProvider;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart' hide Visibility;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show ActionItem;

import '../support/programme_fixtures.dart';
import '../support/recording_cutoff_events.dart';

const _eventVersion = 3;
const _reason = 'The rink is closed';

/// What a stale refusal tells the admin: who changed the event.
final Finder _changedByAnotherAdmin = find.textContaining(
  'was changed by another_admin',
);

Event _camp({bool cancelled = false}) {
  final start = localNoon(10).toUtc();
  return Event(
    id: 1,
    version: _eventVersion,
    title: 'workflow_cutoff_camp',
    description: '',
    type: EventType.camp,
    visibility: Visibility.public,
    venueId: 7,
    rrule: 'FREQ=DAILY;COUNT=3',
    startTimeUtc: start,
    endTimeUtc: start.add(const Duration(hours: 1)),
    untilTimeUtc: cancelled ? localNoon(11).toUtc() : null,
    createdAtUtc: DateTime.utc(2026),
    updatedAtUtc: DateTime.utc(2026),
  );
}

Occurrence _occurrence(DateTime start) => Occurrence(
  eventId: 1,
  originalStartTimeUtc: start,
  actualStartTimeUtc: start,
  actualEndTimeUtc: start.add(const Duration(hours: 1)),
  status: OccurrenceStatus.scheduled,
  venueId: 7,
  version: 6,
);

final _admin = UserPrivate(
  username: 'an_admin',
  displayName: 'an_admin',
  status: UserStatus.active,
  isSuperAdmin: false,
  roles: const UserRoles(isAdmin: true),
  createdAtUtc: DateTime.utc(2024),
);

class _StaticAuth extends AuthNotifier {
  @override
  Future<UserPrivate?> build() async => _admin;
}

/// Pumps [body] over an events master that records the cutoff calls of
/// [event], refusing each with [error] when one is given.
Future<RecordingCutoffEvents> _pump(
  WidgetTester tester,
  Event event,
  Widget body, {
  Exception? error,
}) async {
  tester.view.physicalSize = const Size(1400, 2600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final events = RecordingCutoffEvents(event)..error = error;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        clEventsMasterProvider.overrideWith(() => events),
        authStateProvider.overrideWith(_StaticAuth.new),
        clSingleOccurrenceProvider.overrideWith(
          (ref, key) async => _occurrence(key.occurrenceTimeUtc),
        ),
        clOccurrencesProvider.overrideWith(
          (ref, key) async => [
            for (final days in [10, 11, 12])
              _occurrence(localNoon(days).toUtc()),
          ],
        ),
      ],
      child: ShadApp(home: Scaffold(body: body)),
    ),
  );
  await tester.pumpAndSettle();
  return events;
}

/// A button that opens [dialog].
Widget _opener(Widget dialog) => Builder(
  builder: (context) => ShadButton(
    onPressed: () =>
        showShadDialog<void>(context: context, builder: (_) => dialog),
    child: const Text('open'),
  ),
);

Future<void> _press(WidgetTester tester, String label) async {
  await tester.tap(find.widgetWithText(ShadButton, label).last);
  await tester.pumpAndSettle();
}

/// Opens the Cancel camp dialog of [event] and presses its action with a
/// reason typed.
Future<RecordingCutoffEvents> _cancelCamp(
  WidgetTester tester,
  Event event, {
  Exception? error,
}) async {
  final events = await _pump(
    tester,
    event,
    _opener(EventCancellationDialog(event: event)),
    error: error,
  );
  await _press(tester, 'open');
  await tester.enterText(find.byType(EditableText), _reason);
  await tester.pump();
  await _press(tester, EventCancellationMessages.cancelCamp);
  return events;
}

/// Presses Undo cancel on [event]'s management section and confirms.
Future<RecordingCutoffEvents> _undoCancel(
  WidgetTester tester,
  Event event, {
  Exception? error,
}) async {
  final events = await _pump(
    tester,
    event,
    SingleChildScrollView(
      child: EventManagementSection(event: event, currentUser: _admin),
    ),
    error: error,
  );
  await _press(tester, EventCancellationMessages.undoCancel);
  await _press(tester, EventCancellationMessages.undoCancel);
  return events;
}

/// Opens the end date dialog of [event], picks a last day, types a reason
/// and presses Save.
Future<RecordingCutoffEvents> _setEndDate(
  WidgetTester tester,
  Event event, {
  Exception? error,
}) async {
  final events = await _pump(
    tester,
    event,
    _opener(ProgrammeEndDateDialog(event: event)),
    error: error,
  );
  await _press(tester, 'open');
  final day = localNoon(5);
  tester
      .state<ProgrammeEndDateFormState>(find.byType(ProgrammeEndDateForm))
      .formKey
      .currentState!
      .setFieldValue<DateTime?>(
        ProgrammeEndDateFormFields.lastDayId,
        DateTime(day.year, day.month, day.day),
      );
  await tester.pumpAndSettle();
  await tester.enterText(
    find.descendant(
      of: find.byType(ProgrammeEndDateForm),
      matching: find.byType(EditableText),
    ),
    'Season over',
  );
  await tester.pump();
  await _press(tester, 'Save');
  return events;
}

/// Presses **Cancel entire series** on a session of [event] and gives a
/// reason.
Future<RecordingCutoffEvents> _cancelSeriesFromSession(
  WidgetTester tester,
  Event event, {
  Exception? error,
}) async {
  late List<ActionItem> actions;
  final events = await _pump(
    tester,
    event,
    AdminOccurrenceActions(
      occurrence: _occurrence(localNoon(10).toUtc()),
      onMarkAttendance: (_, _) {},
      builder: (context, resolved) {
        actions = resolved;
        return const SizedBox.shrink();
      },
    ),
    error: error,
  );
  actions.firstWhere((a) => a.label == 'Cancel entire series').onPressed!();
  await tester.pumpAndSettle();
  await tester.enterText(
    find.descendant(
      of: find.byType(CancelReasonDialog),
      matching: find.byType(EditableText),
    ),
    _reason,
  );
  await _press(tester, 'Cancel Session');
  return events;
}

void main() {
  group(
    'Issue 123: the cutoff actions send the version of the event shown',
    () {
      testWidgets('Issue 123: Cancel camp sends the camp version', (
        tester,
      ) async {
        final events = await _cancelCamp(tester, _camp());

        expect(events.calls, ['cancelSeries(v$_eventVersion)']);
      });

      testWidgets('Issue 123: Undo cancel sends the camp version', (
        tester,
      ) async {
        final events = await _undoCancel(tester, _camp(cancelled: true));

        expect(events.calls, ['undoCancelSeries(v$_eventVersion)']);
        expect(
          find.text(EventCancellationMessages.cancelUndone),
          findsOneWidget,
        );
      });

      testWidgets(
        'Issue 123: the end date dialog sends the programme version',
        (
          tester,
        ) async {
          final event = programmeFixture();
          final events = await _setEndDate(tester, event);

          expect(events.calls, ['terminate(v${event.version})']);
        },
      );

      testWidgets('Issue 123: Cancel entire series, from a session, leaves the '
          'version to the master, which sends the one it holds', (
        tester,
      ) async {
        final events = await _cancelSeriesFromSession(tester, _camp());

        expect(events.calls, ['cancelSeries(vnull)']);
      });
    },
  );

  group('Issue 123: an event another admin changed first: the action is '
      'refused and says who changed it', () {
    testWidgets('Issue 123: Cancel camp closes its dialog and says who', (
      tester,
    ) async {
      await _cancelCamp(tester, _camp(), error: staleCutoff());

      expect(_changedByAnotherAdmin, findsOneWidget);
      expect(find.textContaining('It has been reloaded'), findsOneWidget);
      expect(find.byType(EventCancellationDialog), findsNothing);
    });

    testWidgets('Issue 123: Undo cancel says who', (tester) async {
      await _undoCancel(tester, _camp(cancelled: true), error: staleCutoff());

      expect(_changedByAnotherAdmin, findsOneWidget);
      expect(find.text(EventCancellationMessages.cancelUndone), findsNothing);
    });

    testWidgets('Issue 123: the end date dialog closes and says who', (
      tester,
    ) async {
      await _setEndDate(tester, programmeFixture(), error: staleCutoff());

      expect(_changedByAnotherAdmin, findsOneWidget);
      expect(find.textContaining('This programme'), findsOneWidget);
      expect(
        find.byType(ProgrammeEndDateDialog),
        findsNothing,
        reason: 'it held the programme as it was before the reload',
      );
    });

    testWidgets('Issue 123: Cancel entire series says who changed the event', (
      tester,
    ) async {
      await _cancelSeriesFromSession(tester, _camp(), error: staleCutoff());

      expect(_changedByAnotherAdmin, findsOneWidget);
      expect(find.textContaining('This event'), findsOneWidget);
    });
  });
}
