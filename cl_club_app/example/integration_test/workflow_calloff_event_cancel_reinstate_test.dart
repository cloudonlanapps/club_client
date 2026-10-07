// workflow_calloff: calling an event off and taking that back, from the
// Event Management card of `/memberzone/events/:id` (club_client#40).
//
//   * Camp: Cancel camp, from a chosen upcoming session (the next one by
//     default) with a reason, then Undo cancel.
//   * One-off: Call off with a reason, then Reinstate.
//
// Flow (the super admin `sudo` acts as the admin):
//   0. Sudo creates a venue and seeds a three-day camp and a one-off a
//      month ahead (through the master notifier, so their dates are known).
//   1. The camp page offers Cancel camp only. Its dialog says the members
//      are notified, offers the camp's sessions, and refuses an empty
//      reason; with a reason the camp is cancelled from its first session.
//      The page then offers Undo cancel only, which clears the cutoff.
//   2. The one-off page offers Call off only; with a reason its occurrence
//      is cancelled and the page offers Reinstate only, which puts it back.
//   3. Cleanup: both events are archived from Event Management.
//
// Recommended run (from the club_client root):
//   just app-test-one app_test_server1.conf \
//       workflow_calloff_event_cancel_reinstate_test.dart

import 'package:cl_remote_store/cl_remote_store.dart'
    show clEventsMasterProvider;
import 'package:club_sdk_2/club_sdk_2.dart' show Event, EventType, Visibility;
import 'package:flutter/material.dart' hide Visibility;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/src/widgets/event_cancellation/event_cancellation_form_validators.dart'
    show EventCancellationFormValidators;
import 'package:ui_lib/ui_lib.dart'
    show ActionButton, EntityCard, EventCancellationFormFields;

import '_helpers/auth.dart';
import '_helpers/events.dart';
import '_helpers/forms.dart';
import '_helpers/pump.dart';
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

const _kVenueName = 'workflow_calloff_venue';
const _kCamp = 'workflow_calloff_camp';
const _kOneOff = 'workflow_calloff_one_off';
const _kReason = 'workflow_calloff: the rink is closed';

const _kCampsPath = '/memberzone/events/camps';
const _kOneOffPath = '/memberzone/events/one-off';
const _kManagement = 'Event Management';

const _kCancelCamp = 'Cancel camp';
const _kUndoCancel = 'Undo cancel';
const _kCallOff = 'Call off';
const _kReinstate = 'Reinstate';
const List<String> _kFour = [
  _kCancelCamp,
  _kUndoCancel,
  _kCallOff,
  _kReinstate,
];

