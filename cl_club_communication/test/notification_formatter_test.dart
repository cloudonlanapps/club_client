import 'package:cl_club_communication/src/utils/notification_formatter.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_test/flutter_test.dart';

AppNotification _make({
  required String type,
  Map<String, dynamic>? data,
  PendingActionType? pendingActionType,
}) {
  return AppNotification(
    id: 1,
    username: 'someone',
    type: type,
    channel: NotificationChannel.inApp,
    payload: <String, dynamic>{
      'v': 1,
      'type': type,
      'data': data ?? <String, dynamic>{},
    },
    pendingActionType: pendingActionType,
    isRead: false,
    createdAtUtc: DateTime.utc(2026, 5, 12, 10, 0, 0),
  );
}

void main() {
  group('formatNotification — group family', () {
    test('group.join_request renders requester + group name', () {
      final d = formatNotification(
        _make(
          type: 'group.join_request',
          data: {
            'groupId': 7,
            'groupName': 'U-14 Boys',
            'requesterUsername': 'asha',
          },
        ),
      );
      expect(d.title, 'U-14 Boys');
      expect(d.body, 'asha asked to join U-14 Boys.');
    });

    test('group.join_response uses outcome verb', () {
      final approved = formatNotification(
        _make(
          type: 'group.join_response',
          data: {
            'groupId': 7,
            'groupName': 'U-14 Boys',
            'outcome': 'approved',
          },
        ),
      );
      expect(approved.body, contains('approved'));

      final rejected = formatNotification(
        _make(
          type: 'group.join_response',
          data: {
            'groupId': 7,
            'groupName': 'U-14 Boys',
            'outcome': 'rejected',
          },
        ),
      );
      expect(rejected.body, contains('rejected'));
    });

    test('group.archived / group.member_removed / group.settings_changed', () {
      expect(
        formatNotification(
          _make(
            type: 'group.archived',
            data: {'groupId': 1, 'groupName': 'A'},
          ),
        ).body,
        contains('archived'),
      );
      expect(
        formatNotification(
          _make(
            type: 'group.member_removed',
            data: {'groupId': 1, 'groupName': 'A'},
          ),
        ).body,
        contains('removed from A'),
      );
      expect(
        formatNotification(
          _make(
            type: 'group.settings_changed',
            data: {
              'groupId': 1,
              'groupName': 'A',
              'changes': <String, dynamic>{},
            },
          ),
        ).body,
        contains('Settings changed'),
      );
    });
  });

  group('formatNotification — event family', () {
    test('event.cancelled appends reason when present', () {
      final withReason = formatNotification(
        _make(
          type: 'event.cancelled',
          data: {
            'eventId': 1,
            'eventTitle': 'Practice',
            'reason': 'rain',
            'effectiveTimeUtc': 0,
          },
        ),
      );
      expect(withReason.body, contains('Practice'));
      expect(withReason.body, contains('rain'));

      final noReason = formatNotification(
        _make(
          type: 'event.cancelled',
          data: {
            'eventId': 1,
            'eventTitle': 'Practice',
            'reason': '',
            'effectiveTimeUtc': 0,
          },
        ),
      );
      expect(noReason.body, 'Practice was cancelled.');
    });

    test('event.rescheduled', () {
      final d = formatNotification(
        _make(
          type: 'event.rescheduled',
          data: {
            'eventId': 1,
            'eventTitle': 'Practice',
            'changes': <String, dynamic>{},
          },
        ),
      );
      expect(d.body, 'Practice was rescheduled.');
    });

    test('event.venue_changed', () {
      final d = formatNotification(
        _make(
          type: 'event.venue_changed',
          data: {'eventId': 1, 'eventTitle': 'Practice', 'newVenueId': 2},
        ),
      );
      expect(d.body, 'Venue changed for Practice.');
    });

    test('event.coach_changed lists coach names', () {
      final d = formatNotification(
        _make(
          type: 'event.coach_changed',
          data: {
            'eventId': 1,
            'eventTitle': 'Practice',
            'coachNames': ['Coach A', 'Coach B'],
          },
        ),
      );
      expect(d.body, contains('Coach A, Coach B'));
    });
  });

  group('formatNotification — enrollment family', () {
    test('enrollment.opened / closed / rsvp', () {
      expect(
        formatNotification(
          _make(
            type: 'enrollment.opened',
            data: {'eventId': 1, 'eventTitle': 'Camp'},
          ),
        ).body,
        'Enrollment is open for Camp.',
      );
      expect(
        formatNotification(
          _make(
            type: 'enrollment.closed',
            data: {'eventId': 1, 'eventTitle': 'Camp'},
          ),
        ).body,
        'Enrollment closed for Camp.',
      );
      expect(
        formatNotification(
          _make(
            type: 'enrollment.rsvp',
            data: {
              'eventId': 1,
              'eventTitle': 'Camp',
              'memberUsername': 'aarav',
              'outcome': 'accepted',
            },
          ),
        ).body,
        contains('aarav'),
      );
    });

    test('enrollment.admin_enrolled trial flag changes copy', () {
      final trial = formatNotification(
        _make(
          type: 'enrollment.admin_enrolled',
          data: {'eventId': 1, 'eventTitle': 'Camp', 'trial': true},
        ),
      );
      expect(trial.body, contains('trial'));
      final real = formatNotification(
        _make(
          type: 'enrollment.admin_enrolled',
          data: {'eventId': 1, 'eventTitle': 'Camp', 'trial': false},
        ),
      );
      expect(real.body, isNot(contains('trial')));
    });

    test('enrollment.cancelled_admin / cancelled_self', () {
      expect(
        formatNotification(
          _make(
            type: 'enrollment.cancelled_admin',
            data: {'eventId': 1, 'eventTitle': 'Camp', 'reason': 'paused'},
          ),
        ).body,
        contains('paused'),
      );
      expect(
        formatNotification(
          _make(
            type: 'enrollment.cancelled_self',
            data: {'eventId': 1, 'eventTitle': 'Camp'},
          ),
        ).body,
        'You withdrew from Camp.',
      );
    });
  });

  group('formatNotification — attendance family', () {
    test('attendance.marked includes status when given', () {
      final d = formatNotification(
        _make(
          type: 'attendance.marked',
          data: {
            'eventId': 1,
            'occurrenceTimeUtc': 1700000000000,
            'memberUsername': 'aarav',
            'status': 'present',
          },
        ),
      );
      expect(d.body, contains('present'));
    });

    test('attendance.correction_requested', () {
      final d = formatNotification(
        _make(
          type: 'attendance.correction_requested',
          data: {
            'eventId': 1,
            'occurrenceTimeUtc': 1700000000000,
            'memberUsername': 'aarav',
            'reason': 'was there',
          },
          pendingActionType: PendingActionType.attendanceCorrection,
        ),
      );
      expect(d.body, contains('aarav'));
    });

    test('attendance.correction_response approved vs rejected', () {
      final approved = formatNotification(
        _make(
          type: 'attendance.correction_response',
          data: {
            'eventId': 1,
            'occurrenceTimeUtc': 1700000000000,
            'memberUsername': 'aarav',
            'outcome': 'approved',
          },
        ),
      );
      expect(approved.body, contains('approved'));

      final rejected = formatNotification(
        _make(
          type: 'attendance.correction_response',
          data: {
            'eventId': 1,
            'occurrenceTimeUtc': 1700000000000,
            'memberUsername': 'aarav',
            'outcome': 'rejected',
          },
        ),
      );
      expect(rejected.body, contains('rejected'));
    });
  });

  group('formatNotification — defensive', () {
    test('unknown type falls back to generic line with raw type', () {
      final d = formatNotification(_make(type: 'something.weird'));
      expect(d.title, 'Notification');
      expect(d.body, contains('something.weird'));
    });

    test('missing data does not throw and yields a non-empty sentence', () {
      final d = formatNotification(
        AppNotification(
          id: 1,
          username: 'u',
          type: 'group.join_request',
          channel: NotificationChannel.inApp,
          payload: const <String, dynamic>{},
          isRead: false,
          createdAtUtc: DateTime.utc(2026, 1, 1),
        ),
      );
      expect(d.body, isNotEmpty);
    });

    test('broadcast.text uses the text field as body', () {
      final d = formatNotification(
        _make(
          type: 'broadcast.text',
          data: {'text': 'Practice cancelled tomorrow.'},
        ),
      );
      expect(d.body, 'Practice cancelled tomorrow.');
    });

    test(
      'broadcast.message (server-emitted type) uses the text field as body',
      () {
        final d = formatNotification(
          _make(
            type: 'broadcast.message',
            data: {'text': 'Practice cancelled tomorrow.'},
          ),
        );
        expect(d.title, 'Announcement');
        expect(d.body, 'Practice cancelled tomorrow.');
      },
    );

    test(
      'broadcast.message with empty text falls back to announcement copy',
      () {
        final d = formatNotification(
          _make(
            type: 'broadcast.message',
            data: <String, dynamic>{},
          ),
        );
        expect(d.title, 'Announcement');
        expect(d.body, 'New announcement.');
        expect(d.body, isNot(contains('broadcast.message')));
      },
    );
  });

  group('formatNotification — account family', () {
    test('password_changed_by_admin with actor', () {
      final d = formatNotification(
        _make(
          type: 'account.password_changed_by_admin',
          data: {'actorUsername': 'asha'},
        ),
      );
      expect(d.body, contains('@asha'));
      expect(d.body, contains('new password'));
    });

    test('password_changed_by_admin without actor', () {
      final d = formatNotification(
        _make(type: 'account.password_changed_by_admin'),
      );
      expect(d.body, contains('admin changed your password'));
      expect(d.body, isNot(contains('@')));
    });

    test('password_changed_self has fixed copy', () {
      expect(
        formatNotification(_make(type: 'account.password_changed_self')).body,
        'Your password was changed.',
      );
    });

    test('registration_approved has fixed copy', () {
      expect(
        formatNotification(_make(type: 'account.registration_approved')).body,
        contains('approved'),
      );
    });
  });

  group('formatNotification — profile family', () {
    test('changed_by_admin lists the changed field names', () {
      final d = formatNotification(
        _make(
          type: 'profile.changed_by_admin',
          data: {
            'actorUsername': 'admin',
            'changedFields': ['email', 'phone'],
          },
        ),
      );
      expect(d.body, contains('@admin'));
      expect(d.body, contains('email'));
      expect(d.body, contains('phone'));
    });

    test('changed_by_admin without fields falls back', () {
      final d = formatNotification(_make(type: 'profile.changed_by_admin'));
      expect(d.body, 'An admin updated your profile.');
    });
  });

  group('formatNotification — occurrence family', () {
    test('rescheduled with eventTitle and occurrenceTimeUtc', () {
      final d = formatNotification(
        _make(
          type: 'occurrence.rescheduled',
          data: {
            'eventTitle': 'Practice',
            'occurrenceTimeUtc': 1700000000000,
            'changes': <String, dynamic>{},
          },
        ),
      );
      expect(d.body, contains('Practice'));
      expect(d.body, contains('rescheduled'));
    });

    test('cancelled appends reason', () {
      final d = formatNotification(
        _make(
          type: 'occurrence.cancelled',
          data: {
            'eventTitle': 'Practice',
            'occurrenceTimeUtc': 1700000000000,
            'reason': 'rain',
          },
        ),
      );
      expect(d.body, contains('rain'));
      expect(d.body, contains('cancelled'));
    });

    test('restored has its own copy', () {
      final d = formatNotification(
        _make(
          type: 'occurrence.restored',
          data: {
            'eventTitle': 'Practice',
            'occurrenceTimeUtc': 1700000000000,
          },
        ),
      );
      expect(d.body, contains('on again'));
    });

    test('missing occurrenceTimeUtc still renders', () {
      final d = formatNotification(
        _make(
          type: 'occurrence.cancelled',
          data: {'eventTitle': 'Practice'},
        ),
      );
      expect(d.body, contains('Practice'));
      expect(d.body, contains('cancelled'));
    });
  });

  group('formatNotification — event lifecycle', () {
    test('event.deleted / restored / split each render', () {
      for (final entry in {
        'event.deleted': 'deleted',
        'event.restored': 'back on the schedule',
        'event.split': 'split',
      }.entries) {
        final d = formatNotification(
          _make(
            type: entry.key,
            data: {'eventTitle': 'Practice'},
          ),
        );
        expect(
          d.body,
          contains(entry.value),
          reason: '"${entry.key}" body did not contain expected fragment.',
        );
      }
    });

    test('event.conflict_detected counts conflicts', () {
      final d = formatNotification(
        _make(
          type: 'event.conflict_detected',
          data: {
            'eventTitle': 'Practice',
            'conflictingEvents': [
              {'eventId': 1},
              {'eventId': 2},
            ],
          },
        ),
      );
      expect(d.body, contains('2'));
      expect(d.body, contains('Practice'));
    });

    test('event.upcoming_reminder formats lead time', () {
      expect(
        formatNotification(
          _make(
            type: 'event.upcoming_reminder',
            data: {'eventTitle': 'Practice', 'leadHours': 1},
          ),
        ).body,
        contains('in 1 hour'),
      );
      expect(
        formatNotification(
          _make(
            type: 'event.upcoming_reminder',
            data: {'eventTitle': 'Practice', 'leadHours': 24},
          ),
        ).body,
        contains('in 24 hours'),
      );
      expect(
        formatNotification(
          _make(
            type: 'event.upcoming_reminder',
            data: {'eventTitle': 'Practice'},
          ),
        ).body,
        contains('soon'),
      );
    });
  });

  group('formatNotification — group.member_added', () {
    test('with actor', () {
      final d = formatNotification(
        _make(
          type: 'group.member_added',
          data: {'groupName': 'U-14', 'addedByUsername': 'coach'},
        ),
      );
      expect(d.body, 'You were added to U-14 by @coach.');
    });

    test('without actor', () {
      final d = formatNotification(
        _make(
          type: 'group.member_added',
          data: {'groupName': 'U-14'},
        ),
      );
      expect(d.body, 'You were added to U-14.');
    });
  });

  group('formatNotification — venue.renamed', () {
    test('with both names and affectedEventIds', () {
      final d = formatNotification(
        _make(
          type: 'venue.renamed',
          data: {
            'oldName': 'Rink A',
            'newName': 'Main Rink',
            'affectedEventIds': [1, 2, 3],
          },
        ),
      );
      expect(d.body, contains('Rink A → Main Rink'));
      expect(d.body, contains('3'));
    });

    test('without affected events', () {
      final d = formatNotification(
        _make(
          type: 'venue.renamed',
          data: {'oldName': 'A', 'newName': 'B'},
        ),
      );
      expect(d.body, contains('A → B'));
      expect(d.body, isNot(contains('Affects')));
    });

    test('with empty payload falls back', () {
      expect(
        formatNotification(_make(type: 'venue.renamed')).body,
        'Venue renamed.',
      );
    });
  });

  group('formatNotification — user family', () {
    test(
      'Issue 381: user.registration_pending renders '
      '"<First> <Last> (@<username>) registered and is awaiting approval."',
      () {
        final d = formatNotification(
          _make(
            type: 'user.registration_pending',
            data: {
              'username': 'asha',
              'firstName': 'Asha',
              'lastName': 'Rao',
            },
          ),
        );
        expect(
          d.body,
          'Asha Rao (@asha) registered and is awaiting approval.',
        );
      },
    );

    test(
      'Issue 381: user.registration_pending title-cases lowercase names '
      'from the server',
      () {
        final d = formatNotification(
          _make(
            type: 'user.registration_pending',
            data: {
              'username': 'asha',
              'firstName': 'asha',
              'lastName': 'rao',
            },
          ),
        );
        expect(
          d.body,
          'Asha Rao (@asha) registered and is awaiting approval.',
        );
      },
    );

    test(
      'Issue 381: user.registration_pending falls back cleanly to '
      '"@<username> registered…" when names are missing (no stray spaces)',
      () {
        final d = formatNotification(
          _make(
            type: 'user.registration_pending',
            data: {'username': 'asha'},
          ),
        );
        expect(d.body, '@asha registered and is awaiting approval.');
      },
    );

    test(
      'Issue 381: user.registration_pending handles blank-string names '
      '(no double-space, no empty parens)',
      () {
        final d = formatNotification(
          _make(
            type: 'user.registration_pending',
            data: {
              'username': 'asha',
              'firstName': '',
              'lastName': '',
            },
          ),
        );
        expect(d.body, '@asha registered and is awaiting approval.');
      },
    );

    test('user.blocked includes reason when present', () {
      expect(
        formatNotification(_make(type: 'user.blocked')).body,
        'Your account was blocked.',
      );
      expect(
        formatNotification(
          _make(
            type: 'user.blocked',
            data: {'reason': 'spam'},
          ),
        ).body,
        'Your account was blocked: spam.',
      );
    });

    test('user.unblocked / user.restored have fixed copy', () {
      expect(
        formatNotification(_make(type: 'user.unblocked')).body,
        'Your account was unblocked.',
      );
      expect(
        formatNotification(_make(type: 'user.restored')).body,
        'Your account was restored.',
      );
    });

    test('user.role_changed: added only', () {
      final d = formatNotification(
        _make(
          type: 'user.role_changed',
          data: {
            'added': ['admin'],
            'removed': <String>[],
          },
        ),
      );
      expect(d.body, 'You were granted: admin.');
    });

    test('user.role_changed: removed only', () {
      final d = formatNotification(
        _make(
          type: 'user.role_changed',
          data: {
            'added': <String>[],
            'removed': ['coach'],
          },
        ),
      );
      expect(d.body, 'You no longer have: coach.');
    });

    test('user.role_changed: both added and removed', () {
      final d = formatNotification(
        _make(
          type: 'user.role_changed',
          data: {
            'added': ['admin'],
            'removed': ['coach'],
          },
        ),
      );
      expect(d.body, contains('+admin'));
      expect(d.body, contains('coach'));
    });

    test('user.role_changed: only newRoles given', () {
      final d = formatNotification(
        _make(
          type: 'user.role_changed',
          data: {
            'newRoles': ['admin', 'coach'],
          },
        ),
      );
      expect(d.body, contains('admin'));
      expect(d.body, contains('coach'));
    });

    test('user.role_changed: empty payload falls back to generic line', () {
      final d = formatNotification(_make(type: 'user.role_changed'));
      expect(d.body, 'Your roles were updated.');
    });

    test('user.deleted uses @username when present', () {
      expect(
        formatNotification(
          _make(
            type: 'user.deleted',
            data: {'username': 'asha'},
          ),
        ).body,
        '@asha was deleted.',
      );
      expect(
        formatNotification(_make(type: 'user.deleted')).body,
        'A user account was deleted.',
      );
    });
  });

  group('formatNotification — attendance scheduler', () {
    test('absence_streak_warning includes streak length', () {
      final d = formatNotification(
        _make(
          type: 'attendance.absence_streak_warning',
          data: {'streakLength': 3},
        ),
      );
      expect(d.body, contains('3 sessions'));
    });

    test('absence_streak_warning without streak still renders', () {
      final d = formatNotification(
        _make(
          type: 'attendance.absence_streak_warning',
        ),
      );
      expect(d.body, contains('several sessions'));
    });

    test('pending_mark_reminder includes event and occurrence', () {
      final d = formatNotification(
        _make(
          type: 'attendance.pending_mark_reminder',
          data: {
            'eventTitle': 'Practice',
            'occurrenceTimeUtc': 1700000000000,
          },
        ),
      );
      expect(d.body, contains('Practice'));
      expect(d.body, contains('not yet marked'));
    });
  });

  group('registry coverage', () {
    test('every formatter row is reachable through formatNotification', () {
      for (final type in kNotificationFormatters.keys) {
        final d = formatNotification(_make(type: type));
        expect(
          d.body,
          isNotEmpty,
          reason: 'Registry row for "$type" produced an empty body.',
        );
      }
    });

    test('unimplemented types fall through to the generic line', () {
      for (final type in kKnownUnimplementedTypes) {
        expect(
          kNotificationFormatters.containsKey(type),
          isFalse,
          reason:
              '"$type" is listed as unimplemented but a formatter row exists. '
              'Remove it from kKnownUnimplementedTypes when wiring the row.',
        );
        final d = formatNotification(_make(type: type));
        expect(d.title, 'Notification');
        expect(d.body, contains(type));
      }
    });
  });
}
