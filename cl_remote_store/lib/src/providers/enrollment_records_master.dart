import 'package:cl_remote_store/src/providers/client.dart';
import 'package:cl_remote_store/src/providers/events_master.dart';
import 'package:cl_remote_store/src/providers/manual_refresh.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Admin master provider for full enrollment records of an event.
///
/// Keyed by eventId. Holds `Map<String, Enrollment>` (membername -> record)
/// including `enrolledAtUtc` / `withdrawnAtUtc`, used to compute per-occurrence
/// attendance eligibility client-side via `enrollmentCoversOccurrence`.
///
/// Read-only: enrollment mutations live on `clEnrollmentsMasterProvider`. This
/// provider reacts to the same freshness signals (event changes and manual
/// refresh) so it stays consistent without duplicating mutation logic.
final AsyncNotifierProviderFamily<
  ClEnrollmentRecordsMasterNotifier,
  Map<String, Enrollment>,
  int
>
clEnrollmentRecordsMasterProvider =
    AsyncNotifierProvider.family<
      ClEnrollmentRecordsMasterNotifier,
      Map<String, Enrollment>,
      int
    >(
      ClEnrollmentRecordsMasterNotifier.new,
    );

/// Notifier fetching full enrollment records for a single event.
class ClEnrollmentRecordsMasterNotifier
    extends FamilyAsyncNotifier<Map<String, Enrollment>, int> {
  int get eventId => arg;

  @override
  Future<Map<String, Enrollment>> build(int arg) async {
    // React to event deletion/changes and manual refresh, mirroring
    // clEnrollmentsMasterProvider's freshness model.
    ref
      ..watch(clEventsMasterProvider.select((s) => s.valueOrNull?[eventId]))
      ..watch(clManualRefreshProvider);
    final client = await ref.read(secureClientProvider.future);
    return client.enrollments.listEnrollmentsDetailed(eventId);
  }
}
