import 'package:cl_remote_store/src/providers/client.dart';
import 'package:cl_remote_store/src/providers/media_download_url.dart';
import 'package:cl_remote_store/src/providers/mutation_guard.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tags used for an event's media in the v2 media link table. Server
/// validation requires tags to match `^[A-Za-z0-9_-]{1,64}$`.
const String kEventCoverTag = 'event_cover';
const String kEventGalleryTag = 'event_gallery';

/// One resolved gallery item: the link's media uuid (for removal), the
/// authenticated download URL (for display), where its still preview lives
/// (`null` for an image, which is its own preview), and the denormalized media
/// kind (`image` / `video` / `pdf`, from the link row) so the read path can
/// build a typed gallery item without a second fetch.
typedef EventGalleryImage = ({
  String mediaUuid,
  String url,
  String? previewUrl,
  String mediaType,
});

/// Most-recent cover-image download URL for the event, or `null` when the
/// event has no `event_cover`-tagged media. Mirrors `avatarImageProvider`.
final FutureProviderFamily<String?, int> eventCoverImageProvider =
    FutureProvider.family<String?, int>((ref, eventId) async {
      final client = await ref.watch(secureClientProvider.future);
      final links = await client.eventMedia.listByTag(eventId, kEventCoverTag);
      if (links.isEmpty) return null;
      final sorted = [...links]
        ..sort((a, b) => b.createdAtUtc.compareTo(a.createdAtUtc));
      return ref.read(
        mediaDownloadUrlProvider(
          (uuid: sorted.first.mediaUuid, variant: 'original'),
        ),
      );
    });

/// Resolved gallery images for the event, oldest first, each with its media
/// uuid and download URL.
final FutureProviderFamily<List<EventGalleryImage>, int> eventGalleryProvider =
    FutureProvider.family<List<EventGalleryImage>, int>((ref, eventId) async {
      final client = await ref.watch(secureClientProvider.future);
      final links = await client.eventMedia.listByTag(
        eventId,
        kEventGalleryTag,
      );
      final sorted = [...links]
        ..sort((a, b) => a.createdAtUtc.compareTo(b.createdAtUtc));
      return [
        for (final link in sorted)
          (
            mediaUuid: link.mediaUuid,
            url: ref.read(
              mediaDownloadUrlProvider(
                (uuid: link.mediaUuid, variant: 'original'),
              ),
            ),
            previewUrl: ref.read(mediaRefPosterUrlProvider(link.media)),
            mediaType: link.media.mediaTypeWord,
          ),
      ];
    });

/// Mutation surface for a single event's cover image and gallery.
///
/// Widgets call the methods below; reads observe [eventCoverImageProvider] /
/// [eventGalleryProvider]. Event media is always uploaded `['public']`.
/// Mirrors `AvatarMutationNotifier`: on cover replace, the new link is
/// attached before prior media is detached + soft-deleted, so the event
/// keeps a renderable cover across failures.
final EventMediaMutationProvider eventMediaMutationProvider =
    AsyncNotifierProvider.family<EventMediaMutationNotifier, void, int>(
      EventMediaMutationNotifier.new,
    );

typedef EventMediaMutationProvider =
    AsyncNotifierProviderFamily<EventMediaMutationNotifier, void, int>;

