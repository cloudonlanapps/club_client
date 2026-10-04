import 'package:cl_club_communication/src/utils/notification_registry.dart';
import 'package:flutter_test/flutter_test.dart';

/// Per-family coverage of the muted `~Label` subtitle copy. Pairs with
/// `notification_formatter_test.dart` (body + icon) and
/// `notification_deep_link_test.dart` (tap target).
void main() {
  group('typeLabel — account.* family', () {
    test('password_changed_by_admin distinguishes from self change', () {
      expect(
        notificationTypeLabel('account.password_changed_by_admin'),
        'Password reset by admin',
      );
    });
    test('password_changed_self', () {
      expect(
        notificationTypeLabel('account.password_changed_self'),
        'Password changed',
      );
    });
    test('registration_approved', () {
      expect(
        notificationTypeLabel('account.registration_approved'),
        'Account approved',
      );
    });
  });

  group('typeLabel — profile.* family', () {
    test('changed_by_admin', () {
      expect(
        notificationTypeLabel('profile.changed_by_admin'),
        'Profile updated',
      );
    });
  });

  group('typeLabel — venue.* family', () {
    test('renamed', () {
      expect(notificationTypeLabel('venue.renamed'), 'Venue renamed');
    });
  });

  group('typeLabel — attendance.* scheduler family', () {
    test('absence_streak_warning', () {
      expect(
        notificationTypeLabel('attendance.absence_streak_warning'),
        'Absence streak',
      );
    });
    test('pending_mark_reminder', () {
      expect(
        notificationTypeLabel('attendance.pending_mark_reminder'),
        'Attendance pending',
      );
    });
  });

  group('typeLabel — group.* family additions', () {
    test('member_added reads from recipient perspective', () {
      // Recipient is always the new member; "Added to group" beats the
      // ambiguous third-person "Group member added".
      expect(notificationTypeLabel('group.member_added'), 'Added to group');
    });
  });

  group('typeLabel — event.* lifecycle extensions', () {
    test('deleted', () {
      expect(notificationTypeLabel('event.deleted'), 'Event deleted');
    });
    test('restored', () {
      expect(notificationTypeLabel('event.restored'), 'Event restored');
    });
    test('split', () {
      expect(notificationTypeLabel('event.split'), 'Event split');
    });
    test('conflict_detected reads as the situation, not a verb', () {
      expect(
        notificationTypeLabel('event.conflict_detected'),
        'Scheduling conflict',
      );
    });
    test('upcoming_reminder', () {
      expect(
        notificationTypeLabel('event.upcoming_reminder'),
        'Upcoming event',
      );
    });
  });
}
