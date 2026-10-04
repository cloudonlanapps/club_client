import 'package:cl_club_branding/cl_club_branding.dart' show appLogoUriProvider;
import 'package:cl_member_zone/src/widgets/sidebar/app_sidebar.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

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
  required bool evaluations,
  ValueChanged<String>? onNavigate,
}) async {
  // Tall enough that the whole sidebar is on screen for the tap.
  await tester.binding.setSurfaceSize(const Size(800, 1600));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => Scaffold(
          body: AppSidebar(
            currentUser: user,
            evaluations: evaluations,
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
  group('Issue 174: the Reviews sidebar entries', () {
    testWidgets('Issue 174: a member sees Reviews under Main, to their own', (
      tester,
    ) async {
      String? went;
      await _pump(
        tester,
        _user(),
        evaluations: true,
        onNavigate: (p) => went = p,
      );
      expect(find.text('Reviews'), findsOneWidget);
      await tester.tap(find.text('Reviews'));
      expect(went, '/reviews/mine');
    });

    testWidgets('Issue 174: a coach sees both entries; staff one opens '
        '/reviews', (tester) async {
      final went = <String>[];
      await _pump(
        tester,
        _user(coach: true),
        evaluations: true,
        onNavigate: went.add,
      );
      expect(find.text('Reviews'), findsNWidgets(2));
      await tester.tap(find.text('Reviews').last);
      expect(went, ['/reviews']);
    });

    testWidgets('Issue 174: an admin who does not coach sees both entries', (
      tester,
    ) async {
      await _pump(tester, _user(admin: true), evaluations: true);
      expect(find.text('Reviews'), findsNWidgets(2));
    });

    testWidgets('Issue 174: with evaluations off nobody sees Reviews', (
      tester,
    ) async {
      await _pump(
        tester,
        _user(admin: true, coach: true),
        evaluations: false,
      );
      expect(find.text('Reviews'), findsNothing);
    });
  });
}
