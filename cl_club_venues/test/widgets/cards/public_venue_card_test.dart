import 'package:cl_club_venues/cl_club_venues.dart'
    show PublicVenueCard, PublicVenueList;
import 'package:cl_server_config/cl_server_config.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart'
    show EntityCard, EntityImage, StatusBadge, ThemedMarkdown;

const _base = 'https://api.example.test/v1';

const _photo = MediaRef(
  uuid: 'rink-photo-41',
  mimeType: 'image/jpeg',
  filename: 'rink.jpg',
);

const _venue = PublicVenue(
  publicId: 'pv-riverside',
  name: 'Riverside Rink',
  address: '1 Rink Road',
  description:
      '## About\n\n**Biggest rink in town**, open all year round.\n\n'
      'Second paragraph.',
  isDefault: true,
  isFeatured: true,
  primaryVenueBadge: 'Home Rink',
  image: _photo,
);

Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        serverConfigProvider.overrideWithValue(
          const ServerConfig(baseUrl: _base),
        ),
      ],
      child: ShadApp(
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('Issue 53: PublicVenueCard is the member venue card over a '
      'PublicVenue', () {
    testWidgets('Issue 53: shows the photo, name, address and description', (
      tester,
    ) async {
      await _pump(tester, const PublicVenueCard(venue: _venue));

      final card = tester.widget<EntityCard>(find.byType(EntityCard));
      expect(card.title, 'Riverside Rink');
      expect(card.caption, '1 Rink Road');

      final image = tester.widget<EntityImage>(find.byType(EntityImage));
      expect(image.imageUrl, startsWith(_base));
      expect(image.imageUrl, contains('rink-photo-41'));

      expect(find.byType(ThemedMarkdown), findsOneWidget);
      expect(find.textContaining('Biggest rink in town'), findsOneWidget);
      expect(find.textContaining('Second paragraph'), findsNothing);
    });

    testWidgets('Issue 53: badges are plain bordered labels — the server '
        'badge text and Featured', (tester) async {
      await _pump(tester, const PublicVenueCard(venue: _venue));

      final labels = tester
          .widgetList<StatusBadge>(find.byType(StatusBadge))
          .map((b) => b.label)
          .toList();
      expect(labels, ['Home Rink', 'Featured']);
    });

    testWidgets('Issue 53: a venue with no photo shows the placeholder', (
      tester,
    ) async {
      await _pump(
        tester,
        const PublicVenueCard(
          venue: PublicVenue(publicId: 'pv-2', name: 'Annex'),
        ),
      );

      final image = tester.widget<EntityImage>(find.byType(EntityImage));
      expect(image.imageUrl, isNull);
      expect(find.byType(StatusBadge), findsNothing);
    });

    testWidgets('Issue 53: tapping the card calls onTap', (tester) async {
      var taps = 0;
      await _pump(
        tester,
        PublicVenueCard(venue: _venue, onTap: () => taps++),
      );

      await tester.tap(find.text('Riverside Rink'));
      expect(taps, 1);
    });
  });

  group('Issue 53: PublicVenueList', () {
    testWidgets('Issue 53: one card per venue; a tap reports its public id', (
      tester,
    ) async {
      final tapped = <String>[];
      await _pump(
        tester,
        PublicVenueList(
          venues: const [
            _venue,
            PublicVenue(publicId: 'pv-2', name: 'Annex'),
          ],
          onVenueTap: tapped.add,
        ),
      );

      expect(find.byType(PublicVenueCard), findsNWidgets(2));
      await tester.tap(find.text('Annex'));
      expect(tapped, ['pv-2']);
    });
  });
}
