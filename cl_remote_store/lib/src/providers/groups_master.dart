import 'package:cl_remote_store/src/providers/client.dart';
import 'package:cl_remote_store/src/providers/current_user.dart';
import 'package:cl_remote_store/src/providers/group_members.dart';
import 'package:cl_remote_store/src/providers/manual_refresh.dart';
import 'package:cl_remote_store/src/providers/user_groups.dart';
import 'package:cl_remote_store/src/utils/fetch_all_pages.dart';
import 'package:cl_remote_store/src/utils/uncertain_write.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Master provider for all group data.
///
/// Holds the canonical `Map<int, Group>` state (active + deleted).
/// All group mutations go through this notifier. Membership mutations
/// cross-invalidate [clGroupMembersProvider] and [clUserGroupsProvider].
final AsyncNotifierProvider<ClGroupsMasterNotifier, Map<int, Group>>
clGroupsMasterProvider =
    AsyncNotifierProvider<ClGroupsMasterNotifier, Map<int, Group>>(
      ClGroupsMasterNotifier.new,
    );

/// Notifier managing all group state and mutations.
class ClGroupsMasterNotifier extends AsyncNotifier<Map<int, Group>> {
  @override
  Future<Map<int, Group>> build() async {
    ref.watch(clManualRefreshProvider);
    final client = await ref.watch(secureClientProvider.future);
    // Watched (not read) so the build re-runs when the role lands: during a
    // login transition the client may resolve before the admin role does, and
    // without this dependency the master would never refetch the deleted set.
    final currentUser = ref.watch(currentUserProvider);

    final active = await fetchAllPages(
      client.groups.getGroups,
    );

    // `GET /groups/deleted` is admin-only (`GET /groups` allows coaches too).
    // Fetching it unconditionally 403s for coaches and poisons the whole map —
    // and a transient 403 during a login race used to leave the list empty.
    // Only admins fetch the deleted set; others get the active groups alone.
    final deleted = (currentUser?.isAdmin ?? false)
        ? await fetchAllPages(client.groups.getDeletedGroups)
        : const <Group>[];

    return {
      for (final g in active) g.id: g,
      for (final g in deleted) g.id: g,
    };
  }

  // -- Create / Update / Delete -----------------------------------------------

  /// Create a new group.
  Future<Group> createGroup({
    required String name,
    String? description,
    DateTime? dobOnOrAfterUtc,
    DateTime? dobOnOrBeforeUtc,
    Gender? gender,
    bool? semiAuto,
  }) {
    return refetchIfWriteUncertain(() async {
      final client = await ref.read(secureClientProvider.future);
      final created = await client.groups.createGroup(
        name: name,
        description: description,
        dobOnOrAfterUtc: dobOnOrAfterUtc,
        dobOnOrBeforeUtc: dobOnOrBeforeUtc,
        gender: gender,
        semiAuto: semiAuto,
      );

      replaceLocally(created);
      return created;
    }, refetch: ref.invalidateSelf);
  }

  /// Update a group. Uses ValueGetter pattern for nullable fields.
  Future<Group> updateGroup(
    int id, {
    String? name,
    String? Function()? description,
    DateTime? Function()? dobOnOrAfterUtc,
    DateTime? Function()? dobOnOrBeforeUtc,
    Gender? Function()? gender,
    bool? semiAuto,
  }) {
    return refetchIfWriteUncertain(() async {
      final client = await ref.read(secureClientProvider.future);
      final updated = await client.groups.updateGroup(
        id,
        name: name,
        description: description,
        dobOnOrAfterUtc: dobOnOrAfterUtc,
        dobOnOrBeforeUtc: dobOnOrBeforeUtc,
        gender: gender,
        semiAuto: semiAuto,
      );

      replaceLocally(updated);
      return updated;
    }, refetch: ref.invalidateSelf);
  }

  /// Soft-delete a group.
  Future<void> deleteGroup(int id) {
    return refetchIfWriteUncertain(() async {
      final client = await ref.read(secureClientProvider.future);
      await client.groups.deleteGroup(id);

      try {
        final refreshed = await client.groups.getGroup(id);
        replaceLocally(refreshed);
      } on Exception catch (_) {
        removeLocally(id);
      }
    }, refetch: ref.invalidateSelf);
  }

  /// Restore a soft-deleted group.
  Future<Group> restoreGroup(int id) {
    return refetchIfWriteUncertain(() async {
      final client = await ref.read(secureClientProvider.future);
      final restored = await client.groups.restoreGroup(id);
      replaceLocally(restored);
      return restored;
    }, refetch: ref.invalidateSelf);
  }

  /// Permanently delete a group (super admin only).
  Future<void> hardDeleteGroup(int id) {
    return refetchIfWriteUncertain(() async {
      final client = await ref.read(secureClientProvider.future);
      await client.groups.hardDeleteGroup(id);
      removeLocally(id);
    }, refetch: ref.invalidateSelf);
  }

  // -- Membership Mutations ---------------------------------------------------

  /// Add a member to a group.
  Future<void> addMember(int groupId, String username) {
    return refetchIfWriteUncertain(() async {
      final client = await ref.read(secureClientProvider.future);
      await client.groups.addMember(groupId, username);
      ref
        ..invalidate(clGroupMembersProvider(groupId))
        ..invalidate(clUserGroupsProvider(username));
      await ref.read(clGroupMembersProvider(groupId).future);
    }, refetch: () => refetchMembership(groupId, [username]));
  }

  /// Remove a member from a group.
  Future<void> removeMember(int groupId, String username) {
    return refetchIfWriteUncertain(() async {
      final client = await ref.read(secureClientProvider.future);
      await client.groups.removeMember(groupId, username);
      ref
        ..invalidate(clGroupMembersProvider(groupId))
        ..invalidate(clUserGroupsProvider(username));
      await ref.read(clGroupMembersProvider(groupId).future);
    }, refetch: () => refetchMembership(groupId, [username]));
  }

  /// Add multiple members to a group.
  Future<BulkMembersResult> addMembersBulk(
    int groupId,
    List<String> membernames,
  ) {
    return refetchIfWriteUncertain(() async {
      final client = await ref.read(secureClientProvider.future);
      final result = await client.groups.addMembersBulk(groupId, membernames);
      ref.invalidate(clGroupMembersProvider(groupId));
      for (final username in membernames) {
        ref.invalidate(clUserGroupsProvider(username));
      }
      await ref.read(clGroupMembersProvider(groupId).future);
      return result;
    }, refetch: () => refetchMembership(groupId, membernames));
  }

  /// After a membership write that may have landed
  /// ([refetchIfWriteUncertain]): reload the group's members and each
  /// member's groups.
  void refetchMembership(int groupId, List<String> usernames) {
    ref.invalidate(clGroupMembersProvider(groupId));
    for (final username in usernames) {
      ref.invalidate(clUserGroupsProvider(username));
    }
  }

  // -- Local State Helpers ----------------------------------------------------

  /// Replace or add a group in the master map.
  void replaceLocally(Group group) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData({...current, group.id: group});
  }

  /// Remove a group from the master map.
  void removeLocally(int id) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(Map.of(current)..remove(id));
  }
}
