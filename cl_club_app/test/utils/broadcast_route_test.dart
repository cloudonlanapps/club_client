import 'package:cl_club_app/src/utils/router_helpers.dart';
import 'package:cl_remote_store/cl_remote_store.dart' show BroadcastScope;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// The Broadcast route read the way `router.dart` reads it.
GoRouter _router(String location) => GoRouter(
  initialLocation: location,
  routes: [
    GoRoute(path: '/', builder: (context, state) => const Text('dashboard')),
    GoRoute(
      path: broadcastRoute,
      pageBuilder: (context, state) {
        final scope = broadcastScopeFrom(state.uri.queryParameters);
        if (scope == null) return notFoundPage(context);
        return NoTransitionPage(child: Text('broadcast $scope'));
      },
    ),
  ],
);

void main() {
  group('Issue 252: one Broadcast route, the audience as its filter', () {
    test('Issue 252: each entry point opens the route with its filter', () {
      expect(
        broadcastPath(const BroadcastScope.all()),
        '/memberzone/broadcast',
      );
      expect(
        broadcastPath(const BroadcastScope.group(3)),
        '/memberzone/broadcast?group=3',
      );
      expect(
        broadcastPath(const BroadcastScope.event(9)),
        '/memberzone/broadcast?event=9',
      );
      expect(
        broadcastPath(const BroadcastScope.member('alice')),
        '/memberzone/broadcast?member=alice',
      );
    });

    test('Issue 252: the filter reads back as the scope', () {
      const scopes = [
        BroadcastScope.all(),
        BroadcastScope.group(3),
        BroadcastScope.event(9),
        BroadcastScope.member('a.b+c'),
      ];
      for (final scope in scopes) {
        final uri = Uri.parse(broadcastPath(scope));
        expect(broadcastScopeFrom(uri.queryParameters), scope);
      }
    });

    test('Issue 252: a filter that cannot be read is no scope', () {
      expect(broadcastScopeFrom({'group': 'x'}), isNull);
      expect(broadcastScopeFrom({'event': ''}), isNull);
      expect(broadcastScopeFrom({'member': ''}), isNull);
      expect(broadcastScopeFrom({'group': '3', 'event': '9'}), isNull);
    });

    testWidgets('Issue 252: ?group=3 opens the screen for the group', (
      tester,
    ) async {
      await tester.pumpWidget(
        ShadApp.router(
          routerConfig: _router('/memberzone/broadcast?group=3'),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('broadcast ${const BroadcastScope.group(3)}'),
        findsOneWidget,
      );
    });

    testWidgets('Issue 252: ?group=x shows Page not found', (tester) async {
      await tester.pumpWidget(
        ShadApp.router(
          routerConfig: _router('/memberzone/broadcast?group=x'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Page not found'), findsOneWidget);
    });
  });
}
