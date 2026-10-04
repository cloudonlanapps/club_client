import 'package:cl_club_members/src/widgets/pending_approvals_banner.dart'
    show PendingApprovalsBanner;
import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class _StubUsersMasterNotifier extends ClUsersMasterNotifier {
  _StubUsersMasterNotifier(this._users);
  final Map<String, UserInfo> _users;
  @override
  Future<Map<String, UserInfo>> build() async => _users;
}

UserInfo _pending(String username) => UserInfo(
  username: username,
  displayName: username,
  status: UserStatus.pending,
  isSuperAdmin: false,
  roles: const UserRoles(),
);

UserInfo _active(String username) => UserInfo(
  username: username,
  displayName: username,
  status: UserStatus.active,
  isSuperAdmin: false,
  roles: const UserRoles(),
);

Widget _wrap({
  required Map<String, UserInfo> users,
  required VoidCallback onActNow,
}) {
  return ProviderScope(
    overrides: [
      clUsersMasterProvider.overrideWith(() => _StubUsersMasterNotifier(users)),
    ],
    child: ShadApp(
      home: Scaffold(
        body: PendingApprovalsBanner(onActNow: onActNow),
      ),
    ),
  );
}

void main() {
  testWidgets(
    'Issue 400: banner is hidden when there are no pending users',
    (tester) async {
      await tester.pumpWidget(
        _wrap(
          users: {'a': _active('a')},
          onActNow: () {},
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Act Now'), findsNothing);
      expect(find.textContaining('waiting for approval'), findsNothing);
    },
  );

  testWidgets(
    'Issue 400: banner shows pending count and Act Now when count > 0',
    (tester) async {
      await tester.pumpWidget(
        _wrap(
          users: {
            'p1': _pending('p1'),
            'p2': _pending('p2'),
            'a': _active('a'),
          },
          onActNow: () {},
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('You have 2 registrations waiting for approval.'),
        findsOneWidget,
      );
      expect(find.text('Act Now'), findsOneWidget);
    },
  );

  testWidgets(
    'Issue 400: singular wording when exactly one pending user',
    (tester) async {
      await tester.pumpWidget(
        _wrap(
          users: {'p1': _pending('p1')},
          onActNow: () {},
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('You have 1 registration waiting for approval.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'Issue 400: tapping Act Now invokes the callback',
    (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _wrap(
          users: {'p1': _pending('p1')},
          onActNow: () => taps++,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Act Now'));
      await tester.pumpAndSettle();

      expect(taps, 1);
    },
  );
}
