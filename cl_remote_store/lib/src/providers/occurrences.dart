import 'package:cl_remote_store/src/providers/client.dart';
import 'package:cl_remote_store/src/providers/club_event_types.dart';
import 'package:cl_remote_store/src/providers/manual_refresh.dart';
import 'package:cl_remote_store/src/providers/resource_version.dart';
import 'package:cl_remote_store/src/utils/fetch_for_event_types.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Key for occurrence date-range queries.
typedef ClOccurrencesKey = ({DateTime from, DateTime to});

/// Read-only provider for occurrences within a date range (admin/coach).
///
/// Restricted to the event types the club runs ([clubEventTypesProvider]).
/// Watches `occurrencesVersion` from [clResourceVersionProvider] and
/// refetches when any occurrence mutation bumps the version.
final AutoDisposeFutureProviderFamily<List<Occurrence>, ClOccurrencesKey>
clOccurrencesProvider = FutureProvider.autoDispose
    .family<List<Occurrence>, ClOccurrencesKey>(
      (ref, key) async {
        ref
          ..watch(
            clResourceVersionProvider.select((s) => s.occurrencesVersion),
          )
          ..watch(clManualRefreshProvider);
        final types = ref.watch(clubEventTypesProvider);
        final client = await ref.read(secureClientProvider.future);
        final occurrences = await fetchForEventTypes(
          types,
          (type) => client.occurrences.listOccurrences(
            fromTimeUtc: key.from,
            toTimeUtc: key.to,
            eventType: type,
          ),
        );
        return occurrences..sort(
          (a, b) => a.actualStartTimeUtc.compareTo(b.actualStartTimeUtc),
        );
      },
    );
