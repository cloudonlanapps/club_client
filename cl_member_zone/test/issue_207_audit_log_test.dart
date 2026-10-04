import 'package:cl_member_auth/cl_member_auth.dart';
import 'package:cl_member_zone/cl_member_zone.dart';
import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

UserPrivate _user({
  required UserRoles roles,
  bool isSuperAdmin = false,
}) => UserPrivate(
  username: 'u1',
  displayName: 'Test User',
  status: UserStatus.active,
  isSuperAdmin: isSuperAdmin,
  roles: roles,
  createdAtUtc: DateTime.utc(2024),
);

UserPrivate _member() => _user(roles: const UserRoles());
UserPrivate _admin() => _user(roles: const UserRoles(isAdmin: true));
UserPrivate _superAdmin() =>
    _user(roles: const UserRoles(isAdmin: true), isSuperAdmin: true);

class _StubAuth extends AuthNotifier {
  _StubAuth(this._u);
  final UserPrivate? _u;
  @override
  Future<UserPrivate?> build() async => _u;
}

/// Returns a fixed page for any scope, so view tests don't touch the SDK.
class _StubAuditNotifier extends ClAuditLogMasterNotifier {
  _StubAuditNotifier(this._page);
  final AuditLogPage _page;
  @override
  Future<AuditLogPage> build(AuditLogScope scope) async => _page;
}

Widget _wrap(
  Widget child, {
  required UserPrivate? user,
  AuditLogPage? page,
}) {
  return ProviderScope(
    overrides: [
      authStateProvider.overrideWith(() => _StubAuth(user)),
      if (page != null)
        clAuditLogMasterProvider.overrideWith(() => _StubAuditNotifier(page)),
    ],
    child: ShadApp(home: Scaffold(body: child)),
  );
}

AuditLogPage _page(List<AuditLogRow> rows, {int total = 0}) => AuditLogPage(
  total: total == 0 ? rows.length : total,
  offset: 0,
  limit: 50,
  rows: rows,
);

void main() {
  group('Issue 207: AuditLogScreen gating', () {
    testWidgets('global feed denies a non-super-admin', (tester) async {
      await tester.pumpWidget(
        _wrap(
          AuditLogScreen(
            scope: const AuditLogScope.global(),
            title: 'Audit Log',
            onHome: () {},
          ),
          user: _admin(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Access Denied'), findsOneWidget);
    });

    testWidgets('entity scope denies a plain member', (tester) async {
      await tester.pumpWidget(
        _wrap(
          AuditLogScreen(
            scope: const AuditLogScope.event(7),
            title: 'Event History',
            onHome: () {},
          ),
          user: _member(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Access Denied'), findsOneWidget);
    });
  });

  group('Issue 207: AuditLogView rendering', () {
    final row = AuditLogRow(
      id: 1,
      timestampUtc: DateTime.utc(2026, 6, 1, 13, 30),
      action: 'cancel_event',
      summary: const {'en': 'Asha cancelled event U10 Practice.'},
      actor: const AuditUserRef(username: 'asha', fullName: 'Asha Patil'),
      resource: const {'type': 'event', 'id': 7, 'label': 'U10 Practice'},
      details: const {'reason': 'rink closed'},
    );

    testWidgets('shows the summary sentence by default, JSON hidden', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          AuditLogScreen(
            scope: const AuditLogScope.event(7),
            title: 'Event History',
            onHome: () {},
          ),
          user: _admin(),
          page: _page([row]),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Asha cancelled event U10 Practice.'), findsOneWidget);
      // Raw fields are not rendered until long-press.
      expect(find.textContaining('rink closed'), findsNothing);
    });

    testWidgets('long-press reveals the raw details block', (tester) async {
      await tester.pumpWidget(
        _wrap(
          AuditLogScreen(
            scope: const AuditLogScope.event(7),
            title: 'Event History',
            onHome: () {},
          ),
          user: _superAdmin(),
          page: _page([row]),
        ),
      );
      await tester.pumpAndSettle();

      await tester.longPress(
        find.text('Asha cancelled event U10 Practice.'),
      );
      await tester.pumpAndSettle();

      expect(
        find.textContaining('rink closed', findRichText: true),
        findsOneWidget,
      );
      expect(
        find.textContaining('cancel_event', findRichText: true),
        findsOneWidget,
      );
    });

    testWidgets('pager disables Prev/Next on a single full page', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          AuditLogScreen(
            scope: const AuditLogScope.event(7),
            title: 'Event History',
            onHome: () {},
          ),
          user: _admin(),
          page: _page([row]),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('1–1 of 1'), findsOneWidget);
    });
  });
}
