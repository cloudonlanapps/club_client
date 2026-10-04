import 'package:cl_remote_store/src/providers/client.dart';
import 'package:cl_remote_store/src/providers/current_user.dart';
import 'package:cl_remote_store/src/providers/manual_refresh.dart';
import 'package:cl_remote_store/src/providers/notifications_master.dart';
import 'package:cl_remote_store/src/providers/pending_actions_master.dart';
import 'package:cl_remote_store/src/utils/fetch_all_pages.dart';
import 'package:cl_remote_store/src/utils/uncertain_write.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Master provider for all user data.
///
/// Holds the canonical `Map<String, UserInfo>` state. All user mutations
/// (CRUD, status changes, role management) go through this notifier.
///
/// Fetch strategy depends on the logged-in user's role:
/// - Admin or Coach: load all users
/// - Member only: self only
final AsyncNotifierProvider<ClUsersMasterNotifier, Map<String, UserInfo>>
clUsersMasterProvider =
    AsyncNotifierProvider<ClUsersMasterNotifier, Map<String, UserInfo>>(
      ClUsersMasterNotifier.new,
    );

/// Notifier managing all user state and mutations.
class ClUsersMasterNotifier extends AsyncNotifier<Map<String, UserInfo>> {
  @override
  Future<Map<String, UserInfo>> build() async {
    ref.watch(clManualRefreshProvider);
    final client = await ref.watch(secureClientProvider.future);
    final currentUser = ref.watch(currentUserProvider);

    if (currentUser == null) return {};

    if (currentUser.isCoachOrAdmin) {
      final items = await fetchAllPages(
        client.users.getUsers,
      );
      // TODO(server-133): stop-gap — exclude pre-submission `registered`
      // users from admin lists until the server's `list_users` default
      // filter ships. Remove this filter once
      // server issue 133
      // lands.
      return {
        for (final u in items)
          if (u.status != UserStatus.registered) u.username: u,
      };
    }

    // Non-admin: just self.
    return {currentUser.username: currentUser};
  }

  // -- Create / Update / Delete -----------------------------------------------

  /// Create a new user.
  ///
  /// An admin-created user is always active: the server admits them
  /// directly, with no approval step.
  Future<UserPrivate> createUser({
    required String username,
    required String email,
    required String passwordHash,
    required String phone,
    required DateTime dateOfBirthUtc,
    required Gender gender,
    String? firstName,
    String? middleName,
    String? lastName,
    String? bio,
    String? achievements,
    String? emergencyContact,
    String? medicalNotes,
    Address? address,
  }) {
    return refetchIfWriteUncertain(() async {
      final client = await ref.read(secureClientProvider.future);
      final created = await client.users.createUser(
        username: username,
        email: email,
        passwordHash: passwordHash,
        phone: phone,
        dateOfBirthUtc: dateOfBirthUtc,
        gender: gender,
        firstName: firstName,
        middleName: middleName,
        lastName: lastName,
        bio: bio,
        achievements: achievements,
        emergencyContact: emergencyContact,
        medicalNotes: medicalNotes,
        address: address,
      );

      replaceLocally(created);
      return created;
    }, refetch: ref.invalidateSelf);
  }

  /// Update a user's profile.
  Future<UserPrivate> updateUser(
    String username, {
    String? email,
    String? Function()? firstName,
    String? Function()? middleName,
    String? Function()? lastName,
    String? Function()? phone,
    DateTime? Function()? dateOfBirthUtc,
    String? Function()? bio,
    String? Function()? achievements,
    String? Function()? emergencyContact,
    String? Function()? medicalNotes,
    String? Function()? nickname,
    bool? useNamePublicly,
    Gender? Function()? gender,
    Address? Function()? address,
    bool? isPublicProfile,
  }) {
    return refetchIfWriteUncertain(() async {
      final client = await ref.read(secureClientProvider.future);
      final updated = await client.users.updateUser(
        username,
        email: email,
        firstName: firstName,
        middleName: middleName,
        lastName: lastName,
        phone: phone,
        dateOfBirthUtc: dateOfBirthUtc,
        bio: bio,
        achievements: achievements,
        emergencyContact: emergencyContact,
        medicalNotes: medicalNotes,
        nickname: nickname,
        useNamePublicly: useNamePublicly,
        gender: gender,
        address: address,
        isPublicProfile: isPublicProfile,
      );

      replaceLocally(updated);
      return updated;
    }, refetch: ref.invalidateSelf);
  }