class EventMediaMutationNotifier extends FamilyAsyncNotifier<void, int>
    with MediaMutationGuard<int> {
  @override
  Future<void> build(int eventId) async {
    // Idle. Mutation methods drive state transitions.
  }

  /// Upload [bytes] as the event's cover, replacing any prior cover.
  Future<void> uploadCover({
    required List<int> bytes,
    required String filename,
    required String contentType,
  }) async {
    final eventId = arg;
    await runGuarded('EventMedia.uploadCover', () async {
      final client = await ref.read(secureClientProvider.future);
      final priorLinks = await client.eventMedia.listByTag(
        eventId,
        kEventCoverTag,
      );
      final media = await client.media.upload(
        fileBytes: bytes,
        filename: filename,
        contentType: contentType,
        accessRoles: const ['public'],
      );
      await client.eventMedia.attach(
        eventId,
        tag: kEventCoverTag,
        mediaUuid: media.uuid,
      );
      for (final prior in priorLinks) {
        await _detachAndDelete(
          client,
          eventId,
          kEventCoverTag,
          prior.mediaUuid,
        );
      }
      ref.invalidate(eventCoverImageProvider(eventId));
    }, refetch: () => ref.invalidate(eventCoverImageProvider(eventId)));
  }

  /// Detach + soft-delete every cover-tagged media for the event.
  Future<void> clearCover() async {
    final eventId = arg;
    await runGuarded('EventMedia.clearCover', () async {
      final client = await ref.read(secureClientProvider.future);
      final links = await client.eventMedia.listByTag(eventId, kEventCoverTag);
      for (final link in links) {
        await _detachAndDelete(client, eventId, kEventCoverTag, link.mediaUuid);
      }
      ref.invalidate(eventCoverImageProvider(eventId));
    }, refetch: () => ref.invalidate(eventCoverImageProvider(eventId)));
  }

  /// Upload [bytes] as a standalone media (no link), returning the created
  /// [Media]. Used by the multi-file gallery uploader, which polls
  /// [galleryMediaStatus] until conversion completes and then calls
  /// [attachGalleryMedia]. Errors propagate so the uploader can mark the item
  /// failed; this does not touch the notifier's shared loading state because
  /// the uploader dialog owns its own per-item progress UI.
  Future<Media> uploadGalleryMedia({
    required List<int> bytes,
    required String filename,
    String? contentType,
  }) async {
    final client = await ref.read(secureClientProvider.future);
    return client.media.upload(
      fileBytes: bytes,
      filename: filename,
      contentType: contentType,
      accessRoles: const ['public'],
    );
  }

  /// Current server-side state of a media by id, for conversion polling.
  Future<Media> galleryMediaStatus(int id) async {
    final client = await ref.read(secureClientProvider.future);
    return client.media.getById(id);
  }

  /// Attach an already-uploaded media to the event's gallery (`event_gallery`
  /// tag) and refresh the gallery. Called once per completed item by the
  /// uploader's `onComplete`.
  Future<void> attachGalleryMedia(String mediaUuid) async {
    final eventId = arg;
    await runGuarded('EventMedia.attachGalleryMedia', () async {
      final client = await ref.read(secureClientProvider.future);
      await client.eventMedia.attach(
        eventId,
        tag: kEventGalleryTag,
        mediaUuid: mediaUuid,
      );
      ref.invalidate(eventGalleryProvider(eventId));
    }, refetch: () => ref.invalidate(eventGalleryProvider(eventId)));
  }

  /// Detach + soft-delete a single gallery image by its media uuid.
  Future<void> removeGalleryImage(String mediaUuid) async {
    final eventId = arg;
    await runGuarded('EventMedia.removeGalleryImage', () async {
      final client = await ref.read(secureClientProvider.future);
      await _detachAndDelete(client, eventId, kEventGalleryTag, mediaUuid);
      ref.invalidate(eventGalleryProvider(eventId));
    }, refetch: () => ref.invalidate(eventGalleryProvider(eventId)));
  }

  /// Detach the link then soft-delete the media. Order matters — the server
  /// returns 409 `MEDIA_IN_USE` if soft-delete sees a live link. Failures are
  /// logged, not swallowed, so a real fault surfaces without aborting a loop.
  Future<void> _detachAndDelete(
    SecureClient client,
    int eventId,
    String tag,
    String mediaUuid,
  ) async {
    try {
      await client.eventMedia.detach(eventId, tag, mediaUuid);
      final myFiles = await client.media.listMyFiles(limit: 100);
      final found = myFiles.items.where((m) => m.uuid == mediaUuid).toList();
      if (found.isNotEmpty) await client.media.softDelete(found.first.id);
    } on Object catch (e, st) {
      debugPrint('eventMediaMutation: cleanup failed for $mediaUuid: $e\n$st');
    }
  }
}
