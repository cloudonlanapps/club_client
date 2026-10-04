import 'package:cl_club_branding/cl_club_branding.dart' show appLogoUriProvider;
import 'package:cl_member_zone/src/widgets/sidebar/app_sidebar.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

UserInfo _user({
  bool admin = false,
  bool coach = false,
  bool superAdmin = false,
}) => UserInfo(
  username: 'sidebar_user',
  displayName: 'Side Bar',
  status: UserStatus.active,
  isSuperAdmin: superAdmin,
  roles: UserRoles(isAdmin: admin, isCoach: coach),
);

Widget _wrap(
  UserInfo user, {
  int unhandledInquiries = 0,
  ValueChanged<String>? onNavigate,
}) {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => Scaffold(
          body: AppSidebar(
            currentUser: user,
            unhandledInquiries: unhandledInquiries,
            onNavigate: onNavigate ?? (_) {},
          ),
        ),
      ),
    ],
  );
  return ProviderScope(
    overrides: [appLogoUriProvider.overrideWithValue(Uri.parse('none:'))],
    child: ShadApp.router(routerConfig: router),
  );
}

void main() {
  group('Issue 21: the admin sidebar entry for inquiries', () {
    testWidgets('Issue 21: an admin sees Inquiries with the open count', (
      tester,
    ) async {
      String? went;
      // Tall enough that the whole sidebar is on screen for the tap.
      await tester.binding.setSurfaceSize(const Size(800, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        _wrap(
          _user(admin: true),
          unhandledInquiries: 3,
          onNavigate: (p) => went = p,
        ),
      );
      await tester.pumpAndSettle();

      final entry = find.ancestor(
        of: find.text('Inquiries'),
        matching: find.byType(GestureDetector),
      );
      expect(find.text('ADMIN'), findsOneWidget);
      expect(
        find.descendant(of: entry.first, matching: find.text('3')),
        findsOneWidget,
      );

      await tester.tap(find.text('Inquiries'));
      expect(went, '/inquiries');
    });

    testWidgets('Issue 21: no count shows when nothing is open', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(_user(admin: true)));
      await tester.pumpAndSettle();
      expect(find.text('Inquiries'), findsOneWidget);
      expect(find.text('0'), findsNothing);
    });

    testWidgets('Issue 21: a coach does not see Inquiries', (tester) async {
      await tester.pumpWidget(_wrap(_user(coach: true), unhandledInquiries: 3));
      await tester.pumpAndSettle();
      expect(find.text('Inquiries'), findsNothing);
    });
  });

  group('Issue 19: the super-admin sidebar entry for website media', () {
    testWidgets('Issue 19: a super-admin sees Website media', (tester) async {
      String? went;
      await tester.binding.setSurfaceSize(const Size(800, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        _wrap(
          _user(admin: true, superAdmin: true),
          onNavigate: (p) => went = p,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Website media'));
      expect(went, '/site-media');
    });

    testWidgets('Issue 19: an admin who is not super-admin does not', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(_user(admin: true)));
      await tester.pumpAndSettle();
      expect(find.text('Inquiries'), findsOneWidget);
      expect(find.text('Website media'), findsNothing);
    });
  });

  group('Issue 20: the super-admin sidebar entry for club details', () {
    testWidgets('Issue 20: a super-admin sees Club details', (tester) async {
      String? went;
      await tester.binding.setSurfaceSize(const Size(800, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        _wrap(
          _user(admin: true, superAdmin: true),
          onNavigate: (p) => went = p,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Club details'));
      expect(went, '/club-details');
    });

    testWidgets('Issue 20: an admin who is not super-admin does not', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(_user(admin: true)));
      await tester.pumpAndSettle();
      expect(find.text('Inquiries'), findsOneWidget);
      expect(find.text('Club details'), findsNothing);
    });
  });
}
