import 'package:cl_club_credits/cl_club_credits.dart' show CreditView;
import 'package:cl_member_auth/cl_member_auth.dart'
    show AuthNotifier, authStateProvider;
import 'package:cl_member_zone/cl_member_zone.dart';
import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class _Auth extends AuthNotifier {
  _Auth(this.user);
  final UserPrivate user;
  @override
  Future<UserPrivate?> build() async => user;
}

class _Accounts extends ClCreditAccountsMasterNotifier {
  @override
  Future<List<CreditAccount>> build(String arg) async => const [];
}

class _Entries extends ClCreditEntriesMasterNotifier {
  @override
  Future<CreditStatement> build(String arg) async =>
      (entries: const <CreditEntry>[], hasMore: false);
}

class _MyEvents extends ClMyEventsMasterNotifier {
  @override
  Future<List<Event>> build(String arg) async => const [];
}

UserPrivate _user(String username, {bool coach = false}) => UserPrivate(
  username: username,
  displayName: username,
  status: UserStatus.active,
  isSuperAdmin: false,
  roles: UserRoles(isCoach: coach),
  createdAtUtc: DateTime.utc(2024),
);

Future<void> _pump(
  WidgetTester tester, {
  required UserPrivate viewer,
  required bool creditSystem,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authStateProvider.overrideWith(() => _Auth(viewer)),
        creditSystemProvider.overrideWithValue(creditSystem),
        clCreditAccountsMasterProvider.overrideWith(_Accounts.new),
        clCreditEntriesMasterProvider.overrideWith(_Entries.new),
        clMyEventsMasterProvider.overrideWith(_MyEvents.new),
      ],
      child: ShadApp(
        home: Scaffold(
          body: CreditScreen(targetUsername: 'member_a', onHome: () {}),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('Issue 32: the credit route', () {
    testWidgets('Issue 32: the member sees their own credit', (tester) async {
      await _pump(tester, viewer: _user('member_a'), creditSystem: true);
      expect(find.byType(CreditView), findsOneWidget);
    });

    testWidgets('Issue 32: another member is refused', (tester) async {
      await _pump(tester, viewer: _user('member_b'), creditSystem: true);
      expect(find.byType(CreditView), findsNothing);
      expect(find.text('Access Denied'), findsOneWidget);
    });

    testWidgets('Issue 32: credit off is refused', (tester) async {
      await _pump(tester, viewer: _user('member_a'), creditSystem: false);
      expect(find.byType(CreditView), findsNothing);
    });
  });
}
