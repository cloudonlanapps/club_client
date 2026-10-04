import 'package:cl_club_members/src/utils/admin_user_actions.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_test/flutter_test.dart';

UserPrivate _user({
  required UserStatus status,
  DateTime? deletedAtUtc,
  bool isSuperAdmin = false,
}) {
  return UserPrivate(
    username: 'u',
    displayName: 'U',
    status: status,
    isSuperAdmin: isSuperAdmin,
    roles: const UserRoles(),
    createdAtUtc: DateTime.utc(2024),
    deletedAtUtc: deletedAtUtc,
  );
}

void main() {
  group('canMutateUser', () {
    test('Issue 248: returns true only for active, non-deleted users', () {
      expect(canMutateUser(_user(status: UserStatus.active)), isTrue);
      expect(canMutateUser(_user(status: UserStatus.pending)), isFalse);
      expect(canMutateUser(_user(status: UserStatus.blocked)), isFalse);
      expect(canMutateUser(_user(status: UserStatus.left)), isFalse);
      expect(
        canMutateUser(
          _user(
            status: UserStatus.active,
            deletedAtUtc: DateTime.utc(2025),
          ),
        ),
        isFalse,
      );
    });
  });

  group('adminActionsFor', () {
    List<String> keys(List<UserAdminAction> actions) =>
        actions.map((a) => a.key).toList();

    test('Issue 380: pending → review, delete', () {
      final actions = adminActionsFor(
        _user(status: UserStatus.pending),
        isSuperAdmin: false,
      );
      expect(keys(actions), ['review', 'delete']);
      expect(actions[0].label, 'Review');
    });

    test('Issue 248: active → block, markLeft, delete', () {
      final actions = adminActionsFor(
        _user(status: UserStatus.active),
        isSuperAdmin: false,
      );
      expect(keys(actions), ['block', 'markLeft', 'delete']);
    });

    test('Issue 248: blocked → unblock, delete', () {
      final actions = adminActionsFor(
        _user(status: UserStatus.blocked),
        isSuperAdmin: false,
      );
      expect(keys(actions), ['unblock', 'delete']);
    });

    test('Issue 248: left → reactivate, restore, delete', () {
      final actions = adminActionsFor(
        _user(status: UserStatus.left),
        isSuperAdmin: false,
      );
      expect(keys(actions), ['reactivate', 'restore', 'delete']);
    });

    test('Issue 402: registered → empty action list (no delete)', () {
      final actions = adminActionsFor(
        _user(status: UserStatus.registered),
        isSuperAdmin: false,
      );
      expect(keys(actions), <String>[]);
      expect(
        keys(
          adminActionsFor(
            _user(status: UserStatus.registered),
            isSuperAdmin: true,
          ),
        ),
        <String>[],
      );
    });

    test('Issue 248: soft-deleted → restore only for non-super-admin', () {
      final user = _user(
        status: UserStatus.active,
        deletedAtUtc: DateTime.utc(2025),
      );
      expect(
        keys(adminActionsFor(user, isSuperAdmin: false)),
        ['restore'],
      );
      expect(
        keys(adminActionsFor(user, isSuperAdmin: true)),
        ['restore', 'hardDelete'],
      );
    });
  });
}
