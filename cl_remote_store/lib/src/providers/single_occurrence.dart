import 'package:cl_remote_store/src/providers/client.dart';
import 'package:cl_remote_store/src/providers/manual_refresh.dart';
import 'package:cl_remote_store/src/providers/resource_version.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Key for a single occurrence lookup: event ID + slot key
/// (RRULE-derived original start time, never the rescheduled one).
typedef ClSingleOccurrenceKey = ({int eventId, DateTime occurrenceTimeUtc});

/// Read-only provider for a single occurrence, override-aware.
///
/// The returned [Occurrence.actualStartTimeUtc] reflects any
/// `OccurrenceOverride.newStartTimeUtc` server-side — use it as the
/// effective start when computing windows (30-min pre-occurrence gate,
/// 2-hour leave cutoff, 15-day attendance edit window).
///
/// Watches `occurrencesVersion` from [clResourceVersionProvider] and
/// refetches when any occurrence mutation (reschedule, cancel, restore)
/// bumps the version.
final AutoDisposeFutureProviderFamily<Occurrence, ClSingleOccurrenceKey>
clSingleOccurrenceProvider = FutureProvider.autoDispose
    .family<Occurrence, ClSingleOccurrenceKey>(
      (ref, key) async {
        ref
          ..watch(
            clResourceVersionProvider.select((s) => s.occurrencesVersion),
          )
          ..watch(clManualRefreshProvider);
        final client = await ref.read(secureClientProvider.future);
        return client.occurrences.getOccurrence(
          key.eventId,
          key.occurrenceTimeUtc,
        );
      },
    );
