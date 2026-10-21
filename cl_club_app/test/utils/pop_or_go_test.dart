import 'dart:async';

import 'package:cl_club_app/src/utils/router_helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// A list page and its create page inside one shell, as the member zone
/// has them; the create page's Close calls [popOrGo] with the list as the
/// fallback, as the create routes in `router.dart` do.
GoRouter _router() => GoRouter(
  initialLocation: '/',
  routes: [
    ShellRoute(
      builder: (context, state, child) => Scaffold(body: child),
      routes: [
        GoRoute(
          path: '/',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: Text('dashboard')),
        ),
        GoRoute(
          path: '/memberzone/venues',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: Text('venues')),
        ),
        GoRoute(
          path: '/memberzone/venues/new',
          pageBuilder: (context, state) => NoTransitionPage(
            child: Builder(
              builder: (context) => TextButton(
                onPressed: () => popOrGo(context, '/memberzone/venues'),
                child: const Text('Close'),
              ),
            ),
          ),
        ),
      ],
    ),
  ],
);

String _location(GoRouter router) =>
    router.routerDelegate.currentConfiguration.uri.toString();

void main() {
  group('Issue 193: popOrGo closes a create page however it was reached', () {
    testWidgets('Issue 193: a create page reached by go() (reload, typed '
        'URL, deep link) closes to its list without throwing', (
      tester,
    ) async {
      final router = _router();
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      router.go('/memberzone/venues/new');
      await tester.pumpAndSettle();
      expect(router.canPop(), isFalse);

      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(_location(router), '/memberzone/venues');
    });

    testWidgets('Issue 193: a pushed create page pops back to where it was '
        'opened from', (tester) async {
      final router = _router();
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();
      unawaited(router.push('/memberzone/venues/new'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(_location(router), '/');
    });
  });
}