  /// Soft-delete a user.
  Future<void> deleteUser(String username) {
    return refetchIfWriteUncertain(() async {
      final client = await ref.read(secureClientProvider.future);
      await client.users.deleteUser(username);

      try {
        final refreshed = await client.users.getUserInfo(username);
        replaceLocally(refreshed);
      } on Exception catch (_) {
        removeLocally(username);
      }
    }, refetch: ref.invalidateSelf);
  }

  /// Restore a soft-deleted user.
  Future<UserPrivate> restoreUser(String username) {
    return refetchIfWriteUncertain(() async {
      final client = await ref.read(secureClientProvider.future);
      final restored = await client.users.restoreUser(username);
      replaceLocally(restored);
      return restored;
    }, refetch: ref.invalidateSelf);
  }

  /// Permanently delete a user (super admin only).
  Future<void> hardDeleteUser(String username) {
    return refetchIfWriteUncertain(() async {
      final client = await ref.read(secureClientProvider.future);
      await client.users.hardDeleteUser(username);
      removeLocally(username);
    }, refetch: ref.invalidateSelf);
  }

  // -- Status Mutations -------------------------------------------------------

  /// Approve a pending user (pending -> active).
  ///
  /// [resolutionReason] is recorded server-side as the closing note on the
  /// pending review record (SDK #376). Optional.
  Future<UserInfo> approveUser(
    String username, {
    String? resolutionReason,
  }) async {
    return statusMutation(
      username,
      expectedTo: UserStatus.active,
      action: (client) => client.users.approveUser(
        username,
        resolutionReason: resolutionReason,
      ),
    );
  }

  /// Block a user.
  ///
  /// [resolutionReason] is recorded server-side as the closing note when
  /// blocking from a pending review (SDK #376). Optional.
  Future<UserInfo> blockUser(
    String username, {
    String? resolutionReason,
  }) async {
    return statusMutation(
      username,
      expectedTo: UserStatus.blocked,
      action: (client) => client.users.blockUser(
        username,
        resolutionReason: resolutionReason,
      ),
    );
  }

  /// Send a pending user back for reconsideration with an admin note.
  ///
  /// Server transitions the user back to a state where they can act on the
  /// note and resubmit (SDK #376). [reason] is required.
  Future<UserInfo> reconsiderUser(String username, String reason) async {
    return statusMutation(
      username,
      expectedTo: UserStatus.registered,
      action: (client) => client.users.reconsiderUser(username, reason),
    );
  }

  /// Unblock a user (blocked -> active).
  Future<UserInfo> unblockUser(String username) async {
    return statusMutation(
      username,
      expectedTo: UserStatus.active,
      action: (client) => client.users.unblockUser(username),
    );
  }

  /// Mark a user as left.
  Future<UserInfo> markLeft(String username) async {
    return statusMutation(
      username,
      expectedTo: UserStatus.left,
      action: (client) => client.users.markLeft(username),
    );
  }

  /// Reactivate a user who left (left -> active).
  Future<UserInfo> reactivateUser(String username) async {
    return statusMutation(
      username,
      expectedTo: UserStatus.active,
      action: (client) => client.users.reactivateUser(username),
    );
  }

  /// Self-action: signal that the caller's application is complete and
  /// ready for admin review. Server flips status `registered` → `pending`
  /// and enqueues the `user_approval` admin notification (server #120).
  ///
  /// The returned `UserPrivate` carries the new status; per the
  /// CLAUDE.md "Auth Sync" rule, the calling widget is responsible for
  /// propagating it into `authStateProvider`.
  Future<UserPrivate> submitForReviewForSelf() {
    return refetchIfWriteUncertain(() async {
      final client = await ref.read(secureClientProvider.future);
      final updated = await client.users.submitForReview();
      replaceLocally(updated);
      return updated;
    }, refetch: ref.invalidateSelf);
  }

