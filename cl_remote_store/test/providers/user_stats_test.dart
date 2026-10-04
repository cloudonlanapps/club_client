import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_test/flutter_test.dart';

UserInfo _u(String username, UserStatus status) => UserInfo(
  username: username,
  displayName: username,
  status: status,
  isSuperAdmin: false,
  roles: const UserRoles(),
);

void main() {
  group('Issue 397: ClUserStatsData handles UserStatus.registered', () {
    test('countByStatus(registered) returns the registered count', () {
      final stats = ClUserStatsData.fromMap({
        'a1': _u('a1', UserStatus.active),
        'p1': _u('p1', UserStatus.pending),
        'r1': _u('r1', UserStatus.registered),
        'r2': _u('r2', UserStatus.registered),
        'b1': _u('b1', UserStatus.blocked),
        'l1': _u('l1', UserStatus.left),
      });

      expect(stats.total, 6);
      expect(stats.activeCount, 1);
      expect(stats.pendingCount, 1);
      expect(stats.blockedCount, 1);
      expect(stats.leftCount, 1);
      expect(stats.registeredCount, 2);

      expect(stats.countByStatus(UserStatus.active), 1);
      expect(stats.countByStatus(UserStatus.pending), 1);
      expect(stats.countByStatus(UserStatus.blocked), 1);
      expect(stats.countByStatus(UserStatus.left), 1);
      expect(stats.countByStatus(UserStatus.registered), 2);
    });

    test(
      'countByStatus returns 0 when no users of that status are present',
      () {
        final stats = ClUserStatsData.fromMap({
          'a1': _u('a1', UserStatus.active),
        });
        expect(stats.countByStatus(UserStatus.registered), 0);
        expect(stats.registeredCount, 0);
      },
    );

    test('defaults are all zero', () {
      const stats = ClUserStatsData();
      for (final s in UserStatus.values) {
        expect(stats.countByStatus(s), 0, reason: 'status=$s');
      }
    });
  });
}
