// workflow_archive: Archive, Unarchive and Delete for an event, from the
// Event Management card of `/memberzone/events/:id` (club_client#36).
//
// In the app the server's soft delete is Archive, its restore Unarchive and
// its hard delete Delete.
//
// Flow:
//   0. Sudo creates an admin and a coach, and a venue.
//   1. The coach creates a camp (and so is its organizer): Event Management
//      offers Rename, none of Archive / Unarchive / Delete, and the camps
//      list has no Show archived switch.
//   2. The admin archives the camp after confirming: it leaves the camps
//      list and its page turns read-only. With Show archived on it is
//      listed, marked Archived, and opens; the admin has no Delete there,
//      unarchives it, and it is back in the list. The admin archives it
//      again.
//   3. The coach never loads the archived camp.
//   4. Sudo (the super admin) finds it with Show archived, deletes it after
//      confirming, and is returned to the camps list.
//   5. Cleanup: sudo soft-deletes the actors via the UI.
//
// Recommended run (from the club_client root):
//   just app-test-one app_test_server1.conf \
//       workflow_archive_event_archive_delete_test.dart

import 'package:cl_club_events/cl_club_events.dart' show EventDetailsView;
import 'package:cl_remote_store/cl_remote_store.dart'
    show clEventsMasterProvider;
import 'package:club_sdk_2/club_sdk_2.dart' show Event, EventType, Role;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart'
    show ActionButton, EntityCard, SectionEditButton;

import '_helpers/auth.dart';
import '_helpers/events.dart';
import '_helpers/forms.dart';
import '_helpers/pump.dart';
import '_helpers/users.dart';
import '_helpers/venues.dart';

const _kApiBaseUrl = String.fromEnvironment(
  'CLUB_API_BASE_URL',
  defaultValue: 'http://127.0.0.1:8155/v1',
);
const _kSudoUsername = String.fromEnvironment(
  'SUDO_USERNAME',
  defaultValue: 'sudo',
);
const _kSudoPassword = String.fromEnvironment('SUDO_PASSWORD');

const _kAdmin = 'workflow_archive_admin';
const _kCoach = 'workflow_archive_coach';
const _kPwd = 'WfArchivePwd!2024';

const _kVenueName = 'workflow_archive_venue';
const _kCamp = 'workflow_archive_camp';

