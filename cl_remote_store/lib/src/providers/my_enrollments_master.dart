import 'package:cl_remote_store/src/providers/client.dart';
import 'package:cl_remote_store/src/providers/enrollment_records_master.dart';
import 'package:cl_remote_store/src/providers/enrollments_master.dart';
import 'package:cl_remote_store/src/providers/manual_refresh.dart';
import 'package:cl_remote_store/src/providers/my_events_master.dart';
import 'package:cl_remote_store/src/providers/notifications_master.dart';
import 'package:cl_remote_store/src/providers/pending_actions_master.dart';
import 'package:cl_remote_store/src/utils/bump_credits_version.dart';
import 'package:cl_remote_store/src/utils/uncertain_write.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Key for member enrollment provider.
typedef ClMyEnrollmentsKey = ({String username, int eventId});

/// Member master provider for enrollment status on a specific event.
///
/// Keyed by (username, eventId). Holds the member's enrollment.
/// Cross-invalidates admin enrollment provider after mutations.
final AutoDisposeAsyncNotifierProviderFamily<
  ClMyEnrollmentsMasterNotifier,
  Enrollment,
  ClMyEnrollmentsKey
>
clMyEnrollmentsMasterProvider = AsyncNotifierProvider.autoDispose
    .family<ClMyEnrollmentsMasterNotifier, Enrollment, ClMyEnrollmentsKey>(
      ClMyEnrollmentsMasterNotifier.new,
    );

/// Notifier managing member enrollment mutations for a single event.
class ClMyEnrollmentsMasterNotifier
    extends AutoDisposeFamilyAsyncNotifier<Enrollment, ClMyEnrollmentsKey> {
  ClMyEnrollmentsKey get key => arg;

  @override
  Future<Enrollment> build(ClMyEnrollmentsKey arg) async {
    ref.watch(clManualRefreshProvider);
    final client = await ref.read(secureClientProvider.future);
    return client.myEvents.getMyEnrollment(key.username, key.eventId);
  }

  /// Accept an invitation.
  Future<void> acceptInvite() {
    return refetchIfWriteUncertain(() async {
      final client = await ref.read(secureClientProvider.future);
      await client.myEvents.acceptInvite(key.username, key.eventId);
      await refetchAndCrossInvalidate();
    }, refetch: refetchAfterUncertainWrite);
  }

  /// Decline an invitation.
  Future<void> declineInvite() {
    return refetchIfWriteUncertain(() async {
      final client = await ref.read(secureClientProvider.future);
      await client.myEvents.declineInvite(key.username, key.eventId);
      await refetchAndCrossInvalidate();
    }, refetch: refetchAfterUncertainWrite);
  }

  /// Request to join a public event.
  Future<void> requestToJoin() {
    return refetchIfWriteUncertain(() async {
      final client = await ref.read(secureClientProvider.future);
      await client.myEvents.requestToJoin(key.username, key.eventId);
      await refetchAndCrossInvalidate();
    }, refetch: refetchAfterUncertainWrite);
  }

  /// Request withdrawal from an event.
  Future<void> withdraw({
    String? reason,
  }) {
    return refetchIfWriteUncertain(() async {
      final client = await ref.read(secureClientProvider.future);
      await client.myEvents.withdraw(
        key.username,
        key.eventId,
        reason: reason,
      );
      await refetchAndCrossInvalidate();
    }, refetch: refetchAfterUncertainWrite);
  }

  /// Cancel a pending withdrawal request.
  Future<void> cancelWithdrawRequest() {
    return refetchIfWriteUncertain(() async {
      final client = await ref.read(secureClientProvider.future);
      await client.myEvents.cancelWithdrawRequest(key.username, key.eventId);
      await refetchAndCrossInvalidate();
    }, refetch: refetchAfterUncertainWrite);
  }

  // -- Helpers ----------------------------------------------------------------

  Future<void> refetchAndCrossInvalidate() async {
    final client = await ref.read(secureClientProvider.future);
    final updated = await client.myEvents.getMyEnrollment(
      key.username,
      key.eventId,
    );
    state = AsyncData(updated);
    crossInvalidate();
  }

  /// After a write that may have landed ([refetchIfWriteUncertain]): reload
  /// this enrollment and everything a change to it touches.
  void refetchAfterUncertainWrite() {
    ref.invalidateSelf();
    crossInvalidate();
  }

  /// Cross-invalidate admin view, my events list, and the notification
  /// feeds (accept/decline/withdraw resolves the matching enrollment
  /// pending action — server auto-dismisses it, so refetch the feeds).
  void crossInvalidate() {
    ref
      ..invalidate(clEnrollmentsMasterProvider(key.eventId))
      ..invalidate(clEnrollmentRecordsMasterProvider(key.eventId))
      ..invalidate(clMyEventsMasterProvider(key.username))
      ..invalidate(clPendingActionsMasterProvider)
      ..invalidate(clNotificationsMasterProvider);
    bumpCreditsVersion(ref);
  }
}
