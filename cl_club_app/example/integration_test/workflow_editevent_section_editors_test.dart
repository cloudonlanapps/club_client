// workflow_editevent: focused coverage of the camp-event section editors on
// `/memberzone/events/:id` (EventDetailsView), across roles.
//
// Only admins and coaches can reach `/memberzone/events/*`
// (`userAllowedForEvents`), and only admins get the inline editors; members
// are routed to a different view (`MyEventDetailsView`) entirely, so they are
// out of scope here.
//
// Flow:
//   0. Sudo creates an admin and two coaches.
//   1. Admin creates a venue (UI) and seeds a camp (there is no event-create
//      UI yet), opens it, and sees the editable sections.
//   2. Coach opens the camp — read-only: no pencils, flags disabled, no
//      management section; content is still visible.
//   3. Admin edits via the section editors — transfer the organizer + add a
//      coach (one Save), then remove the coach (Save); eligibility (inline:
//      gender and the age band, club_client#33), description (markdown), the
//      featured flag, and the title (rename dialog); each change round-trips
//      to the server.
//   4. Coach re-opens and sees the updated title.
//   5. Cleanup: admin soft-deletes the camp (no delete UI in the editor, so via
//      the master notifier); sudo soft-deletes the actors via the UI.

import 'package:cl_club_events/cl_club_events.dart' show EventDetailsView;
import 'package:cl_club_events/src/widgets/events_preview/cl_event_gallery.dart'
    show ClEventGallery;
import 'package:cl_club_forms/cl_club_forms.dart'
    show AgeEligibilityText, EventFormFields, EventGender;
import 'package:cl_club_forms/src/widgets/age_eligibility/age_eligibility_form_fields.dart'
    show AgeEligibilityFormFields;
import 'package:cl_club_forms/src/widgets/age_eligibility/age_eligibility_form_validators.dart'
    show AgeEligibilityFormValidators;
import 'package:cl_remote_store/cl_remote_store.dart'
    show clEventsMasterProvider, clVenuesMasterProvider;
import 'package:club_sdk_2/club_sdk_2.dart'
    show Age, Event, EventType, Gender, Role, Visibility;
import 'package:flutter/material.dart' hide Visibility;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart'
    show ActionButton, EntityCard, SectionEditButton;

import '_helpers/auth.dart';
import '_helpers/editors.dart';
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

const _kAdmin = 'workflow_editevent_admin';
const _kCoach = 'workflow_editevent_coach';
const _kCoach2 = 'workflow_editevent_coach2';
const _kPwd = 'WfEditEventPwd!2024';

const _kVenueName = 'workflow_editevent_site';
const _kVenueAddress = 'workflow_editevent address line 1';
const _kEventTitle = 'workflow_editevent_camp';
const _kInitialDescription = 'workflow_editevent initial description.';
// organizer_name is a username reference on the server (it 404s if no such
// user exists), so the organizer must be an existing account — here the admin,
// then re-pointed at the coach.
const String _kInitialOrganizer = _kAdmin;
const String _kEditedOrganizer = _kCoach;
const _kEditedDescription =
    '# workflow_editevent updated\n\nEdited inline by the admin.';
const _kEditedTitle = 'workflow_editevent_camp_renamed';

