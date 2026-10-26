import 'package:cl_remote_store/src/providers/client.dart';
import 'package:cl_remote_store/src/providers/notifications_master.dart';
import 'package:cl_remote_store/src/providers/pending_actions_master.dart';
import 'package:cl_remote_store/src/providers/registered_users.dart';
import 'package:cl_remote_store/src/utils/uncertain_write.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The status mutations of `ClUsersMasterNotifier`: approve, block,
/// reconsider, unblock, mark left and reactivate a user. Each is optimistic
/// and reverts on failure ([statusMutation]).
mixin ClUsersStatusMutations on AsyncNotifier<Map<String, UserInfo>> {
  /// Replace or add a user in the master map.
  void replaceLocally(UserInfo updated);

  /// Remove a user from the master map.
  void removeLocally(String username);

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
  ///
  /// The user is then `registered`, which this master leaves out, so they
  /// are removed from it and [clRegisteredUsersProvider] refetches
  /// (club_client#233).
  Future<UserInfo> reconsiderUser(String username, String reason) async {
    final updated = await statusMutation(
      username,
      expectedTo: UserStatus.registered,
      action: (client) => client.users.reconsiderUser(username, reason),
    );
    removeLocally(username);
    ref.invalidate(clRegisteredUsersProvider);
    return updated;
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
      // (club_core#138); the profile provider follows this master. Only the
      // status this call set is undone, on the user as they are now, so a
      // change that completed meanwhile (a role) stays (club_client#235).
      final now = state.valueOrNull?[username];
      if (existing != null && now != null && now.status == expectedTo) {
        replaceLocally(now.copyWith(status: existing.status));
      }
      if (writeMayHaveLanded(e)) ref.invalidateSelf();
      rethrow;
    }
  }
}
