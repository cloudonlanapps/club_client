import 'package:cl_club_venues/src/views/venue_profile_view.dart'
    show VenueHeroImage;
import 'package:cl_member_auth/cl_member_auth.dart'
    show imageAuthHeadersProvider;
import 'package:cl_remote_store/cl_remote_store.dart' show venueImageProvider;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

void main() {
  testWidgets(
    'Issue 473: VenueHeroImage tolerates parent IntrinsicHeight without '
    'throwing "LayoutBuilder does not support intrinsic dimensions"',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            venueImageProvider(
              1,
            ).overrideWith((ref) async => 'http://localhost/x.png'),
            imageAuthHeadersProvider.overrideWith((ref) async => const {}),
          ],
          child: const ShadApp(
            home: Scaffold(
              body: Center(
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        width: 280,
                        child: VenueHeroImage(venueId: 1, canEdit: false),
                      ),
                      SizedBox(
                        width: 400,
                        height: 240,
                        child: Text('content'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      // Pump through the FutureProvider resolution so the image branch (not
      // just the placeholder) is exercised inside the IntrinsicHeight.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 10));

      expect(tester.takeException(), isNull);
    },
  );
}