// The age band the admin sets on the camp (club_client#33).
const _kMinAgeYears = 5;
const _kMaxAgeYears = 18;

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
    'camp section editors across admin (editable) and coach '
    '(read-only)',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1600, 4000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await pumpApp(tester, apiBaseUrl: _kApiBaseUrl);
      await ensureLoggedOut(tester);

      // ─── Phase 0: sudo creates the two actors ──────────────────────────
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
      await createUserViaUi(tester, username: _kCoach2, password: _kPwd);
      await grantRolesViaCheckboxViaUi(
        tester,
        username: _kCoach2,
        roles: {Role.coach},
      );
      await logout(tester);

      // ─── Phase 1: admin creates the venue + camp, sees editable sections ─
      await loginViaUi(tester, _kAdmin, _kPwd);
      await createVenueViaUi(
        tester,
        name: _kVenueName,
        address: _kVenueAddress,
      );
      final venueId = await _waitForVenueId(tester, _kVenueName);

      // No event-create UI yet — seed the camp through the master notifier.
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
            organizerName: _kInitialOrganizer,
            rrule: 'FREQ=DAILY;COUNT=3',
          );
      final eventId = created.id;

      await _openCampDetail(tester, _kEventTitle);
      expect(find.byType(EventDetailsView), findsOneWidget);
      // Admin sees section pencils, the description editor, and management.
      expectSectionEditable(tester, find.byType(EventDetailsView));
      expect(find.text('Eligibility'), findsOneWidget);
      expect(find.text('Organizer & Coaches'), findsOneWidget);
      expect(find.text('Event Management'), findsOneWidget);
      expect(find.byTooltip('Edit Description'), findsOneWidget);
      await logout(tester);

      // ─── Phase 2: coach view is read-only ──────────────────────────────
      await loginViaUi(tester, _kCoach, _kPwd);
      await _openCampDetail(tester, _kEventTitle);
      expect(find.byType(EventDetailsView), findsOneWidget);
      // A coach may edit only the gallery: the server lets admins and
      // coaches write event media (require_admin_or_coach), so its pencil is
      // theirs; every other section is read-only (club_core#59).
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
      expect(
        find.byTooltip('Edit Description'),
        findsNothing,
        reason: 'coach must not get the description editor',
      );
      expect(
        find.text('Event Management'),
        findsNothing,
        reason: 'coach must not see the management section',
      );
      _expectFeaturedFlagDisabled(tester);
      // Content is still visible to the coach (organizer shows in the audit
      // section).
      expect(find.text(_kInitialOrganizer), findsWidgets);
      await logout(tester);

      // ─── Phase 3: admin edits each section ─────────────────────────────
      await loginViaUi(tester, _kAdmin, _kPwd);
      await _openCampDetail(tester, _kEventTitle);

      // Organizer + coaches — transfer the organizer and add a coach in one
      // edit session, committed by a single Save (no per-change SDK call).
      await tapSectionPencil(tester, _sectionCard('Organizer & Coaches'));
      await _transferOrganizer(tester, _kEditedOrganizer);
      await _addCoach(tester, _kCoach2);
      await saveInlineEditor(tester);
      await waitFor(
        tester,
        () {
          final e = _event(tester, eventId);
          return e.organizerName == _kEditedOrganizer &&
              (e.coachNames ?? const []).contains(_kCoach2);
        },
        description: 'organizer transfer + coach add to round-trip',
      );

      // Coaches — remove the coach (strikethrough), Save, confirm it's gone.
      await tapSectionPencil(tester, _sectionCard('Organizer & Coaches'));
      await _removeFirstCoach(tester);
      await saveInlineEditor(tester);
      await waitFor(
        tester,
        () => (_event(tester, eventId).coachNames ?? const []).isEmpty,
        description: 'coach removal to round-trip',
      );

      // Eligibility — inline edit: the gender select, the minimum and
      // maximum age and the Strict age check (club_client#33).
      await tapSectionPencil(tester, _sectionCard('Eligibility'));
      expect(find.textContaining('DOB'), findsNothing);
      setShadFormValues(tester, {
        EventFormFields.genderId: EventGender.girls,
        AgeEligibilityFormFields.strictAgeId: true,
      });
      await enterTextById(
        tester,
        AgeEligibilityFormFields.minAgeYearsId,
        '$_kMinAgeYears',
      );
      await enterTextById(
        tester,
        AgeEligibilityFormFields.maxAgeYearsId,
        '$_kMaxAgeYears',
      );
      await saveInlineEditor(tester);
      await waitFor(
        tester,
        () {
          final e = _event(tester, eventId);
          return e.gender == Gender.female &&
              e.minAge == const Age(years: _kMinAgeYears) &&
              e.maxAge == const Age(years: _kMaxAgeYears) &&
              e.strictAge;
        },
        description: 'eligibility gender and age band to round-trip',
      );
      // The read view: the age sentence, with the dates the server worked
      // out and the day it counted them on beneath.
      final banded = _event(tester, eventId);
      expect(banded.dobOnOrAfterUtc, isNotNull);
      expect(banded.dobOnOrBeforeUtc, isNotNull);
      expect(banded.eligibilityReferenceDayUtc, isNotNull);
      expect(
        find.text('Open to members aged $_kMinAgeYears to $_kMaxAgeYears.'),
        findsOneWidget,
      );
      expect(
        find.text(
          AgeEligibilityText.window(
            dobOnOrAfter: banded.dobOnOrAfterUtc,
            dobOnOrBefore: banded.dobOnOrBeforeUtc,
            referenceDay: banded.eligibilityReferenceDayUtc,
          )!,
        ),
        findsOneWidget,
      );

      // A minimum above the maximum shows the inline message and saves
      // nothing.
      await tapSectionPencil(tester, _sectionCard('Eligibility'));
      await enterTextById(
        tester,
        AgeEligibilityFormFields.minAgeYearsId,
        '${_kMaxAgeYears + 1}',
      );
      invokeShadButton(
        tester,
        find.widgetWithText(ShadButton, 'Save'),
        reason: 'inline section editor Save',
      );
      await settle(tester);
      expect(
        find.text(AgeEligibilityFormValidators.bandMessage),
        findsOneWidget,
      );
      expect(
        _event(tester, eventId).minAge,
        const Age(years: _kMinAgeYears),
        reason: 'an inverted band must not be saved',
      );

      // Emptying an age clears that bound.
      await enterTextById(tester, AgeEligibilityFormFields.minAgeYearsId, '');
      await saveInlineEditor(tester);
      await waitFor(
        tester,
        () {
          final e = _event(tester, eventId);
          return e.minAge == null &&
              e.maxAge == const Age(years: _kMaxAgeYears);
        },
        description: 'emptied minimum age to clear on the server',
      );
      expect(
        find.text('Open to members aged up to $_kMaxAgeYears.'),
        findsOneWidget,
      );

      // Description — markdown editor.
      await editMarkdownField(
        tester,
        tooltip: 'Edit Description',
        markdown: _kEditedDescription,
      );
      await waitFor(
        tester,
        () => _event(tester, eventId).description == _kEditedDescription,
        description: 'description to round-trip to the server',
      );

      // Flag — toggle featured on.
      await _toggleFlag(tester, 'This event is featured');
      await waitFor(
        tester,
        () => _event(tester, eventId).isFeatured,
        description: 'isFeatured to become true on the server',
      );

      // Title — rename via the management dialog.
      await _renameEvent(tester, _kEditedTitle);
      await waitFor(
        tester,
        () => _event(tester, eventId).title == _kEditedTitle,
        description: 'title to round-trip to the server',
      );
      await logout(tester);

      // ─── Phase 4: coach sees the updated title ─────────────────────────
      await loginViaUi(tester, _kCoach, _kPwd);
      await _openCampDetail(tester, _kEditedTitle);
      expect(find.text(_kEditedOrganizer), findsWidgets);
      await logout(tester);

      // ─── Phase 5: cleanup ──────────────────────────────────────────────
      await loginViaUi(tester, _kAdmin, _kPwd);
      // Soft-delete via the master notifier: the section editors under test
      // do not own deletion (the editor's management section does).
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
      await softDeleteUserViaUi(tester, _kCoach);
      await softDeleteUserViaUi(tester, _kCoach2);
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

