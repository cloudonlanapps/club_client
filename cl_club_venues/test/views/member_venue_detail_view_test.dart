import 'package:cl_club_venues/cl_club_venues.dart' show MemberVenueDetailView;
import 'package:cl_member_auth/cl_member_auth.dart'
    show imageAuthHeadersProvider;
import 'package:cl_remote_store/cl_remote_store.dart'
    show clVenueDetailProvider, venueImageProvider;
import 'package:club_sdk_2/club_sdk_2.dart' show Venue;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

final Venue _venue = Venue(
  id: 1,
  name: 'North Rink',
  address: '12 Rink Road',
  description: 'Two pads and a cafe.',
  createdAtUtc: DateTime.utc(2026),
  updatedAtUtc: DateTime.utc(2026),
);

void main() {
  testWidgets('Issue 293: a venue with no image shows its name and address '
      'to a member', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          clVenueDetailProvider(1).overrideWithValue(AsyncData(_venue)),
          venueImageProvider(1).overrideWith((ref) async => null),
          imageAuthHeadersProvider.overrideWith((ref) async => const {}),
        ],
        child: const ShadApp(
          home: Scaffold(body: MemberVenueDetailView(venueId: 1)),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('North Rink', findRichText: true), findsOneWidget);
    expect(find.text('12 Rink Road', findRichText: true), findsOneWidget);
    expect(
      find.text('Two pads and a cafe.', findRichText: true),
      findsOneWidget,
    );
  });
}
