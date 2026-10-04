// workflow_sitemedia: the website media slots screen (club_core#19).
//
// A super-admin (`sudo`), from the sidebar's Admin section:
//
//   * uploads a file into the Logo slot (public on upload);
//   * links existing public media into the Landing background slot — the
//     library offers a non-public item but will not link it;
//   * saves, and the public club info now publishes both slots;
//   * links media that is made private before the save, and the server's
//     refusal shows on that slot;
//   * clears every slot and saves, which is also the cleanup: the public
//     club info is back to no site media.
//
// Setup media (one public, two to go private) is uploaded through the SDK;
// the app has no media library screen of its own. It is soft-deleted at the
// end, with the file uploaded through the screen.
//
// Recommended run (from the club_core root):
//   just app-test-one app_test_server1.conf \
//       workflow_sitemedia_website_media_slots_test.dart

import 'package:cl_member_zone/src/widgets/sidebar/sidebar_item.dart'
    show SidebarItem;
import 'package:cl_remote_store/cl_remote_store.dart'
    show imagePickerProvider, secureClientProvider;
import 'package:club_sdk_2/club_sdk_2.dart' show Media, SecureClient;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show PickedImage;

import '_helpers/auth.dart';
import '_helpers/forms.dart';
import '_helpers/pump.dart';

const _kApiBaseUrl = String.fromEnvironment(
  'CLUB_API_BASE_URL',
  defaultValue: 'http://127.0.0.1:8155/v1',
);
const _kSudoUsername = String.fromEnvironment(
  'SUDO_USERNAME',
  defaultValue: 'sudo',
);
const _kSudoPassword = String.fromEnvironment('SUDO_PASSWORD');

/// A valid 1×1 PNG.
const List<int> _kPng = [
  137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 13, 73, 72, 68, 82, 0, 0, 0, 1, //
  0, 0, 0, 1, 8, 2, 0, 0, 0, 144, 119, 83, 222, 0, 0, 0, 12, 73, 68, 65, //
  84, 120, 156, 99, 248, 255, 255, 63, 0, 5, 254, 2, 254, 13, 239, 70, 184, //
  0, 0, 0, 0, 73, 69, 78, 68, 174, 66, 96, 130,
];

Future<PickedImage?> _stubPicker() async => const PickedImage(
  bytes: _kPng,
  filename: 'workflow_sitemedia_upload.png',
  mimeType: 'image/png',
);

Future<Media> _upload(SecureClient client, String name, List<String> roles) =>
    client.media.upload(
      fileBytes: _kPng,
      filename: '$name.png',
      contentType: 'image/png',
      accessRoles: roles,
    );

Finder _slot(String key) => find.byKey(ValueKey('siteMediaSlot.$key'));

Finder _button(String key) => find.byKey(ValueKey(key));

Future<void> _press(WidgetTester tester, String key) async {
  invokeShadButton(tester, _button(key), reason: key);
  await settle(tester);
}

Future<void> _linkFromLibrary(
  WidgetTester tester,
  String slot,
  String uuid,
) async {
  await _press(tester, 'siteMediaSlot.$slot.link');
  await waitFor(
    tester,
    () => _button('mediaLibrary.$uuid').evaluate().isNotEmpty,
    description: '$uuid in the media library',
  );
  await _press(tester, 'mediaLibrary.$uuid');
  await waitFor(
    tester,
    () => find
        .descendant(of: _slot(slot), matching: find.textContaining(uuid))
        .evaluate()
        .isNotEmpty,
    description: '$uuid in the $slot slot',
  );
}

