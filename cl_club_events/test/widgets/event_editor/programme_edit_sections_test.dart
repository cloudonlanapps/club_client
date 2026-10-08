// A programme's title is corrected and its staffing changes by a split from
// a session onward; a camp's are updated (club_client#118).
import 'package:cl_club_events/src/models/event_management_messages.dart';
import 'package:cl_club_events/src/models/programme_schedule_form_helpers.dart'
    show programmeAdjustFromOptions;
import 'package:cl_club_events/src/widgets/event_editor/event_management_section.dart';
import 'package:cl_club_events/src/widgets/event_editor/organizer_coaches_section.dart'
    show OrganizerCoachesSection;
import 'package:cl_club_forms/cl_club_forms.dart'
    show EventFormFields, RenameFormFields;
import 'package:cl_remote_store/cl_remote_store.dart'
    show
        ClUsersMasterNotifier,
        clEventSchedulesProvider,
        clEventsMasterProvider,
        clUsersMasterProvider;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart' hide Visibility;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../support/programme_fixtures.dart';
import '../../support/recording_edit_events.dart';

final Event _programme = programmeFixture().copyWith(
  organizerName: () => 'org',
  coachNames: () => const ['coach_a'],
);

final Event _camp = _programme.copyWith(
  type: EventType.camp,
  rrule: () => 'FREQ=DAILY;COUNT=3',
);

final UserPrivate _admin = UserPrivate(
  username: 'an_admin',
  displayName: 'an_admin',
  status: UserStatus.active,
  isSuperAdmin: false,
  roles: const UserRoles(isAdmin: true),
  createdAtUtc: DateTime.utc(2024),
);

class _NoUsers extends ClUsersMasterNotifier {
  @override
  Future<Map<String, UserInfo>> build() async => {};
}

Future<RecordingEditEvents> _pump(
  WidgetTester tester,
  Event event,
  Widget section,
) async {
  tester.view.physicalSize = const Size(1200, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final events = RecordingEditEvents(event);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        clEventsMasterProvider.overrideWith(() => events),
        clUsersMasterProvider.overrideWith(_NoUsers.new),
        clEventSchedulesProvider(event.id).overrideWith((ref) async => []),
      ],
      child: ShadApp(
        home: ShadToaster(
          child: Scaffold(body: SingleChildScrollView(child: section)),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return events;
}

Future<RecordingEditEvents> _rename(WidgetTester tester, Event event) async {
  final events = await _pump(
    tester,
    event,
    EventManagementSection(event: event, currentUser: _admin, onDeleted: () {}),
  );
  await tester.tap(
    find.widgetWithText(ShadButton, EventManagementMessages.rename),
  );
  await tester.pumpAndSettle();
  await tester.enterText(
    find.byWidgetPredicate(
      (w) => w is ShadInputFormField && w.id == RenameFormFields.valueId,
    ),
    'Renamed',
  );
  await tester.tap(find.widgetWithText(ShadButton, 'Save'));
  await tester.pumpAndSettle();
  return events;
}

/// Opens the Organizer & Coaches editor of [event] and removes its one
/// coach, so there is something to save.
Future<RecordingEditEvents> _openStaffEditor(
  WidgetTester tester,
  Event event,
) async {
  final events = await _pump(
    tester,
    event,
    OrganizerCoachesSection(event: event),
  );
  await tester.tap(find.byIcon(LucideIcons.pencil));
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithIcon(ShadButton, LucideIcons.x));
  await tester.pumpAndSettle();
  return events;
}

Future<void> _save(WidgetTester tester) async {
  await tester.tap(find.widgetWithText(ShadButton, 'Save'));
  await tester.pumpAndSettle();
}

Finder _field(String id) =>
    find.byWidgetPredicate((w) => w is ShadFormBuilderField && w.id == id);

void main() {
  testWidgets("Issue 118: a programme's rename is saved as a correction", (
    tester,
  ) async {
    final events = await _rename(tester, _programme);

    expectOneEdit(events, correctionVerb, {'title': 'Renamed'});
  });

  testWidgets("Issue 118: a camp's rename is saved as an update", (
    tester,
  ) async {
    final events = await _rename(tester, _camp);

    expectOneEdit(events, updateVerb, {'title': 'Renamed'});
  });

  testWidgets("Issue 118: a programme's organizer and coaches change by a "
      'split from the session the editor asks for', (tester) async {
    final events = await _openStaffEditor(tester, _programme);
    final upcoming = programmeAdjustFromOptions(_programme);

    // The editor asks for the session, and opens on the soonest.
    expect(_field(EventFormFields.effectiveFromId), findsOneWidget);
    await _save(tester);

    expectOneEdit(events, splitVerb, {
      'effectiveDateTimeUtc': upcoming.first,
      'version': _programme.version,
      'coachNames': const <String>[],
    });
  });

  testWidgets("Issue 118: a camp's organizer and coaches are saved as an "
      'update, with no session asked for', (tester) async {
    final events = await _openStaffEditor(tester, _camp);

    expect(_field(EventFormFields.effectiveFromId), findsNothing);
    await _save(tester);

    expectOneEdit(events, updateVerb, {
      'organizerName': 'org',
      'coachNames': const <String>[],
    });
  });

  testWidgets('Issue 118: a session the server no longer accepts shows on '
      'the From field', (tester) async {
    final events = await _openStaffEditor(tester, _programme);
    events.refusal = const ServerException(
      statusCode: 400,
      code: SdkErrorCode.cutoffTooSoon,
      message: 'too soon',
    );
    await _save(tester);

    expect(
      find.descendant(
        of: _field(EventFormFields.effectiveFromId),
        matching: find.textContaining('30 minutes'),
      ),
      findsOneWidget,
    );
    expect(find.byType(ShadToast), findsNothing);
  });
}
