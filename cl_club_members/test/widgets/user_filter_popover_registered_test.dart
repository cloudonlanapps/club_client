import 'package:cl_club_members/src/widgets/user_filter_popover.dart';
import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class _StubUsersMasterNotifier extends ClUsersMasterNotifier {
  @override
  Future<Map<String, UserInfo>> build() async => const {};
}

UserInfo _registered(String username) => UserInfo(
  username: username,
  displayName: username,
  status: UserStatus.registered,
  isSuperAdmin: false,
  roles: const UserRoles(),
);

void main() {
  testWidgets(
    'Issue 91: the status filter offers registered users, with their count',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final chosen = <UserListFilter>[];
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            clUsersMasterProvider.overrideWith(_StubUsersMasterNotifier.new),
            clRegisteredUsersProvider.overrideWith(
              (ref) async => [_registered('regD'), _registered('regE')],
            ),
          ],
          child: ShadApp(
            home: Scaffold(
              body: Center(
                child: UserFilterPopover(
                  filter: const UserListFilter(),
                  onFilterChanged: chosen.add,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(ShadButton).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('All statuses'));
      await tester.pumpAndSettle();

      expect(find.text('Registered, not submitted (2)'), findsOneWidget);

      await tester.tap(find.text('Registered, not submitted (2)'));
      await tester.pumpAndSettle();
      expect(chosen.single.status, UserStatus.registered);
    },
  );
}
