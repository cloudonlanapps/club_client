import 'package:cl_remote_store/cl_remote_store.dart'
    show
        clPublicEventMarketingProvider,
        clPublicEventProvider,
        clPublicMediaUrlProvider;
import 'package:club_sdk_2/club_sdk_2.dart' show PublicEvent;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/public/public_event_view.dart';

/// One public event by its public id, with its extended marketing block when
/// there is one.
///
/// Null when the event itself cannot be read, which is what the not-found
/// page is for. The marketing block is allowed to be missing
/// (`clPublicEventMarketingProvider` resolves to null then), and the detail
/// page renders without the sections it would have filled.
final AutoDisposeFutureProviderFamily<PublicEventView?, String>
publicEventByIdProvider = FutureProvider.autoDispose
    .family<PublicEventView?, String>((ref, publicId) async {
      final media = ref.watch(clPublicMediaUrlProvider);
      final event = ref.watch(clPublicEventProvider(publicId).future);
      final marketing = ref.watch(
        clPublicEventMarketingProvider(publicId).future,
      );

      final PublicEvent found;
      try {
        found = await event;
      } on Object {
        return null;
      }
      return PublicEventView(
        event: found,
        media: media,
        marketing: await marketing,
      );
    });
