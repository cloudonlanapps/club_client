import 'package:cl_club_app/src/member_zone_routes.dart';
import 'package:cl_club_app/src/router.dart' show routerProvider;
import 'package:cl_member_auth/cl_member_auth.dart'
    show AuthNotifier, authStateProvider;
import 'package:cl_member_zone/cl_member_zone.dart' show SidebarDestination;
import 'package:cl_remote_store/cl_remote_store.dart'
    show identityVerificationProvider;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _SignedOut extends AuthNotifier {
  @override
  Future<UserPrivate?> build() async => null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Issue 204: every sidebar destination is a route of the router', () {
    final container = ProviderContainer(
      overrides: [
        authStateProvider.overrideWith(_SignedOut.new),
        identityVerificationProvider.overrideWithValue(false),
      ],
    );
    addTearDown(container.dispose);
    final router = container.read(routerProvider);

    final unmatched = [
      for (final destination in SidebarDestination.values)
        if (router.configuration
            .findMatch(Uri.parse(memberZoneSidebarRoute(destination, 'm1')))
            .isEmpty)
          destination,
    ];
    expect(unmatched, isEmpty);
    expect(
      {
        for (final d in SidebarDestination.values)
          memberZoneSidebarRoute(d, 'm1'),
      },
      hasLength(SidebarDestination.values.length),
      reason: 'each entry has its own route',
    );
  });
}
