import 'package:cl_remote_store/src/providers/client.dart';
import 'package:cl_remote_store/src/providers/manual_refresh.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Users who can be assigned to or invited to the given event.
///
/// Family-keyed by `eventId`. Filters by the event's structured
/// eligibility (gender + DOB window) and excludes users already
/// enrolled. Auto-disposes — the picker that consumes this provider
/// is short-lived.
final AutoDisposeFutureProviderFamily<List<EligibleUser>, int>
clEligibleUsersForEventProvider = FutureProvider.autoDispose
    .family<List<EligibleUser>, int>(
      (ref, eventId) async {
        ref.watch(clManualRefreshProvider);
        final client = await ref.watch(secureClientProvider.future);
        return client.events.listEligible(eventId);
      },
    );
