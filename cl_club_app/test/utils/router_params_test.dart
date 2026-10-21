import 'package:cl_club_app/src/utils/router_helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// A route read the way the member-zone routes in `router.dart` read their
/// ids.
GoRouter _router(String location) => GoRouter(
  initialLocation: location,
  routes: [
    GoRoute(path: '/', builder: (context, state) => const Text('dashboard')),
    GoRoute(
      path: '/memberzone/groups/:id',
      pageBuilder: (context, state) {
        final id = intPathParam(state, 'id');
        if (id == null) return notFoundPage(context);
        return NoTransitionPage(child: Text('group $id'));
      },
    ),
  ],
);

void main() {
  group('Issue 207: a member-zone id that is not a number', () {
    testWidgets('Issue 207: a numeric id opens the page', (tester) async {
      await tester.pumpWidget(
        ShadApp.router(routerConfig: _router('/memberzone/groups/12')),
      );
      await tester.pumpAndSettle();
      expect(find.text('group 12'), findsOneWidget);
    });

    testWidgets('Issue 207: /memberzone/groups/12x shows Page not found, '
        'and Home leaves it', (tester) async {
      final router = _router('/memberzone/groups/12x');
      await tester.pumpWidget(ShadApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Page not found'), findsOneWidget);

      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();
      expect(find.text('dashboard'), findsOneWidget);
    });
  });
}
