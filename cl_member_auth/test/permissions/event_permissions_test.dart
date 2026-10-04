import 'package:cl_member_auth/cl_member_auth.dart'
    show canManageEnrollments, canManageEvent;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_test/flutter_test.dart';

const _organizer = 'the_organizer';
const _assignedCoach = 'assigned_coach';

Event _event() => Event(
  id: 1,
  title: 'A programme',
  description: '',
  type: EventType.programme,
  visibility: Visibility.public,
  venueId: 1,
  startTimeUtc: DateTime.utc(2026, 10),
  endTimeUtc: DateTime.utc(2026, 10, 1, 1),
  organizerName: _organizer,
  coachNames: const [_assignedCoach],
  createdAtUtc: DateTime.utc(2026),
  updatedAtUtc: DateTime.utc(2026),
);

UserPrivate _user(
  String username, {
  bool admin = false,
  bool coach = false,
  bool superAdmin = false,
}) => UserPrivate(
  username: username,
  displayName: username,
  status: UserStatus.active,
  isSuperAdmin: superAdmin,
  roles: UserRoles(isAdmin: admin, isCoach: coach),
  createdAtUtc: DateTime.utc(2026),
);

void main() {
  group('Issue 136: canManageEnrollments is organizer-or-admin', () {
    test('Issue 136: an admin may manage enrollments', () {
      expect(
        canManageEnrollments(_event(), _user('an_admin', admin: true)),
        isTrue,
      );
    });

    test('Issue 136: a super-admin may manage enrollments', () {
      expect(
        canManageEnrollments(_event(), _user('root', superAdmin: true)),
        isTrue,
      );
    });

    test('Issue 136: the organizer may manage enrollments', () {
      expect(
        canManageEnrollments(_event(), _user(_organizer, coach: true)),
        isTrue,
      );
    });

    test('Issue 136: a coach assigned to the event may not', () {
      expect(
        canManageEnrollments(_event(), _user(_assignedCoach, coach: true)),
        isFalse,
      );
    });

    test('Issue 136: a coach not on the event may not', () {
      expect(
        canManageEnrollments(_event(), _user('other_coach', coach: true)),
        isFalse,
      );
    });

    test('Issue 136: a member may not', () {
      expect(canManageEnrollments(_event(), _user('a_member')), isFalse);
    });
  });

  group('Issue 146: canManageEvent is organizer-or-admin', () {
    test('Issue 146: an admin may manage the event', () {
      expect(canManageEvent(_event(), _user('an_admin', admin: true)), isTrue);
    });

    test('Issue 146: a super-admin may manage the event', () {
      expect(
        canManageEvent(_event(), _user('root', superAdmin: true)),
        isTrue,
      );
    });

    test('Issue 146: the organizer may manage the event', () {
      expect(canManageEvent(_event(), _user(_organizer, coach: true)), isTrue);
    });

    test('Issue 146: a coach assigned to the event may not', () {
      expect(
        canManageEvent(_event(), _user(_assignedCoach, coach: true)),
        isFalse,
      );
    });

    test('Issue 146: a coach not on the event may not', () {
      expect(
        canManageEvent(_event(), _user('other_coach', coach: true)),
        isFalse,
      );
    });

    test('Issue 146: a member may not', () {
      expect(canManageEvent(_event(), _user('a_member')), isFalse);
    });
  });
}
