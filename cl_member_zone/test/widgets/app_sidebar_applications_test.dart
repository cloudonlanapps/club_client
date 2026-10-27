import 'package:cl_club_branding/cl_club_branding.dart' show appLogoUriProvider;
import 'package:cl_member_zone/src/widgets/sidebar/app_sidebar.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'sidebar_test_routes.dart';

UserInfo _user({bool admin = false, bool coach = false}) => UserInfo(
  username: 'sidebar_user',
  displayName: 'Side Bar',
  status: UserStatus.active,
  isSuperAdmin: false,
  roles: UserRoles(isAdmin: admin, isCoach: coach),
);

Future<void> _pump(
  WidgetTester tester,
  UserInfo user, {
  required bool applications,
  ValueChanged<String>? onNavigate,
}) async {
  await tester.binding.setSurfaceSize(const Size(800, 1600));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => Scaffold(
          body: AppSidebar(
            currentUser: user,
            applications: applications,
            routeFor: testSidebarRoute,
            currentLocation: '/',
            onNavigate: onNavigate ?? (_) {},
          ),
        ),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [appLogoUriProvider.overrideWithValue(Uri.parse('none:'))],
      child: ShadApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('Issue 321: the Applications sidebar entry', () {
    testWidgets('Issue 321: a member sees Applications after Events, and it '
        'opens their own list', (tester) async {
      String? went;
      await _pump(
        tester,
        _user(),
        applications: true,
        onNavigate: (p) => went = p,
      );
      final events = tester.getTopLeft(find.text('Events'));
      final applications = tester.getTopLeft(find.text('Applications'));
      expect(applications.dy, greaterThan(events.dy));
      await tester.tap(find.text('Applications'));
      expect(went, '/applications/mine');
    });

    testWidgets('Issue 380: a member sees it once, under Main only', (
      tester,
    ) async {
      await _pump(tester, _user(), applications: true);
      expect(find.text('Applications'), findsOneWidget);
    });

    testWidgets('Issue 380: an admin also sees it under Club Management, '
        'which opens the management list', (tester) async {
      String? went;
      await _pump(
        tester,
        _user(admin: true),
        applications: true,
        onNavigate: (p) => went = p,
      );
      final entries = find.text('Applications');
      expect(entries, findsNWidgets(2));
      final management = tester.getTopLeft(find.text('CLUB MANAGEMENT'));
      expect(tester.getTopLeft(entries.first).dy, lessThan(management.dy));
      expect(tester.getTopLeft(entries.last).dy, greaterThan(management.dy));
      await tester.tap(entries.last);
      expect(went, '/applications');
    });

    testWidgets('Issue 380: a coach who is not an admin sees it once', (
      tester,
    ) async {
      await _pump(tester, _user(coach: true), applications: true);
      expect(find.text('Applications'), findsOneWidget);
    });

    testWidgets('Issue 321: with applications off nobody sees it', (
      tester,
    ) async {
      await _pump(tester, _user(admin: true), applications: false);
      expect(find.text('Applications'), findsNothing);
    });
  });
}