/// A day a month ahead, at midnight UTC: inside the server's 52-week
/// scheduling horizon, and far beyond the 30-minute cancellation lead.
DateTime get _firstDay {
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
    'a camp is cancelled and the cancellation undone, and a one-off is '
    'called off and reinstated, from Event Management',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1600, 4000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await pumpApp(tester, apiBaseUrl: _kApiBaseUrl);
      await ensureLoggedOut(tester);

      // ─── Phase 0: the venue, a three-day camp and a one-off ────────────
      await loginViaUi(tester, _kSudoUsername, _kSudoPassword);
      await createVenueViaUi(tester, name: _kVenueName);
      final venueId = await waitForVenueId(tester, _kVenueName);
      final campStart = _firstDay.add(const Duration(hours: 9));
      final notifier = container(tester).read(clEventsMasterProvider.notifier);
      final camp = await notifier.createEvent(
        title: _kCamp,
        description: '',
        type: EventType.camp,
        visibility: Visibility.public,
        venueId: venueId,
        startTimeUtc: campStart,
        endTimeUtc: campStart.add(const Duration(hours: 1)),
        organizerName: _kSudoUsername,
        rrule: 'FREQ=DAILY;COUNT=3',
      );
      final oneOffStart = _firstDay.add(const Duration(days: 5, hours: 9));
      final oneOff = await notifier.createEvent(
        title: _kOneOff,
        description: '',
        type: EventType.oneOff,
        visibility: Visibility.public,
        venueId: venueId,
        startTimeUtc: oneOffStart,
        endTimeUtc: oneOffStart.add(const Duration(hours: 1)),
        organizerName: _kSudoUsername,
      );

      // ─── Phase 1: the camp is cancelled, then the cancellation undone ──
      await _openEvent(tester, _kCampsPath, _kCamp);
      await _waitForOnly(tester, _kCancelCamp);

      await _pressManagement(tester, _kCancelCamp);
      expect(
        find.textContaining('Enrolled members are notified'),
        findsOneWidget,
      );
      expect(find.text('Cancel from *'), findsOneWidget);
      // No reason: nothing is sent.
      await _answerDialog(tester, _kCancelCamp);
      expect(
        find.text(EventCancellationFormValidators.reasonRequired),
        findsOneWidget,
      );
      expect(_event(tester, camp.id).untilTimeUtc, isNull);

      await enterTextById(
        tester,
        EventCancellationFormFields.reasonId,
        _kReason,
      );
      await _answerDialog(tester, _kCancelCamp);
      await waitFor(
        tester,
        () => _event(tester, camp.id).untilTimeUtc != null,
        description: 'the camp to be cancelled on the server',
      );
      expect(
        _event(tester, camp.id).untilTimeUtc,
        campStart,
        reason: 'the default is the next session, here the first',
      );
      await _waitForOnly(tester, _kUndoCancel);

      await _pressManagement(tester, _kUndoCancel);
      await _answerDialog(tester, _kUndoCancel);
      await waitFor(
        tester,
        () => _event(tester, camp.id).untilTimeUtc == null,
        description: 'the camp cancellation to be undone on the server',
      );
      await _waitForOnly(tester, _kCancelCamp);

      // ─── Phase 2: the one-off is called off, then reinstated ───────────
      await _openEvent(tester, _kOneOffPath, _kOneOff);
      await _waitForOnly(tester, _kCallOff);

      await _pressManagement(tester, _kCallOff);
      expect(
        find.textContaining('Enrolled members are notified'),
        findsOneWidget,
      );
      expect(find.text('Cancel from *'), findsNothing);
      await enterTextById(
        tester,
        EventCancellationFormFields.reasonId,
        _kReason,
      );
      await _answerDialog(tester, _kCallOff);
      // The page reads the one-off's occurrence back: once it is cancelled
      // on the server, Reinstate replaces Call off.
      await _waitForOnly(tester, _kReinstate);
      expect(
        _event(tester, oneOff.id).untilTimeUtc,
        isNull,
        reason:
            'a called-off one-off has no cutoff; its occurrence is '
            'cancelled',
      );

      await _pressManagement(tester, _kReinstate);
      await _answerDialog(tester, _kReinstate);
      await _waitForOnly(tester, _kCallOff);

      // ─── Phase 3: cleanup, through Event Management ────────────────────
      await _archiveOpenEvent(tester, oneOff.id);
      await _openEvent(tester, _kCampsPath, _kCamp);
      await _archiveOpenEvent(tester, camp.id);
      await logout(tester);
    },
    timeout: const Timeout(Duration(minutes: 20)),
  );
}

// ---------------------------------------------------------------------------
// Local helpers.
// ---------------------------------------------------------------------------

Event _event(WidgetTester tester, int eventId) {
  final event = container(
    tester,
  ).read(clEventsMasterProvider).valueOrNull?[eventId];
  expect(event, isNotNull, reason: 'event #$eventId must be in the master');
  return event!;
}

/// A button of the Event Management card, by its label.
Finder _managementButton(String label) => find.descendant(
  of: find.ancestor(
    of: find.text(_kManagement),
    matching: find.byType(ShadCard),
  ),
  matching: find.widgetWithText(ActionButton, label),
);

/// Waits until, of the four actions, the card offers [label] alone.
Future<void> _waitForOnly(WidgetTester tester, String label) async {
  await waitFor(
    tester,
    () => _kFour.every(
      (each) =>
          _managementButton(each).evaluate().length == (each == label ? 1 : 0),
    ),
    description: 'Event Management to offer "$label" alone of $_kFour',
  );
}

/// Opens the event titled [title] from the staff list at [listPath].
Future<void> _openEvent(
  WidgetTester tester,
  String listPath,
  String title,
) async {
  await go(tester, listPath);
  final card = find.byWidgetPredicate(
    (w) => w is EntityCard && w.title == title,
  );
  await waitFor(
    tester,
    () => card.evaluate().isNotEmpty,
    description: 'event card "$title" on $listPath',
  );
  tester.widget<EntityCard>(card.first).onTap!.call();
  await settle(tester);
  await waitFor(
    tester,
    () => find.text(_kManagement).evaluate().isNotEmpty,
    description: 'the page of "$title" with Event Management',
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

/// Archives the event whose page is open and waits for the server's answer.
Future<void> _archiveOpenEvent(WidgetTester tester, int eventId) async {
  await _pressManagement(tester, 'Archive');
  await _answerDialog(tester, 'Archive');
  await waitFor(
    tester,
    () => !_event(tester, eventId).isActive,
    description: 'event #$eventId to be archived',
  );
}
