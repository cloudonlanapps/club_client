import 'dart:io';

import 'package:cl_club_branding/cl_club_branding.dart' show appLogoUriProvider;
import 'package:cl_member_zone/src/widgets/sidebar/app_sidebar.dart';
import 'package:cl_member_zone/src/widgets/sidebar/sidebar_item.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

const _admin = UserInfo(
  username: 'sidebar_user',
  displayName: 'Side Bar',
  status: UserStatus.active,
  isSuperAdmin: false,
  roles: UserRoles(isAdmin: true),
);

/// The host's routes: deliberately not the app's, so nothing in the
/// sidebar can be hiding a path of its own.
String _route(SidebarDestination destination, String username) =>
    switch (destination) {
      SidebarDestination.dashboard => '/',
      SidebarDestination.myEvents => '/zone/mine/$username',
      _ => '/zone/${destination.name}',
    };

Widget _sidebar({
  required String location,
  ValueChanged<String>? onNavigate,
}) => ProviderScope(
  overrides: [appLogoUriProvider.overrideWithValue(Uri.parse('none:'))],
  child: ShadApp(
    home: Scaffold(
      body: AppSidebar(
        currentUser: _admin,
        routeFor: _route,
        currentLocation: location,
        onNavigate: onNavigate ?? (_) {},
      ),
    ),
  ),
);

bool _selected(WidgetTester tester, String label) => tester
    .widget<SidebarItem>(
      find.ancestor(of: find.text(label), matching: find.byType(SidebarItem)),
    )
    .isSelected;

void main() {
  group('Issue 204: the sidebar takes its routes from the host', () {
    testWidgets('Issue 204: the highlight follows the location passed in', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(800, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_sidebar(location: '/zone/venues/3'));
      await tester.pumpAndSettle();
      expect(_selected(tester, 'Venues'), isTrue);
      expect(_selected(tester, 'Dashboard'), isFalse);
      expect(_selected(tester, 'Members'), isFalse);

      await tester.pumpWidget(_sidebar(location: '/'));
      await tester.pumpAndSettle();
      expect(_selected(tester, 'Dashboard'), isTrue);
      expect(_selected(tester, 'Venues'), isFalse);

      await tester.pumpWidget(_sidebar(location: '/zone/mine/sidebar_user'));
      await tester.pumpAndSettle();
      expect(_selected(tester, 'Events'), isTrue);
    });

    testWidgets('Issue 204: a tap navigates to the route the host gives', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(800, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      String? went;
      await tester.pumpWidget(
        _sidebar(location: '/', onNavigate: (path) => went = path),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Members'));
      expect(went, '/zone/members');
      await tester.tap(find.text('Events'));
      expect(went, '/zone/mine/sidebar_user');
    });
  });

  test(
    'Issue 204: cl_member_zone holds no route literal and reads no '
    'GoRouterState',
    () {
      final files = Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .toList();
      expect(files, isNotEmpty, reason: 'run from the package root');
      final offenders = [
        for (final f in files)
          for (final needle in ["'/memberzone", "'/auth", 'GoRouterState'])
            if (f.readAsStringSync().contains(needle)) '${f.path}: $needle',
      ];
      expect(offenders, isEmpty);
    },
  );
}
