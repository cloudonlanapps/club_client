import 'package:cl_remote_store/src/providers/group_members.dart';
import 'package:cl_remote_store/src/providers/user_groups.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The ids of the groups a member belongs to but no longer meets the
/// criteria of (club_client#43). Keyed by username; for staff only, since
/// a group's member list is an admin-or-coach read.
///
/// Derived, with no call of its own: the member's group rows
/// ([clUserGroupsProvider]) carry only the group's count of such members,
/// so the member list ([clGroupMembersProvider], whose rows carry
/// `GroupMember.eligible`) is read for the semi-auto groups whose count is
/// above zero, and for no other group.
final AutoDisposeFutureProviderFamily<Set<int>, String>
clUserIneligibleGroupIdsProvider = FutureProvider.autoDispose
    .family<Set<int>, String>((ref, username) async {
      final groups = await ref.watch(clUserGroupsProvider(username).future);
      final ids = <int>{};
      for (final group in groups) {
        if (group.kind != GroupKind.semiAuto) continue;
        if (group.ineligibleMemberCount == 0) continue;
        final members = await ref.watch(
          clGroupMembersProvider(group.id).future,
        );
        final flagged = members.any(
          (m) => m.membername == username && !m.eligible,
        );
        if (flagged) ids.add(group.id);
      }
      return ids;
    });
