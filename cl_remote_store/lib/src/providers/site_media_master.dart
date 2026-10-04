import 'package:cl_remote_store/src/providers/client.dart';
import 'package:cl_remote_store/src/providers/current_user.dart';
import 'package:cl_remote_store/src/providers/manual_refresh.dart';
import 'package:cl_remote_store/src/utils/uncertain_write.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The server preference that holds the website's media slots.
const String siteMediaPreferenceKey = 'site_media';

/// The access roles that let an anonymous website visitor fetch a file.
const List<String> publicMediaAccessRoles = ['public'];

/// Master provider for the public website's media slots (club_core#19):
/// `{ serverKey: MediaRef }` for every slot that is set.
///
/// Read from the public club info, which publishes each slot as a
/// [MediaRef] (what a thumbnail needs) and leaves out any slot whose media is
/// no longer live and public. Written through the super-admin
/// `site_media` preference, always as the whole map: keys the app does not
/// name are carried through untouched.
///
/// Super-admin only, like the preference endpoint: anyone else gets an
/// empty map without a server call.
final AsyncNotifierProvider<ClSiteMediaMasterNotifier, Map<String, MediaRef>>
clSiteMediaMasterProvider =
    AsyncNotifierProvider<ClSiteMediaMasterNotifier, Map<String, MediaRef>>(
      ClSiteMediaMasterNotifier.new,
    );

class ClSiteMediaMasterNotifier extends AsyncNotifier<Map<String, MediaRef>> {
  @override
  Future<Map<String, MediaRef>> build() async {
    ref.watch(clManualRefreshProvider);
    final currentUser = ref.watch(currentUserProvider);
    if (currentUser == null || !currentUser.isSuperAdmin) {
      return const <String, MediaRef>{};
    }
    final client = await ref.watch(secureClientProvider.future);
    final info = await client.public.getPublicClubInfo();
    return Map<String, MediaRef>.unmodifiable(info.siteMedia);
  }

  /// Write [slots] as the whole `site_media` map. A 422
  /// `SITE_MEDIA_NOT_PUBLIC` `ServerException` (a slot names media an
  /// anonymous visitor could not fetch) is rethrown and the saved state kept.
  Future<void> save(Map<String, MediaRef> slots) {
    return refetchIfWriteUncertain(() async {
      final client = await ref.read(secureClientProvider.future);
      await client.admin.setPreference(siteMediaPreferenceKey, {
        for (final entry in slots.entries) entry.key: entry.value.uuid,
      });
      state = AsyncData(Map<String, MediaRef>.unmodifiable(slots));
    }, refetch: ref.invalidateSelf);
  }

  /// Upload a file any website visitor may fetch, for a slot to name.
  Future<MediaRef> uploadPublic({
    required List<int> bytes,
    required String filename,
    required String contentType,
  }) {
    return refetchIfWriteUncertain(() async {
      final client = await ref.read(secureClientProvider.future);
      final media = await client.media.upload(
        fileBytes: bytes,
        filename: filename,
        contentType: contentType,
        accessRoles: publicMediaAccessRoles,
      );
      return MediaRef(
        uuid: media.uuid,
        mimeType: media.mimeType,
        filename: media.filename,
      );
    }, refetch: () => ref.invalidate(clMediaLibraryProvider));
  }
}

/// Rows the media library fetches.
const int mediaLibraryLimit = 100;

/// The media a super-admin can link to a website slot: live images and
/// videos, newest the server gives first. Whether each is public is the
/// caller's to show — only public items can fill a slot.
///
/// Super-admin only (it serves the site media screen); anyone else gets an
/// empty list without a server call.
final AutoDisposeAsyncNotifierProvider<ClMediaLibraryNotifier, List<Media>>
clMediaLibraryProvider =
    AutoDisposeAsyncNotifierProvider<ClMediaLibraryNotifier, List<Media>>(
      ClMediaLibraryNotifier.new,
    );

class ClMediaLibraryNotifier extends AutoDisposeAsyncNotifier<List<Media>> {
  @override
  Future<List<Media>> build() async {
    ref.watch(clManualRefreshProvider);
    final currentUser = ref.watch(currentUserProvider);
    if (currentUser == null || !currentUser.isSuperAdmin) {
      return const <Media>[];
    }
    final client = await ref.watch(secureClientProvider.future);
    final page = await client.media.list(limit: mediaLibraryLimit);
    return [
      for (final m in page.items)
        if (!m.isDeleted && (m.mediaType == 'image' || m.mediaType == 'video'))
          m,
    ];
  }
}

/// Whether an anonymous website visitor may fetch [media].
bool isPublicMedia(Media media) =>
    media.accessRoles.contains(publicMediaAccessRoles.single);
