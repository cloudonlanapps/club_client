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
import 'package:ui_lib/ui_lib.dart' show EntityImage;

class _Venues extends ClVenuesMasterNotifier {
  @override
  Future<Map<int, Venue>> build() async => {
    1: Venue(
      id: 1,
      name: 'Riverside Rink',
      createdAtUtc: DateTime.utc(2025),
      updatedAtUtc: DateTime.utc(2025),
    ),
  };
}

Future<void> _pump(WidgetTester tester, List<Override> failing) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [clVenuesMasterProvider.overrideWith(_Venues.new), ...failing],
      child: const ShadApp(
        home: Scaffold(
          body: SizedBox(width: 360, child: VenueCard(venueId: 1)),
        ),
      ),
    ),
  );
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  group('Issue 194: a failed lookup leaves the venue row standing', () {
    testWidgets('Issue 194: the image lookup fails: the row shows the venue '
        'with the placeholder', (tester) async {
      await _pump(tester, [
        venueImageProvider(1).overrideWith((ref) async => throw Exception()),
        imageAuthHeadersProvider.overrideWith((ref) async => const {}),
      ]);

      expect(tester.takeException(), isNull);
      expect(find.text('Riverside Rink'), findsOneWidget);
      final image = tester.widget<EntityImage>(find.byType(EntityImage));
      expect(image.imageUrl, isNull);
    });

    testWidgets('Issue 194: the image headers fail: the row shows the venue', (
      tester,
    ) async {
      await _pump(tester, [
        venueImageProvider(1).overrideWith((ref) async => null),
        imageAuthHeadersProvider.overrideWith((ref) async => throw Exception()),
      ]);

      expect(tester.takeException(), isNull);
      expect(find.text('Riverside Rink'), findsOneWidget);
    });
  });
}
