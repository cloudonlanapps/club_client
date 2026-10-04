import 'package:cl_remote_store/src/utils/public_read.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// How many events one public catalogue read asks for: the server's maximum.
const int publicEventsPageLimit = 100;

/// Every public, live event of one [EventType] (club_core#53), past ones
/// included — `PublicEvent.isPast` is the server's to compute, and the split
/// the caller's to make.
///
/// Listing cards read the basic marketing block that comes on the event
/// itself; the extended block is `clPublicEventMarketingProvider`'s.
final AutoDisposeFutureProviderFamily<List<PublicEvent>, EventType>
clPublicEventsProvider = FutureProvider.autoDispose
    .family<List<PublicEvent>, EventType>((ref, type) async {
      final page = await readPublic(
        ref,
        (source) =>
            source.listPublicEvents(type: type, limit: publicEventsPageLimit),
      );
      return page.items;
    });
