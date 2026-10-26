import 'package:cl_club_app/src/application_routes.dart';
import 'package:cl_club_app/src/utils/router_helpers.dart';
import 'package:cl_member_auth/cl_member_auth.dart'
    show AuthNotifier, authStateProvider;
import 'package:cl_member_zone/cl_member_zone.dart';
import 'package:cl_remote_store/cl_remote_store.dart' show applicationsProvider;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class _Auth extends AuthNotifier {
  @override
  Future<UserPrivate?> build() async => UserPrivate(
    username: 'member_a',
    displayName: 'member_a',
    status: UserStatus.active,
    isSuperAdmin: false,
    roles: const UserRoles(),
    createdAtUtc: DateTime.utc(2024),
  );
}

Future<void> _open(WidgetTester tester, String location) async {
  final router = GoRouter(
    initialLocation: location,
    routes: applicationRoutes(),
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authStateProvider.overrideWith(_Auth.new),
        // Off: every screen refuses, so no master is read.
        applicationsProvider.overrideWithValue(false),
      ],
      child: ShadApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('Issue 321: the Applications routes', () {
    testWidgets('Issue 321: the list path mounts ApplicationsScreen', (
      tester,
    ) async {
      await _open(tester, applicationsPath);
      expect(find.byType(ApplicationsScreen), findsOneWidget);
    });

    testWidgets('Issue 321: a template path mounts its ApplicationScreen', (
      tester,
    ) async {
      await _open(tester, applicationPath(12));
      final screen = tester.widget<ApplicationScreen>(
        find.byType(ApplicationScreen),
      );
      expect(screen.applicationId, 12);
    });

    testWidgets('Issue 321: an id that is not a number is not found', (
      tester,
    ) async {
      await _open(tester, '$applicationsPath/12x');
      expect(find.byType(ApplicationScreen), findsNothing);
      expect(find.text('Page not found'), findsOneWidget);
    });
  });
}
