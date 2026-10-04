import 'package:cl_club_branding/cl_club_branding.dart' show appLogoUriProvider;
import 'package:cl_member_zone/src/widgets/sidebar/app_sidebar.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

const _coach = UserInfo(
  username: 'sidebar_coach',
  displayName: 'Side Bar',
  status: UserStatus.active,
  isSuperAdmin: false,
  roles: UserRoles(isCoach: true),
);

Widget _wrap(Set<EventType> types) {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => Scaffold(
          body: AppSidebar(
            currentUser: _coach,
            eventTypes: types,
            onNavigate: (_) {},
          ),
        ),
      ),
    ],
  );
  return ProviderScope(
    // No logo asset in tests; an unknown scheme renders an empty box.
    overrides: [appLogoUriProvider.overrideWithValue(Uri.parse('none:'))],
    child: ShadApp.router(routerConfig: router),
  );
}

void main() {
  group('Issue 115: the staff sidebar lists the club event types', () {
    testWidgets('Issue 115: camps only by default', (tester) async {
      await tester.pumpWidget(_wrap(const {EventType.camp}));
      await tester.pumpAndSettle();

      expect(find.text('Camps'), findsOneWidget);
      expect(find.text('Programs'), findsNothing);
    });

    testWidgets('Issue 115: programmes appear when the club runs them', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap({EventType.camp, EventType.programme}));
      await tester.pumpAndSettle();

      expect(find.text('Camps'), findsOneWidget);
      expect(find.text('Programs'), findsOneWidget);
      expect(find.text('One-Off Events'), findsNothing);
    });

    testWidgets('Issue 122: one-off events appear when the club runs them', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(EventType.values.toSet()));
      await tester.pumpAndSettle();

      expect(find.text('One-Off Events'), findsOneWidget);
    });
  });
}
