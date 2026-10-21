import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/foundation.dart';

/// Whether admin mutations (profile edits, role toggles, group membership)
/// should be allowed on this user. Only currently active, non-deleted users
/// are mutable — everyone else is read-only until a lifecycle action moves
/// them back to active.
bool canMutateUser(UserPrivate user) =>
    user.status == UserStatus.active && user.deletedAtUtc == null;

/// Why Block, Mark as Left and Delete are greyed out on the super admin:
/// the server refuses all three for them (club_client#224).
const String superAdminProtectedReason =
    "The super admin can't be blocked, marked as left or deleted.";

/// A lifecycle action the admin can apply to a user.
///
/// [key] is the stable identifier passed to status-action callbacks
/// (e.g. `'approve'`, `'block'`). [label] is the human label rendered on
/// the button. An action with a [reason] is shown greyed out with that
/// reason and is never tried.
@immutable
class UserAdminAction {
  const UserAdminAction({required this.key, required this.label, this.reason});

  final String key;
  final String label;

  /// Why the action is unavailable; `null` when it can be used.
  final String? reason;

  /// Whether the action can be used.
  bool get isAvailable => reason == null;

  /// This action, unavailable for [why].
  UserAdminAction unavailable(String why) =>
      UserAdminAction(key: key, label: label, reason: why);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserAdminAction &&
          other.key == key &&
          other.label == label &&
          other.reason == reason;

  @override
  int get hashCode => Object.hash(key, label, reason);

  @override
  String toString() =>
      'UserAdminAction(key: $key, label: $label, reason: $reason)';
}

/// The actions the server refuses on the super admin.
const _superAdminProtected = {'block', 'markLeft', 'delete'};

/// The set of lifecycle actions the admin can apply to [user], in the order
/// they should be presented.
///
/// Soft-deleted users (`deletedAtUtc != null`) surface Restore plus, for
/// super admins only, Hard Delete. Every other status follows the standard
/// lifecycle transition matrix, with Delete appended as the final action.
/// On the super admin, Block, Mark as Left and Delete carry
/// [superAdminProtectedReason].
List<UserAdminAction> adminActionsFor(
  UserPrivate user, {
  required bool isSuperAdmin,
}) {
  if (user.deletedAtUtc != null) {
    return [
      const UserAdminAction(key: 'restore', label: 'Restore'),
      if (isSuperAdmin)
        const UserAdminAction(key: 'hardDelete', label: 'Hard Delete'),
    ];
  }

  // Defensive — admins have nothing actionable on a `registered` user
  // until they submit for review. Returned before the trailing
  // 'delete' append so the list is genuinely empty.
  if (user.status == UserStatus.registered) {
    return const <UserAdminAction>[];
  }

  final actions = <UserAdminAction>[];
  switch (user.status) {
    case UserStatus.pending:
      // Pending users go through the dedicated AdminUserReviewView (#380)
      // — a single Review entry replaces the old inline Approve/Block.
      actions.add(const UserAdminAction(key: 'review', label: 'Review'));
    case UserStatus.active:
      actions
        ..add(const UserAdminAction(key: 'block', label: 'Block'))
        ..add(const UserAdminAction(key: 'markLeft', label: 'Mark as Left'));
    case UserStatus.blocked:
      actions.add(const UserAdminAction(key: 'unblock', label: 'Unblock'));
    case UserStatus.left:
      // Restore only undoes a delete (the server refuses it otherwise with
      // NOTHING_TO_RESTORE); a left member comes back through Reactivate.
      actions.add(
        const UserAdminAction(key: 'reactivate', label: 'Reactivate'),
      );
    case UserStatus.registered:
      // Handled by early return above.
      break;
  }
  actions.add(const UserAdminAction(key: 'delete', label: 'Delete'));
  if (!user.isSuperAdmin) return actions;
  return [
    for (final action in actions)
      if (_superAdminProtected.contains(action.key))
        action.unavailable(superAdminProtectedReason)
      else
        action,
  ];
}
