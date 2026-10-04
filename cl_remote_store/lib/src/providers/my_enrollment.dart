import 'package:cl_remote_store/src/providers/my_enrollments_master.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Fetches the user's enrollment for a specific event.
///
/// Watches [clMyEnrollmentsMasterProvider] so it rebuilds automatically when
/// the master state changes (e.g., after accept, decline, withdraw
/// mutations). Returns null if the user has no enrollment for the event.
final AutoDisposeFutureProviderFamily<
  Enrollment?,
  ({String username, int eventId})
>
clMyEnrollmentProvider = FutureProvider.autoDispose
    .family<Enrollment?, ({String username, int eventId})>((ref, key) async {
      try {
        return await ref.watch(
          clMyEnrollmentsMasterProvider(
            (username: key.username, eventId: key.eventId),
          ).future,
        );
      } on Exception catch (_) {
        // No enrollment exists (public event, or not enrolled)
        return null;
      }
    });