const _kCampsPath = '/memberzone/events/camps';
const _kManagement = 'Event Management';
const _kShowArchived = 'Show archived';
const _kArchivedCaption = 'Archived';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  if (_kSudoPassword.isEmpty) {
    throw StateError(
      'SUDO_PASSWORD must be supplied via --dart-define '
      '(or --dart-define-from-file=integration_test/.test_env).',
    );
  }

  testWidgets(
    'an admin archives and unarchives a camp from Event Management, and '
    'the super admin deletes the archived camp',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1600, 4000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await pumpApp(tester, apiBaseUrl: _kApiBaseUrl);
      await ensureLoggedOut(tester);

      // ─── Phase 0: sudo creates the actors and the venue ────────────────
      await loginViaUi(tester, _kSudoUsername, _kSudoPassword);
      await createUserViaUi(tester, username: _kAdmin, password: _kPwd);
      await grantRolesViaCheckboxViaUi(
        tester,
        username: _kAdmin,
        roles: {Role.admin},
      );
      await createUserViaUi(tester, username: _kCoach, password: _kPwd);
      await grantRolesViaCheckboxViaUi(
        tester,
        username: _kCoach,
        roles: {Role.coach},
      );
      await createVenueViaUi(tester, name: _kVenueName);
      final venueId = await waitForVenueId(tester, _kVenueName);
      await logout(tester);

      // ─── Phase 1: the organizer (a coach) has none of the three ────────
      await loginViaUi(tester, _kCoach, _kPwd);
      await createEventViaUi(
        tester,
        type: EventType.camp,
        title: _kCamp,
        venueId: venueId,
      );
      final eventId = (await waitForEvent(tester, _kCamp)).id;
      await _openCamp(tester);
      expect(_managementButton('Rename'), findsOneWidget);
      expect(_managementButton('Archive'), findsNothing);
      expect(_managementButton('Unarchive'), findsNothing);
      expect(_managementButton('Delete'), findsNothing);
      await go(tester, _kCampsPath);
      await _openFilter(tester);
      expect(
        find.text(_kShowArchived),
        findsNothing,
        reason: 'only an admin is offered Show archived',
      );
      await logout(tester);

      // ─── Phase 2: the admin archives, finds and unarchives the camp ────
      await loginViaUi(tester, _kAdmin, _kPwd);
      await _openCamp(tester);
      expect(
        _managementButton('Delete'),
        findsNothing,
        reason: 'Delete is offered on an archived event only',
      );
      expect(_managementButton('Unarchive'), findsNothing);

      // Archive asks first and says the members are notified; Cancel
      // archives nothing.
      await _pressManagement(tester, 'Archive');
      expect(find.text('Archive event'), findsOneWidget);
      expect(
        find.textContaining('enrolled members are notified'),
        findsOneWidget,
      );
      await _answerDialog(tester, 'Cancel');
      expect(_event(tester, eventId)!.isActive, isTrue);

      await _archive(tester, eventId);

      // Its page is read-only apart from Event Management.
      expect(
        find.descendant(
          of: find.byType(EventDetailsView),
          matching: find.byType(SectionEditButton),
        ),
        findsNothing,
        reason: 'an archived event has no section editor',
      );
      expect(find.byTooltip('Edit Description'), findsNothing);
      expect(find.textContaining('This event is archived'), findsOneWidget);
      expect(_managementButton('Rename'), findsNothing);
      expect(_managementButton('Unarchive'), findsOneWidget);
      expect(
        _managementButton('Delete'),
        findsNothing,
        reason: 'an admin who is not the super admin never sees Delete',
      );

      // It has left the camps list; Show archived brings it back, marked.
      await go(tester, _kCampsPath);
      await settle(tester);
      expect(_campCard(), findsNothing);
      await _showArchived(tester);
      await waitFor(
        tester,
        () => _campCard().evaluate().isNotEmpty,
        description: 'the archived camp to be listed with Show archived on',
      );
      expect(
        tester.widget<EntityCard>(_campCard()).caption,
        _kArchivedCaption,
      );

      // It opens from there, and the admin unarchives it.
      tester.widget<EntityCard>(_campCard()).onTap!.call();
      await settle(tester);
      await waitFor(
        tester,
        () => _managementButton('Unarchive').evaluate().isNotEmpty,
        description: 'the archived camp page with Unarchive',
      );
      await _pressManagement(tester, 'Unarchive');
      await waitFor(
        tester,
        () => _event(tester, eventId)?.isActive ?? false,
        description: 'the camp to be unarchived on the server',
      );
      expect(_managementButton('Archive'), findsOneWidget);
      expect(_managementButton('Rename'), findsOneWidget);

      // It is back in the list without Show archived.
      await _openCamp(tester);

      // Archived again, for the super admin to delete.
      await _archive(tester, eventId);
      await logout(tester);

      // ─── Phase 3: the coach never loads the archived camp ──────────────
      await loginViaUi(tester, _kCoach, _kPwd);
      await go(tester, _kCampsPath);
      await waitFor(
        tester,
        () => container(tester).read(clEventsMasterProvider).hasValue,
        description: 'the events master to load for the coach',
      );
      expect(
        _event(tester, eventId),
        isNull,
        reason: 'a non-admin never loads archived events',
      );
      expect(_campCard(), findsNothing);
      await logout(tester);

      // ─── Phase 4: the super admin deletes the archived camp ────────────
      await loginViaUi(tester, _kSudoUsername, _kSudoPassword);
      await go(tester, _kCampsPath);
      await _showArchived(tester);
      await waitFor(
        tester,
        () => _campCard().evaluate().isNotEmpty,
        description: 'the archived camp in the super admin camps list',
      );
      tester.widget<EntityCard>(_campCard()).onTap!.call();
      await settle(tester);
      await waitFor(
        tester,
        () => _managementButton('Delete').evaluate().isNotEmpty,
        description: 'Delete on the archived camp for the super admin',
      );

      await _pressManagement(tester, 'Delete');
      expect(find.text('Delete event'), findsOneWidget);
      expect(find.textContaining('"$_kCamp"'), findsOneWidget);
      expect(find.textContaining('permanently'), findsOneWidget);
      await _answerDialog(tester, 'Delete');
      await waitFor(
        tester,
        () {
          final map = container(
            tester,
          ).read(clEventsMasterProvider).valueOrNull;
          return map != null && !map.containsKey(eventId);
        },
        description: 'the camp to be gone after Delete',
      );
      await settle(tester);

      // The app is back on the camps list, where even Show archived no
      // longer finds the camp.
      expect(find.byType(EventDetailsView), findsNothing);
      expect(find.text('Camps'), findsWidgets);
      expect(_filterButton(), findsOneWidget);
      await _showArchived(tester);
      expect(_campCard(), findsNothing);

      // ─── Phase 5: cleanup ──────────────────────────────────────────────
      await softDeleteUserViaUi(tester, _kAdmin);
      await softDeleteUserViaUi(tester, _kCoach);
      await logout(tester);
    },
    timeout: const Timeout(Duration(minutes: 20)),
  );
}

