import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

UserInfo _user(
  String username, {
  bool admin = false,
  bool coach = false,
  bool superAdmin = false,
  UserStatus status = UserStatus.active,
}) => UserInfo(
  username: username,
  displayName: username,
  status: status,
  isSuperAdmin: superAdmin,
  roles: UserRoles(isAdmin: admin, isCoach: coach),
);

final Map<String, UserInfo> _users = {
  for (final u in [
    _user('admin1', admin: true),
    _user('root', superAdmin: true),
    _user('coach1', coach: true),
    _user('coach2', coach: true),
    _user('blockedcoach', coach: true, status: UserStatus.blocked),
    _user('alice'),
    _user('bob'),
    _user('carol'),
  ])
    u.username: u,
};

class _Users extends ClUsersMasterNotifier {
  @override
  Future<Map<String, UserInfo>> build() async => _users;
}

class _Events extends ClEventsMasterNotifier {
  @override
  Future<Map<int, Event>> build() async => {
    9: Event(
      id: 9,
      title: 'Camp',
      description: '',
      type: EventType.camp,
      visibility: Visibility.public,
      venueId: 1,
      organizerName: 'admin1',
      coachNames: const ['coach2', 'admin1'],
      startTimeUtc: DateTime.utc(2026),
      endTimeUtc: DateTime.utc(2026, 2),
      createdAtUtc: DateTime.utc(2026),
      updatedAtUtc: DateTime.utc(2026),
    ),
  };
}

class _Enrollments extends ClEnrollmentsMasterNotifier {
  @override
  Future<Map<String, EnrollmentStatus>> build(int arg) async => const {
    'alice': EnrollmentStatus.assigned,
    'bob': EnrollmentStatus.withdrawn,
    'carol': EnrollmentStatus.requested,
  };
}

ProviderContainer _container() {
  final c = ProviderContainer(
    overrides: [
      clUsersMasterProvider.overrideWith(_Users.new),
      clEventsMasterProvider.overrideWith(_Events.new),
      clEnrollmentsMasterProvider.overrideWith(_Enrollments.new),
      clGroupMembersProvider.overrideWith(
        (ref, groupId) async => const [
          GroupMember(membername: 'coach1'),
          GroupMember(membername: 'alice'),
          GroupMember(membername: 'root'),
        ],
      ),
    ],
  );
  addTearDown(c.dispose);
  return c;
}

void main() {
  group('Issue 252: Staff only', () {
    test(
      'Issue 252: all members narrows to every active coach and admin',
      () async {
        final staff = await _container().read(
          clBroadcastStaffProvider(const BroadcastScope.all()).future,
        );

        expect(staff, unorderedEquals(['admin1', 'root', 'coach1', 'coach2']));
      },
    );

    test(
      "Issue 252: a group narrows to the group's coaches and admins",
      () async {
        final staff = await _container().read(
          clBroadcastStaffProvider(const BroadcastScope.group(3)).future,
        );

        expect(staff, unorderedEquals(['coach1', 'root']));
      },
    );

    test(
      'Issue 252: an event narrows to its own organizer and coaches',
      () async {
        final staff = await _container().read(
          clBroadcastStaffProvider(const BroadcastScope.event(9)).future,
        );

        expect(staff, unorderedEquals(['admin1', 'coach2']));
      },
    );
  });

  group('Issue 252: Choose members offers the screen audience', () {
    test('Issue 252: all members offers every active member', () async {
      final members = await _container().read(
        clBroadcastMembersProvider(const BroadcastScope.all()).future,
      );

      expect(
        members.map((u) => u.username),
        unorderedEquals([
          'admin1',
          'root',
          'coach1',
          'coach2',
          'alice',
          'bob',
          'carol',
        ]),
      );
    });

    test('Issue 252: a group offers its members', () async {
      final members = await _container().read(
        clBroadcastMembersProvider(const BroadcastScope.group(3)).future,
      );

      expect(
        members.map((u) => u.username),
        unorderedEquals(['coach1', 'alice', 'root']),
      );
    });

    test(
      'Issue 252: an event offers its enrolled members and its staff',
      () async {
        final members = await _container().read(
          clBroadcastMembersProvider(const BroadcastScope.event(9)).future,
        );

        expect(
          members.map((u) => u.username),
          unorderedEquals(['alice', 'carol', 'admin1', 'coach2']),
        );
      },
    );
  });
}
