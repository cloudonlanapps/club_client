// workflow_imgupload: end-to-end coverage of the image-upload affordance, via
// the event cover on `/memberzone/events/:id` (EventDetailsView).
//
// This is the first integration test of the *UI* upload path (tap pencil →
// pick → preview → Upload → image renders). The picker can't open a native OS
// file dialog under test, so `imagePickerProvider` is overridden to return a
// fixed in-memory PNG — the rest of the path (preview dialog, the media
// upload + tag attach, provider invalidation, re-render) runs for real against
// the isolated server.
//
// Flow:
//   0. Sudo creates an admin.
//   1. Admin creates a venue (UI) and seeds a camp (no event-create UI yet).
//   2. Admin opens the camp; the cover starts empty (placeholder).
//   3. Admin taps the cover pencil, confirms the preview, uploads.
//   4. The cover round-trips: eventCoverImageProvider resolves to a URL.
//   5. Cleanup: clear the cover, soft-delete the camp + admin.

import 'package:cl_club_events/cl_club_events.dart' show EventDetailsView;
import 'package:cl_remote_store/cl_remote_store.dart'
    show
        clEventsMasterProvider,
        clVenuesMasterProvider,
        eventCoverImageProvider,
        eventMediaMutationProvider,
        imagePickerProvider;
import 'package:club_sdk_2/club_sdk_2.dart'
    show Event, EventType, Role, Visibility;
import 'package:flutter/material.dart' hide Visibility;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart'
    show CircleIconButton, EntityCard, ImageUploadAffordance, PickedImage;

import '_helpers/auth.dart';
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

const _kAdmin = 'workflow_imgupload_admin';
const _kPwd = 'WfImgUploadPwd!2024';
const _kVenueName = 'workflow_imgupload_site';
const _kVenueAddress = 'workflow_imgupload address line 1';
const _kEventTitle = 'workflow_imgupload_camp';

// A tiny VALID 8x8 PNG (generated with ImageMagick). It must be a real,
// decodable image: the server runs it through `media_convert.sh` (PNG → webp),
// which rejects malformed input — the 1x1 fixture some older tests use only
// survives because they pass preserveOriginal: true and skip conversion.
const _pixelPng = <int>[
  137,
  80,
  78,
  71,
  13,
  10,
  26,
  10,
  0,
  0,
  0,
  13,
  73,
  72,
  68,
  82,
  0,
  0,
  0,
  8,
  0,
  0,
  0,
  8,
  1,
  3,
  0,
  0,
  0,
  254,
  193,
  44,
  200,
  0,
  0,
  0,
  32,
  99,
  72,
  82,
  77,
  0,
  0,
  122,
  38,
  0,
  0,
  128,
  132,
  0,
  0,
  250,
  0,
  0,
  0,
  128,
  232,
  0,
  0,
  117,
  48,
  0,
  0,
  234,
  96,
  0,
  0,
  58,
  152,
  0,
  0,
  23,
  112,
  156,
  186,
  81,
  60,
  0,
  0,
  0,
  6,
  80,
  76,
  84,
  69,
  34,
  102,
  170,
  255,
  255,
  255,
  219,
  25,
  64,
  108,
  0,
  0,
  0,
  1,
  98,
  75,
  71,
  68,
  1,
  255,
  2,
  45,
  222,
  0,
  0,
  0,
  7,
  116,
  73,
  77,
  69,
  7,
  234,
  5,
  31,
  14,
  8,
  46,
  165,
  0,
  240,
  48,
  0,
  0,
  0,
  37,
  116,
  69,
  88,
  116,
  100,
  97,
  116,
  101,
  58,
  99,
  114,
  101,
  97,
  116,
  101,
  0,
  50,
  48,
  50,
  54,
  45,
  48,
  53,
  45,
  51,
  49,
  84,
  49,
  52,
  58,
  48,
  56,
  58,
  52,
  54,
  43,
  48,
  48,
  58,
  48,
  48,
  20,
  238,
  139,
  9,
  0,
  0,
  0,
  37,
  116,
  69,
  88,
  116,
  100,
  97,
  116,
  101,
  58,
  109,
  111,
  100,
  105,
  102,
  121,
  0,
  50,
  48,
  50,
  54,
  45,
  48,
  53,
  45,
  51,
  49,
  84,
  49,
  52,
  58,
  48,
  56,
  58,
  52,
  54,
  43,
  48,
  48,
  58,
  48,
  48,
  101,
  179,
  51,
  181,
  0,
  0,
  0,
  40,
  116,
  69,
  88,
  116,
  100,
  97,
  116,
  101,
  58,
  116,
  105,
  109,
  101,
  115,
  116,
  97,
  109,
  112,
  0,
  50,
  48,
  50,
  54,
  45,
  48,
  53,
  45,
  51,
  49,
  84,
  49,
  52,
  58,
  48,
  56,
  58,
  52,
  54,
  43,
  48,
  48,
  58,
  48,
  48,
  50,
  166,
  18,
  106,
  0,
  0,
  0,
  11,
  73,
  68,
  65,
  84,
  8,
  215,
  99,
  96,
  64,
  5,
  0,
  0,
  16,
  0,
  1,
  161,
  197,
  33,
  193,
  0,
  0,
  0,
  0,
  73,
  69,
  78,
  68,
  174,
  66,
  96,
  130,
];

