import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'selected_day.dart';

/// All club-wide occurrences for the selected day.
///
/// Used by the admin/coach `Today's Events` dashboard panel. Reads from
/// [clOccurrencesProvider], the admin/coach-scoped endpoint that returns
/// every event's occurrences in a date range. Regular members never reach
/// this provider — the panel itself is gated by role.
final FutureProvider<List<Occurrence>> todayAllOccurrencesProvider =
    FutureProvider<List<Occurrence>>((ref) async {
      final selected = ref.watch(selectedDayProvider);
      final from = startOfDayLocal(selected).toUtc();
      final to = endOfDayLocal(selected).toUtc();

      return ref.watch(
        clOccurrencesProvider((from: from, to: to)).future,
      );
    });
