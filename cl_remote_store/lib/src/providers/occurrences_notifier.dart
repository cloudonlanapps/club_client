import 'package:cl_remote_store/src/models/occurrence_key.dart';
import 'package:cl_remote_store/src/models/occurrences_key.dart';
import 'package:cl_remote_store/src/providers/client.dart';
import 'package:cl_remote_store/src/providers/manual_refresh.dart';
import 'package:cl_remote_store/src/providers/resource_version.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Family provider for occurrences notifier.
/// Key is (startUtc, endUtc) - caches occurrences per range.
final AutoDisposeAsyncNotifierProviderFamily<
  OccurrencesNotifier,
  Map<OccurrenceKey, Occurrence>,
  ClOccurrencesNotifierKey
>
occurrencesNotifierProvider = AsyncNotifierProvider.autoDispose
    .family<
      OccurrencesNotifier,
      Map<OccurrenceKey, Occurrence>,
      ClOccurrencesNotifierKey
    >(OccurrencesNotifier.new);

/// AsyncNotifier that manages occurrences for a date range (admin view).
/// Shows all occurrences org-wide, not user-specific.
///
/// Provides mutation methods for admin/organizer actions only.
class OccurrencesNotifier
    extends
        AutoDisposeFamilyAsyncNotifier<
          Map<OccurrenceKey, Occurrence>,
          ClOccurrencesNotifierKey
        > {
  /// Key is available via [arg] property from Riverpod family notifier.
  ClOccurrencesNotifierKey get key => arg;

  @override
  Future<Map<OccurrenceKey, Occurrence>> build(
    ClOccurrencesNotifierKey key,
  ) async {
    ref
      ..watch(clManualRefreshProvider)
      ..watch(
        clResourceVersionProvider.select((s) => s.occurrencesVersion),
      );
    return fetchOccurrences();
  }

  /// Fetch occurrences from SDK for the current range.
  Future<Map<OccurrenceKey, Occurrence>> fetchOccurrences() async {
    try {
      final client = await ref.read(secureClientProvider.future);

      final occurrences = await client.occurrences.listOccurrences(
        fromTimeUtc: key.startUtc,
        toTimeUtc: key.endUtc,
      );

      // Convert list to map keyed by (eventId, originalStartTime)
      final map = <OccurrenceKey, Occurrence>{};
      for (final occ in occurrences) {
        try {
          final occKey = (
            eventId: occ.eventId,
            originalStartTime: occ.originalStartTimeUtc,
          );
          map[occKey] = occ;
        } on Exception catch (e) {
          debugPrint('Warning: Skipping invalid occurrence: $e');
          continue;
        }
      }
      return map;
    } catch (e, stackTrace) {
      debugPrint('Error fetching occurrences: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Re-fetch occurrences after a mutation.
  Future<void> refetchOccurrences() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(fetchOccurrences);
  }

  /// Get occurrences as a list (convenience method for widgets).
  List<Occurrence> getOccurrencesList() {
    return state.valueOrNull?.values.toList() ?? [];
  }

  /// Get a specific occurrence by key.
  Occurrence? getOccurrence(OccurrenceKey occKey) {
    return state.valueOrNull?[occKey];
  }
}
