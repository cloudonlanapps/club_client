import 'package:cl_club_communication/src/models/notification_filter.dart';
import 'package:cl_club_communication/src/providers/notification_filter.dart';
import 'package:cl_club_communication/src/views/notifications_list_view.dart';
import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class StubNotificationsMaster extends ClNotificationsMasterNotifier {
  StubNotificationsMaster(this._initial);

  final Map<int, AppNotification> _initial;
  int refreshCallCount = 0;

  @override
  Future<Map<int, AppNotification>> build() async => _initial;

  @override
  Future<void> refresh() async {
    refreshCallCount++;
  }
}

class StubPendingActionsMaster extends ClPendingActionsMasterNotifier {
  StubPendingActionsMaster(this._initial);

  final Map<int, AppNotification> _initial;

  @override
  Future<Map<int, AppNotification>> build() async => _initial;

  @override
  Future<void> refresh() async {}
}

UserPrivate _user() => UserPrivate(
  username: 'someone',
  displayName: 'Some One',
  status: UserStatus.active,
  isSuperAdmin: false,
  roles: const UserRoles(),
  createdAtUtc: DateTime.utc(2026, 1, 1),
);

AppNotification _broadcast(int id, {bool isRead = false}) => AppNotification(
  id: id,
  username: 'someone',
  type: 'broadcast.message',
  channel: NotificationChannel.inApp,
  payload: const <String, dynamic>{
    'v': 1,
    'type': 'broadcast.message',
    'data': <String, dynamic>{'text': 'Hello'},
  },
  isRead: isRead,
  createdAtUtc: DateTime.utc(2026, 5, 12, 10, 0, 0),
);

AppNotification _groupJoinRequest({
  required int id,
  required DateTime createdAtUtc,
}) => AppNotification(
  id: id,
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
  createdAtUtc: createdAtUtc,
);

Widget _wrap(Widget child, ProviderContainer container) {
  return UncontrolledProviderScope(
    container: container,
    child: ShadApp(home: Scaffold(body: child)),
  );
}