Future<int> _waitForVenueId(WidgetTester tester, String name) async {
  await waitFor(
    tester,
    () {
      final map = container(tester).read(clVenuesMasterProvider).valueOrNull;
      return map != null && map.values.any((v) => v.name == name);
    },
    description: 'clVenuesMasterProvider to contain "$name"',
  );
  final map = container(tester).read(clVenuesMasterProvider).valueOrNull!;
  return map.values.firstWhere((v) => v.name == name).id;
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

void _expectFeaturedFlagDisabled(WidgetTester tester) {
  final cb = find.ancestor(
    of: find.text('This event is featured'),
    matching: find.byType(ShadCheckbox),
  );
  expect(cb, findsOneWidget, reason: 'featured flag must render');
  expect(
    tester.widget<ShadCheckbox>(cb).enabled,
    isFalse,
    reason: 'featured flag must be disabled for a read-only viewer',
  );
}

Future<void> _toggleFlag(WidgetTester tester, String label) async {
  final cb = find.ancestor(
    of: find.text(label),
    matching: find.byType(ShadCheckbox),
  );
  expect(cb, findsOneWidget, reason: 'flag "$label" must render');
  final w = tester.widget<ShadCheckbox>(cb);
  expect(w.onChanged, isNotNull, reason: 'flag "$label" must be editable');
  w.onChanged!(!w.value);
  await settle(tester);
}

/// Drives the organizer "Transfer" single-select picker: opens it, selects the
/// target user by @username, and confirms.
Future<void> _transferOrganizer(WidgetTester tester, String username) async {
  // The editor's "Transfer" button is the only one until the dialog opens.
  invokeShadButton(
    tester,
    find.widgetWithText(ShadButton, 'Transfer'),
    reason: 'open the transfer picker',
  );
  await settle(tester);
  await tester.tap(find.text('@$username'));
  await settle(tester);
  invokeShadButton(
    tester,
    find.descendant(
      of: find.byType(ShadDialog),
      matching: find.widgetWithText(ShadButton, 'Transfer'),
    ),
    reason: 'confirm transfer',
  );
  await settle(tester);
}

/// Drives the multi-select "Add coaches" picker: opens it, selects [username],
/// and confirms (the confirm label carries the selected count, e.g. "Add (1)").
Future<void> _addCoach(WidgetTester tester, String username) async {
  invokeShadButton(
    tester,
    find.widgetWithText(ShadButton, 'Add coaches'),
    reason: 'open the add-coaches picker',
  );
  await settle(tester);
  await tester.tap(find.text('@$username'));
  await settle(tester);
  invokeShadButton(
    tester,
    find.ancestor(
      of: find.text('Add (1)'),
      matching: find.byType(ShadButton),
    ),
    reason: 'confirm add coach',
  );
  await settle(tester);
}

/// Stages removal of the first coach row (its ✕ flips it to strikethrough).
Future<void> _removeFirstCoach(WidgetTester tester) async {
  await tester.tap(find.widgetWithIcon(ShadButton, LucideIcons.x).first);
  await settle(tester);
}

Future<void> _renameEvent(WidgetTester tester, String newTitle) async {
  final managementCard = _sectionCard('Event Management');
  final trigger = find.descendant(
    of: managementCard,
    matching: find.widgetWithText(ActionButton, 'Rename'),
  );
  expect(trigger, findsOneWidget, reason: 'management Rename button');
  tester.widget<ActionButton>(trigger).onPressed!.call();
  await settle(tester);
  expect(find.text('Rename event'), findsOneWidget);
  await enterTextById(tester, 'value', newTitle);
  invokeShadButton(
    tester,
    find.descendant(
      of: find.byType(ShadDialog),
      matching: find.widgetWithText(ShadButton, 'Save'),
    ),
    reason: 'confirm event rename',
  );
  await settle(tester);
}
