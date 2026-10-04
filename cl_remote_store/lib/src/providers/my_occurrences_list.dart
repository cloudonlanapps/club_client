import 'package:cl_remote_store/src/providers/my_occurrences.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Fetches the user's occurrences within a date range via
/// [clMyOccurrencesProvider] and sorts by actual start time.
final AutoDisposeFutureProviderFamily<
  List<Occurrence>,
  ({String username, DateTime fromTimeUtc, DateTime toTimeUtc})
>
clMyOccurrencesListProvider = FutureProvider.autoDispose
    .family<
      List<Occurrence>,
      ({String username, DateTime fromTimeUtc, DateTime toTimeUtc})
    >(
      (ref, key) async {
        final occurrences = await ref.watch(
          clMyOccurrencesProvider((
            username: key.username,
            from: key.fromTimeUtc,
            to: key.toTimeUtc,
          )).future,
        );

        return [...occurrences]..sort(
          (a, b) => a.actualStartTimeUtc.compareTo(b.actualStartTimeUtc),
        );
      },
    );
