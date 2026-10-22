// workflow_marketing: an admin edits an event's marketing on its Marketing
// page (club_client#1), reached from the event's detail page.
//
// Flow:
//   1. Sudo (an admin) creates a venue (UI) and seeds a camp.
//   2. On the camp's page, "Edit marketing" opens the Marketing page.
//   3. The Basic card's stamp is edited; the preview shows it, and it
//      round-trips to the event.
//   4. With the Event Marketing module on, the Details card's duration is
//      edited and round-trips to the block; with it off, no extended card
//      shows.
//   5. Cleanup: the camp is soft-deleted.

import 'package:cl_club_events/cl_club_events.dart'
    show EventDetailsView, EventMarketingView;
import 'package:cl_club_events/src/widgets/event_marketing/event_marketing_preview.dart'
    show EventMarketingPreview;
import 'package:cl_club_forms/cl_club_forms.dart'
    show EventBasicMarketingFormFields, EventMarketingDetailsFormFields;
import 'package:cl_remote_store/cl_remote_store.dart'
    show clEventMarketingMasterProvider, clEventsMasterProvider;
import 'package:club_sdk_2/club_sdk_2.dart'
    show Capabilities, Event, EventType, Visibility;
import 'package:flutter/material.dart' hide Visibility;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show EntityCard;

import '_helpers/auth.dart';
import '_helpers/capabilities.dart';
import '_helpers/editors.dart';
import '_helpers/events.dart' show waitForVenueId;
import '_helpers/forms.dart';
import '_helpers/pump.dart';
import '_helpers/surface.dart';
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

const _kVenueName = 'workflow_marketing_site';
const _kVenueAddress = 'workflow_marketing address line 1';
const _kEventTitle = 'workflow_marketing_camp';
const _kStamp = 'workflow_marketing NEW';
const _kDuration = 'workflow_marketing 5 days';

/// A day a month ahead, at midnight UTC: well inside the server's 52-week
/// scheduling horizon.
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

  late Capabilities caps;
  setUpAll(() async {
    caps = await stackCapabilities(
      baseUrl: _kApiBaseUrl,
      username: _kSudoUsername,
      password: _kSudoPassword,
    );
  });

  testWidgets(
    "an admin edits a camp's marketing on its Marketing page, with a live "
    'preview',
    (tester) async {
      await useTestSurface(tester, const Size(1600, 4000));

      await pumpApp(tester, apiBaseUrl: _kApiBaseUrl);
      await ensureLoggedOut(tester);
      await loginViaUi(tester, _kSudoUsername, _kSudoPassword);

      // ─── Phase 1: a venue and a camp ───────────────────────────────────
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
            description: 'workflow_marketing description.',
            type: EventType.camp,
            visibility: Visibility.public,
            venueId: venueId,
            startTimeUtc: _campDay.add(const Duration(hours: 9)),
            endTimeUtc: _campDay.add(const Duration(hours: 10)),
            rrule: 'FREQ=DAILY;COUNT=3',
          );
      final eventId = created.id;

      // ─── Phase 2: from the camp's page to its Marketing page ───────────
      await _openCampDetail(tester, _kEventTitle);
      invokeShadButton(
        tester,
        find.widgetWithText(ShadButton, 'Edit marketing'),
        reason: 'the Marketing link on the event page',
      );
      await settle(tester);
      await waitFor(
        tester,
        () => find.byType(EventMarketingView).evaluate().isNotEmpty,
        description: 'EventMarketingView to render',
      );

      // ─── Phase 3: the stamp, previewed and saved ───────────────────────
      await tapSectionPencil(tester, _sectionCard('Basic'));
      await enterTextById(
        tester,
        EventBasicMarketingFormFields.stampId,
        _kStamp,
      );
      await settle(tester);
      expect(
        find.descendant(
          of: find.byType(EventMarketingPreview),
          // The card and the banner draw a stamp in capitals.
          matching: find.text(_kStamp.toUpperCase()),
        ),
        findsWidgets,
        reason: 'the preview shows the stamp before it is saved',
      );
      await saveInlineEditor(tester);
      await waitFor(
        tester,
        () => _event(tester, eventId).stamp == _kStamp,
        description: 'the stamp to round-trip',
      );

      // ─── Phase 4: the extended block, where the module runs ────────────
      if (caps.eventMarketing) {
        await tapSectionPencil(tester, _sectionCard('Details'));
        await enterTextById(
          tester,
          EventMarketingDetailsFormFields.durationTextId,
          _kDuration,
        );
        await saveInlineEditor(tester);
        await waitFor(
          tester,
          () =>
              container(tester)
                  .read(clEventMarketingMasterProvider(eventId))
                  .valueOrNull
                  ?.durationText ==
              _kDuration,
          description: 'the duration to round-trip',
        );
      } else {
        expect(
          find.text('Details'),
          findsNothing,
          reason: 'no extended card without the module',
        );
      }

      // ─── Phase 5: cleanup ──────────────────────────────────────────────
      await container(
        tester,
      ).read(clEventsMasterProvider.notifier).deleteEvent(eventId);
      await waitFor(
        tester,
        () => !_event(tester, eventId).isActive,
        description: 'camp to be soft-deleted',
      );
      await logout(tester);
    },
    timeout: const Timeout(Duration(minutes: 10)),
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
