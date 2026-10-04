import 'package:cl_remote_store/cl_remote_store.dart'
    show clPublicFeaturedEventsProvider, clPublicMediaUrlProvider;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/public/highlight.dart';
import '../models/public/public_event_view.dart';

/// What the landing page's highlight carousel shows: the featured public
/// events of every type, each as a `Highlight`.
final AutoDisposeFutureProvider<List<Highlight>> publicHighlightsProvider =
    FutureProvider.autoDispose<List<Highlight>>((ref) async {
      final media = ref.watch(clPublicMediaUrlProvider);
      final events = await ref.watch(clPublicFeaturedEventsProvider.future);
      return [
        for (final event in events)
          PublicEventView(event: event, media: media).toHighlight(),
      ];
    });
