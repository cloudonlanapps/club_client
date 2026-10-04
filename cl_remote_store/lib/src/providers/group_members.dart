import 'package:cl_remote_store/src/providers/client.dart';
import 'package:cl_remote_store/src/providers/manual_refresh.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Read-only provider for members of a specific group.
///
/// Fetches from server. Invalidated by `clGroupsMasterProvider` when
/// membership changes (addMember, removeMember, addMembersBulk).
final AutoDisposeFutureProviderFamily<List<GroupMember>, int>
clGroupMembersProvider = FutureProvider.autoDispose
    .family<List<GroupMember>, int>((ref, groupId) async {
      ref.watch(clManualRefreshProvider);
      final client = await ref.read(secureClientProvider.future);
      return client.groups.getMembers(groupId);
    });