Future<PickedImage?> _stubPicker() async => const PickedImage(
  bytes: _pixelPng,
  filename: 'workflow_imgupload_cover.png',
  mimeType: 'image/png',
);

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
    'admin uploads an event cover end-to-end via the pencil',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1600, 4000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await pumpApp(
        tester,
        apiBaseUrl: _kApiBaseUrl,
        // Stand in for the native file dialog so the UI flow can run headless.
        extraOverrides: [
          imagePickerProvider.overrideWithValue(_stubPicker),
        ],
      );
      await ensureLoggedOut(tester);

      // ─── Phase 0: sudo creates the admin ───────────────────────────────
      await loginViaUi(tester, _kSudoUsername, _kSudoPassword);
      await createUserViaUi(tester, username: _kAdmin, password: _kPwd);
      await grantRolesViaCheckboxViaUi(
        tester,
        username: _kAdmin,
        roles: {Role.admin},
      );
      await logout(tester);

      // ─── Phase 1: admin creates venue + camp ───────────────────────────
      await loginViaUi(tester, _kAdmin, _kPwd);
      await createVenueViaUi(
        tester,
        name: _kVenueName,
        address: _kVenueAddress,
      );
      final venueId = await _waitForVenueId(tester, _kVenueName);

      final created = await container(tester)
          .read(clEventsMasterProvider.notifier)
          .createEvent(
            title: _kEventTitle,
            description: 'workflow_imgupload initial description.',
            type: EventType.camp,
            visibility: Visibility.public,
            venueId: venueId,
            startTimeUtc: _campDay.add(const Duration(hours: 9)),
            endTimeUtc: _campDay.add(const Duration(hours: 10)),
            organizerName: _kAdmin,
            rrule: 'FREQ=DAILY;COUNT=3',
          );
      final eventId = created.id;

      // ─── Phase 2: open the camp; cover starts empty ────────────────────
      await _openCampDetail(tester, _kEventTitle);
      expect(find.byType(EventDetailsView), findsOneWidget);
      await waitFor(
        tester,
        () => _cover(tester, eventId).hasValue,
        description: 'cover provider to resolve',
      );
      expect(
        _cover(tester, eventId).value,
        isNull,
        reason: 'the camp has no cover before the upload',
      );

      // ─── Phase 3: tap the cover pencil, confirm, upload ────────────────
      // The cover affordance is the only ImageUploadAffordance on the page;
      // with no cover yet it shows just the pencil (no trash).
      final pencil = find.descendant(
        of: find.byType(ImageUploadAffordance),
        matching: find.byType(CircleIconButton),
      );
      expect(
        pencil,
        findsOneWidget,
        reason: 'admin sees the cover pencil',
      );
      // Invoke onTap directly — screen-size independent (the affordance can
      // sit off-screen on the default desktop window).
      tester.widget<CircleIconButton>(pencil).onTap!.call();
      await settle(tester);

      expect(
        find.text('Upload image'),
        findsOneWidget,
        reason: 'the preview dialog opens with the picked image',
      );
      invokeShadButton(
        tester,
        find.descendant(
          of: find.byType(ShadDialog),
          matching: find.widgetWithText(ShadButton, 'Upload'),
        ),
        reason: 'confirm the cover upload',
      );
      await settle(tester);

      // ─── Phase 4: the cover round-trips to the server ──────────────────
      await waitFor(
        tester,
        () => _cover(tester, eventId).value != null,
        description: 'eventCoverImageProvider to resolve to a URL after upload',
        timeout: const Duration(seconds: 30),
      );

      // ─── Phase 5: cleanup ──────────────────────────────────────────────
      await container(
        tester,
      ).read(eventMediaMutationProvider(eventId).notifier).clearCover();
      await waitFor(
        tester,
        () => _cover(tester, eventId).value == null,
        description: 'cover to clear',
      );
      await container(
        tester,
      ).read(clEventsMasterProvider.notifier).deleteEvent(eventId);
      await waitFor(
        tester,
        () => !(_event(tester, eventId)?.isActive ?? true),
        description: 'camp to be soft-deleted',
      );
      await logout(tester);

      await loginViaUi(tester, _kSudoUsername, _kSudoPassword);
      await softDeleteUserViaUi(tester, _kAdmin);
      await logout(tester);
    },
    timeout: const Timeout(Duration(minutes: 15)),
  );
}

// ---------------------------------------------------------------------------
// Local helpers.
// ---------------------------------------------------------------------------

AsyncValue<String?> _cover(WidgetTester tester, int eventId) =>
    container(tester).read(eventCoverImageProvider(eventId));

Event? _event(WidgetTester tester, int eventId) =>
    container(tester).read(clEventsMasterProvider).valueOrNull?[eventId];

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
