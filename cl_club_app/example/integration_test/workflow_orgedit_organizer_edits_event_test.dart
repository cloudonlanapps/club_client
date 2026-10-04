// workflow_orgedit: the organizer of an event edits it on
// `/memberzone/events/:id` (EventDetailsView) even when they are a coach and
// not an admin; any other coach reads it (club_core#150).
//
// The server lets the organizer or an admin change an event
// (`require_organizer_or_admin` on PATCH, correction, reschedule, cancel), so
// the app gates the inline editor on `canManageEvent`, not on the admin role.
//
// Flow:
//   0. Sudo creates an admin and two coaches.
//   1. Admin creates a venue (UI) and seeds a camp organized by the first
//      coach.
//   2. The organizer-coach opens the camp, sees the section editors (the
//      schedule among them), and edits the description and the eligibility;
//      both round-trip to the server.
//   3. The other coach opens the camp: no description editor, no management
//      section, no schedule pencil.
//   4. Cleanup: admin soft-deletes the camp (no delete UI in the editor, so via
//      the master notifier); sudo soft-deletes the actors via the UI.

import 'package:cl_club_events/cl_club_events.dart' show EventDetailsView;
import 'package:cl_club_events/src/widgets/event_editor/camp_schedule_section.dart'
    show CampScheduleSection;
import 'package:cl_club_events/src/widgets/events_preview/cl_event_gallery.dart'
    show ClEventGallery;
import 'package:cl_remote_store/cl_remote_store.dart'
    show clEventsMasterProvider;
import 'package:club_sdk_2/club_sdk_2.dart'
    show Event, EventType, Gender, Role, Visibility;
import 'package:flutter/material.dart' hide Visibility;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart'
    show EntityCard, EventFormFields, EventGender, SectionEditButton;

import '_helpers/auth.dart';
import '_helpers/editors.dart';
import '_helpers/events.dart' show waitForVenueId;
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

const _kAdmin = 'workflow_orgedit_admin';
const _kOrganizer = 'workflow_orgedit_organizer';
const _kOtherCoach = 'workflow_orgedit_coach';
const _kPwd = 'WfOrgEditPwd!2024';

const _kVenueName = 'workflow_orgedit_site';
const _kVenueAddress = 'workflow_orgedit address line 1';
const _kEventTitle = 'workflow_orgedit_camp';
const _kInitialDescription = 'workflow_orgedit initial description.';
const _kEditedDescription =
    '# workflow_orgedit updated\n\nEdited inline by the organizer.';

const _kEditDescriptionTooltip = 'Edit Description';
const _kManagementTitle = 'Event Management';
const _kEligibilityTitle = 'Eligibility';

