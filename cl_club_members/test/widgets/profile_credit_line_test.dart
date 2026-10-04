import 'package:cl_club_members/src/widgets/profile_credit_line.dart';
import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

const _member = UserInfo(
  username: 'profile_member',
  displayName: 'Pro File',
  status: UserStatus.active,
  isSuperAdmin: false,
  roles: UserRoles(),
);

class _Accounts extends ClCreditAccountsMasterNotifier {
  @override
  Future<List<CreditAccount>> build(String arg) async => [
    CreditAccount(
      accountId: 'GEN00001',
      membername: arg,
      kind: CreditAccountKind.general,
      isTrial: false,
      balance: 12,
      validFromUtc: DateTime.utc(2026),
      validUntilUtc: DateTime.utc(2027),
      usable: true,
      state: CreditAccountState.usable,
      openedAtUtc: DateTime.utc(2026),
    ),
  ];
}

Widget _wrap({required bool? creditSystem}) => ProviderScope(
  overrides: [
    creditSystemProvider.overrideWithValue(creditSystem),
    clCreditAccountsMasterProvider.overrideWith(_Accounts.new),
  ],
  child: const ShadApp(
    home: Scaffold(body: ProfileCreditLine(user: _member)),
  ),
);

void main() {
  group('Issue 102: the profile shows the member credit after the name', () {
    testWidgets('Issue 102: name and 🪙 12 when credit is on', (tester) async {
      await tester.pumpWidget(_wrap(creditSystem: true));
      await tester.pumpAndSettle();

      expect(find.text('Pro File'), findsOneWidget);
      expect(find.bySemanticsLabel('Credit 12'), findsOneWidget);
    });

    for (final state in [false, null]) {
      testWidgets('Issue 102: nothing when credit is $state', (tester) async {
        await tester.pumpWidget(_wrap(creditSystem: state));
        await tester.pumpAndSettle();

        expect(find.text('Pro File'), findsNothing);
        expect(find.bySemanticsLabel(RegExp('Credit')), findsNothing);
      });
    }
  });
}
