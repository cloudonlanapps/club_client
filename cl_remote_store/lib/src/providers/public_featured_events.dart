import 'package:cl_remote_store/src/providers/public_events.dart';
import 'package:cl_remote_store/src/utils/public_read.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The featured public events, across every type (club_core#53).
final AutoDisposeFutureProvider<List<PublicEvent>>
clPublicFeaturedEventsProvider = FutureProvider.autoDispose<List<PublicEvent>>(
  (ref) async {
    final page = await readPublic(
      ref,
      (source) =>
          source.listPublicEvents(featured: true, limit: publicEventsPageLimit),
    );
    return page.items;
  },
);
