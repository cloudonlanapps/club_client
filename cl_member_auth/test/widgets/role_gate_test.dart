import 'dart:async';

import 'package:cl_member_auth/cl_member_auth.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show LoadingView;

UserPrivate _user({UserRoles roles = const UserRoles()}) => UserPrivate(
  username: 'm1',
  displayName: 'Member One',
  status: UserStatus.active,
  isSuperAdmin: false,
  roles: roles,
  createdAtUtc: DateTime.utc(2024),
);

class _StubAuth extends AuthNotifier {
  _StubAuth(this.result);
  final Future<UserPrivate?> result;
  @override
  Future<UserPrivate?> build() => result;
}

Future<void> _pump(
  WidgetTester tester,
  Future<UserPrivate?> user, {
  VoidCallback? onHome,
}) => tester.pumpWidget(
  ProviderScope(
    overrides: [authStateProvider.overrideWith(() => _StubAuth(user))],
    child: ShadApp(
      home: Scaffold(
        body: RoleGate(
          allow: RoleGate.admin,
          onHome: onHome ?? () {},
          builder: (currentUser) => Text('view for ${currentUser.username}'),
        ),
      ),
    ),
  ),
);

void main() {
  group('Issue 203: RoleGate', () {
    testWidgets('Issue 203: shows a loader while the member is not known', (
      tester,
    ) async {
      final pending = Completer<UserPrivate?>();
      await _pump(tester, pending.future);
      await tester.pump();

      expect(find.byType(LoadingView), findsOneWidget);
      expect(find.text(AccessDeniedView.title), findsNothing);
      pending.complete(null);
    });

    testWidgets('Issue 203: refuses a member the check does not allow', (
      tester,
    ) async {
      var home = 0;
      await _pump(tester, Future.value(_user()), onHome: () => home++);
      await tester.pumpAndSettle();

      expect(find.text(AccessDeniedView.title), findsOneWidget);
      expect(find.text(AccessDeniedView.defaultMessage), findsOneWidget);
      expect(find.textContaining('view for'), findsNothing);
      await tester.tap(find.text('Home'));
      expect(home, 1);
    });

    testWidgets('Issue 203: builds the view for a member it allows', (
      tester,
    ) async {
      await _pump(
        tester,
        Future.value(_user(roles: const UserRoles(isAdmin: true))),
      );
      await tester.pumpAndSettle();

      expect(find.text('view for m1'), findsOneWidget);
      expect(find.text(AccessDeniedView.title), findsNothing);
    });
  });
}
