import 'package:cl_club_admin/cl_club_admin.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'support/admin_test_scope.dart';

const _hero = MediaRef(
  uuid: 'uuid-hero',
  mimeType: 'image/webp',
  filename: 'hero.webp',
);

Future<StubSiteMedia> _pump(
  WidgetTester tester, {
  Map<String, MediaRef> saved = const {},
  List<Media> library = const [],
}) async {
  await tester.binding.setSurfaceSize(const Size(1100, 1400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final stub = StubSiteMedia(saved);
  await tester.pumpWidget(
    adminScope(
      overrides: siteMediaOverrides(siteMedia: stub, library: library),
      child: SiteMediaView(currentUser: adminViewer(superAdmin: true)),
    ),
  );
  await tester.pumpAndSettle();
  return stub;
}

Finder _slot(String key) => find.byKey(ValueKey('siteMediaSlot.$key'));

Finder _inSlot(String key, Finder matching) =>
    find.descendant(of: _slot(key), matching: matching);

Future<void> _tapIn(WidgetTester tester, String key, String label) async {
  await tester.tap(_inSlot(key, find.text(label)));
  await tester.pumpAndSettle();
}

Future<void> _save(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('siteMedia.save')));
  await tester.pumpAndSettle();
}

void main() {
  group('Issue 19: the website media screen', () {
    testWidgets('Issue 19: every slot is listed, set or on its default', (
      tester,
    ) async {
      await _pump(tester, saved: const {'page_hero_default': _hero});

      expect(
        _inSlot('landing_background', find.text('Landing background')),
        findsOneWidget,
      );
      expect(
        _inSlot('landing_background', find.textContaining('bundled file')),
        findsOneWidget,
      );
      expect(
        _inSlot('page_hero_default', find.textContaining('uuid-hero')),
        findsOneWidget,
      );
      expect(_inSlot('logo', find.text('Logo')), findsOneWidget);
    });

    testWidgets('Issue 19: Save is off until something changes', (
      tester,
    ) async {
      await _pump(tester);
      final save = tester.widget<ShadButton>(
        find.byKey(const ValueKey('siteMedia.save')),
      );
      expect(save.onPressed, isNull);
    });

    testWidgets('Issue 19: Clear, then Save writes the map without the '
        'slot, keeping keys the app does not name', (tester) async {
      final stub = await _pump(
        tester,
        saved: const {'page_hero_default': _hero, 'page_hero.about': _hero},
      );

      await _tapIn(tester, 'page_hero_default', 'Clear');
      expect(
        _inSlot('page_hero_default', find.textContaining('bundled file')),
        findsOneWidget,
      );
      await _save(tester);

      expect(stub.saves.single, {'page_hero.about': _hero});
    });

    testWidgets('Issue 19: Upload puts public media in the slot', (
      tester,
    ) async {
      final stub = await _pump(tester);

      await _tapIn(tester, 'logo', 'Upload');
      // The confirm-preview dialog the shared image picker opens.
      await tester.tap(
        find.descendant(
          of: find.byType(ShadDialog),
          matching: find.text('Upload'),
        ),
      );
      await tester.pumpAndSettle();

      expect(stub.uploads, ['hero.png']);
      expect(
        _inSlot('logo', find.textContaining('uuid-uploaded')),
        findsOneWidget,
      );
      await _save(tester);
      expect(stub.saves.single.keys, ['logo']);
      expect(stub.saves.single['logo']!.uuid, 'uuid-uploaded');
    });

    testWidgets('Issue 19: Link existing offers only public media', (
      tester,
    ) async {
      final stub = await _pump(
        tester,
        library: [
          libraryMedia('uuid-public'),
          libraryMedia('uuid-private', roles: const ['admin']),
        ],
      );

      await _tapIn(tester, 'landing_background', 'Link existing');
      final private = tester.widget<ShadButton>(
        find.byKey(const ValueKey('mediaLibrary.uuid-private')),
      );
      expect(private.onPressed, isNull);
      expect(find.textContaining('Not public'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('mediaLibrary.uuid-public')));
      await tester.pumpAndSettle();
      expect(
        _inSlot('landing_background', find.textContaining('uuid-public')),
        findsOneWidget,
      );
      await _save(tester);
      expect(stub.saves.single['landing_background']!.uuid, 'uuid-public');
    });

    testWidgets('Issue 19: a refusal for non-public media shows on its slot', (
      tester,
    ) async {
      final stub = await _pump(tester, library: [libraryMedia('uuid-late')]);
      stub.refuseWith = const ServerException(
        statusCode: 422,
        code: 'SITE_MEDIA_NOT_PUBLIC',
        message:
            "site_media slot 'logo' names uuid-late, which is not live "
            'public media',
      );

      await _tapIn(tester, 'logo', 'Link existing');
      await tester.tap(find.byKey(const ValueKey('mediaLibrary.uuid-late')));
      await tester.pumpAndSettle();
      await _save(tester);

      expect(
        _inSlot('logo', find.textContaining('is not public')),
        findsOneWidget,
      );
      expect(
        _inSlot('landing_background', find.textContaining('is not public')),
        findsNothing,
      );
    });
  });
}
