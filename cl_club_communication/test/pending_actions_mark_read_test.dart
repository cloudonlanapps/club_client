import 'package:cl_club_communication/cl_club_communication.dart'
    show NotificationDeepLink, NotificationRow;
import 'package:cl_club_communication/src/views/pending_actions_list_view.dart';
import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Records what is marked read.
class _Notifications extends ClNotificationsMasterNotifier {
  _Notifications(this._initial);

  final Map<int, AppNotification> _initial;
  final List<int> markedRead = [];

  @override
  Future<Map<int, AppNotification>> build() async => _initial;

  @override
  Future<void> markRead(int id) async => markedRead.add(id);
}

class _Pending extends ClPendingActionsMasterNotifier {
  _Pending(this._initial);

  final Map<int, AppNotification> _initial;

  @override
  Future<Map<int, AppNotification>> build() async => _initial;
}

final _joinRequest = AppNotification(
  id: 11,
  username: 'someone',
  type: 'group.join_request',
  channel: NotificationChannel.inApp,
  payload: const <String, dynamic>{
    'v': 1,
    'type': 'group.join_request',
    'data': <String, dynamic>{
      'groupId': 7,
      'groupName': 'U-14',
      'requesterUsername': 'asha',
    },
  },
  pendingActionType: PendingActionType.groupJoinRequest,
  pendingActionId: 99,
  isRead: false,
  createdAtUtc: DateTime.utc(2026, 5, 12, 9),
);

void main() {
  testWidgets('Issue 201: opening a row of Pending actions marks its '
      'notification read, then opens it', (tester) async {
    final notifications = _Notifications({_joinRequest.id: _joinRequest});
    final opened = <NotificationDeepLink>[];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          clNotificationsMasterProvider.overrideWith(() => notifications),
          clPendingActionsMasterProvider.overrideWith(
            () => _Pending({_joinRequest.id: _joinRequest}),
          ),
        ],
        child: ShadApp(
          home: Scaffold(
            body: PendingActionsListView(
              currentUser: UserPrivate(
                username: 'someone',
                displayName: 'Some One',
                status: UserStatus.active,
                isSuperAdmin: false,
                roles: const UserRoles(isAdmin: true),
                createdAtUtc: DateTime.utc(2026),
              ),
              onDeepLink: opened.add,
              onHome: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    tester.widget<NotificationRow>(find.byType(NotificationRow)).onTap!();
    await tester.pumpAndSettle();

    expect(notifications.markedRead, [11]);
    expect(opened, hasLength(1));
  });
}
