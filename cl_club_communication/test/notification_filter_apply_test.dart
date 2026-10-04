import 'package:cl_club_communication/src/models/notification_filter.dart';
import 'package:cl_club_communication/src/utils/notification_filter_apply.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_test/flutter_test.dart';

AppNotification _n({
  required int id,
  required String type,
  required bool isRead,
  required DateTime createdAt,
  PendingActionType? pendingActionType,
  int? pendingActionId,
  int? broadcastId,
}) {
  return AppNotification(
    id: id,
    username: 'u',
    type: type,
    channel: NotificationChannel.inApp,
    payload: <String, dynamic>{
      'v': 1,
      'type': type,
      'data': const <String, dynamic>{},
    },
    pendingActionType: pendingActionType,
    pendingActionId: pendingActionId,
    broadcastId: broadcastId,
    isRead: isRead,
    createdAtUtc: createdAt,
  );
}

void main() {
  // Build a fixed map spanning every bucket plus a few of the families that
  // were previously unreachable (`occurrence.*`, `account.*`, `profile.*`,
  // `venue.*`, `user.*`) so the bucket classification is exercised end-to-end.
  final t0 = DateTime.utc(2026, 5, 12, 10, 0, 0);

  // Broadcast bucket: broadcastId set.
  final broadcastUnread = _n(
    id: 1,
    type: 'broadcast.message',
    isRead: false,
    createdAt: t0.add(const Duration(minutes: 7)),
    broadcastId: 101,
  );
  final broadcastRead = _n(
    id: 2,
    type: 'broadcast.message',
    isRead: true,
    createdAt: t0,
    broadcastId: 102,
  );

  // Action Pending bucket: pendingActionType set.
  final groupJoinRequest = _n(
    id: 3,
    type: 'group.join_request',
    isRead: false,
    createdAt: t0.add(const Duration(minutes: 6)),
    pendingActionType: PendingActionType.groupJoinRequest,
    pendingActionId: 11,
  );
  final enrollmentOpportunity = _n(
    id: 4,
    type: 'enrollment.opened',
    isRead: false,
    createdAt: t0.add(const Duration(minutes: 5)),
    pendingActionType: PendingActionType.enrollmentOpportunity,
    pendingActionId: 12,
  );

  // Info bucket: neither pendingActionType nor broadcastId.
  final eventCancelled = _n(
    id: 5,
    type: 'event.cancelled',
    isRead: true,
    createdAt: t0.add(const Duration(minutes: 4)),
  );
  final occurrenceRescheduled = _n(
    id: 6,
    type: 'occurrence.rescheduled',
    isRead: false,
    createdAt: t0.add(const Duration(minutes: 3)),
  );
  final profileChanged = _n(
    id: 7,
    type: 'profile.changed_by_admin',
    isRead: true,
    createdAt: t0.add(const Duration(minutes: 2)),
  );
  final venueRenamed = _n(
    id: 8,
    type: 'venue.renamed',
    isRead: false,
    createdAt: t0.add(const Duration(minutes: 1)),
  );
  final attendanceMarked = _n(
    id: 9,
    type: 'attendance.marked',
    isRead: true,
    createdAt: t0.add(const Duration(seconds: 30)),
  );

  final all = {
    for (final n in [
      broadcastUnread,
      broadcastRead,
      groupJoinRequest,
      enrollmentOpportunity,
      eventCancelled,
      occurrenceRescheduled,
      profileChanged,
      venueRenamed,
      attendanceMarked,
    ])
      n.id: n,
  };

  group('read filter', () {
    test('all returns every row', () {
      final out = applyNotificationFilter(
        all,
        const NotificationFilter(),
      );
      expect(out.length, all.length);
    });

    test('unread drops read rows', () {
      final out = applyNotificationFilter(
        all,
        const NotificationFilter(read: NotificationReadFilter.unread),
      );
      expect(out.map((n) => n.id).toSet(), {
        broadcastUnread.id,
        groupJoinRequest.id,
        enrollmentOpportunity.id,
        occurrenceRescheduled.id,
        venueRenamed.id,
      });
    });
  });

  group('Issue 246: bucket-based type filter', () {
    test('broadcast matches rows with broadcastId set', () {
      final out = applyNotificationFilter(
        all,
        const NotificationFilter(type: NotificationTypeFilter.broadcast),
      );
      expect(out.map((n) => n.id).toSet(), {
        broadcastUnread.id,
        broadcastRead.id,
      });
    });

    test('actionPending matches rows with pendingActionType set', () {
      final out = applyNotificationFilter(
        all,
        const NotificationFilter(type: NotificationTypeFilter.actionPending),
      );
      expect(out.map((n) => n.id).toSet(), {
        groupJoinRequest.id,
        enrollmentOpportunity.id,
      });
    });

    test(
      'info matches rows with neither pendingActionType nor broadcastId',
      () {
        final out = applyNotificationFilter(
          all,
          const NotificationFilter(type: NotificationTypeFilter.info),
        );
        expect(out.map((n) => n.id).toSet(), {
          eventCancelled.id,
          occurrenceRescheduled.id,
          profileChanged.id,
          venueRenamed.id,
          attendanceMarked.id,
        });
      },
    );

    test('Issue 246: previously unreachable families '
        '(occurrence/profile/venue) are reachable via the info bucket', () {
      final out = applyNotificationFilter(
        all,
        const NotificationFilter(type: NotificationTypeFilter.info),
      );
      final ids = out.map((n) => n.id).toSet();
      expect(ids, contains(occurrenceRescheduled.id));
      expect(ids, contains(profileChanged.id));
      expect(ids, contains(venueRenamed.id));
    });

    test('Issue 246: buckets are mutually exclusive and exhaustive', () {
      final infoIds = applyNotificationFilter(
        all,
        const NotificationFilter(type: NotificationTypeFilter.info),
      ).map((n) => n.id).toSet();
      final actionIds = applyNotificationFilter(
        all,
        const NotificationFilter(type: NotificationTypeFilter.actionPending),
      ).map((n) => n.id).toSet();
      final broadcastIds = applyNotificationFilter(
        all,
        const NotificationFilter(type: NotificationTypeFilter.broadcast),
      ).map((n) => n.id).toSet();

      // Exclusivity: no row appears in more than one bucket.
      expect(infoIds.intersection(actionIds), isEmpty);
      expect(infoIds.intersection(broadcastIds), isEmpty);
      expect(actionIds.intersection(broadcastIds), isEmpty);

      // Exhaustiveness: union of buckets == every row.
      expect(infoIds.union(actionIds).union(broadcastIds), all.keys.toSet());
    });

    test('all matches every row', () {
      final out = applyNotificationFilter(
        all,
        const NotificationFilter(type: NotificationTypeFilter.all),
      );
      expect(out.length, all.length);
    });
  });

  group('combined filters + sort', () {
    test('result is sorted newest first regardless of map insertion order', () {
      final out = applyNotificationFilter(
        all,
        const NotificationFilter(),
      );
      for (var i = 1; i < out.length; i++) {
        expect(
          out[i - 1].createdAtUtc.isAfter(out[i].createdAtUtc) ||
              out[i - 1].createdAtUtc.isAtSameMomentAs(out[i].createdAtUtc),
          isTrue,
          reason:
              'Expected newest first; got ${out[i - 1].createdAtUtc} '
              'before ${out[i].createdAtUtc}',
        );
      }
    });

    test('unread + broadcast narrows to a single matching row', () {
      final out = applyNotificationFilter(
        all,
        const NotificationFilter(
          read: NotificationReadFilter.unread,
          type: NotificationTypeFilter.broadcast,
        ),
      );
      expect(out.map((n) => n.id), [broadcastUnread.id]);
    });

    test('combined filters return empty when no row matches', () {
      // Every actionPending row in the fixture is unread; flip the read
      // filter to "all" and the actionPending broadcast cross-section is
      // necessarily empty (a single row can't be in both buckets).
      final out = applyNotificationFilter(
        {broadcastRead.id: broadcastRead},
        const NotificationFilter(
          read: NotificationReadFilter.unread,
          type: NotificationTypeFilter.broadcast,
        ),
      );
      expect(out, isEmpty);
    });
  });
}
