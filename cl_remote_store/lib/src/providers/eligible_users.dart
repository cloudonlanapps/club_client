import 'package:cl_remote_store/src/providers/client.dart';
import 'package:cl_remote_store/src/providers/manual_refresh.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Users who can be added to (or request to join) the given group.
///
/// Family-keyed by `groupId`. Auto-disposes — the picker that consumes
/// this provider is short-lived, and the underlying eligibility query
/// is cheap enough to re-run on demand.
final AutoDisposeFutureProviderFamily<List<EligibleUser>, int>
clEligibleUsersProvider = FutureProvider.autoDispose
    .family<List<EligibleUser>, int>(
      (ref, groupId) async {
        ref.watch(clManualRefreshProvider);
        final client = await ref.watch(secureClientProvider.future);
        return client.groups.listEligible(groupId);
      },
    );
