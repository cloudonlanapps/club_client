import 'package:cl_remote_store/src/providers/client.dart';
import 'package:cl_remote_store/src/providers/manual_refresh.dart';
import 'package:cl_remote_store/src/providers/resource_version.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Single event detail from the member-facing `/myevents` endpoint.
///
/// Authorized for self, admin, or coach. Server returns the
/// event whether the target user is enrolled or it is publicly visible,
/// so it is safe for the request-to-join path.
final AutoDisposeFutureProviderFamily<Event, ({String username, int eventId})>
clMyEventDetailProvider = FutureProvider.autoDispose
    .family<Event, ({String username, int eventId})>((ref, key) async {
      ref
        ..watch(
          clResourceVersionProvider.select((s) => s.occurrencesVersion),
        )
        ..watch(clManualRefreshProvider);
      final client = await ref.watch(secureClientProvider.future);
      return client.myEvents.getMyEvent(key.username, key.eventId);
    });
