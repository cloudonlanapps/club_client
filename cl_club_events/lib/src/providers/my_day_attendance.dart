import 'package:cl_remote_store/cl_remote_store.dart'
    show clMyOccurrencesProvider;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/my_range_occurrences_key.dart';

/// A member's recorded attendance per local day of the month view: the
/// status of each session of that day that has one, in start order
/// (club_client#416).
///
/// Read from the member occurrence list the day cells already load
/// (`clMyOccurrencesProvider`, as `myDayEventCountsProvider`), so it makes
/// no call of its own. A session not marked, or of an event the member is
/// not enrolled in, has no status and is left out; a day with none is
/// absent from the map.
final AutoDisposeFutureProviderFamily<
  Map<DateTime, List<AttendanceStatus>>,
  MyRangeOccurrencesKey
>
myDayAttendanceProvider = FutureProvider.autoDispose
    .family<Map<DateTime, List<AttendanceStatus>>, MyRangeOccurrencesKey>((
      ref,
      key,
    ) async {
      final occurrences = await ref.watch(
        clMyOccurrencesProvider((
          username: key.username,
          from: key.range.start,
          to: key.range.end,
        )).future,
      );
      final recorded =
          occurrences.where((o) => o.attendanceStatus != null).toList()..sort(
            (a, b) => a.actualStartTimeUtc.compareTo(b.actualStartTimeUtc),
          );
      final result = <DateTime, List<AttendanceStatus>>{};
      for (final occ in recorded) {
        final day = DateUtils.dateOnly(occ.actualStartTimeUtc.toLocal());
        (result[day] ??= []).add(occ.attendanceStatus!);
      }
      return result;
    });