/// A day a month ahead, at midnight UTC: well inside the server's 52-week
/// scheduling horizon, which a fixed future date would one day leave.
DateTime get _campDay {
  final d = DateTime.now().toUtc().add(const Duration(days: 30));
  return DateTime.utc(d.year, d.month, d.day);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  if (_kSudoPassword.isEmpty) {
    throw StateError(
      'SUDO_PASSWORD must be supplied via --dart-define '
      '(or --dart-define-from-file=integration_test/.test_env).',
    );
  }

  testWidgets(
    'the organizer of a camp edits it as a coach; another coach reads it',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1600, 4000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await pumpApp(tester, apiBaseUrl: _kApiBaseUrl);
      await ensureLoggedOut(tester);

      // ─── Phase 0: sudo creates the actors ──────────────────────────────
      await loginViaUi(tester, _kSudoUsername, _kSudoPassword);
      await createUserViaUi(tester, username: _kAdmin, password: _kPwd);
      await grantRolesViaCheckboxViaUi(
        tester,
        username: _kAdmin,
        roles: {Role.admin},
      );
      for (final coach in [_kOrganizer, _kOtherCoach]) {
        await createUserViaUi(tester, username: coach, password: _kPwd);
        await grantRolesViaCheckboxViaUi(
          tester,
          username: coach,
          roles: {Role.coach},
        );
      }
      await logout(tester);

      // ─── Phase 1: admin creates the venue + a camp the coach organizes ──
      await loginViaUi(tester, _kAdmin, _kPwd);
      await createVenueViaUi(
        tester,
        name: _kVenueName,
        address: _kVenueAddress,
      );
      final venueId = await waitForVenueId(tester, _kVenueName);
      final created = await container(tester)
          .read(clEventsMasterProvider.notifier)
          .createEvent(
            title: _kEventTitle,
            description: _kInitialDescription,
            type: EventType.camp,
            visibility: Visibility.public,
            venueId: venueId,
            startTimeUtc: _campDay.add(const Duration(hours: 9)),
            endTimeUtc: _campDay.add(const Duration(hours: 10)),
            organizerName: _kOrganizer,
            rrule: 'FREQ=DAILY;COUNT=3',
          );
      final eventId = created.id;
      await logout(tester);

      // ─── Phase 2: the organizer-coach edits the camp ───────────────────
      await loginViaUi(tester, _kOrganizer, _kPwd);
      await _openCampDetail(tester, _kEventTitle);
      expect(find.byTooltip(_kEditDescriptionTooltip), findsOneWidget);
      expect(find.text(_kManagementTitle), findsOneWidget);
      expectSectionEditable(tester, find.byType(CampScheduleSection));

      await editMarkdownField(
        tester,
        tooltip: _kEditDescriptionTooltip,
        markdown: _kEditedDescription,
      );
      await waitFor(
        tester,
        () => _event(tester, eventId).description == _kEditedDescription,
        description: 'organizer description edit to round-trip',
      );

      await tapSectionPencil(tester, _sectionCard(_kEligibilityTitle));
      setShadFormValues(tester, {
        EventFormFields.genderId: EventGender.female,
        EventFormFields.dobOnOrAfterId: DateTime.utc(2010),
        EventFormFields.dobOnOrBeforeId: DateTime.utc(2014),
      });
      await saveInlineEditor(tester);
      await waitFor(
        tester,
        () => _event(tester, eventId).gender == Gender.female,
        description: 'organizer eligibility edit to round-trip',
      );
      await logout(tester);

      // ─── Phase 3: another coach reads the camp ─────────────────────────
      await loginViaUi(tester, _kOtherCoach, _kPwd);
      await _openCampDetail(tester, _kEventTitle);
      expect(
        find.byTooltip(_kEditDescriptionTooltip),
        findsNothing,
        reason: 'a coach who does not organize the camp gets no editor',
      );
      expect(find.text(_kManagementTitle), findsNothing);
      // Any coach may write event media (require_admin_or_coach), so the
      // gallery pencil is theirs; no other section has one.
      final pencils = find.descendant(
        of: find.byType(EventDetailsView),
        matching: find.byType(SectionEditButton),
      );
      final galleryPencils = find.descendant(
        of: find.byType(ClEventGallery),
        matching: find.byType(SectionEditButton),
      );
      expect(
        pencils.evaluate().length,
        galleryPencils.evaluate().length,
        reason: 'a coach sees no section pencil outside the gallery',
      );
      expect(find.byType(CampScheduleSection), findsNothing);
      await logout(tester);

      // ─── Phase 4: cleanup ──────────────────────────────────────────────
      await loginViaUi(tester, _kAdmin, _kPwd);
      await container(
        tester,
      ).read(clEventsMasterProvider.notifier).deleteEvent(eventId);
      await waitFor(
        tester,
        () => !_event(tester, eventId).isActive,
        description: 'camp to be soft-deleted',
      );
      await logout(tester);

      await loginViaUi(tester, _kSudoUsername, _kSudoPassword);
      await softDeleteUserViaUi(tester, _kAdmin);
      await softDeleteUserViaUi(tester, _kOrganizer);
      await softDeleteUserViaUi(tester, _kOtherCoach);
      await logout(tester);
    },
    timeout: const Timeout(Duration(minutes: 20)),
  );
}

// ---------------------------------------------------------------------------
// Local helpers.
// ---------------------------------------------------------------------------

Event _event(WidgetTester tester, int eventId) {
  final map = container(tester).read(clEventsMasterProvider).valueOrNull;
  expect(map, isNotNull, reason: 'clEventsMasterProvider should be loaded');
  final event = map![eventId];
  expect(event, isNotNull, reason: 'event #$eventId must exist');
  return event!;
}

/// Finds a section card's `ShadCard` by its title text.
Finder _sectionCard(String title) =>
    find.ancestor(of: find.text(title), matching: find.byType(ShadCard));

Future<void> _openCampDetail(WidgetTester tester, String title) async {
  await go(tester, '/memberzone/events/camps');
  final cardFinder = find.byWidgetPredicate(
    (w) => w is EntityCard && w.title == title,
  );
  await waitFor(
    tester,
    () => cardFinder.evaluate().isNotEmpty,
    description: 'camp card "$title" to render in the camps list',
  );
  tester.widget<EntityCard>(cardFinder.first).onTap!.call();
  await settle(tester);
  await waitFor(
    tester,
    () => find.byType(EventDetailsView).evaluate().isNotEmpty,
    description: 'EventDetailsView to render',
  );
}