  /// Self-action: apply the user's edits to the registration fields after
  /// an admin reconsider request (server #122). Status stays `registered`
  /// and `adminReviewNote` clears to `null`. The caller must subsequently
  /// invoke [submitForReviewForSelf] to re-notify admins.
  ///
  /// Like [submitForReviewForSelf], the returned `UserPrivate` carries
  /// the updated server state; the calling widget propagates it into
  /// `authStateProvider`.
  Future<UserPrivate> reapplyForSelf({
    String? firstName,
    String? middleName,
    String? lastName,
    DateTime? dateOfBirthUtc,
    Gender? gender,
    String? phone,
    String? email,
  }) {
    return refetchIfWriteUncertain(() async {
      final client = await ref.read(secureClientProvider.future);
      final self = ref.read(currentUserProvider);
      if (self == null) {
        throw StateError('reapplyForSelf called without a logged-in user');
      }
      final updated = await client.users.reapply(
        self.username,
        firstName: firstName,
        middleName: middleName,
        lastName: lastName,
        dateOfBirthUtc: dateOfBirthUtc,
        gender: gender,
        phone: phone,
        email: email,
      );
      replaceLocally(updated);
      return updated;
    }, refetch: ref.invalidateSelf);
  }

  // -- Role Management --------------------------------------------------------

  /// Assign a role to a user.
  Future<UserInfo> assignRole(String username, String role) {
    return refetchIfWriteUncertain(() async {
      final client = await ref.read(secureClientProvider.future);
      final updated = await client.users.assignRole(username, role);
      replaceLocally(updated);
      return updated;
    }, refetch: ref.invalidateSelf);
  }

  /// Remove a role from a user.
  Future<UserInfo> removeRole(String username, String role) {
    return refetchIfWriteUncertain(() async {
      final client = await ref.read(secureClientProvider.future);
      final updated = await client.users.removeRole(username, role);
      replaceLocally(updated);
      return updated;
    }, refetch: ref.invalidateSelf);
  }

  /// Transfer super admin to another user.
  Future<UserInfo> transferSuperAdmin(String username) {
    return refetchIfWriteUncertain(() async {
      final client = await ref.read(secureClientProvider.future);
      final updated = await client.users.transferSuperAdmin(username);
      replaceLocally(updated);
      return updated;
    }, refetch: ref.invalidateSelf);
  }

  /// Admin resets a user's password (super admin only).
  Future<String> adminResetPassword(String username) async {
    final client = await ref.read(secureClientProvider.future);
    return client.users.adminResetPassword(username);
  }

  // -- Local State Helpers ----------------------------------------------------

  /// Replace or add a user in the master map.
  void replaceLocally(UserInfo updated) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData({...current, updated.username: updated});
  }

  /// Remove a user from the master map.
  void removeLocally(String username) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(Map.of(current)..remove(username));
  }

  /// Optimistic status mutation with revert on failure.
  Future<UserInfo> statusMutation(
    String username, {
    required UserStatus expectedTo,
    required Future<UserInfo> Function(SecureClient client) action,
  }) async {
    final current = state.valueOrNull;
    final existing = current?[username];

    // Optimistic update.
    if (existing != null) {
      replaceLocally(existing.copyWith(status: expectedTo));
    }

    try {
      final client = await ref.read(secureClientProvider.future);
      final serverResult = await action(client);
      replaceLocally(serverResult);
      // A status flip resolves any pending-action notification tied to
      // this user (server auto-dismisses); refresh both feeds so the
      // affected rows leave the UI without a manual refresh.
      ref
        ..invalidate(clPendingActionsMasterProvider)
        ..invalidate(clNotificationsMasterProvider);
      return serverResult;
    } catch (e) {
      // Revert on failure, then reload a change that may have landed
      // (club_core#138); the profile provider follows this master.
      if (existing != null) {
        replaceLocally(existing);
      }
      if (writeMayHaveLanded(e)) ref.invalidateSelf();
      rethrow;
    }
  }
}
