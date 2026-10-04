import 'package:cl_club_events/src/widgets/events_preview/cl_event_venue_detail.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show MapEmbed;

Venue venueFixture({
  int id = 1,
  String name = 'Test Arena',
  String? address,
  String? mapUri,
}) {
  final now = DateTime.utc(2026, 5, 14);
  return Venue(
    id: id,
    name: name,
    address: address,
    mapUri: mapUri,
    createdAtUtc: now,
    updatedAtUtc: now,
  );
}

Widget wrap(Widget child) => ShadApp(
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

void main() {
  testWidgets(
    'Issue 259: renders name fallback row when venue is null',
    (tester) async {
      await tester.pumpWidget(
        wrap(const ClEventVenueDetail(venueId: 42)),
      );
      expect(find.text('Venue #42'), findsOneWidget);
      expect(find.byType(MapEmbed), findsNothing);
    },
  );

  testWidgets(
    'Issue 259: renders name and address but no map when mapUri is null',
    (tester) async {
      await tester.pumpWidget(
        wrap(
          ClEventVenueDetail(
            venueId: 1,
            venue: venueFixture(address: '123 Rink Lane'),
          ),
        ),
      );
      expect(find.text('Test Arena'), findsOneWidget);
      expect(find.text('123 Rink Lane'), findsOneWidget);
      expect(find.byType(MapEmbed), findsNothing);
    },
  );

  testWidgets(
    'Issue 259: renders MapEmbed when venue.mapUri is present',
    (tester) async {
      await tester.pumpWidget(
        wrap(
          ClEventVenueDetail(
            venueId: 1,
            venue: venueFixture(
              address: '123 Rink Lane',
              mapUri: 'https://www.google.com/maps/embed?pb=test',
            ),
          ),
        ),
      );
      // Native MapEmbed initialises webview_flutter, which has no platform
      // implementation under unit tests — swallow that and assert that the
      // MapEmbed widget itself is in the tree.
      tester.takeException();
      expect(find.text('Test Arena'), findsOneWidget);
      expect(find.text('123 Rink Lane'), findsOneWidget);
      expect(find.byType(MapEmbed), findsOneWidget);
    },
  );

  testWidgets(
    'Issue 259: tapping the header invokes onVenueTap with the venueId',
    (tester) async {
      int? tapped;
      await tester.pumpWidget(
        wrap(
          ClEventVenueDetail(
            venueId: 7,
            venue: venueFixture(id: 7),
            onVenueTap: (id) => tapped = id,
          ),
        ),
      );
      await tester.tap(find.text('Test Arena'));
      await tester.pump();
      expect(tapped, 7);
    },
  );
}
