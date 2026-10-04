import 'package:cl_remote_store/src/providers/client.dart';
import 'package:cl_remote_store/src/providers/enrollment_records_master.dart';
import 'package:cl_remote_store/src/providers/enrollments_master.dart';
import 'package:cl_remote_store/src/providers/events_master.dart';
import 'package:cl_remote_store/src/providers/manual_refresh.dart';
import 'package:cl_remote_store/src/providers/my_attendances_master.dart';
import 'package:cl_remote_store/src/providers/notifications_master.dart';
import 'package:cl_remote_store/src/providers/pending_actions_master.dart';
import 'package:cl_remote_store/src/providers/resource_version.dart';
import 'package:cl_remote_store/src/utils/bump_credits_version.dart';
import 'package:cl_remote_store/src/utils/uncertain_write.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Key for attendance master provider.
typedef ClAttendancesKey = ({int eventId, DateTime occurrenceTimeUtc});

/// Admin master provider for attendance of a specific occurrence.
///
/// Keyed by (eventId, occurrenceTimeUtc). Holds attendance records.
/// Watches event master and occurrences version.
/// Cross-invalidates member attendance providers after mutations.
final AsyncNotifierProviderFamily<
  ClAttendancesMasterNotifier,
  List<AttendanceRecord>,
  ClAttendancesKey
>
clAttendancesMasterProvider =
    AsyncNotifierProvider.family<
      ClAttendancesMasterNotifier,
      List<AttendanceRecord>,
      ClAttendancesKey
    >(
      ClAttendancesMasterNotifier.new,
    );

