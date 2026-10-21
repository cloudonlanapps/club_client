import 'package:cl_club_events/src/widgets/cards/actions/admin_occurrence_actions.dart';
import 'package:cl_club_events/src/widgets/event_editor/programme_end_date_dialog.dart';
import 'package:cl_club_forms/cl_club_forms.dart'
    show ProgrammeEndDateForm, ProgrammeEndDateFormState;
import 'package:cl_member_auth/cl_member_auth.dart';
import 'package:cl_remote_store/cl_remote_store.dart'
    show clEventSchedulesProvider, clEventsMasterProvider;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart' hide Visibility;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show ActionItem;

import '../../support/programme_fixtures.dart';
import '../../support/recording_schedule_events.dart';

class _StaticAuthNotifier extends AuthNotifier {
  @override
  Future<UserPrivate?> build() async => UserPrivate(
    username: 'admin_user',
    displayName: 'Admin User',
    status: UserStatus.active,
    isSuperAdmin: false,
    roles: const UserRoles(isAdmin: true),
    createdAtUtc: DateTime.now().toUtc(),
  );
}

/// The programme's session [days] from today, at local noon.
Occurrence _session(int days) {
  final start = localNoon(days).toUtc();
  return Occurrence(
    eventId: 1,
    originalStartTimeUtc: start,
    actualStartTimeUtc: start,
    actualEndTimeUtc: start.add(const Duration(hours: 1)),
    status: OccurrenceStatus.scheduled,
    venueId: 7,
  );
}

/// Pumps the card actions of [occurrence] of [event] and opens End
/// programme from here.
Future<RecordingScheduleEvents> _openEndProgramme(
  WidgetTester tester,
  Event event,
  Occurrence occurrence,
) async {
  tester.view.physicalSize = const Size(1400, 2600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final events = RecordingScheduleEvents(event);
  late List<ActionItem> actions;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        clEventsMasterProvider.overrideWith(() => events),
        clEventSchedulesProvider.overrideWith((ref, id) async => const []),
        authStateProvider.overrideWith(_StaticAuthNotifier.new),
      ],
      child: ShadApp(
        home: Scaffold(
          body: AdminOccurrenceActions(
            occurrence: occurrence,
            onMarkAttendance: (_, _) {},
            builder: (context, resolved) {
              actions = resolved;
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  actions.singleWhere((a) => a.label == 'End programme from here').onPressed!();
  await tester.pumpAndSettle();
  return events;
}

ProgrammeEndDateFormState _form(WidgetTester tester) =>
    tester.state<ProgrammeEndDateFormState>(find.byType(ProgrammeEndDateForm));

void main() {
  testWidgets('Issue 178: End programme from here opens Adjust end date on '
      'the day before the session, and Save terminates at it', (tester) async {
    final events = await _openEndProgramme(
      tester,
      programmeFixture(),
      _session(5),
    );

    expect(find.text(ProgrammeEndDateDialog.title), findsOneWidget);
    final day = localNoon(4);
    expect(_form(tester).lastDay, DateTime(day.year, day.month, day.day));
    expect(_form(tester).isDirty, isTrue);

    await tester.enterText(
      find.descendant(
        of: find.byType(ProgrammeEndDateForm),
        matching: find.byType(EditableText),
      ),
      'Season over',
    );
    await tester.pump();
    await tester.tap(find.widgetWithText(ShadButton, 'Save'));
    await tester.pumpAndSettle();

    expect(events.endDateCalls, [
      'terminate(${localNoon(5).toUtc()}, Season over)',
    ]);
  });

  testWidgets('Issue 178: on a programme with an end ahead it moves the end '
      'to the day before the session', (tester) async {
    final events = await _openEndProgramme(
      tester,
      programmeFixture(untilTimeUtc: localNoon(10).toUtc()),
      _session(5),
    );

    await tester.tap(find.widgetWithText(ShadButton, 'Save'));
    await tester.pumpAndSettle();

    expect(events.endDateCalls, ['extend(${localNoon(5).toUtc()}, null)']);
  });

  testWidgets('Issue 182: End programme from here on a session later today '
      'terminates at that session', (tester) async {
    // A daily programme whose sessions start 45 minutes from now: today's
    // is still inside the scheduling window.
    final now = DateTime.now();
    final today = DateTime(
      now.year,
      now.month,
      now.day,
      now.hour,
      now.minute,
    ).add(const Duration(minutes: 45));
    final start = today.subtract(const Duration(days: 20)).toUtc();
    final event = programmeFixture().copyWith(
      startTimeUtc: start,
      endTimeUtc: start.add(const Duration(hours: 1)),
    );
    final session = Occurrence(
      eventId: 1,
      originalStartTimeUtc: today.toUtc(),
      actualStartTimeUtc: today.toUtc(),
      actualEndTimeUtc: today.toUtc().add(const Duration(hours: 1)),
      status: OccurrenceStatus.scheduled,
      venueId: 7,
    );
    final events = await _openEndProgramme(tester, event, session);

    await tester.enterText(
      find.descendant(
        of: find.byType(ProgrammeEndDateForm),
        matching: find.byType(EditableText),
      ),
      'Season over',
    );
    await tester.pump();
    await tester.tap(find.widgetWithText(ShadButton, 'Save'));
    await tester.pumpAndSettle();

    expect(
      find.text('The end date cannot be before today'),
      findsNothing,
    );
    expect(events.endDateCalls, ['terminate(${today.toUtc()}, Season over)']);
  });
}
