import 'package:cl_remote_store/src/providers/client.dart';
import 'package:cl_remote_store/src/providers/manual_refresh.dart';
import 'package:cl_remote_store/src/providers/user_groups.dart';
import 'package:cl_remote_store/src/utils/uncertain_write.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Master provider for the user's own join requests (any status).
///
/// Family-keyed by `username`. Holds the canonical
/// `Map<requestId, JoinRequest>` of every join request the user has
/// submitted. The `join` and `cancel` mutations on the master notifiers
/// update this state with the server response; no manual refetch is
/// needed.
final AsyncNotifierProviderFamily<
  ClMyJoinRequestsMasterNotifier,
  Map<int, JoinRequest>,
  String
>
clMyJoinRequestsMasterProvider =
    AsyncNotifierProvider.family<
      ClMyJoinRequestsMasterNotifier,
      Map<int, JoinRequest>,
      String
    >(
      ClMyJoinRequestsMasterNotifier.new,
    );

class ClMyJoinRequestsMasterNotifier
    extends FamilyAsyncNotifier<Map<int, JoinRequest>, String> {
  @override
  Future<Map<int, JoinRequest>> build(String username) async {
    ref.watch(clManualRefreshProvider);
    final client = await ref.watch(secureClientProvider.future);
    final requests = await client.myGroups.listMyRequests(username);
    return {for (final r in requests) r.id: r};
  }

  /// Cancel a still-pending join request. Replaces local state with
  /// the server's updated [JoinRequest] (status `cancelled`).
  Future<JoinRequest> cancel(int requestId) {
    return refetchIfWriteUncertain(() async {
      final client = await ref.read(secureClientProvider.future);
      final updated = await client.myGroups.cancelRequest(arg, requestId);
      replaceLocally(updated);
      return updated;
    }, refetch: ref.invalidateSelf);
  }

  /// Public helper used by sibling notifiers (e.g.
  /// `clMyGroupsMasterProvider.join`) to fold a newly created request
  /// into local state.
  void replaceLocally(JoinRequest request) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData({...current, request.id: request});
    // When a request is approved (server-side, by admin) and the user
    // is added to the group, the next view that re-reads
    // `clUserGroupsProvider` should reflect that — invalidate to be safe.
    if (request.status == JoinRequestStatus.approved) {
      ref.invalidate(clUserGroupsProvider(arg));
    }
  }
}
