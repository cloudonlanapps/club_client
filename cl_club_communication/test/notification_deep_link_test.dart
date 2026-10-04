import 'package:cl_club_communication/src/utils/notification_deep_link.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_test/flutter_test.dart';

AppNotification _make({
  required String type,
  Map<String, dynamic>? data,
  int id = 42,
}) {
  return AppNotification(
    id: id,
    username: 'me',
    type: type,
    channel: NotificationChannel.inApp,
    payload: <String, dynamic>{
      'v': 1,
      'type': type,
      'data': data ?? <String, dynamic>{},
    },
    isRead: false,
    createdAtUtc: DateTime.utc(2026, 5, 12),
  );
}

void main() {
  test('group.join_request → admin group link (admin-perspective)', () {
    final link = resolveDeepLink(
      _make(
        type: 'group.join_request',
        data: {'groupId': 7, 'groupName': 'A', 'requesterUsername': 'asha'},
      ),
      currentUsername: 'admin',
    );
    expect(link, isA<NotifGroupLink>());
    expect((link! as NotifGroupLink).groupId, 7);
    expect(link.sourceNotificationId, 42);
  });

  test('my-event link carries sourceNotificationId', () {
    final link = resolveDeepLink(
      _make(type: 'event.cancelled', data: {'eventId': 9, 'eventTitle': 'X'}),
      currentUsername: 'me',
    );
    expect(link, isA<NotifMyEventLink>());
    final myLink = link! as NotifMyEventLink;
    expect(myLink.eventId, 9);
    expect(myLink.username, 'me');
    expect(myLink.sourceNotificationId, 42);
  });

  test('admin-event link (rsvp) carries sourceNotificationId', () {
    final link = resolveDeepLink(
      _make(type: 'enrollment.rsvp', data: {'eventId': 11}, id: 99),
      currentUsername: 'admin',
    );
    expect(link, isA<NotifEventLink>());
    final eLink = link! as NotifEventLink;
    expect(eLink.eventId, 11);
    expect(eLink.sourceNotificationId, 99);
  });

  test(
    'occurrence link (admin attendance roster) carries sourceNotificationId',
    () {
      // attendance.correction_requested is admin-perspective (staff get
      // notified that a member asked for a correction) so it still routes to
      // the admin occurrence roster.
      final link = resolveDeepLink(
        _make(
          type: 'attendance.correction_requested',
          data: {
            'eventId': 3,
            'occurrenceTimeUtc': 1700000000000,
            'memberUsername': 'asha',
          },
          id: 7,
        ),
        currentUsername: 'admin',
      );
      expect(link, isA<NotifOccurrenceLink>());
      final occ = link! as NotifOccurrenceLink;
      expect(occ.eventId, 3);
      expect(occ.sourceNotificationId, 7);
    },
  );

  test('Issue 179: attendance.marked → my-event link, not admin roster '
      '(member-perspective)', () {
    final link = resolveDeepLink(
      _make(
        type: 'attendance.marked',
        data: {
          'eventId': 3,
          'occurrenceTimeUtc': 1700000000000,
          'status': 'present',
        },
        id: 11,
      ),
      currentUsername: 'asha',
    );
    expect(
      link,
      isA<NotifMyEventLink>(),
      reason:
          'Members must not be deep-linked into the admin-only '
          'attendance roster (was the cause of the 403 in #179).',
    );
    final l = link! as NotifMyEventLink;
    expect(l.eventId, 3);
    expect(l.username, 'asha');
    expect(l.sourceNotificationId, 11);
  });

  test('Issue 179: attendance.correction_response → my-event link '
      '(member-perspective)', () {
    final link = resolveDeepLink(
      _make(
        type: 'attendance.correction_response',
        data: {
          'eventId': 4,
          'occurrenceTimeUtc': 1700000000000,
          'outcome': 'approved',
        },
        id: 12,
      ),
      currentUsername: 'asha',
    );
    expect(link, isA<NotifMyEventLink>());
    final l = link! as NotifMyEventLink;
    expect(l.eventId, 4);
    expect(l.username, 'asha');
  });

  test('Issue 179: admin-perspective attendance notifications still use the '
      'admin occurrence roster', () {
    for (final type in [
      'attendance.correction_requested',
      'attendance.pending_mark_reminder',
    ]) {
      final link = resolveDeepLink(
        _make(
          type: type,
          data: {'eventId': 1, 'occurrenceTimeUtc': 1700000000000},
        ),
        currentUsername: 'admin',
      );
      expect(
        link,
        isA<NotifOccurrenceLink>(),
        reason:
            '"$type" is staff-targeted and must continue to route to '
            'the admin attendance roster.',
      );
    }
  });

  test('missing target id returns null (no link, no notif id leaked)', () {
    final link = resolveDeepLink(
      _make(type: 'group.join_request'),
      currentUsername: 'admin',
    );
    expect(link, isNull);
  });

  group('user-family links', () {
    test(
      'Issue 381: user.registration_pending → admin user review link '
      '(routes to AdminUserReviewView, not the regular profile)',
      () {
        final link = resolveDeepLink(
          _make(
            type: 'user.registration_pending',
            data: {'username': 'asha'},
            id: 31,
          ),
          currentUsername: 'admin',
        );
        expect(link, isA<NotifAdminUserReviewLink>());
        final l = link! as NotifAdminUserReviewLink;
        expect(l.username, 'asha');
        expect(l.sourceNotificationId, 31);
      },
    );

    test('user.deleted → admin user link (admins receive this)', () {
      final link = resolveDeepLink(
        _make(
          type: 'user.deleted',
          data: {'username': 'asha'},
          id: 32,
        ),
        currentUsername: 'admin',
      );
      expect(link, isA<NotifAdminUserLink>());
      expect((link! as NotifAdminUserLink).username, 'asha');
    });

    test('user.registration_pending with missing username returns null', () {
      final link = resolveDeepLink(
        _make(type: 'user.registration_pending'),
        currentUsername: 'admin',
      );
      expect(link, isNull);
    });

    test('user.blocked → self profile link', () {
      final link = resolveDeepLink(
        _make(type: 'user.blocked', id: 12),
        currentUsername: 'me',
      );
      expect(link, isA<NotifSelfProfileLink>());
      expect(link!.sourceNotificationId, 12);
    });

    test(
      'user.unblocked / user.role_changed / user.restored → self profile',
      () {
        for (final type in [
          'user.unblocked',
          'user.role_changed',
          'user.restored',
        ]) {
          final link = resolveDeepLink(
            _make(type: type),
            currentUsername: 'me',
          );
          expect(
            link,
            isA<NotifSelfProfileLink>(),
            reason: '"$type" did not resolve to self profile.',
          );
        }
      },
    );
  });

  group('new per-family links', () {
    test('account.* and profile.changed_by_admin → self profile', () {
      for (final type in [
        'account.password_changed_by_admin',
        'account.password_changed_self',
        'account.registration_approved',
        'profile.changed_by_admin',
      ]) {
        final link = resolveDeepLink(_make(type: type), currentUsername: 'me');
        expect(
          link,
          isA<NotifSelfProfileLink>(),
          reason: '"$type" did not resolve to self profile.',
        );
      }
    });

    test('occurrence.* → my-event link with currentUsername', () {
      final link = resolveDeepLink(
        _make(
          type: 'occurrence.rescheduled',
          data: {'eventId': 9, 'eventTitle': 'X', 'occurrenceTimeUtc': 1},
          id: 33,
        ),
        currentUsername: 'me',
      );
      expect(link, isA<NotifMyEventLink>());
      final l = link! as NotifMyEventLink;
      expect(l.eventId, 9);
      expect(l.username, 'me');
      expect(l.sourceNotificationId, 33);
    });

    test('event.deleted/restored/split/upcoming_reminder → my-event link', () {
      for (final type in [
        'event.deleted',
        'event.restored',
        'event.split',
        'event.upcoming_reminder',
      ]) {
        final link = resolveDeepLink(
          _make(type: type, data: {'eventId': 1, 'eventTitle': 'X'}),
          currentUsername: 'me',
        );
        expect(
          link,
          isA<NotifMyEventLink>(),
          reason: '"$type" did not resolve to my-event link.',
        );
      }
    });

    test('event.conflict_detected → admin event link', () {
      final link = resolveDeepLink(
        _make(
          type: 'event.conflict_detected',
          data: {'eventId': 7, 'eventTitle': 'X'},
        ),
        currentUsername: 'admin',
      );
      expect(link, isA<NotifEventLink>());
      expect((link! as NotifEventLink).eventId, 7);
    });

    test(
      'Issue 177: group.member_added → my-groups link (member-perspective)',
      () {
        final link = resolveDeepLink(
          _make(
            type: 'group.member_added',
            data: {'groupId': 5, 'groupName': 'U-14'},
            id: 99,
          ),
          currentUsername: 'asha',
        );
        expect(
          link,
          isA<NotifMyGroupsLink>(),
          reason:
              'Members must not be deep-linked into the admin-only '
              'group profile (was the cause of the 403 in #177).',
        );
        final l = link! as NotifMyGroupsLink;
        expect(l.username, 'asha');
        expect(l.sourceNotificationId, 99);
      },
    );

    test('Issue 177: group.join_response / archived / member_removed / '
        'settings_changed → my-groups link', () {
      for (final type in [
        'group.join_response',
        'group.archived',
        'group.member_removed',
        'group.settings_changed',
      ]) {
        final link = resolveDeepLink(
          _make(type: type, data: {'groupId': 1, 'groupName': 'G'}),
          currentUsername: 'asha',
        );
        expect(
          link,
          isA<NotifMyGroupsLink>(),
          reason:
              '"$type" must route members to /my-groups, not the '
              'admin group profile.',
        );
        expect((link! as NotifMyGroupsLink).username, 'asha');
      }
    });

    test('Issue 177: group.member_added resolves even with no groupId '
        '(list view does not need group identity)', () {
      final link = resolveDeepLink(
        _make(type: 'group.member_added'),
        currentUsername: 'asha',
      );
      expect(link, isA<NotifMyGroupsLink>());
      expect((link! as NotifMyGroupsLink).username, 'asha');
    });

    test('venue.renamed → venue link', () {
      final link = resolveDeepLink(
        _make(
          type: 'venue.renamed',
          data: {'venueId': 11, 'oldName': 'A', 'newName': 'B'},
        ),
        currentUsername: 'admin',
      );
      expect(link, isA<NotifVenueLink>());
      expect((link! as NotifVenueLink).venueId, 11);
    });

    test('venue.renamed without venueId returns null', () {
      final link = resolveDeepLink(
        _make(type: 'venue.renamed'),
        currentUsername: 'admin',
      );
      expect(link, isNull);
    });

    test('attendance.absence_streak_warning → my-events home link', () {
      final link = resolveDeepLink(
        _make(
          type: 'attendance.absence_streak_warning',
          data: {'streakLength': 3},
          id: 42,
        ),
        currentUsername: 'asha',
      );
      expect(link, isA<NotifMyEventsHomeLink>());
      final l = link! as NotifMyEventsHomeLink;
      expect(l.username, 'asha');
      expect(l.sourceNotificationId, 42);
    });

    test('attendance.pending_mark_reminder → occurrence link', () {
      final link = resolveDeepLink(
        _make(
          type: 'attendance.pending_mark_reminder',
          data: {'eventId': 9, 'occurrenceTimeUtc': 1700000000000},
        ),
        currentUsername: 'admin',
      );
      expect(link, isA<NotifOccurrenceLink>());
    });
  });
}
