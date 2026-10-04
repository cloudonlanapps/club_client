import 'package:cl_remote_store/src/providers/client.dart';
import 'package:cl_remote_store/src/providers/manual_refresh.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Read-only provider for groups that a user belongs to.
///
/// Fetches from server. Invalidated by `clGroupsMasterProvider` when
/// membership changes (addMember, removeMember, addMembersBulk).
final AutoDisposeFutureProviderFamily<List<Group>, String>
clUserGroupsProvider = FutureProvider.autoDispose.family<List<Group>, String>(
  (ref, username) async {
    ref.watch(clManualRefreshProvider);
    final client = await ref.read(secureClientProvider.future);
    return client.groups.getMyGroups(username);
  },
);
