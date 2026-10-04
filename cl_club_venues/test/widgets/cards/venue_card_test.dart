import 'package:cl_club_venues/src/widgets/cards/venue_card.dart';
import 'package:cl_member_auth/cl_member_auth.dart'
    show imageAuthHeadersProvider;
import 'package:cl_remote_store/cl_remote_store.dart'
    show ClVenuesMasterNotifier, clVenuesMasterProvider, venueImageProvider;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show EntityImage, ThemedMarkdown;

class _StubVenuesMaster extends ClVenuesMasterNotifier {
  _StubVenuesMaster(this._venues);
  final Map<int, Venue> _venues;
  @override
  Future<Map<int, Venue>> build() async => _venues;
}

Venue _venue({String? description}) => Venue(
  id: 3,
  name: 'Riverside Rink',
  address: '1 Rink Road',
  description: description,
  createdAtUtc: DateTime.utc(2025),
  updatedAtUtc: DateTime.utc(2025),
);

Future<void> _pump(
  WidgetTester tester, {
  String? imageUrl,
  String? description,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        clVenuesMasterProvider.overrideWith(
          () => _StubVenuesMaster({3: _venue(description: description)}),
        ),
        venueImageProvider(3).overrideWith((ref) async => imageUrl),
        imageAuthHeadersProvider.overrideWith((ref) async => const {}),
      ],
      child: const ShadApp(
        home: Scaffold(
          body: SizedBox(width: 360, child: VenueCard(venueId: 3)),
        ),
      ),
    ),
  );
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  group('Issue 712: VenueCard shows the venue image in the list', () {
    testWidgets('Issue 712: renders the venue image when one is available', (
      tester,
    ) async {
      await _pump(tester, imageUrl: 'https://example.test/venue-3.png');
      final image = tester.widget<EntityImage>(find.byType(EntityImage));
      expect(image.imageUrl, 'https://example.test/venue-3.png');
    });

    testWidgets(
      'Issue 712: falls back to the placeholder when there is no image',
      (tester) async {
        await _pump(tester);
        final image = tester.widget<EntityImage>(find.byType(EntityImage));
        expect(image.imageUrl, isNull);
      },
    );
  });

  group('Issue 12: VenueCard renders the description as markdown', () {
    const description =
        '## About\n\n'
        '**Biggest rink in town**, Riverside Rink brings winter sports to '
        'the whole region all year round, with public sessions, coaching '
        'and league nights for every age and every level of skater.\n\n'
        'Second paragraph with *more* detail.';

    testWidgets('Issue 12: shows the lead paragraph without markdown syntax', (
      tester,
    ) async {
      await _pump(tester, description: description);

      expect(tester.takeException(), isNull);
      expect(find.byType(ThemedMarkdown), findsOneWidget);
      expect(find.textContaining('Biggest rink in town'), findsOneWidget);
      expect(find.textContaining('**'), findsNothing);
      expect(find.textContaining('About'), findsNothing);
      expect(find.textContaining('Second paragraph'), findsNothing);
    });
  });
}
