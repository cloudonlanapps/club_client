import 'package:cl_remote_store/src/providers/client.dart';
import 'package:cl_remote_store/src/providers/manual_refresh.dart';
import 'package:cl_remote_store/src/providers/resource_version.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Fetches attendance records for a user within a date range.
///
/// Watches [clResourceVersionProvider] `occurrencesVersion` and
/// `attendanceVersion`, so it refetches after an occurrence change or any
/// attendance write.
/// Returns a list of [MyAttendanceRecord] sorted by occurrence time.
final AutoDisposeFutureProviderFamily<
  List<MyAttendanceRecord>,
  ({String username, DateTime fromTimeUtc, DateTime toTimeUtc})
>
clMyAttendanceListProvider = FutureProvider.autoDispose
    .family<
      List<MyAttendanceRecord>,
      ({String username, DateTime fromTimeUtc, DateTime toTimeUtc})
    >(
      (ref, key) async {
        ref
          ..watch(
            clResourceVersionProvider.select((s) => s.occurrencesVersion),
          )
          ..watch(
            clResourceVersionProvider.select((s) => s.attendanceVersion),
          )
          ..watch(clManualRefreshProvider);
        final client = await ref.watch(secureClientProvider.future);
        final records = await client.myEvents.listMyAttendance(
          key.username,
          fromTimeUtc: key.fromTimeUtc,
          toTimeUtc: key.toTimeUtc,
        );
        // Sort by occurrence time ascending (oldest first).
        records.sort(
          (a, b) => a.occurrenceTimeUtc.compareTo(b.occurrenceTimeUtc),
        );
        return records;
      },
    );
