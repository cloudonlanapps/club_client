// Issue 113: while the member is added, the Add to Group dialog is closed
// by nothing.
import 'dart:async';

import 'package:cl_club_members/src/widgets/add_to_group_dialog.dart';
import 'package:cl_remote_store/cl_remote_store.dart'
    show ClGroupsMasterNotifier, clGroupsMasterProvider;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../support/dialog_dismissal.dart';

const _groupName = 'Rink Rats';

/// A groups master with one manual group, whose add waits on [held].
class _HeldGroups extends ClGroupsMasterNotifier {
  _HeldGroups(this.held);

  final Completer<void> held;

  /// The members added, as `groupId username`.
  final List<String> added = [];

  @override
  Future<Map<int, Group>> build() async => {
    1: Group(
      id: 1,
      name: _groupName,
      kind: GroupKind.manual,
      createdAtUtc: DateTime.utc(2024),
    ),
  };

  @override
  Future<void> addMember(int groupId, String username) async {
    added.add('$groupId $username');
    await held.future;
  }
}

void main() {
  testWidgets('Issue 113: while Add to Group adds the member, the X, a tap '
      'outside, Escape and system back do not close it', (tester) async {
    final groups = _HeldGroups(Completer<void>());
    final results = <bool>[];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [clGroupsMasterProvider.overrideWith(() => groups)],
        child: ShadApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ShadButton(
                onPressed: () async => results.add(
                  await AddToGroupDialog.show(
                    context,
                    username: 'ana',
                    currentGroupIds: const {},
                    roles: const UserRoles(isAdmin: false, isCoach: false),
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_groupName));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ShadButton, 'Add'));
    await tester.pump();
    expect(groups.added, ['1 ana']);

    await expectNoDismissal(tester, find.byType(AddToGroupDialog));
    expect(results, isEmpty);

    groups.held.complete();
    await tester.pumpAndSettle();
    expect(find.byType(AddToGroupDialog), findsNothing);
    expect(results, [true]);
  });
}
