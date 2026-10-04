import 'package:cl_club_communication/src/utils/notification_deep_link.dart';
import 'package:cl_club_communication/src/widgets/pending_action_trailing.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

AppNotification _make({
  required String type,
  required PendingActionType? pendingActionType,
  Map<String, dynamic>? data,
  int? pendingActionId,
}) {
  return AppNotification(
    id: 1,
    username: 'me',
    type: type,
    channel: NotificationChannel.inApp,
    payload: <String, dynamic>{
      'v': 1,
      'type': type,
      'data': data ?? <String, dynamic>{},
    },
    pendingActionType: pendingActionType,
    pendingActionId: pendingActionId,
    isRead: false,
    createdAtUtc: DateTime.utc(2026, 5, 12, 10, 0, 0),
  );
}

Widget _wrap(Widget child) {
  return ProviderScope(
    child: ShadApp(
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  testWidgets('groupJoinRequest renders Approve + Reject', (tester) async {
    final n = _make(
      type: 'group.join_request',
      pendingActionType: PendingActionType.groupJoinRequest,
      data: {'groupId': 7, 'groupName': 'U-14', 'requesterUsername': 'asha'},
      pendingActionId: 99,
    );
    await tester.pumpWidget(
      _wrap(
        PendingActionTrailing(
          notification: n,
          currentUsername: 'me',
          onOpen: (_) {},
        ),
      ),
    );
    expect(find.text('Approve'), findsOneWidget);
    expect(find.text('Reject'), findsOneWidget);
  });

  testWidgets('enrollmentOpportunity renders Accept + Decline', (tester) async {
    final n = _make(
      type: 'enrollment.opened',
      pendingActionType: PendingActionType.enrollmentOpportunity,
      data: {'eventId': 42, 'eventTitle': 'Camp'},
      pendingActionId: 5,
    );
    await tester.pumpWidget(
      _wrap(
        PendingActionTrailing(
          notification: n,
          currentUsername: 'me',
          onOpen: (_) {},
        ),
      ),
    );
    expect(find.text('Accept'), findsOneWidget);
    expect(find.text('Decline'), findsOneWidget);
  });

  testWidgets('attendanceCorrection renders Open', (tester) async {
    final n = _make(
      type: 'attendance.correction_requested',
      pendingActionType: PendingActionType.attendanceCorrection,
      data: {
        'eventId': 1,
        'occurrenceTimeUtc': 1700000000000,
        'memberUsername': 'aarav',
      },
    );
    await tester.pumpWidget(
      _wrap(
        PendingActionTrailing(
          notification: n,
          currentUsername: 'me',
          onOpen: (_) {},
        ),
      ),
    );
    expect(find.text('Open'), findsOneWidget);
    expect(find.text('Approve'), findsNothing);
    expect(find.text('Accept'), findsNothing);
  });

  testWidgets('null pendingActionType falls back to Open', (tester) async {
    final n = _make(
      type: 'unknown',
      pendingActionType: null,
    );
    await tester.pumpWidget(
      _wrap(
        PendingActionTrailing(
          notification: n,
          currentUsername: 'me',
          onOpen: (_) {},
        ),
      ),
    );
    expect(find.text('Open'), findsOneWidget);
  });

  testWidgets(
    'groupJoinRequest with missing groupId degrades to Open',
    (tester) async {
      final n = _make(
        type: 'group.join_request',
        pendingActionType: PendingActionType.groupJoinRequest,
        data: const <String, dynamic>{},
        pendingActionId: 99,
      );
      await tester.pumpWidget(
        _wrap(
          PendingActionTrailing(
            notification: n,
            currentUsername: 'me',
            onOpen: (_) {},
          ),
        ),
      );
      expect(find.text('Open'), findsOneWidget);
      expect(find.text('Approve'), findsNothing);
    },
  );

  testWidgets(
    'Issue 381: userApproval renders only Review (no inline Approve — '
    'admin acts inside AdminUserReviewView)',
    (tester) async {
      final n = _make(
        type: 'user.registration_pending',
        pendingActionType: PendingActionType.userApproval,
        data: {'username': 'asha', 'firstName': 'Asha'},
      );
      await tester.pumpWidget(
        _wrap(
          PendingActionTrailing(
            notification: n,
            currentUsername: 'admin',
            onOpen: (_) {},
          ),
        ),
      );
      expect(find.text('Review'), findsOneWidget);
      expect(find.text('Approve'), findsNothing);
      expect(find.text('Reject'), findsNothing);
      expect(find.text('Open'), findsNothing);
    },
  );

  testWidgets(
    'Issue 381: userApproval tap on Review resolves to '
    'NotifAdminUserReviewLink',
    (tester) async {
      final n = _make(
        type: 'user.registration_pending',
        pendingActionType: PendingActionType.userApproval,
        data: {'username': 'asha'},
      );
      NotificationDeepLink? captured;
      await tester.pumpWidget(
        _wrap(
          PendingActionTrailing(
            notification: n,
            currentUsername: 'admin',
            onOpen: (l) => captured = l,
          ),
        ),
      );
      await tester.tap(find.text('Review'));
      await tester.pump();
      expect(captured, isA<NotifAdminUserReviewLink>());
      expect((captured! as NotifAdminUserReviewLink).username, 'asha');
    },
  );

  testWidgets(
    'Issue 358: enrollmentRequest renders Approve + Reject',
    (tester) async {
      final n = _make(
        type: 'enrollment.rsvp',
        pendingActionType: PendingActionType.enrollmentRequest,
        data: {
          'eventId': 42,
          'eventTitle': 'Camp',
          'outcome': 'requested',
          'memberUsername': 'asha',
        },
        pendingActionId: 5,
      );
      await tester.pumpWidget(
        _wrap(
          PendingActionTrailing(
            notification: n,
            currentUsername: 'admin',
            onOpen: (_) {},
          ),
        ),
      );
      expect(find.text('Approve'), findsOneWidget);
      expect(find.text('Reject'), findsOneWidget);
      expect(find.text('Open'), findsNothing);
    },
  );

  testWidgets(
    'Issue 358: enrollmentRequest with missing eventId degrades to Open',
    (tester) async {
      final n = _make(
        type: 'enrollment.rsvp',
        pendingActionType: PendingActionType.enrollmentRequest,
        data: {'memberUsername': 'asha'},
        pendingActionId: 5,
      );
      await tester.pumpWidget(
        _wrap(
          PendingActionTrailing(
            notification: n,
            currentUsername: 'admin',
            onOpen: (_) {},
          ),
        ),
      );
      expect(find.text('Open'), findsOneWidget);
      expect(find.text('Approve'), findsNothing);
    },
  );

  // Issue 405's `userReconsider` case is gone: the server no longer raises a
  // pending action for a reconsider. `UserReviewService.reconsider` deletes the
  // outstanding `user_approval` notification instead (server
  // `services/user_review.py`), and the user reappears under `user_approval`
  // when they reapply — which the userApproval cases below already cover.
  // `PendingActionType.userReconsider` was dropped from the SDK to match.

  testWidgets(
    'Issue 381: userApproval with missing username still renders the Review '
    'button; tap is inert because the link cannot resolve',
    (tester) async {
      final n = _make(
        type: 'user.registration_pending',
        pendingActionType: PendingActionType.userApproval,
        data: const <String, dynamic>{},
      );
      var taps = 0;
      await tester.pumpWidget(
        _wrap(
          PendingActionTrailing(
            notification: n,
            currentUsername: 'admin',
            onOpen: (_) => taps++,
          ),
        ),
      );
      expect(find.text('Review'), findsOneWidget);
      expect(find.text('Approve'), findsNothing);
      expect(find.text('Open'), findsNothing);
      await tester.tap(find.text('Review'));
      await tester.pump();
      expect(taps, 0);
    },
  );
}
