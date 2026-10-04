import 'package:cl_remote_store/src/providers/client.dart';
import 'package:cl_remote_store/src/providers/group_members.dart';
import 'package:cl_remote_store/src/providers/manual_refresh.dart';
import 'package:cl_remote_store/src/providers/notifications_master.dart';
import 'package:cl_remote_store/src/providers/pending_actions_master.dart';
import 'package:cl_remote_store/src/providers/user_groups.dart';
import 'package:cl_remote_store/src/utils/uncertain_write.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Master provider for join requests on a single group.
///
/// Family-keyed by `groupId`. Holds the canonical
/// `Map<int, JoinRequest>` (keyed by `requestId`) of every request on
/// that group, regardless of status, so the admin triage view can
/// client-side filter without re-hitting the server. Mutations
/// (approve / reject) update local state with the server response.
final AsyncNotifierProviderFamily<
  ClGroupRequestsMasterNotifier,
  Map<int, JoinRequest>,
  int
>
clGroupRequestsMasterProvider =
    AsyncNotifierProvider.family<
      ClGroupRequestsMasterNotifier,
      Map<int, JoinRequest>,
      int
    >(
      ClGroupRequestsMasterNotifier.new,
    );

class ClGroupRequestsMasterNotifier
    extends FamilyAsyncNotifier<Map<int, JoinRequest>, int> {
  @override
  Future<Map<int, JoinRequest>> build(int groupId) async {
    ref.watch(clManualRefreshProvider);
    final client = await ref.watch(secureClientProvider.future);
    final requests = await client.groups.listRequests(groupId);
    return {for (final r in requests) r.id: r};
  }

  /// Approve a pending request. Replaces local state with the server's
  /// updated [JoinRequest]. On approve, the user becomes a group member;
  /// cross-invalidates the group-members and the user's groups lists so
  /// dependent views refresh.
  Future<JoinRequest> approve(int requestId) {
    return refetchIfWriteUncertain(() async {
      final client = await ref.read(secureClientProvider.future);
      final updated = await client.groups.approveRequest(arg, requestId);
      _replaceLocally(updated);
      ref
        ..invalidate(clGroupMembersProvider(arg))
        ..invalidate(clUserGroupsProvider(updated.username));
      await ref.read(clGroupMembersProvider(arg).future);
      _invalidateNotificationFeeds();
      return updated;
    }, refetch: refetchAfterUncertainWrite);
  }

  /// Reject a pending request, optionally with a reason.
  Future<JoinRequest> reject(int requestId, {String? reason}) {
    return refetchIfWriteUncertain(() async {
      final client = await ref.read(secureClientProvider.future);
      final updated = await client.groups.rejectRequest(
        arg,
        requestId,
        reason: reason,
      );
      _replaceLocally(updated);
      _invalidateNotificationFeeds();
      return updated;
    }, refetch: refetchAfterUncertainWrite);
  }

  /// After an approve or reject that may have landed
  /// ([refetchIfWriteUncertain]): reload the requests, the members and the
  /// notification feeds.
  void refetchAfterUncertainWrite() {
    ref
      ..invalidateSelf()
      ..invalidate(clGroupMembersProvider(arg));
    _invalidateNotificationFeeds();
  }

  /// Approve/reject resolves the matching group_join_request pending
  /// action server-side; refresh both feeds so the row disappears
  /// without a manual refresh.
  void _invalidateNotificationFeeds() {
    ref
      ..invalidate(clPendingActionsMasterProvider)
      ..invalidate(clNotificationsMasterProvider);
  }

  void _replaceLocally(JoinRequest request) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData({...current, request.id: request});
  }
}