/// Notifier managing admin attendance mutations for a single occurrence.
class ClAttendancesMasterNotifier
    extends FamilyAsyncNotifier<List<AttendanceRecord>, ClAttendancesKey> {
  ClAttendancesKey get key => arg;

  @override
  Future<List<AttendanceRecord>> build(ClAttendancesKey arg) async {
    // React to event changes, occurrence mutations, and manual refresh.
    ref
      ..watch(
        clEventsMasterProvider.select((s) => s.valueOrNull?[key.eventId]),
      )
      ..watch(
        clResourceVersionProvider.select((s) => s.occurrencesVersion),
      )
      ..watch(clManualRefreshProvider);
    return fetch();
  }

  Future<List<AttendanceRecord>> fetch() async {
    final client = await ref.read(secureClientProvider.future);
    return client.attendance.getAttendanceForOccurrence(
      key.eventId,
      key.occurrenceTimeUtc,
    );
  }

  /// Mark attendance for one or more members. Returns the server's report:
  /// who was recorded, who was refused (no credit, club_core#99) and whose
  /// trial the mark ended (club_core#98). A member whose trial ended has
  /// left the programme, so the event's enrollments are refetched too.
  Future<AttendanceMarkReport> markAttendance(
    List<AttendanceMarkRecord> records,
  ) {
    return refetchIfWriteUncertain(
      () async {
        final client = await ref.read(secureClientProvider.future);
        final report = await client.attendance.markAttendance(
          key.eventId,
          key.occurrenceTimeUtc,
          records,
        );
        ref.invalidateSelf();
        await future;
        if (report.trialEnded.isNotEmpty) {
          ref
            ..invalidate(clEnrollmentsMasterProvider(key.eventId))
            ..invalidate(clEnrollmentRecordsMasterProvider(key.eventId));
        }

        // A mark charges credit (or, changing an uncharged record, may).
        bumpCreditsVersion(ref);
        for (final record in records) {
          ref.invalidate(
            clMyAttendancesMasterProvider((
              username: record.membername,
              eventId: key.eventId,
              occurrenceTimeUtc: key.occurrenceTimeUtc,
            )),
          );
        }
        return report;
      },
      refetch: () =>
          refetchAfterUncertainWrite([for (final r in records) r.membername]),
    );
  }

  /// Clear a member's attendance mark, returning them to "not recorded".
  Future<void> clearAttendance(String username) {
    return refetchIfWriteUncertain(() async {
      final client = await ref.read(secureClientProvider.future);
      await client.attendance.clearAttendance(
        key.eventId,
        username,
        key.occurrenceTimeUtc,
      );
      ref.invalidateSelf();
      await future;
      // Clearing a charged mark refunds it.
      bumpCreditsVersion(ref);

      ref.invalidate(
        clMyAttendancesMasterProvider((
          username: username,
          eventId: key.eventId,
          occurrenceTimeUtc: key.occurrenceTimeUtc,
        )),
      );
    }, refetch: () => refetchAfterUncertainWrite([username]));
  }

  /// Approve a leave request.
  Future<void> approveLeave(String username) {
    return refetchIfWriteUncertain(() async {
      final client = await ref.read(secureClientProvider.future);
      await client.attendance.approveLeave(
        key.eventId,
        username,
        key.occurrenceTimeUtc,
      );
      ref.invalidateSelf();
      await future;
      crossInvalidateMember(username);
    }, refetch: () => refetchAfterUncertainWrite([username]));
  }

  /// Approve multiple leave requests.
  Future<void> approveLeaveBulk(List<String> usernames) {
    return refetchIfWriteUncertain(() async {
      final client = await ref.read(secureClientProvider.future);
      await client.attendance.approveLeaveBulk(
        key.eventId,
        usernames,
        key.occurrenceTimeUtc,
      );
      ref.invalidateSelf();
      await future;
      usernames.forEach(crossInvalidateMember);
    }, refetch: () => refetchAfterUncertainWrite(usernames));
  }

  /// Reject a leave request.
  Future<void> rejectLeave(
    String username, {
    String? reason,
  }) {
    return refetchIfWriteUncertain(() async {
      final client = await ref.read(secureClientProvider.future);
      await client.attendance.rejectLeave(
        key.eventId,
        username,
        key.occurrenceTimeUtc,
        reason: reason,
      );
      ref.invalidateSelf();
      await future;
      crossInvalidateMember(username);
    }, refetch: () => refetchAfterUncertainWrite([username]));
  }

  /// Reject multiple leave requests.
  Future<void> rejectLeaveBulk(
    List<String> usernames, {
    String? reason,
  }) {
    return refetchIfWriteUncertain(() async {
      final client = await ref.read(secureClientProvider.future);
      await client.attendance.rejectLeaveBulk(
        key.eventId,
        usernames,
        key.occurrenceTimeUtc,
        reason: reason,
      );
      ref.invalidateSelf();
      await future;
      usernames.forEach(crossInvalidateMember);
    }, refetch: () => refetchAfterUncertainWrite(usernames));
  }

  // -- Cross-Invalidation -----------------------------------------------------

  /// After a write that may have landed ([refetchIfWriteUncertain]): reload
  /// this roster, the event's enrollments (a mark can end a trial) and each
  /// member's side, including credit.
  void refetchAfterUncertainWrite(List<String> usernames) {
    ref
      ..invalidateSelf()
      ..invalidate(clEnrollmentsMasterProvider(key.eventId))
      ..invalidate(clEnrollmentRecordsMasterProvider(key.eventId));
    usernames.forEach(crossInvalidateMember);
    bumpCreditsVersion(ref);
  }

  void crossInvalidateMember(String username) {
    ref
      ..invalidate(
        clMyAttendancesMasterProvider((
          username: username,
          eventId: key.eventId,
          occurrenceTimeUtc: key.occurrenceTimeUtc,
        )),
      )
      // Approve/reject leave (or any future attendance correction)
      // resolves the matching attendance_correction pending action.
      ..invalidate(clPendingActionsMasterProvider)
      ..invalidate(clNotificationsMasterProvider);
    // An approved leave refunds a charged session; a rejected one charges.
    bumpCreditsVersion(ref);
  }
}
