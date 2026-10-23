import 'package:cl_remote_store/src/providers/client.dart';
import 'package:cl_remote_store/src/providers/enrollment_records_master.dart';
import 'package:cl_remote_store/src/providers/events_master.dart';
import 'package:cl_remote_store/src/providers/manual_refresh.dart';
import 'package:cl_remote_store/src/providers/my_enrollments_master.dart';
import 'package:cl_remote_store/src/providers/my_events_master.dart';
import 'package:cl_remote_store/src/providers/notifications_master.dart';
import 'package:cl_remote_store/src/providers/pending_actions_master.dart';
import 'package:cl_remote_store/src/providers/user_private.dart';
import 'package:cl_remote_store/src/utils/bump_credits_version.dart';
import 'package:cl_remote_store/src/utils/event_eligibility.dart';
import 'package:cl_remote_store/src/utils/uncertain_write.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Admin master provider for enrollments of a specific event.
///
/// Keyed by eventId. Holds `Map<String, EnrollmentStatus>` for that event.
/// Watches the event master for what changes the event's enrolments
/// ([enrollmentEventInputs]: the event's presence, archive and cutoff), not
/// the whole event, so a save of its title, visibility or description does
/// not read them again (club_client#230).
/// Cross-invalidates member enrollment providers after mutations.
final AsyncNotifierProviderFamily<
  ClEnrollmentsMasterNotifier,
  Map<String, EnrollmentStatus>,
  int
>
clEnrollmentsMasterProvider =
    AsyncNotifierProvider.family<
      ClEnrollmentsMasterNotifier,
      Map<String, EnrollmentStatus>,
      int
    >(
      ClEnrollmentsMasterNotifier.new,
    );

