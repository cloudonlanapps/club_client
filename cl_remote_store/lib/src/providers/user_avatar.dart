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
/// `'public'`. Returns `false` when the user has no avatar, or when its
/// file is one the caller may not read.
///
/// The file is read by its uuid (club_client#86).
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
      final current = await findAvatarMedia(client, sorted.first.mediaUuid);
      if (current == null) return false;
      return current.accessRoles.contains(kAvatarPublicAccessRoles.single);
    });

/// The media record with [mediaUuid], or null when no file has that uuid or
/// the caller may not read it (the server answers both 404).
///
/// A media link carries the uuid; the calls that change a file take the id
/// this record holds (club_client#86).
Future<Media?> findAvatarMedia(SecureClient client, String mediaUuid) async {
  try {
    return await client.media.getByUuid(mediaUuid);
  } on ServerException catch (e) {
    if (e.statusCode == kNotFoundStatus) return null;
    rethrow;
  }
}

/// HTTP status of a file that does not exist or the caller may not read.
const int kNotFoundStatus = 404;

/// Mutation surface for a single user's avatar.
///
/// Widgets call [AvatarMutationNotifier.upload],
/// [AvatarMutationNotifier.uploadOnBehalf],
/// [AvatarMutationNotifier.setVisibility] or [AvatarMutationNotifier.clear];
/// reads observe [avatarImageProvider] and [avatarVisibilityProvider].
/// The notifier uploads and attaches; the server keeps a user to one avatar
/// and replaces the previous one when the new link is made
/// (club_client#87), so a failed upload or attach leaves the current photo
/// in place.
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
  /// On a failure during upload or attach, the prior avatar stays.
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
      ownerUsername: arg,
    ),
    refetch: () => refetchAvatar(arg),
  );

  /// Make the user's current avatar public ([allowOthersToSee] true) or
  /// private again, without a new upload (club_client#35).
  ///
  /// For the member themselves. Throws a [StateError] when the user has no
  /// avatar or the current one is a file the caller may not read.
  Future<void> setVisibility({required bool allowOthersToSee}) async {
    final username = arg;
    await runGuarded('Avatar.setVisibility', () async {
      final client = await ref.read(secureClientProvider.future);
      final links = await client.userMedia.listByTag(username, kUserAvatarTag);
      if (links.isEmpty) throw StateError('No avatar to change');
      final current = links.reduce(
        (a, b) => b.createdAtUtc.isAfter(a.createdAtUtc) ? b : a,
      );
      final media = await findAvatarMedia(client, current.mediaUuid);
      if (media == null) throw StateError('The current avatar is not yours');
      await client.media.patch(
        media.id,
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
          await softDeleteByUuid(client, link.mediaUuid);
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

  /// The body shared by [upload] and [uploadOnBehalf]: upload, then attach
  /// under [kUserAvatarTag].
  ///
  /// The server replaces the user's previous avatar when the new link is
  /// made: it removes the old link, one the caller may not view included,
  /// and soft-deletes its file (club_client#87). Nothing is detached or
  /// deleted from here.
  ///
  /// [ownerUsername] names the user as the file's owner when an admin
  /// uploads for them.
  Future<void> replaceAvatar({
    required List<int> bytes,
    required String filename,
    required String contentType,
    required List<String> accessRoles,
    String? ownerUsername,
  }) async {
    final username = arg;
    final client = await ref.read(secureClientProvider.future);
    final media = await client.media.upload(
      fileBytes: bytes,
      filename: filename,
      contentType: contentType,
      accessRoles: accessRoles,
      ownerUsername: ownerUsername,
    );
    await client.userMedia.attach(
      username,
      tag: kUserAvatarTag,
      mediaUuid: media.uuid,
    );
    refetchAvatar(username);
  }

  /// Soft-delete the media with [mediaUuid], if [findAvatarMedia] resolves
  /// it. Best-effort cleanup: an unresolved uuid stays an orphan media row.
  Future<void> softDeleteByUuid(SecureClient client, String mediaUuid) async {
    final media = await findAvatarMedia(client, mediaUuid);
    if (media == null) return;
    await client.media.softDelete(media.id);
  }
}
