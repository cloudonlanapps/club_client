import 'package:cl_remote_store/src/providers/client.dart';
import 'package:cl_remote_store/src/providers/manual_refresh.dart';
import 'package:cl_remote_store/src/providers/my_join_requests_master.dart';
import 'package:cl_remote_store/src/providers/user_groups.dart';
import 'package:cl_remote_store/src/utils/uncertain_write.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Master provider for the groups a single user belongs to (explicit
/// memberships + matching auto groups).
///
/// Family-keyed by `username`. Mirrors the read-only data exposed by the
/// existing [clUserGroupsProvider] — that provider is now treated as the
/// admin-side surface (calls the admin endpoint) and this one is the
/// member-side surface backed by `/mygroups`. Mutations available here
/// are the member-side actions: submit a join request and cancel one.
final AsyncNotifierProviderFamily<ClMyGroupsMasterNotifier, List<Group>, String>
clMyGroupsMasterProvider =
    AsyncNotifierProvider.family<ClMyGroupsMasterNotifier, List<Group>, String>(
      ClMyGroupsMasterNotifier.new,
    );

class ClMyGroupsMasterNotifier
    extends FamilyAsyncNotifier<List<Group>, String> {
  @override
  Future<List<Group>> build(String username) async {
    ref.watch(clManualRefreshProvider);
    final client = await ref.watch(secureClientProvider.future);
    return client.myGroups.listGroups(username);
  }

  /// Submit a join request for a semi-auto group. The new
  /// [JoinRequest] is folded into [clMyJoinRequestsMasterProvider] so
  /// "My requests" updates without a refetch. Surfaces
  /// `AUTO_GROUP_NOT_JOINABLE` and other server errors to the caller.
  Future<JoinRequest> join(int groupId, {String? reason}) {
    return refetchIfWriteUncertain(() async {
      final client = await ref.read(secureClientProvider.future);
      final created = await client.myGroups.joinGroup(
        arg,
        groupId,
        reason: reason,
      );
      ref
          .read(clMyJoinRequestsMasterProvider(arg).notifier)
          .replaceLocally(created);
      return created;
    }, refetch: () => ref.invalidate(clMyJoinRequestsMasterProvider(arg)));
  }
}
