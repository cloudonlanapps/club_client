import 'package:cl_remote_store/src/providers/client.dart';
import 'package:cl_remote_store/src/providers/media_download_url.dart';
import 'package:cl_remote_store/src/providers/mutation_guard.dart';
import 'package:cl_remote_store/src/utils/media_by_uuid.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tag used for a group's image in the v2 media link table. Server validation
/// requires tags to match `^[A-Za-z0-9_-]{1,64}$`. Mirrors `kEventCoverTag`.
const String kGroupImageTag = 'group_image';

/// Most-recent image download URL for the group, or `null` when the group has
/// no `group_image`-tagged media. Mirrors `eventCoverImageProvider`.
final FutureProviderFamily<String?, int> groupImageProvider =
    FutureProvider.family<String?, int>((ref, groupId) async {
      final client = await ref.watch(secureClientProvider.future);
      final links = await client.groupMedia.listByTag(groupId, kGroupImageTag);
      if (links.isEmpty) return null;
      final sorted = [...links]
        ..sort((a, b) => b.createdAtUtc.compareTo(a.createdAtUtc));
      return ref.read(
        mediaDownloadUrlProvider(
          (uuid: sorted.first.mediaUuid, variant: 'original'),
        ),
      );
    });

/// Mutation surface for a single group's image.
///
/// Widgets call the methods below; reads observe [groupImageProvider]. Group
/// media is always uploaded `['public']`. On replace, the new link is attached
/// before prior media is detached + soft-deleted, so the group keeps a
/// renderable image across failures. Mirrors `EventMediaMutationNotifier`.
final GroupMediaMutationProvider groupMediaMutationProvider =
    AsyncNotifierProvider.family<GroupMediaMutationNotifier, void, int>(
      GroupMediaMutationNotifier.new,
    );

typedef GroupMediaMutationProvider =
    AsyncNotifierProviderFamily<GroupMediaMutationNotifier, void, int>;

class GroupMediaMutationNotifier extends FamilyAsyncNotifier<void, int>
    with MediaMutationGuard<int> {
  @override
  Future<void> build(int groupId) async {
    // Idle. Mutation methods drive state transitions.
  }

  /// Upload [bytes] as the group's image, replacing any prior image.
  Future<void> uploadImage({
    required List<int> bytes,
    required String filename,
    required String contentType,
  }) async {
    final groupId = arg;
    await runGuarded('GroupMedia.uploadImage', () async {
      final client = await ref.read(secureClientProvider.future);
      final priorLinks = await client.groupMedia.listByTag(
        groupId,
        kGroupImageTag,
      );
      final media = await client.media.upload(
        fileBytes: bytes,
        filename: filename,
        contentType: contentType,
        accessRoles: const ['public'],
      );
      await client.groupMedia.attach(
        groupId,
        tag: kGroupImageTag,
        mediaUuid: media.uuid,
      );
      for (final prior in priorLinks) {
        await detachAndDelete(client, groupId, prior.mediaUuid);
      }
      ref.invalidate(groupImageProvider(groupId));
    }, refetch: () => ref.invalidate(groupImageProvider(groupId)));
  }

  /// Detach + soft-delete every image-tagged media for the group.
  Future<void> clearImage() async {
    final groupId = arg;
    await runGuarded('GroupMedia.clearImage', () async {
      final client = await ref.read(secureClientProvider.future);
      final links = await client.groupMedia.listByTag(groupId, kGroupImageTag);
      for (final link in links) {
        await detachAndDelete(client, groupId, link.mediaUuid);
      }
      ref.invalidate(groupImageProvider(groupId));
    }, refetch: () => ref.invalidate(groupImageProvider(groupId)));
  }

  /// Detach the link then soft-delete the media, whoever uploaded it
  /// (club_client#105). Order matters — the server returns 409
  /// `MEDIA_IN_USE` if soft-delete sees a live link. Failures are logged,
  /// not swallowed, so a real fault surfaces without aborting a loop.
  Future<void> detachAndDelete(
    SecureClient client,
    int groupId,
    String mediaUuid,
  ) async {
    try {
      await client.groupMedia.detach(groupId, kGroupImageTag, mediaUuid);
      await softDeleteMediaByUuid(client, mediaUuid);
    } on Object catch (e, st) {
      debugPrint('groupMediaMutation: cleanup failed for $mediaUuid: $e\n$st');
    }
  }
}
