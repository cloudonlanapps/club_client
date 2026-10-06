import 'package:cl_remote_store/src/providers/client.dart';
import 'package:cl_remote_store/src/providers/media_download_url.dart';
import 'package:cl_remote_store/src/providers/mutation_guard.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tag used for every user's profile avatar in the v2 media link table.
///
/// Server validation requires tags to match `^[A-Za-z0-9_-]{1,64}$`, so
/// the underscore form is mandatory.
const String kUserAvatarTag = 'user_avatar';

/// Access roles of an avatar everyone may see, logged in or not.
const List<String> kAvatarPublicAccessRoles = ['public'];

/// Access roles of a private avatar: the member it belongs to and staff.
const List<String> kAvatarPrivateAccessRoles = ['self', 'admin', 'coach'];

/// Largest page the server's media listings return.
const int kMediaListPageLimit = 100;

/// Most-recent avatar download URL for `username`, or `null` if the user
/// has no avatar attached.
///
/// Resolves by listing `user/avatar`-tagged links via `UserMediaSource`,
/// picking the most recently created entry, and routing the uuid through
/// `mediaDownloadUrlProvider`.
final FutureProviderFamily<String?, String> avatarImageProvider =
    FutureProvider.family<String?, String>((ref, username) async {
      final client = await ref.watch(secureClientProvider.future);
      final links = await client.userMedia.listByTag(username, kUserAvatarTag);
      if (links.isEmpty) return null;
      final sorted = [...links]
        ..sort((a, b) => b.createdAtUtc.compareTo(a.createdAtUtc));
      final mostRecent = sorted.first;
      return ref.read(
        mediaDownloadUrlProvider(
          (uuid: mostRecent.mediaUuid, variant: 'original'),
        ),
      );
    });

/// Whether the user's current avatar (most-recent `user_avatar`-tagged
/// media) is marked publicly visible, i.e. its `accessRoles` contains
/// `'public'`. Returns `false` when the user has no avatar, or when the
/// most-recent linked media isn't present in the caller's `listMyFiles`
/// page (admin viewing another user's avatar — caller should not rely on
/// the result in that case).
///
/// Seeds the "Allow others to see my photo" checkbox, both in the upload
/// preview dialog and on the member's own current photo (club_client#35).
final FutureProviderFamily<bool, String> avatarVisibilityProvider =
    FutureProvider.family<bool, String>((ref, username) async {
      final client = await ref.watch(secureClientProvider.future);
      final links = await client.userMedia.listByTag(username, kUserAvatarTag);
      if (links.isEmpty) return false;
      final sorted = [...links]
        ..sort((a, b) => b.createdAtUtc.compareTo(a.createdAtUtc));
      final mostRecentUuid = sorted.first.mediaUuid;
      // Server caps `limit` at 100. The just-uploaded avatar is the user's
      // most-recent media, so the first page is sufficient here.
      final myFiles = await client.media.listMyFiles(
        limit: kMediaListPageLimit,
      );
      final match = myFiles.items
          .where((m) => m.uuid == mostRecentUuid)
          .toList();
      if (match.isEmpty) return false;
      return match.first.accessRoles.contains(kAvatarPublicAccessRoles.single);
    });

/// Mutation surface for a single user's avatar.
///
/// Widgets call [AvatarMutationNotifier.upload],
/// [AvatarMutationNotifier.uploadOnBehalf],
/// [AvatarMutationNotifier.setVisibility] or [AvatarMutationNotifier.clear];
/// reads observe [avatarImageProvider] and [avatarVisibilityProvider].
/// The notifier handles the upload → attach → soft-delete-previous flow
/// in an order that keeps the user with a renderable avatar across
/// upload-or-attach failures.
final AvatarMutationProvider avatarMutationProvider =
    AsyncNotifierProvider.family<AvatarMutationNotifier, void, String>(
      AvatarMutationNotifier.new,
    );

