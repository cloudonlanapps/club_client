import 'package:cl_remote_store/src/providers/attendances_master.dart';
import 'package:cl_remote_store/src/providers/client.dart';
import 'package:cl_remote_store/src/providers/manual_refresh.dart';
import 'package:cl_remote_store/src/utils/uncertain_write.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Key for member attendance provider.
typedef ClMyAttendancesKey = ({
  String username,
  int eventId,
  DateTime occurrenceTimeUtc,
});

/// Member master provider for attendance on a specific occurrence.
///
/// Keyed by (username, eventId, occurrenceTimeUtc).
/// Holds the member's attendance record (or null if not yet recorded).
/// Cross-invalidates admin attendance provider after mutations.
final AutoDisposeAsyncNotifierProviderFamily<
  ClMyAttendancesMasterNotifier,
  AttendanceRecord?,
  ClMyAttendancesKey
>
clMyAttendancesMasterProvider = AsyncNotifierProvider.autoDispose
    .family<
      ClMyAttendancesMasterNotifier,
      AttendanceRecord?,
      ClMyAttendancesKey
    >(
      ClMyAttendancesMasterNotifier.new,
    );

/// Notifier managing member leave mutations for a single occurrence.
class ClMyAttendancesMasterNotifier
    extends
        AutoDisposeFamilyAsyncNotifier<AttendanceRecord?, ClMyAttendancesKey> {
  ClMyAttendancesKey get key => arg;

  @override
  Future<AttendanceRecord?> build(ClMyAttendancesKey arg) async {
    ref.watch(clManualRefreshProvider);
    final client = await ref.read(secureClientProvider.future);
    return client.myEvents.getMyOccurrenceAttendance(
      key.username,
      key.eventId,
      key.occurrenceTimeUtc,
    );
  }

  /// Re-reads the record, e.g. after a failed read (club_core#139).
  void reload() => ref.invalidateSelf();

  /// Request leave for this occurrence.
  Future<void> requestLeave({
    String? reason,
  }) {
    return refetchIfWriteUncertain(() async {
      final client = await ref.read(secureClientProvider.future);
      await client.myEvents.requestLeave(
        key.username,
        key.eventId,
        key.occurrenceTimeUtc,
        reason: reason,
      );
      await refetchAndCrossInvalidate();
    }, refetch: refetchAfterUncertainWrite);
  }

  /// Cancel a pending leave request.
  Future<void> cancelLeaveRequest() {
    return refetchIfWriteUncertain(() async {
      final client = await ref.read(secureClientProvider.future);
      await client.myEvents.cancelLeaveRequest(
        key.username,
        key.eventId,
        key.occurrenceTimeUtc,
      );
      await refetchAndCrossInvalidate();
    }, refetch: refetchAfterUncertainWrite);
  }

  // -- Helpers ----------------------------------------------------------------

  /// After a write that may have landed ([refetchIfWriteUncertain]): reload
  /// this record and the organizer's roster.
  void refetchAfterUncertainWrite() {
    ref
      ..invalidateSelf()
      ..invalidate(
        clAttendancesMasterProvider((
          eventId: key.eventId,
          occurrenceTimeUtc: key.occurrenceTimeUtc,
        )),
      );
  }

  /// Re-reads the member's record after a leave mutation and invalidates
  /// the staff register for the occurrence.
  ///
  /// The mutation has already succeeded, so a failed re-read does not throw:
  /// it lands in [state] as an [AsyncError], which the occurrence actions
  /// show as a reload (club_core#139). The staff register is invalidated
  /// either way.
  Future<void> refetchAndCrossInvalidate() async {
    try {
      final client = await ref.read(secureClientProvider.future);
      state = await AsyncValue.guard(
        () => client.myEvents.getMyOccurrenceAttendance(
          key.username,
          key.eventId,
          key.occurrenceTimeUtc,
        ),
      );
    } finally {
      ref.invalidate(
        clAttendancesMasterProvider((
          eventId: key.eventId,
          occurrenceTimeUtc: key.occurrenceTimeUtc,
        )),
      );
    }
  }
}
