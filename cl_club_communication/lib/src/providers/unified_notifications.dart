import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Merged view over [clNotificationsMasterProvider] and
/// [clPendingActionsMasterProvider]. The notifications surface (issue #115)
/// renders a single feed across both sources:
///
/// * Dedupe by [AppNotification.id]. Pending-actions wins because that
///   provider carries the server-side auto-dismiss filter (the unresolved
///   subset). Rows in notifications but absent from pending-actions are
///   considered resolved and render without trailing action buttons.
/// * Loading until both source providers have produced a value at least
///   once; error if either is in error. UI then renders the merged map.
///
/// The merge result also carries the set of notification ids that are
/// still unresolved (present in pending-actions) so the view can decide
/// whether to attach the `PendingActionTrailing` to a row.
class UnifiedNotifications {
  const UnifiedNotifications({
    required this.byId,
    required this.unresolvedIds,
  });

  /// Every notification known to either provider, keyed by id.
  final Map<int, AppNotification> byId;

  /// Subset of ids that are still unresolved (present in
  /// [clPendingActionsMasterProvider]). The view uses this to decide
  /// whether to render the trailing action widget.
  final Set<int> unresolvedIds;
}

final Provider<AsyncValue<UnifiedNotifications>> unifiedNotificationsProvider =
    Provider<AsyncValue<UnifiedNotifications>>((ref) {
      final notifs = ref.watch(clNotificationsMasterProvider);
      final pending = ref.watch(clPendingActionsMasterProvider);

      // Surface error if either is in error.
      if (notifs.hasError) {
        return AsyncError(notifs.error!, notifs.stackTrace ?? StackTrace.empty);
      }
      if (pending.hasError) {
        return AsyncError(
          pending.error!,
          pending.stackTrace ?? StackTrace.empty,
        );
      }

      final notifsMap = notifs.valueOrNull;
      final pendingMap = pending.valueOrNull;

      if (notifsMap == null || pendingMap == null) {
        return const AsyncLoading();
      }

      // Pending-actions wins on dedupe — its row carries the auto-dismiss
      // subset.
      final merged = <int, AppNotification>{
        ...notifsMap,
        ...pendingMap,
      };
      return AsyncData(
        UnifiedNotifications(
          byId: merged,
          unresolvedIds: pendingMap.keys.toSet(),
        ),
      );
    });