Future<void> _saveAndWait(WidgetTester tester) async {
  await _press(tester, 'siteMedia.save');
  await waitFor(
    tester,
    () =>
        tester.widget<ShadButton>(_button('siteMedia.save')).onPressed == null,
    description: 'the save to finish',
  );
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
    'a super-admin fills, saves and clears the website media slots',
    (tester) async {
      await pumpApp(
        tester,
        apiBaseUrl: _kApiBaseUrl,
        extraOverrides: [imagePickerProvider.overrideWithValue(_stubPicker)],
      );
      await ensureLoggedOut(tester);
      await loginViaUi(tester, _kSudoUsername, _kSudoPassword);
      await go(tester, '/memberzone/profile');

      final client = await container(tester).read(secureClientProvider.future);
      final public = await _upload(client, 'workflow_sitemedia_public', [
        'public',
      ]);
      final private = await _upload(client, 'workflow_sitemedia_private', [
        'admin',
      ]);
      final goesPrivate = await _upload(client, 'workflow_sitemedia_late', [
        'public',
      ]);

      // --- Open the screen from the sidebar's Admin section. --------------
      final entry = find.widgetWithText(SidebarItem, 'Website media');
      expect(entry, findsWidgets);
      tester.widget<SidebarItem>(entry.first).onTap();
      await settle(tester);
      await waitFor(
        tester,
        () => _slot('logo').evaluate().isNotEmpty,
        description: 'the website media slots',
      );

      // --- Upload into Logo. ----------------------------------------------
      await _press(tester, 'siteMediaSlot.logo.upload');
      invokeShadButton(
        tester,
        find.descendant(
          of: find.byType(ShadDialog),
          matching: find.widgetWithText(ShadButton, 'Upload'),
        ),
        reason: 'Upload in the preview',
      );
      await settle(tester);
      await waitFor(
        tester,
        () => find
            .descendant(of: _slot('logo'), matching: find.textContaining('·'))
            .evaluate()
            .isNotEmpty,
        description: 'the uploaded file in the Logo slot',
      );

      // --- Link existing: a private item cannot be linked. ----------------
      await _press(tester, 'siteMediaSlot.landing_background.link');
      await waitFor(
        tester,
        () => _button('mediaLibrary.${private.uuid}').evaluate().isNotEmpty,
        description: 'the private item in the media library',
      );
      expect(
        tester
            .widget<ShadButton>(_button('mediaLibrary.${private.uuid}'))
            .onPressed,
        isNull,
        reason: 'non-public media cannot fill a slot',
      );
      await _press(tester, 'mediaLibrary.${public.uuid}');
      await waitFor(
        tester,
        () => find
            .descendant(
              of: _slot('landing_background'),
              matching: find.textContaining(public.uuid),
            )
            .evaluate()
            .isNotEmpty,
        description: 'the public item in the Landing background slot',
      );

      // --- Save, and the public club info publishes both. -----------------
      await _saveAndWait(tester);
      var published = (await client.public.getPublicClubInfo()).siteMedia;
      expect(published['landing_background']?.uuid, public.uuid);
      expect(published['logo'], isNotNull);
      final uploadedUuid = published['logo']!.uuid;

      // --- Media made private before the save is refused on its slot. -----
      await _linkFromLibrary(tester, 'page_hero_default', goesPrivate.uuid);
      await client.media.patch(goesPrivate.id, accessRoles: const ['admin']);
      await _press(tester, 'siteMedia.save');
      await waitFor(
        tester,
        () => find
            .descendant(
              of: _slot('page_hero_default'),
              matching: find.textContaining('is not public'),
            )
            .evaluate()
            .isNotEmpty,
        description: 'the refusal on the Default page hero slot',
      );

      // --- Cleanup: clear every slot and save. ----------------------------
      for (final slot in ['page_hero_default', 'logo', 'landing_background']) {
        await _press(tester, 'siteMediaSlot.$slot.clear');
      }
      await _saveAndWait(tester);
      published = (await client.public.getPublicClubInfo()).siteMedia;
      expect(published, isEmpty, reason: 'every slot back on its default');

      final mine = await client.media.listMyFiles(limit: 100);
      final uploaded = mine.items.where((m) => m.uuid == uploadedUuid);
      for (final m in [public, private, goesPrivate, ...uploaded]) {
        await client.media.softDelete(m.id);
      }
    },
  );
}
