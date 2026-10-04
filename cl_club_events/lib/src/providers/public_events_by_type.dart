import 'package:cl_remote_store/cl_remote_store.dart'
    show clPublicEventsProvider, clPublicMediaUrlProvider;
import 'package:club_sdk_2/club_sdk_2.dart' show EventType;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/public/public_event_split.dart';
import '../models/public/public_event_view.dart';

/// Every public event of one type as the website shows it: active and past.
///
/// The catalogue read is `clPublicEventsProvider`'s; this only wraps each
/// event as a [PublicEventView] and splits on `isPast`, which the server
/// computes.
final AutoDisposeFutureProviderFamily<PublicEventSplit, EventType>
publicEventsByTypeProvider = FutureProvider.autoDispose
    .family<PublicEventSplit, EventType>((ref, type) async {
      final media = ref.watch(clPublicMediaUrlProvider);
      final events = await ref.watch(clPublicEventsProvider(type).future);
      final views = events
          .map((event) => PublicEventView(event: event, media: media))
          .toList();
      return (
        active: views.where((e) => !e.isPast).toList(),
        past: views.where((e) => e.isPast).toList(),
      );
    });
