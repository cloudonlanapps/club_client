import 'package:cl_remote_store/src/providers/client.dart';
import 'package:cl_remote_store/src/providers/manual_refresh.dart';
import 'package:cl_remote_store/src/providers/resource_version.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Key for member occurrence date-range queries.
typedef ClMyOccurrencesKey = ({
  String username,
  DateTime from,
  DateTime to,
});

/// Read-only provider for a member's occurrences within a date range.
///
/// Watches `occurrencesVersion` and `attendanceVersion` from
/// [clResourceVersionProvider] and refetches when an occurrence mutation or
/// an attendance write bumps either.
final AutoDisposeFutureProviderFamily<List<Occurrence>, ClMyOccurrencesKey>
clMyOccurrencesProvider = FutureProvider.autoDispose
    .family<List<Occurrence>, ClMyOccurrencesKey>(
      (ref, key) async {
        ref
          ..watch(
            clResourceVersionProvider.select((s) => s.occurrencesVersion),
          )
          ..watch(
            clResourceVersionProvider.select((s) => s.attendanceVersion),
          )
          ..watch(clManualRefreshProvider);
        final client = await ref.read(secureClientProvider.future);
        return client.myEvents.listMyOccurrences(
          key.username,
          fromTimeUtc: key.from,
          toTimeUtc: key.to,
        );
      },
    );
