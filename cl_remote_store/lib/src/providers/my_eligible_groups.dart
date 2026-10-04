import 'package:cl_remote_store/src/providers/client.dart';
import 'package:cl_remote_store/src/providers/manual_refresh.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Groups the user can request to join.
///
/// Family-keyed by `username`. Auto-disposes — the "Joinable groups"
/// tab that consumes this provider is short-lived, and the underlying
/// query is cheap enough to re-run on demand. Server already excludes
/// auto groups, current memberships, and groups with an outstanding
/// pending request from the same user.
final AutoDisposeFutureProviderFamily<List<Group>, String>
clMyEligibleGroupsProvider = FutureProvider.autoDispose
    .family<List<Group>, String>(
      (ref, username) async {
        ref.watch(clManualRefreshProvider);
        final client = await ref.watch(secureClientProvider.future);
        return client.myGroups.listEligible(username);
      },
    );
