import 'package:cl_remote_store/src/providers/client.dart';
import 'package:cl_remote_store/src/providers/media_download_url.dart';
import 'package:cl_remote_store/src/providers/mutation_guard.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tag used for a venue's image in the v2 media link table. Server validation
/// requires tags to match `^[A-Za-z0-9_-]{1,64}$`. Mirrors `kEventCoverTag`.
const String kVenueImageTag = 'venue_image';

/// Most-recent image download URL for the venue, or `null` when the venue has
/// no `venue_image`-tagged media. Mirrors `eventCoverImageProvider`.
final FutureProviderFamily<String?, int> venueImageProvider =
    FutureProvider.family<String?, int>((ref, venueId) async {
      final client = await ref.watch(secureClientProvider.future);
      final links = await client.venueMedia.listByTag(venueId, kVenueImageTag);
      if (links.isEmpty) return null;
      final sorted = [...links]
        ..sort((a, b) => b.createdAtUtc.compareTo(a.createdAtUtc));
      return ref.read(
        mediaDownloadUrlProvider(
          (uuid: sorted.first.mediaUuid, variant: 'original'),
        ),
      );
    });

/// Mutation surface for a single venue's image.
///
/// Widgets call the methods below; reads observe [venueImageProvider]. Venue
/// media is always uploaded `['public']`. On replace, the new link is attached
/// before prior media is detached + soft-deleted, so the venue keeps a
/// renderable image across failures. Mirrors `EventMediaMutationNotifier`.
final VenueMediaMutationProvider venueMediaMutationProvider =
    AsyncNotifierProvider.family<VenueMediaMutationNotifier, void, int>(
      VenueMediaMutationNotifier.new,
    );

typedef VenueMediaMutationProvider =
    AsyncNotifierProviderFamily<VenueMediaMutationNotifier, void, int>;

class VenueMediaMutationNotifier extends FamilyAsyncNotifier<void, int>
    with MediaMutationGuard<int> {
  @override
  Future<void> build(int venueId) async {
    // Idle. Mutation methods drive state transitions.
  }

  /// Upload [bytes] as the venue's image, replacing any prior image.
  Future<void> uploadImage({
    required List<int> bytes,
    required String filename,
    required String contentType,
  }) async {
    final venueId = arg;
    await runGuarded('VenueMedia.uploadImage', () async {
      final client = await ref.read(secureClientProvider.future);
      final priorLinks = await client.venueMedia.listByTag(
        venueId,
        kVenueImageTag,
      );
      final media = await client.media.upload(
        fileBytes: bytes,
        filename: filename,
        contentType: contentType,
        accessRoles: const ['public'],
      );
      await client.venueMedia.attach(
        venueId,
        tag: kVenueImageTag,
        mediaUuid: media.uuid,
      );
      for (final prior in priorLinks) {
        await _detachAndDelete(client, venueId, prior.mediaUuid);
      }
      ref.invalidate(venueImageProvider(venueId));
    }, refetch: () => ref.invalidate(venueImageProvider(venueId)));
  }

  /// Detach + soft-delete every image-tagged media for the venue.
  Future<void> clearImage() async {
    final venueId = arg;
    await runGuarded('VenueMedia.clearImage', () async {
      final client = await ref.read(secureClientProvider.future);
      final links = await client.venueMedia.listByTag(venueId, kVenueImageTag);
      for (final link in links) {
        await _detachAndDelete(client, venueId, link.mediaUuid);
      }
      ref.invalidate(venueImageProvider(venueId));
    }, refetch: () => ref.invalidate(venueImageProvider(venueId)));
  }

  /// Detach the link then soft-delete the media. Order matters — the server
  /// returns 409 `MEDIA_IN_USE` if soft-delete sees a live link. Failures are
  /// logged, not swallowed, so a real fault surfaces without aborting a loop.
  Future<void> _detachAndDelete(
    SecureClient client,
    int venueId,
    String mediaUuid,
  ) async {
    try {
      await client.venueMedia.detach(venueId, kVenueImageTag, mediaUuid);
      final myFiles = await client.media.listMyFiles(limit: 100);
      final found = myFiles.items.where((m) => m.uuid == mediaUuid).toList();
      if (found.isNotEmpty) await client.media.softDelete(found.first.id);
    } on Object catch (e, st) {
      debugPrint('venueMediaMutation: cleanup failed for $mediaUuid: $e\n$st');
    }
  }
}
