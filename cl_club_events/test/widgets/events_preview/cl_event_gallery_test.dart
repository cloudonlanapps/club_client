import 'package:cl_club_events/src/widgets/events_preview/cl_event_gallery.dart';
import 'package:cl_gallery_viewer/cl_gallery_viewer.dart' show GalleryPdfCard;
import 'package:cl_member_auth/cl_member_auth.dart'
    show imageAuthHeadersProvider;
import 'package:cl_remote_store/cl_remote_store.dart'
    show EventGalleryImage, eventGalleryProvider;
import 'package:cl_server_config/cl_server_config.dart'
    show ServerConfig, serverConfigProvider;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show SectionEditButton;
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

import '../../support/recording_url_launcher.dart';

EventGalleryImage _item(String id, String kind) => (
  mediaUuid: id,
  url: 'https://media.example/$id',
  previewUrl: kind == 'image' ? null : 'https://media.example/$id?poster',
  mediaType: kind,
);

Widget _wrap(
  Widget child, {
  List<EventGalleryImage> gallery = const [],
}) => ProviderScope(
  overrides: [
    eventGalleryProvider.overrideWith((ref, eventId) async => gallery),
    imageAuthHeadersProvider.overrideWith((ref) async => const {}),
    serverConfigProvider.overrideWithValue(
      const ServerConfig(baseUrl: 'https://media.example'),
    ),
  ],
  child: ShadApp(
    home: Scaffold(body: SingleChildScrollView(child: child)),
  ),
);

void main() {
  testWidgets(
    'Issue 679: an empty gallery is hidden entirely from a read-only viewer',
    (tester) async {
      await tester.pumpWidget(
        _wrap(const ClEventGallery(eventId: 1, canEdit: false)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Gallery'), findsNothing);
      expect(find.byType(SectionEditButton), findsNothing);
    },
  );

  testWidgets(
    'Issue 679: an editor sees the empty gallery with the edit pencil',
    (tester) async {
      await tester.pumpWidget(
        _wrap(const ClEventGallery(eventId: 1, canEdit: true)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Gallery'), findsOneWidget);
      expect(find.byType(SectionEditButton), findsOneWidget);
      expect(find.byType(GalleryAddTile), findsNothing);
    },
  );

  testWidgets(
    'Issue 679: a read-only viewer with media shows no edit pencil',
    (tester) async {
      await tester.pumpWidget(
        _wrap(
          const ClEventGallery(eventId: 1, canEdit: false),
          gallery: [_item('a', 'image')],
        ),
      );
      await tester.pumpAndSettle();
      // Network image / gallery widgets have no platform backend in tests.
      tester.takeException();
      expect(find.text('Gallery'), findsOneWidget);
      expect(find.byType(SectionEditButton), findsNothing);
      expect(find.byType(GalleryAddTile), findsNothing);
    },
  );

  testWidgets(
    'Issue 679: tapping the pencil swaps the viewer for the manage grid '
    '(add tile + a remove control per item)',
    (tester) async {
      await tester.pumpWidget(
        _wrap(
          const ClEventGallery(eventId: 1, canEdit: true),
          gallery: [_item('a', 'image')],
        ),
      );
      await tester.pumpAndSettle();
      tester.takeException();

      // Default is the viewer — no manage grid yet.
      expect(find.byType(GalleryAddTile), findsNothing);

      await tester.tap(find.byType(SectionEditButton));
      await tester.pumpAndSettle();
      tester.takeException();

      // Edit grid: one add tile, one tile (with remove) per existing item.
      expect(find.byType(GalleryAddTile), findsOneWidget);
      expect(find.byType(GalleryTile), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);
    },
  );

  testWidgets(
    'Issue 67: tapping a PDF opens its API download URL, not a /downloads '
    'rewrite onto the website origin',
    (tester) async {
      final launcher = RecordingUrlLauncher();
      UrlLauncherPlatform.instance = launcher;
      final pdf = _item('doc-1', 'pdf');

      await tester.pumpWidget(
        _wrap(
          const ClEventGallery(eventId: 1, canEdit: false),
          gallery: [pdf],
        ),
      );
      await tester.pumpAndSettle();
      tester.takeException();

      expect(find.byType(GalleryPdfCard), findsWidgets);
      await tester.tap(find.byType(GalleryPdfCard).first);
      await tester.pumpAndSettle();
      tester.takeException();

      expect(launcher.launched, [pdf.url]);
    },
  );
}