/// Convenience alias for the family type used by [avatarMutationProvider].
typedef AvatarMutationProvider =
    AsyncNotifierProviderFamily<AvatarMutationNotifier, void, String>;

/// Notifier that owns avatar upload / visibility / clear for a single user.
class AvatarMutationNotifier extends FamilyAsyncNotifier<void, String>
    with MediaMutationGuard<String> {
  @override
  Future<void> build(String username) async {
    // Idle. Mutation methods drive state transitions.
  }

  /// Upload [bytes] as the user's own avatar and replace any prior avatar
  /// under [kUserAvatarTag].
  ///
  /// [allowOthersToSee] selects the new media's access roles:
  ///   - `true`  → [kAvatarPublicAccessRoles]
  ///   - `false` → [kAvatarPrivateAccessRoles]
  ///
  /// On a failure during upload or attach, prior media is preserved.
  /// Prior media is only soft-deleted after the new link has been
  /// successfully attached.
  Future<void> upload({
    required List<int> bytes,
    required String filename,
    required String contentType,
    required bool allowOthersToSee,
  }) => runGuarded(
    'Avatar.upload',
    () => replaceAvatar(
      bytes: bytes,
      filename: filename,
      contentType: contentType,
      accessRoles: allowOthersToSee
          ? kAvatarPublicAccessRoles
          : kAvatarPrivateAccessRoles,
      onBehalf: false,
    ),
    refetch: () => refetchAvatar(arg),
  );

  /// An admin uploads [bytes] as this user's avatar (club_client#35).
  ///
  /// The file is uploaded on the user's behalf (`ownerUsername`,
  /// club_server#18), so the user owns it: they can later make it public
  /// with [setVisibility] or replace it. It is stored private
  /// ([kAvatarPrivateAccessRoles]); making a photo public stays the
  /// member's choice. Prior avatars are replaced as in [upload].
  ///
  /// The server refuses a caller who is not an admin (403).
  Future<void> uploadOnBehalf({
    required List<int> bytes,
    required String filename,
    required String contentType,
  }) => runGuarded(
    'Avatar.uploadOnBehalf',
    () => replaceAvatar(
      bytes: bytes,
      filename: filename,
      contentType: contentType,
      accessRoles: kAvatarPrivateAccessRoles,
      onBehalf: true,
    ),
    refetch: () => refetchAvatar(arg),
  );

  /// Make the user's current avatar public ([allowOthersToSee] true) or
  /// private again, without a new upload (club_client#35).
  ///
  /// For the member themselves: the current avatar is looked up among the
  /// caller's own files. Throws a [StateError] when the user has no avatar
  /// or the current one is not among those files.
  Future<void> setVisibility({required bool allowOthersToSee}) async {
    final username = arg;
    await runGuarded('Avatar.setVisibility', () async {
      final client = await ref.read(secureClientProvider.future);
      final links = await client.userMedia.listByTag(username, kUserAvatarTag);
      if (links.isEmpty) throw StateError('No avatar to change');
      final current = links.reduce(
        (a, b) => b.createdAtUtc.isAfter(a.createdAtUtc) ? b : a,
      );
      final id = await findMediaId(client, current.mediaUuid, onBehalf: false);
      if (id == null) throw StateError('The current avatar is not yours');
      await client.media.patch(
        id,
        accessRoles: allowOthersToSee
            ? kAvatarPublicAccessRoles
            : kAvatarPrivateAccessRoles,
      );
      ref.invalidate(avatarVisibilityProvider(username));
    }, refetch: () => refetchAvatar(username));
  }

  /// Detach and soft-delete every avatar media for the user.
  Future<void> clear() async {
    final username = arg;
    await runGuarded('Avatar.clear', () async {
      final client = await ref.read(secureClientProvider.future);
      final links = await client.userMedia.listByTag(
        username,
        kUserAvatarTag,
      );
      await client.userMedia.detachTag(username, kUserAvatarTag);
      for (final link in links) {
        try {
          await softDeleteByUuid(client, link.mediaUuid, onBehalf: false);
        } on Object catch (e, st) {
          debugPrint(
            'avatarMutationProvider.clear: softDelete failed for '
            '${link.mediaUuid}: $e\n$st',
          );
        }
      }
      refetchAvatar(username);
    }, refetch: () => refetchAvatar(username));
  }

  /// Reload the avatar and its visibility for [username].
  void refetchAvatar(String username) {
    ref
      ..invalidate(avatarImageProvider(username))
      ..invalidate(avatarVisibilityProvider(username));
  }

  /// The body shared by [upload] and [uploadOnBehalf]: upload, attach under
  /// [kUserAvatarTag], then detach and soft-delete each prior avatar.
  ///
  /// [onBehalf] names the user as the file's owner (`ownerUsername`) and
  /// looks prior files up in the staff listing, since they are not the
  /// caller's own.
  Future<void> replaceAvatar({
    required List<int> bytes,
    required String filename,
    required String contentType,
    required List<String> accessRoles,
    required bool onBehalf,
  }) async {
    final username = arg;
    final client = await ref.read(secureClientProvider.future);
    final priorLinks = await client.userMedia.listByTag(
      username,
      kUserAvatarTag,
    );
    final media = await client.media.upload(
      fileBytes: bytes,
      filename: filename,
      contentType: contentType,
      accessRoles: accessRoles,
      ownerUsername: onBehalf ? username : null,
    );
    await client.userMedia.attach(
      username,
      tag: kUserAvatarTag,
      mediaUuid: media.uuid,
    );
    // Replace each prior avatar: detach the link, then soft-delete the
    // media. The order matters — the server returns 409 MEDIA_IN_USE
    // if soft-delete sees a live link. Both calls are expected to
    // succeed; failures are logged (not swallowed) so any real fault
    // surfaces in the console without aborting the rest of the loop.
    for (final prior in priorLinks) {
      try {
        await client.userMedia.detach(
          username,
          kUserAvatarTag,
          prior.mediaUuid,
        );
        await softDeleteByUuid(client, prior.mediaUuid, onBehalf: onBehalf);
      } on Object catch (e, st) {
        debugPrint(
          'avatarMutationProvider: cleanup failed for prior media '
          '${prior.mediaUuid}: $e\n$st',
        );
      }
    }
    refetchAvatar(username);
  }

  /// Soft-delete the media with [mediaUuid], if [findMediaId] resolves it.
  /// Best-effort cleanup: an unresolved uuid stays an orphan media row.
  Future<void> softDeleteByUuid(
    SecureClient client,
    String mediaUuid, {
    required bool onBehalf,
  }) async {
    final id = await findMediaId(client, mediaUuid, onBehalf: onBehalf);
    if (id == null) return;
    await client.media.softDelete(id);
  }

  /// The numeric id of the media with [mediaUuid], or null if not found.
  ///
  /// The link table only carries the uuid, the media writes take the id,
  /// and the server has no fetch-by-uuid. For the user themselves the first
  /// page of their own files is searched (a prior avatar buried deeper than
  /// [kMediaListPageLimit] is not found). [onBehalf] (an admin acting for
  /// the user) walks the staff listing of all media instead, since the
  /// files are the user's and not the caller's.
  Future<int?> findMediaId(
    SecureClient client,
    String mediaUuid, {
    required bool onBehalf,
  }) async {
    if (!onBehalf) {
      final mine = await client.media.listMyFiles(limit: kMediaListPageLimit);
      return mine.items.where((m) => m.uuid == mediaUuid).firstOrNull?.id;
    }
    var offset = 0;
    while (true) {
      final page = await client.media.list(
        offset: offset,
        limit: kMediaListPageLimit,
      );
      final found = page.items.where((m) => m.uuid == mediaUuid).firstOrNull;
      if (found != null) return found.id;
      offset += page.items.length;
      if (page.items.isEmpty || offset >= page.total) return null;
    }
  }
}
