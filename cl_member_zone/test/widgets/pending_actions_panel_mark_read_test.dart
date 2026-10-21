import 'package:cl_club_communication/cl_club_communication.dart'
    show NotificationDeepLink, NotificationRow;
import 'package:cl_member_auth/cl_member_auth.dart'
    show AuthNotifier, authStateProvider;
import 'package:cl_member_zone/src/widgets/panels/dashboard_event_nav.dart';
import 'package:cl_member_zone/src/widgets/panels/pending_actions_panel_body.dart';
import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class _Auth extends AuthNotifier {
  @override
  Future<UserPrivate?> build() async => UserPrivate(
    username: 'someone',
    displayName: 'Some One',
    status: UserStatus.active,
    isSuperAdmin: false,
    roles: const UserRoles(isAdmin: true),
    createdAtUtc: DateTime.utc(2026),
  );
}

/// Records what is marked read.
class _Notifications extends ClNotificationsMasterNotifier {
  final List<int> markedRead = [];

  @override
  Future<Map<int, AppNotification>> build() async => {};

  @override
  Future<void> markRead(int id) async => markedRead.add(id);
}

class _Pending extends ClPendingActionsMasterNotifier {
  @override
  Future<Map<int, AppNotification>> build() async => {
    11: AppNotification(
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
    ),
  };
}

void main() {
  testWidgets('Issue 201: opening a row of the dashboard Pending actions '
      'panel marks its notification read, then opens it', (tester) async {
    final notifications = _Notifications();
    final opened = <NotificationDeepLink>[];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith(_Auth.new),
          clNotificationsMasterProvider.overrideWith(() => notifications),
          clPendingActionsMasterProvider.overrideWith(_Pending.new),
        ],
        child: ShadApp(
          home: Scaffold(
            body: DashboardEventNav(
              onAdminEventTap: (_) {},
              onMyEventTap: (_, _) {},
              onSeeMoreNotifications: () {},
              onSeeMorePendingActions: () {},
              onNotificationDeepLink: opened.add,
              onHome: () {},
              child: const PendingActionsPanelBody(),
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