void main() {
  testWidgets('Issue 252: refresh button removed from notifications view', (
    tester,
  ) async {
    final stub = StubNotificationsMaster({1: _broadcast(1)});
    final container = ProviderContainer(
      overrides: [
        clNotificationsMasterProvider.overrideWith(() => stub),
        clPendingActionsMasterProvider.overrideWith(
          () => StubPendingActionsMaster(const {}),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      _wrap(
        NotificationsListView(
          currentUser: _user(),
          onDeepLink: (_) {},
          onHome: () {},
        ),
        container,
      ),
    );
    await tester.pumpAndSettle();

    // Per #252 the screen-level Refresh button is gone — the global one in
    // the shell topbar is the sole refresh affordance.
    expect(find.byTooltip('Refresh notifications'), findsNothing);
  });

  testWidgets('unread filter hides read rows in the list', (tester) async {
    final readBroadcast = _broadcast(1, isRead: true);
    final unreadGroup = AppNotification(
      id: 2,
      username: 'someone',
      type: 'group.archived',
      channel: NotificationChannel.inApp,
      payload: const <String, dynamic>{
        'v': 1,
        'type': 'group.archived',
        'data': <String, dynamic>{'groupId': 1, 'groupName': 'Boys'},
      },
      isRead: false,
      createdAtUtc: DateTime.utc(2026, 5, 12, 10, 0, 0),
    );
    final stub = StubNotificationsMaster({
      readBroadcast.id: readBroadcast,
      unreadGroup.id: unreadGroup,
    });
    final container = ProviderContainer(
      overrides: [
        clNotificationsMasterProvider.overrideWith(() => stub),
        clPendingActionsMasterProvider.overrideWith(
          () => StubPendingActionsMaster(const {}),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      _wrap(
        NotificationsListView(
          currentUser: _user(),
          onDeepLink: (_) {},
          onHome: () {},
        ),
        container,
      ),
    );
    await tester.pumpAndSettle();

    // Sanity: both visible under the default 'all' filter.
    expect(find.text('Hello'), findsOneWidget);
    expect(find.text('The group Boys was archived.'), findsOneWidget);

    container
        .read(notificationFilterProvider.notifier)
        .setRead(NotificationReadFilter.unread);
    await tester.pumpAndSettle();

    expect(find.text('Hello'), findsNothing);
    expect(find.text('The group Boys was archived.'), findsOneWidget);
  });

  testWidgets('Issue 246: type filter restricts to a single bucket', (
    tester,
  ) async {
    final announcement = _broadcast(1).copyWith(broadcastId: () => 555);
    final groupArchived = AppNotification(
      id: 2,
      username: 'someone',
      type: 'group.archived',
      channel: NotificationChannel.inApp,
      payload: const <String, dynamic>{
        'v': 1,
        'type': 'group.archived',
        'data': <String, dynamic>{'groupId': 1, 'groupName': 'Boys'},
      },
      isRead: false,
      createdAtUtc: DateTime.utc(2026, 5, 12, 10, 0, 0),
    );
    final stub = StubNotificationsMaster({
      announcement.id: announcement,
      groupArchived.id: groupArchived,
    });
    final container = ProviderContainer(
      overrides: [
        clNotificationsMasterProvider.overrideWith(() => stub),
        clPendingActionsMasterProvider.overrideWith(
          () => StubPendingActionsMaster(const {}),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      _wrap(
        NotificationsListView(
          currentUser: _user(),
          onDeepLink: (_) {},
          onHome: () {},
        ),
        container,
      ),
    );
    await tester.pumpAndSettle();

    container
        .read(notificationFilterProvider.notifier)
        .setType(NotificationTypeFilter.broadcast);
    await tester.pumpAndSettle();

    // Broadcast bucket: announcement (has broadcastId) is shown; the
    // group.archived row (info bucket — no broadcastId, no pendingAction) is
    // hidden.
    expect(find.text('Hello'), findsOneWidget);
    expect(find.text('The group Boys was archived.'), findsNothing);
  });

  // --- Issue #115: unified pending-actions feed ---

  testWidgets(
    'unresolved pending action (in both providers) renders Approve/Reject',
    (tester) async {
      final n = _groupJoinRequest(
        id: 11,
        createdAtUtc: DateTime.utc(2026, 5, 12, 9, 0, 0),
      );
      final stubN = StubNotificationsMaster({n.id: n});
      final stubP = StubPendingActionsMaster({n.id: n});
      final container = ProviderContainer(
        overrides: [
          clNotificationsMasterProvider.overrideWith(() => stubN),
          clPendingActionsMasterProvider.overrideWith(() => stubP),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        _wrap(
          NotificationsListView(
            currentUser: _user(),
            onDeepLink: (_) {},
            onHome: () {},
          ),
          container,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Approve'), findsOneWidget);
      expect(find.text('Reject'), findsOneWidget);
    },
  );

  testWidgets('dedupes: row in both providers appears only once', (
    tester,
  ) async {
    final n = _groupJoinRequest(
      id: 11,
      createdAtUtc: DateTime.utc(2026, 5, 12, 9, 0, 0),
    );
    final stubN = StubNotificationsMaster({n.id: n});
    final stubP = StubPendingActionsMaster({n.id: n});
    final container = ProviderContainer(
      overrides: [
        clNotificationsMasterProvider.overrideWith(() => stubN),
        clPendingActionsMasterProvider.overrideWith(() => stubP),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      _wrap(
        NotificationsListView(
          currentUser: _user(),
          onDeepLink: (_) {},
          onHome: () {},
        ),
        container,
      ),
    );
    await tester.pumpAndSettle();

    // Each pending-action row contributes exactly one "Approve" button.
    expect(find.text('Approve'), findsOneWidget);
  });

  testWidgets('resolved pending action (in notifications only) renders '
      'without trailing', (tester) async {
    final n = _groupJoinRequest(
      id: 12,
      createdAtUtc: DateTime.utc(2026, 5, 12, 9, 0, 0),
    );
    final stubN = StubNotificationsMaster({n.id: n});
    final stubP = StubPendingActionsMaster(const {}); // resolved on server
    final container = ProviderContainer(
      overrides: [
        clNotificationsMasterProvider.overrideWith(() => stubN),
        clPendingActionsMasterProvider.overrideWith(() => stubP),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      _wrap(
        NotificationsListView(
          currentUser: _user(),
          onDeepLink: (_) {},
          onHome: () {},
        ),
        container,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Approve'), findsNothing);
    expect(find.text('Reject'), findsNothing);
    expect(find.text('Open'), findsNothing);
  });

  testWidgets('merge sorts by createdAtUtc descending', (tester) async {
    final older = _broadcast(1).copyWith(
      createdAtUtc: DateTime.utc(2026, 5, 10, 8, 0, 0),
    );
    final newerPending = _groupJoinRequest(
      id: 2,
      createdAtUtc: DateTime.utc(2026, 5, 12, 9, 0, 0),
    );
    final stubN = StubNotificationsMaster({older.id: older});
    final stubP = StubPendingActionsMaster({newerPending.id: newerPending});
    final container = ProviderContainer(
      overrides: [
        clNotificationsMasterProvider.overrideWith(() => stubN),
        clPendingActionsMasterProvider.overrideWith(() => stubP),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      _wrap(
        NotificationsListView(
          currentUser: _user(),
          onDeepLink: (_) {},
          onHome: () {},
        ),
        container,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Hello'), findsOneWidget);
    expect(find.text('Approve'), findsOneWidget);

    final pendingY = tester.getTopLeft(find.text('Approve')).dy;
    final broadcastY = tester.getTopLeft(find.text('Hello')).dy;
    expect(
      pendingY < broadcastY,
      isTrue,
      reason:
          'Newer createdAtUtc should render above older. '
          'pendingY=$pendingY broadcastY=$broadcastY',
    );
  });
}
