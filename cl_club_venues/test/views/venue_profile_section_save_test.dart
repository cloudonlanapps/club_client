import 'package:cl_club_forms/cl_club_forms.dart' show LocationEditForm;
import 'package:cl_club_venues/src/views/venue_profile_view.dart';
import 'package:cl_member_auth/cl_member_auth.dart'
    show AuthNotifier, authStateProvider, imageAuthHeadersProvider;
import 'package:cl_remote_store/cl_remote_store.dart'
    show ClVenuesMasterNotifier, clVenuesMasterProvider, venueImageProvider;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show LoadingView;

final _venue = Venue(
  id: 4,
  name: 'Main Arena',
  isDefault: false,
  address: '1 Rink Road',
  createdAtUtc: DateTime.utc(2025),
  updatedAtUtc: DateTime.utc(2025),
);

class _Venues extends ClVenuesMasterNotifier {
  @override
  Future<Map<int, Venue>> build() async => {_venue.id: _venue};
}

class _Admin extends AuthNotifier {
  @override
  Future<UserPrivate?> build() async => UserPrivate(
    username: 'admin1',
    displayName: 'admin1',
    status: UserStatus.active,
    isSuperAdmin: false,
    roles: const UserRoles(isAdmin: true),
    createdAtUtc: DateTime.utc(2024),
  );
}

void main() {
  testWidgets('Issue 229: saving one venue section keeps the page and the '
      'other sections on screen', (tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final venues = _Venues();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          clVenuesMasterProvider.overrideWith(() => venues),
          authStateProvider.overrideWith(_Admin.new),
          venueImageProvider(_venue.id).overrideWith((_) async => null),
          imageAuthHeadersProvider.overrideWith((_) async => const {}),
        ],
        child: ShadApp(
          home: ShadToaster(
            child: Scaffold(
              body: VenueProfileView(venueId: _venue.id, onDeleted: () {}),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    // Open the Location editor: the state another section's save must keep.
    await tester.tap(
      find.descendant(
        of: find.byType(VenueLocationCard),
        matching: find.byIcon(LucideIcons.pencil),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(LocationEditForm), findsOneWidget);

    // Another section (the flags) saves: the master takes the server's answer.
    venues.replaceLocally(_venue.copyWith(isFeatured: true));
    for (var i = 0; i < 5; i++) {
      await tester.pump();
      expect(find.byType(LoadingView), findsNothing);
    }
    await tester.pumpAndSettle();

    expect(find.byType(LoadingView), findsNothing);
    expect(
      find.byType(LocationEditForm),
      findsOneWidget,
      reason: 'the Location editor stays open',
    );
  });
}