/// Notifier managing admin enrollment mutations for a single event.
class ClEnrollmentsMasterNotifier
    extends FamilyAsyncNotifier<Map<String, EnrollmentStatus>, int> {
  int get eventId => arg;

  @override
  Future<Map<String, EnrollmentStatus>> build(int arg) async {
    // React to the event's deletion, archive or cutoff, and manual refresh.
    ref
      ..watch(
        clEventsMasterProvider.select(
          (s) => enrollmentEventInputs(s.valueOrNull?[eventId]),
        ),
      )
      ..watch(clManualRefreshProvider);
    // A new session rebuilds this on its client (club_client#294).
    await ref.watch(secureClientProvider.future);
    return fetch();
  }

  Future<Map<String, EnrollmentStatus>> fetch() async {
    final client = await ref.read(secureClientProvider.future);
    return client.enrollments.listEnrollments(eventId);
  }

  // -- Single Actions ---------------------------------------------------------

  /// Invite a user to the event.
  Future<void> invite(String username) {
    return refetchIfWriteUncertain(() async {
      await _assertEligible(username);
      final client = await ref.read(secureClientProvider.future);
      await client.enrollments.invite(eventId, username);
      await _afterWrite([username]);
    }, refetch: () => refetchAfterUncertainWrite([username]));
  }

  /// Assign a user to the event.
  Future<void> assign(String username) {
    return refetchIfWriteUncertain(() async {
      await _assertEligible(username);
      final client = await ref.read(secureClientProvider.future);
      await client.enrollments.assign(eventId, username);
      await _afterWrite([username]);
    }, refetch: () => refetchAfterUncertainWrite([username]));
  }

  /// Assign a trial to the event.
  Future<void> assignTrial(String username) {
    return refetchIfWriteUncertain(() async {
      await _assertEligible(username);
      final client = await ref.read(secureClientProvider.future);
      await client.enrollments.assignTrial(eventId, username);
      await _afterWrite([username]);
    }, refetch: () => refetchAfterUncertainWrite([username]));
  }

  /// Approve a join request.
  Future<void> approveRequest(String username) {
    return refetchIfWriteUncertain(() async {
      await _assertEligible(username);
      final client = await ref.read(secureClientProvider.future);
      await client.enrollments.approveRequest(
        eventId,
        username,
      );
      await _afterWrite([username]);
    }, refetch: () => refetchAfterUncertainWrite([username]));
  }

  /// Client-side eligibility pre-check.
  ///
  /// Throws an [SdkError] with `USER_NOT_ELIGIBLE_FOR_EVENT` when the
  /// target user's profile clearly disqualifies them from the event
  /// (gender mismatch, DOB out of window) — or when the profile is
  /// missing data the event constrains. Saves a round-trip in the
  /// missing-data case and surfaces the failure with the same code the
  /// server uses, so callers can rely on one error path.
  Future<void> _assertEligible(String username) async {
    final event = ref.read(clEventsMasterProvider).valueOrNull?[eventId];
    if (event == null) return;
    if (event.genders.isEmpty &&
        event.dobOnOrAfterUtc == null &&
        event.dobOnOrBeforeUtc == null) {
      return;
    }
    final UserPrivate user;
    try {
      user = await ref.read(clUserPrivateProvider(username).future);
    } on Exception {
      // Profile fetch failed — let the server be the source of truth.
      return;
    }
    final failure = checkEventEligibility(event: event, user: user);
    if (failure != null) {
      throw SdkError(
        failure.message,
        code: SdkErrorCode.userNotEligibleForEvent,
      );
    }
  }

  /// Reject a join request.
  Future<void> rejectRequest(
    String username, {
    String? reason,
  }) {
    return refetchIfWriteUncertain(() async {
      final client = await ref.read(secureClientProvider.future);
      await client.enrollments.rejectRequest(
        eventId,
        username,
        reason: reason,
      );
      await _afterWrite([username]);
    }, refetch: () => refetchAfterUncertainWrite([username]));
  }

  /// Remove an enrollment.
  Future<void> removeEnrollment(
    String username, {
    String? reason,
  }) {
    return refetchIfWriteUncertain(() async {
      final client = await ref.read(secureClientProvider.future);
      await client.enrollments.removeEnrollment(
        eventId,
        username,
        reason: reason,
      );
      await _afterWrite([username]);
    }, refetch: () => refetchAfterUncertainWrite([username]));
  }

  /// Approve a withdrawal request.
  Future<void> approveWithdraw(String username) {
    return refetchIfWriteUncertain(() async {
      final client = await ref.read(secureClientProvider.future);
      await client.enrollments.approveWithdraw(eventId, username);
      await _afterWrite([username]);
    }, refetch: () => refetchAfterUncertainWrite([username]));
  }

  /// Reject a withdrawal request.
  Future<void> rejectWithdraw(
    String username, {
    String? reason,
  }) {
    return refetchIfWriteUncertain(() async {
      final client = await ref.read(secureClientProvider.future);
      await client.enrollments.rejectWithdraw(
        eventId,
        username,
        reason: reason,
      );
      await _afterWrite([username]);
    }, refetch: () => refetchAfterUncertainWrite([username]));
  }

  // -- Bulk Actions -----------------------------------------------------------

  /// Invite multiple users.
  Future<void> inviteBulk(List<String> usernames) {
    return refetchIfWriteUncertain(() async {
      final client = await ref.read(secureClientProvider.future);
      await client.enrollments.inviteBulk(eventId, usernames);
      await _afterWrite(usernames);
    }, refetch: () => refetchAfterUncertainWrite(usernames));
  }

  /// Assign multiple users.
  Future<void> assignBulk(List<String> usernames) {
    return refetchIfWriteUncertain(() async {
      final client = await ref.read(secureClientProvider.future);
      await client.enrollments.assignBulk(eventId, usernames);
      await _afterWrite(usernames);
    }, refetch: () => refetchAfterUncertainWrite(usernames));
  }

  // -- Cross-Invalidation -----------------------------------------------------

  /// After a write that succeeded: refresh each member's side, then re-read
  /// this event's roster.
  ///
  /// The write has already succeeded, so a failed re-read does not throw:
  /// it lands in [state] as an [AsyncError] for the roster to reload, and
  /// the member side is refreshed before it (club_client#227).
  Future<void> _afterWrite(List<String> usernames) async {
    crossInvalidateMembers(usernames);
    state = await AsyncValue.guard(fetch);
  }

  /// After a write that may have landed ([refetchIfWriteUncertain]): reload
  /// this event's enrollments and each member's side.
  void refetchAfterUncertainWrite(List<String> usernames) {
    ref.invalidateSelf();
    crossInvalidateMembers(usernames);
  }

  /// Invalidate the member-side providers of each of [usernames], the
  /// event's enrollment records and the notification feeds (any enrollment
  /// mutation here can resolve an enrollment_request /
  /// enrollment_opportunity pending action), then bump `creditsVersion`
  /// once for the whole action (club_client#238).
  void crossInvalidateMembers(List<String> usernames) {
    for (final username in usernames) {
      ref
        ..invalidate(
          clMyEnrollmentsMasterProvider(
            (username: username, eventId: eventId),
          ),
        )
        ..invalidate(clMyEventsMasterProvider(username));
    }
    ref
      ..invalidate(clEnrollmentRecordsMasterProvider(eventId))
      ..invalidate(clPendingActionsMasterProvider)
      ..invalidate(clNotificationsMasterProvider);
    // Enrolling, leaving or settling changes who the rosters list and can
    // move credit.
    bumpCreditsVersion(ref);
  }
}

/// What of [event] its enrolment masters depend on: whether it is there,
/// archived, and its cutoff. A record, so equal values compare equal and a
/// save that changes none of them reloads no enrolments (club_client#230).
({bool present, DateTime? deletedAtUtc, DateTime? untilTimeUtc})
enrollmentEventInputs(Event? event) => (
  present: event != null,
  deletedAtUtc: event?.deletedAtUtc,
  untilTimeUtc: event?.untilTimeUtc,
);