// ---------------------------------------------------------------------------
// Local helpers.
// ---------------------------------------------------------------------------

/// The camp as the events master holds it, or `null` when it is not there.
Event? _event(WidgetTester tester, int eventId) =>
    container(tester).read(clEventsMasterProvider).valueOrNull?[eventId];

Finder _campCard() =>
    find.byWidgetPredicate((w) => w is EntityCard && w.title == _kCamp);

Finder _filterButton() => find.widgetWithText(ActionButton, 'Filter');

/// A button of the Event Management card, by its label.
Finder _managementButton(String label) => find.descendant(
  of: find.ancestor(
    of: find.text(_kManagement),
    matching: find.byType(ShadCard),
  ),
  matching: find.widgetWithText(ActionButton, label),
);

/// Opens the camp's page from the camps list.
Future<void> _openCamp(WidgetTester tester) async {
  await go(tester, _kCampsPath);
  await waitFor(
    tester,
    () => _campCard().evaluate().isNotEmpty,
    description: 'camp card "$_kCamp" in the camps list',
  );
  tester.widget<EntityCard>(_campCard()).onTap!.call();
  await settle(tester);
  await waitFor(
    tester,
    () => find.text(_kManagement).evaluate().isNotEmpty,
    description: 'the camp page with Event Management',
  );
}

Future<void> _pressManagement(WidgetTester tester, String label) async {
  final button = _managementButton(label);
  expect(button, findsOneWidget, reason: 'Event Management "$label"');
  tester.widget<ActionButton>(button).onPressed!.call();
  await settle(tester);
}

/// Presses the open dialog's [label] button.
Future<void> _answerDialog(WidgetTester tester, String label) async {
  invokeShadButton(
    tester,
    find.descendant(
      of: find.byType(ShadDialog),
      matching: find.widgetWithText(ShadButton, label),
    ),
    reason: 'dialog "$label"',
  );
  await settle(tester);
}

/// Archives the camp from its open page and waits for the server's answer.
Future<void> _archive(WidgetTester tester, int eventId) async {
  await _pressManagement(tester, 'Archive');
  await _answerDialog(tester, 'Archive');
  await waitFor(
    tester,
    () => !(_event(tester, eventId)?.isActive ?? true),
    description: 'the camp to be archived on the server',
  );
  await settle(tester);
}

Future<void> _openFilter(WidgetTester tester) async {
  await waitFor(
    tester,
    () => _filterButton().evaluate().isNotEmpty,
    description: 'the Filter button of the camps list',
  );
  tester.widget<ActionButton>(_filterButton()).onPressed!.call();
  await settle(tester);
  expect(find.text('Include past'), findsOneWidget);
}

/// Turns Show archived on in the open list's filter, then closes the filter.
Future<void> _showArchived(WidgetTester tester) async {
  await _openFilter(tester);
  expect(find.text(_kShowArchived), findsOneWidget);
  // Show archived is the filter's last switch, below Include past.
  final toggle = find.byType(ShadSwitch).last;
  tester.widget<ShadSwitch>(toggle).onChanged!(true);
  await settle(tester);
  tester.widget<ActionButton>(_filterButton()).onPressed!.call();
  await settle(tester);
}
